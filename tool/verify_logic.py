"""Offline verification for Copy Box (no Flutter SDK needed).

1. Extracts every RegExp from the Dart detector/classifier sources, re-implements
   the same decision logic in Python, and runs the test cases parsed from
   test/*.dart.
2. Extracts the SQL from lib/data/db/schema.dart and exercises it in SQLite with
   the same statements ClipRepository issues.

Usage: python3 -I tool/verify_logic.py <project_root>
"""
import re, sqlite3, sys, time
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
fails = 0
def check(cond, label):
    global fails
    print(('PASS ' if cond else 'FAIL ') + label)
    if not cond: fails += 1

def dart_regexes(path):
    src = (root / path).read_text()
    out = {}
    for m in re.finditer(r"static final RegExp (\w+)\s*=\s*RegExp\(", src):
        i = m.end(); depth = 1; j = i
        while depth:
            c = src[j]
            if c == "'" :
                j = src.index("'", j + 1)  # raw strings in these files have no escaped quotes
            elif c == '(': depth += 1
            elif c == ')': depth -= 1
            j += 1
        body = src[i:j-1]
        pattern = ''.join(re.findall(r"r'([^']*)'", body))
        flags = re.ASCII | (re.IGNORECASE if 'caseSensitive: false' in body else 0)
        out[m.group(1)] = re.compile(pattern, flags)
    return out

# ---------------------------------------------------------------- detector --
D = dart_regexes('lib/core/utils/sensitive_detector.dart')
def has(name, t): return D[name].search(t) is not None
def luhn(d):
    if not (13 <= len(d) <= 19): return False
    s = 0
    for i, ch in enumerate(reversed(d)):
        n = int(ch)
        if i % 2: n *= 2; n -= 9 if n > 9 else 0
        s += n
    return s % 10 == 0
def detect(raw):
    t = raw.strip()
    if not t: return None
    if has('_privateKey', t): return 'secretKey'
    if has('_otpOnly', t): return 'otp'
    if len(t) <= 200 and has('_otpKeyword', t) and has('_otpNumber', t): return 'otp'
    if has('_cardShape', t) and luhn(re.sub(r'[^0-9]', '', t)): return 'card'
    if has('_whitespace', t): return None
    if has('_knownToken', t): return 'secretKey'
    if has('_urlOrEmail', t): return None
    lo, up, di, sy = (has(n, t) for n in ('_lower', '_upper', '_digit', '_symbol'))
    if len(t) >= 32 and has('_genericToken', t) and di and (lo or up): return 'secretKey'
    if 8 <= len(t) <= 64 and sum([lo, up, di, sy]) >= 3: return 'password'
    return None

def dart_str(s):  # undo Dart escapes used in the test literals
    return s.replace(r'\n', '\n')
ts = (root / 'test/sensitive_detector_test.dart').read_text()
flag_block = ts[ts.index('final cases'):ts.index('};')]
for inp, reason in re.findall(r"'((?:[^'\\]|\\.)*)': SensitiveReason\.(\w+)", flag_block):
    check(detect(dart_str(inp)) == reason, f'detect flags {inp!r} -> {reason}')
safe_block = ts[ts.index('const safe'):ts.index('];', ts.index('const safe'))]
for inp in re.findall(r"^\s*'((?:[^'\\]|\\.)*)',", safe_block, re.M):
    check(detect(dart_str(inp)) is None, f'detect ignores {inp!r}')

# -------------------------------------------------------------- classifier --
C = dart_regexes('lib/core/utils/content_classifier.dart')
def classify(raw):
    t = raw.strip()
    if not t or '\n' in t: return 'text'
    if C['_url'].search(t): return 'link'
    if C['_email'].search(t): return 'email'
    if C['_isoDate'].search(t): return 'text'
    digits = len(C['_nonDigit'].sub('', t))
    if C['_phoneChars'].search(t) and 7 <= digits <= 15 and (
            t.startswith('+') or C['_phoneSeparators'].search(t) or digits >= 10):
        return 'phone'
    if C['_number'].search(t): return 'number'
    return 'text'
