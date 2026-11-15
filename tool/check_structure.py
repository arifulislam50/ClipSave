"""Static sanity checks that need no SDK: imports resolve, brackets balance,
XML parses, and every @string/@drawable/@style/@color/@mipmap/@xml reference exists.
Usage: python3 -I tool/check_structure.py <project_root>"""
import re, sys
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
errors = []

def strip_code(src, raw_prefix):
    """Remove comments and string literals (Dart/Kotlin) so brackets can be counted."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith('//', i):
            i = src.find('\n', i); i = n if i < 0 else i; continue
        if src.startswith('/*', i):
            i = src.find('*/', i + 2) + 2; continue
        raw = raw_prefix and c == 'r' and i + 1 < n and src[i+1] in '\'"' and (i == 0 or not (src[i-1].isalnum() or src[i-1] == '_'))
        if raw: i += 1; c = src[i]
        if c in '\'"':
            q3 = src[i:i+3]
            if q3 in ("'''", '"""'):
                i = src.index(q3, i + 3) + 3; continue
            j = i + 1
            while src[j] != c:
                if src[j] == '\\' and not raw: j += 1
                elif c == '"' and src.startswith('${', j) and not raw_prefix:  # Kotlin template
                    depth = 1; j += 2
                    while depth:
                        depth += {'{': 1, '}': -1}.get(src[j], 0); j += 1
                    continue
                elif raw_prefix and src.startswith('${', j) and not raw:  # Dart interpolation
                    depth = 1; j += 2
                    while depth:
                        if src[j] in '\'"':
                            j = src.index(src[j], j + 1)
                        depth += {'{': 1, '}': -1}.get(src[j], 0); j += 1
                    continue
                j += 1
            i = j + 1; continue
        out.append(c); i += 1
    return ''.join(out)

def balance(path, raw_prefix):
    try:
        code = strip_code(path.read_text(), raw_prefix)
    except (ValueError, IndexError) as e:
        errors.append(f'{path}: unterminated string/comment ({e})'); return
    stack, pairs = [], {')': '(', ']': '[', '}': '{'}
    for ch in code:
        if ch in '([{': stack.append(ch)
        elif ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                errors.append(f'{path}: unbalanced {ch}'); return
    if stack: errors.append(f'{path}: unclosed {stack[-1]}')

dart_files = sorted(root.glob('lib/**/*.dart')) + sorted(root.glob('test/**/*.dart'))
for f in dart_files:
    balance(f, True)
    for imp in re.findall(r"^import '([^']+)'", f.read_text(), re.M):
        if imp.startswith('package:clipsave/'):
            target = root / 'lib' / imp[len('package:clipsave/'):]
        elif imp.startswith(('package:', 'dart:')):
            continue
        else:
            target = (f.parent / imp).resolve()
        if not target.exists(): errors.append(f'{f}: missing import {imp}')

kt_files = sorted(root.glob('android/**/*.kt'))
for f in kt_files: balance(f, False)

res = root / 'android/app/src/main/res'
defined = {'string': set(), 'color': set(), 'style': set(), 'drawable': set(), 'mipmap': set(), 'xml': set()}
xml_files = list(root.glob('android/app/src/**/*.xml'))
for f in xml_files:
    try: tree = ET.parse(f)
    except ET.ParseError as e: errors.append(f'{f}: {e}'); continue
    folder = f.parent.name.split('-')[0]
    if folder == 'values':
        for el in tree.getroot():
            if el.tag in defined: defined[el.tag].add(el.get('name'))
    elif folder in defined:
        defined[folder].add(f.stem)
for f in xml_files:
    for kind, name in re.findall(r'@(string|color|style|drawable|mipmap|xml)/(\w+)', f.read_text()):
        if name not in defined[kind]: errors.append(f'{f}: undefined @{kind}/{name}')
for f in kt_files:
    for kind, name in re.findall(r'R\.(string|drawable)\.(\w+)', f.read_text()):
        if name not in defined[kind]: errors.append(f'{f}: undefined R.{kind}.{name}')

manifest = (root / 'android/app/src/main/AndroidManifest.xml').read_text()
for cls in re.findall(r'android:name="\.(\w+)"', manifest):
    if not (root / f'android/app/src/main/kotlin/com/clipsave/app/{cls}.kt').exists():
        errors.append(f'manifest references missing class {cls}')
# Only the network permissions AdMob needs; no runtime (dangerous) permissions.
ALLOWED_PERMISSIONS = {'android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE'}
for perm in re.findall(r'<uses-permission[^>]*android:name="([^"]+)"', manifest):
    if perm not in ALLOWED_PERMISSIONS:
        errors.append(f'unexpected permission in main manifest: {perm}')

