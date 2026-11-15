/// Date/time formatting without the intl package.
///
/// Always uses the device's local time zone ([DateTime.toLocal]).
/// Examples: "15 Nov 2026 · 12:48 PM", "Today · 9:05 AM", "Yesterday · 12:00 AM".
class TimeFormat {
  TimeFormat._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 12-hour clock, no leading zero on the hour: "9:05 AM", "12:00 PM" (noon),
  /// "12:05 AM" (just after midnight).
  static String clock12(DateTime time) {
    final t = time.toLocal();
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "15 Nov 2026": day without leading zero, 3-letter English month, 4-digit year.
  static String date(DateTime time) {
    final t = time.toLocal();
    return '${t.day} ${_months[t.month - 1]} ${t.year.toString().padLeft(4, '0')}';
  }

  /// Always the full form: "15 Nov 2026 · 12:48 PM".
  static String absolute(DateTime time) => '${date(time)} · ${clock12(time)}';

  /// "Today · 12:48 PM", "Yesterday · 9:30 PM", otherwise "15 Nov 2026 · 12:48 PM".
  ///
  /// Compares local calendar days (not 24-hour spans), so it is correct across
  /// midnight and DST changes; a date "in the future" (device clock moved
  /// back) falls back to the full date. Pass [now] in tests.
  static String formatDateTime(DateTime time, {DateTime? now}) {
    final t = time.toLocal();
    final days = _dayNumber((now ?? DateTime.now()).toLocal()) - _dayNumber(t);
    if (days == 0) return 'Today · ${clock12(t)}';
    if (days == 1) return 'Yesterday · ${clock12(t)}';
    return absolute(t);
  }

  /// Spoken form for screen readers: "15 Nov 2026 at 12:48 PM".
  static String semantic(DateTime time) => '${date(time)} at ${clock12(time)}';

  /// Days since the epoch for the local calendar date (DST-safe).
  static int _dayNumber(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
