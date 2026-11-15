/// Compact relative timestamps without extra dependencies.
class TimeFormat {
  TimeFormat._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String relative(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDiff = today.difference(day).inDays;
    if (dayDiff == 0) return '${diff.inHours} h ago';
    if (dayDiff == 1) return 'Yesterday ${clock(time)}';
    if (time.year == current.year) return '${time.day} ${_months[time.month - 1]}';
    return '${time.day} ${_months[time.month - 1]} ${time.year}';
  }

  static String clock(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String full(DateTime time) =>
      '${time.day} ${_months[time.month - 1]} ${time.year}, ${clock(time)}';
}