# Channel names must match on both sides.
kt = (root / 'android/app/src/main/kotlin/com/clipsave/app/MainActivity.kt').read_text()
dart = (root / 'lib/platform/clipboard_bridge.dart').read_text()
for ch in re.findall(r'"(com\.clipsave\.app/\w+)"', kt):
    if f"'{ch}'" not in dart: errors.append(f'channel {ch} not used in Dart')
for m in re.findall(r"invokeMethod<[^>]+>\(\s*'(\w+)'", dart):
    if f'"{m}"' not in kt: errors.append(f'method {m} not handled in Kotlin')

# ---- Security invariants -------------------------------------------------
ctrl = (root / 'lib/state/clips_controller.dart').read_text()
# Split the controller into members by indentation: a member starts on a line
# with exactly two spaces of indent and ends at the next "  }" line.
members, current, lines = {}, None, []
for line in ctrl.split('\n'):
    if current is None:
        if re.match(r'  [^ }/@]', line):
            m = re.search(r'(\w+)\(', line)
            if m and not line.rstrip().endswith(';'):
                current, lines = m.group(1), []
    elif line == '  }':
        members.setdefault(current, '\n'.join(lines)); current = None
    else:
        lines.append(line)
def body(name): return members.get(name)
for fn, store in (('_importInbox', '_repo.saveText('), ('_onAutoCaptured', '_store(')):
    b = body(fn)
    if b is None:
        errors.append(f'invariant: {fn} not found'); continue
    gate, save = b.find('_autoFilterReason('), b.find(store)
    if gate < 0 or save < 0 or gate > save:
        errors.append(f'invariant: {fn} must call _autoFilterReason before {store}')
gate_body = body('_autoFilterReason') or ''
if 'systemSensitive' not in gate_body or 'SensitiveDetector.detect' not in gate_body:
    errors.append('invariant: _autoFilterReason must check systemSensitive and SensitiveDetector')
# saveText may only be called from the gated import, the explicit "Save anyway", and _store.
callers = [name for name, b in members.items() if '_repo.saveText(' in b]
if sorted(set(callers)) != ['_importInbox', '_store', 'saveHeldSensitive']:
    errors.append(f'invariant: unexpected saveText callers {callers}')
inbox_kt = (root / 'android/app/src/main/kotlin/com/clipsave/app/ClipInbox.kt').read_text()
if 'MAX_CLIP_LENGTH' not in inbox_kt:
    errors.append('invariant: ClipInbox.add must cap text length')
if not re.search(r'ClipboardCaptureActivity"\s+android:exported="false"', manifest):
    errors.append('invariant: ClipboardCaptureActivity must not be exported')
# ---- Ads isolation ----------------------------------------------------------
ad_cfg = (root / 'lib/core/ad_config.dart').read_text()
dart_app_id = re.search(r"androidAppId = '([^']+)'", ad_cfg).group(1)
mf_app_id = re.search(r'com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value="([^"]+)"', manifest)
if not mf_app_id or mf_app_id.group(1) != dart_app_id:
    errors.append('AdMob App ID in AndroidManifest.xml must match AdConfig.androidAppId')
AD_FILES = {'lib/ads/ads_service.dart', 'lib/ui/widgets/ad_banner.dart'}
for f in dart_files:
    src = f.read_text()
    rel = f.relative_to(root).as_posix()
    if 'package:google_mobile_ads' in src and rel not in AD_FILES and not rel.startswith('test/'):
        errors.append(f'only {sorted(AD_FILES)} may import google_mobile_ads, not {rel}')
    if rel in AD_FILES:
        for banned in ('data/', 'clips_controller', 'clipboard_bridge', 'ClipItem', 'clip_actions'):
            if banned in src:
                errors.append(f'{rel} must not reference {banned} (clip data must never reach ads)')
        for m in re.finditer(r'AdRequest\(([^)]*)\)', src):
            if m.group(1).strip():
                errors.append(f'{rel}: AdRequest must have no targeting arguments, found ({m.group(1).strip()})')

