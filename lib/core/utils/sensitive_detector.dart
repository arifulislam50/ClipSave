/// Why a piece of text looks sensitive.
enum SensitiveReason {
  flaggedBySystem('item the copying app marked as sensitive'),
  otp('one-time code'),
  password('password'),
  card('payment card number'),
  secretKey('private key or access token');

  const SensitiveReason(this.label);
  final String label;

  /// Full sentence for dialogs and messages.
  String get explanation => this == SensitiveReason.flaggedBySystem
      ? 'The app that copied this marked it as sensitive.'
      : 'This looks like a $label.';
}

/// Conservative, on-device heuristics used to skip likely secrets during
/// AUTOMATIC capture. It errs on the side of privacy: a false positive
/// simply means the user saves that clip manually.
class SensitiveDetector {
  SensitiveDetector._();

  static final RegExp _otpOnly = RegExp(r'^\d{4,8}$');
  static final RegExp _otpKeyword = RegExp(
    r'\b(otp|one[- ]?time|verification|verify|passcode|security code|'
    r'login code|auth(entication)? code|pin|2fa|code)\b',
    caseSensitive: false,
  );
  static final RegExp _otpNumber = RegExp(r'\b\d{4,8}\b');
  static final RegExp _cardShape = RegExp(r'^(?:\d[ \-]?){12,18}\d$');
  static final RegExp _privateKey =
      RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----');
  static final RegExp _knownToken = RegExp(
    r'^(sk|pk|rk)_(live|test)_[A-Za-z0-9]{10,}$|'
    r'^gh[pousr]_[A-Za-z0-9]{20,}$|'
    r'^xox[abprs]-[A-Za-z0-9\-]{10,}$|'
    r'^AKIA[0-9A-Z]{16}$|'
    r'^AIza[0-9A-Za-z_\-]{30,}$|'
    r'^eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+$',
  );
  static final RegExp _genericToken = RegExp(r'^[A-Za-z0-9_\-+/=]{32,}$');
  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _urlOrEmail =
      RegExp(r'^(https?://|www\.)|^[^@\s]+@[^@\s]+\.[^@\s]+$', caseSensitive: false);
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');
  static final RegExp _nonDigit = RegExp(r'[^0-9]');

  static SensitiveReason? detect(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    if (_privateKey.hasMatch(t)) return SensitiveReason.secretKey;
    if (_otpOnly.hasMatch(t)) return SensitiveReason.otp;
    if (t.length <= 200 && _otpKeyword.hasMatch(t) && _otpNumber.hasMatch(t)) {
      return SensitiveReason.otp;
    }
    if (_cardShape.hasMatch(t) && luhnValid(t.replaceAll(_nonDigit, ''))) {
      return SensitiveReason.card;
    }

    if (_whitespace.hasMatch(t)) return null; // Sentences are not secrets.
    if (_knownToken.hasMatch(t)) return SensitiveReason.secretKey;
    if (_urlOrEmail.hasMatch(t)) return null;

    final hasLower = _lower.hasMatch(t);
    final hasUpper = _upper.hasMatch(t);
    final hasDigit = _digit.hasMatch(t);
    final hasSymbol = _symbol.hasMatch(t);

    if (t.length >= 32 &&
        _genericToken.hasMatch(t) &&
        hasDigit &&
        (hasLower || hasUpper)) {
      return SensitiveReason.secretKey;
    }

    final classes = [hasLower, hasUpper, hasDigit, hasSymbol].where((b) => b).length;
    if (t.length >= 8 && t.length <= 64 && classes >= 3) {
      return SensitiveReason.password;
    }
    return null;
  }

  /// Luhn checksum used by payment card numbers.
  static bool luhnValid(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 48;
      if (d < 0 || d > 9) return false;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }
}
