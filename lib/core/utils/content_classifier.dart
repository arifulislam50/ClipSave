/// Automatic categories, detected from the clip's content.
enum ClipCategory {
  text('text', 'Text'),
  link('link', 'Links'),
  email('email', 'Emails'),
  phone('phone', 'Phones'),
  number('number', 'Numbers');

  const ClipCategory(this.key, this.label);

  /// Stored in SQLite; never rename.
  final String key;
  final String label;

  static ClipCategory fromKey(String? key) {
    for (final c in ClipCategory.values) {
      if (c.key == key) return c;
    }
    return ClipCategory.text;
  }
}

class ContentClassifier {
  ContentClassifier._();

  static final RegExp _url =
      RegExp(r'^(https?://|www\.)[^\s]+$', caseSensitive: false);
  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+$');
  static final RegExp _phoneChars = RegExp(r'^\+?[0-9\s\-().]{7,20}$');
  static final RegExp _phoneSeparators = RegExp(r'[\s\-().]');
  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _number = RegExp(r'^-?[0-9][0-9,]*(\.[0-9]+)?$');
  static final RegExp _nonDigit = RegExp(r'[^0-9]');

  static ClipCategory classify(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t.contains('\n')) return ClipCategory.text;
    if (_url.hasMatch(t)) return ClipCategory.link;
    if (_email.hasMatch(t)) return ClipCategory.email;
    if (_isoDate.hasMatch(t)) return ClipCategory.text;

    final digits = t.replaceAll(_nonDigit, '').length;
    final looksLikePhone = _phoneChars.hasMatch(t) &&
        digits >= 7 &&
        digits <= 15 &&
        (t.startsWith('+') || _phoneSeparators.hasMatch(t) || digits >= 10);
    if (looksLikePhone) return ClipCategory.phone;
    if (_number.hasMatch(t)) return ClipCategory.number;
    return ClipCategory.text;
  }
}
