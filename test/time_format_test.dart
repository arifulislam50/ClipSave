import 'package:clipsave/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 14, 30);

  test('relative times', () {
    expect(TimeFormat.relative(now.subtract(const Duration(seconds: 10)), now: now),
        'Just now');
    expect(TimeFormat.relative(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago');
    expect(TimeFormat.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3 h ago');
    expect(TimeFormat.relative(DateTime(2026, 11, 14, 9, 5), now: now),
        'Yesterday 09:05');
    expect(TimeFormat.relative(DateTime(2026, 3, 2), now: now), '2 Mar');
    expect(TimeFormat.relative(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
  });

  test('full', () {
    expect(TimeFormat.full(DateTime(2026, 1, 5, 7, 9)), '5 Jan 2026, 07:09');
  });
}