# ---- Logo geometry: Dart widget == generator ---------------------------------
gen = (root / 'tool/generate_logo.py').read_text()
logo = (root / 'lib/ui/widgets/app_logo.dart').read_text()
NUM = r'(\d+(?:\.\d+)?)'
py_cards = [tuple(map(float, c)) for c in re.findall(rf'\({NUM}, {NUM}, {NUM}, {NUM}, [\d.]+\)', gen.split('CARDS_XYWH =')[1].split(']')[0])]
dart_cards = [tuple(map(float, c)) for c in re.findall(rf'Rect\.fromLTWH\({NUM}, {NUM}, {NUM}, {NUM}\)', logo)]
py_lines = [tuple(map(float, c)) for c in re.findall(rf'\(\({NUM}, {NUM}\), \({NUM}, {NUM}\)\)', gen.split('LINES =')[1].split('\n')[0])]
dart_lines = [tuple(map(float, c)) for c in re.findall(rf'\(Offset\({NUM}, {NUM}\), Offset\({NUM}, {NUM}\)\)', logo)]
for name, pat in (('RADIUS', r'RADIUS = ([\d.]+)'), ('STROKE', r'STROKE = ([\d.]+)')):
    dart_pat = {'RADIUS': r'cardRadius = ([\d.]+)', 'STROKE': r'stroke = ([\d.]+)'}[name]
    if float(re.search(pat, gen).group(1)) != float(re.search(dart_pat, logo).group(1)):
        errors.append(f'logo {name} differs between generate_logo.py and app_logo.dart')
if not py_cards or py_cards != dart_cards:
    errors.append(f'logo cards differ: generate_logo.py {py_cards} vs app_logo.dart {dart_cards}')
if not py_lines or py_lines != dart_lines:
    errors.append('logo lines differ between generate_logo.py and app_logo.dart')

# ---- "Save clipboard" is gone: New clip replaced it ---------------------------
for f in list(root.glob('lib/**/*.dart')) + list(root.glob('android/app/src/main/**/*.xml')) + \
        list(root.glob('android/app/src/main/**/*.kt')) + [root / n for n in ('README.md', 'PRIVACY_POLICY.md', 'BUILD.md')]:
    if f.exists() and 'Save clipboard' in f.read_text():
        errors.append(f'{f}: still mentions "Save clipboard" (replaced by New clip)')

# ---- APK size guards ---------------------------------------------------------
pub = (root / 'pubspec.yaml').read_text()
flutter_section = pub.split('\nflutter:\n', 1)[1] if '\nflutter:\n' in pub else ''
if re.search(r'^\s+assets:', flutter_section, re.M) or 'assets/logo' in flutter_section:
    errors.append('pubspec.yaml must not register assets (assets/logo/* are design files, not app assets)')
if re.search(r'^\s+fonts:', flutter_section, re.M):
    errors.append('pubspec.yaml must not bundle fonts (system font only)')
for banned in ('firebase', 'analytics', 'google_fonts', 'cupertino_icons'):
    if re.search(rf'^\s+{banned}\w*:', pub, re.M):
        errors.append(f'pubspec.yaml: unexpected dependency {banned}')
gradle = (root / 'android/app/build.gradle.kts').read_text()
for needle in ('isMinifyEnabled = true', 'isShrinkResources = true', 'useLegacyPackaging = false',
               'localeFilters += "en"', 'abiFilters += "arm64-v8a"', 'DebugProbesKt.bin'):
    if needle not in gradle:
        errors.append(f'build.gradle.kts: missing size setting {needle!r}')
rules = (root / 'android/app/proguard-rules.pro').read_text()
for keep in ('-keep class com.clipsave.app.** { *; }', '-keep class io.flutter.plugins.googlemobileads.** { *; }'):
    if keep not in rules:
        errors.append(f'proguard-rules.pro: missing {keep}')
cm = (root / 'codemagic.yaml').read_text()
for wf, flags in (('clipsave-android:', ['flutter build apk --debug']),
                  ('copybox-release-apk:', ['--target-platform android-arm64', '--split-debug-info=build/symbols', '--obfuscate', '--tree-shake-icons']),
                  ('copybox-release-aab:', ['flutter build appbundle --release', '--split-debug-info=build/symbols', '--obfuscate'])):
    if wf not in cm:
        errors.append(f'codemagic.yaml: missing workflow {wf}')
    else:
        block = cm.split(wf, 1)[1].split('\n  copybox-', 1)[0]
        for f in flags:
            if f not in block:
                errors.append(f'codemagic.yaml {wf} missing {f}')

ml = re.search(r'maxClipLength = ([\d_]+)', (root / 'lib/core/constants.dart').read_text()).group(1)
kl = re.search(r'MAX_CLIP_LENGTH = ([\d_]+)', (root / 'android/app/src/main/kotlin/com/clipsave/app/ClipReader.kt').read_text()).group(1)
if ml.replace('_', '') != kl.replace('_', ''):
    errors.append(f'invariant: Dart maxClipLength {ml} != Kotlin MAX_CLIP_LENGTH {kl}')

print(f'Checked {len(dart_files)} Dart, {len(kt_files)} Kotlin, {len(xml_files)} XML files')
print('\n'.join(errors) if errors else 'No structural problems found')
sys.exit(1 if errors else 0)