cs = (root / 'test/content_classifier_test.dart').read_text()
for inp, cat in re.findall(r"'((?:[^'\\]|\\.)*)': ClipCategory\.(\w+)", cs):
    check(classify(dart_str(inp)) == cat, f'classify {inp!r} -> {cat}')

# --------------------------------------------------------------------- SQL --
schema = (root / 'lib/data/db/schema.dart').read_text()
def const(name):
    return re.search(rf"static const String {name} = '''(.*?)'''", schema, re.S).group(1)
indexes = re.findall(r"'(CREATE [^']+)'", schema)
db = sqlite3.connect(':memory:')
db.execute('PRAGMA foreign_keys = ON')
db.execute(const('createFolders')); db.execute(const('createClips'))
for sql in indexes: db.execute(sql)
check(len(indexes) == 4, 'schema: 4 indexes created')

def now(): return int(time.time() * 1000)
def save(content, source='manual'):
    row = db.execute('SELECT id FROM clips WHERE content = ? LIMIT 1', (content,)).fetchone()
    t = now(); time.sleep(0.003)
    if row:
        db.execute('UPDATE clips SET updated_at = ? WHERE id = ?', (t, row[0])); return row[0], False
    cur = db.execute('INSERT INTO clips (content, category, folder_id, is_favorite, source, created_at, updated_at) VALUES (?,?,?,?,?,?,?)',
                     (content, classify(content), None, 0, source, t, t))
    return cur.lastrowid, True
def query(where='', args=()):
    sql = 'SELECT content FROM clips' + (f' WHERE {where}' if where else '') + ' ORDER BY updated_at DESC, id DESC LIMIT 2000'
    return [r[0] for r in db.execute(sql, args)]
def esc(s): return s.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_')
LIKE = "content LIKE ? ESCAPE '\\'"

save('one'); save('two'); _, created = save('one')
check(not created and query() == ['one', 'two'], 'dedupe moves existing clip to top')
try:
    db.execute("INSERT INTO clips (content, created_at, updated_at) VALUES ('one', 1, 1)"); ok = False
except sqlite3.IntegrityError: ok = True
check(ok, 'unique index rejects duplicate content')

db.execute('DELETE FROM clips')
for t in ['100% done', '100 done', 'Snake_case', 'snakeXcase']: save(t)
check(query(LIKE, ('%' + esc('%') + '%',)) == ['100% done'], 'LIKE escapes %')
check(query(LIKE, ('%' + esc('E_C') + '%',)) == ['Snake_case'], 'LIKE escapes _ and is case-insensitive')

db.execute('DELETE FROM clips')
fid, _ = save('fav'); db.execute('UPDATE clips SET is_favorite = 1 WHERE id = ?', (fid,))
for i in range(5): save(f'item {i}')
db.execute(const('prune'), (2,))
check(set(query()) == {'fav', 'item 4', 'item 3'}, 'prune keeps favourites + newest N')

db.execute("INSERT INTO folders (name, color, created_at) VALUES ('Work', 1, 1)")
try:
    db.execute("INSERT INTO folders (name, color, created_at) VALUES ('work', 1, 1)"); ok = False
except sqlite3.IntegrityError: ok = True
check(ok, 'folder names unique, case-insensitive')
folder = db.execute("SELECT id FROM folders").fetchone()[0]
db.execute('UPDATE clips SET folder_id = ? WHERE content = ?', (folder, 'fav'))
rows = db.execute(const('foldersWithCounts')).fetchall()
check(rows[0][1] == 'Work' and rows[0][4] == 1, 'folders query returns clip counts')
db.execute('DELETE FROM folders WHERE id = ?', (folder,))
check(db.execute("SELECT folder_id FROM clips WHERE content='fav'").fetchone()[0] is None,
      'deleting folder sets clips.folder_id NULL (FK ON DELETE SET NULL)')
check(query('is_favorite = 1') == ['fav'], 'favourites filter')

print(f'\n{"ALL PASSED" if fails == 0 else str(fails) + " FAILED"}')
sys.exit(1 if fails else 0)
