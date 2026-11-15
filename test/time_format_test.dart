import 'package:clipsave/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 14, 30); // local time

  group('clock12', () {
    test('midnight is 12 AM', () => expect(TimeFormat.clock12(DateTime(2026, 1, 1, 0, 5)), '12:05 AM'));
    test('noon is 12 PM', () => expect(TimeFormat.clock12(DateTime(2026, 1, 1, 12, 0)), '12:00 PM'));
    test('single-digit hour, no leading zero', () {
      expect(TimeFormat.clock12(DateTime(2026, 1, 1, 9, 5)), '9:05 AM');
      expect(TimeFormat.clock12(DateTime(2026, 1, 1, 21, 30)), '9:30 PM');
    });
    test('11:59 PM', () => expect(TimeFormat.clock12(DateTime(2026, 1, 1, 23, 59)), '11:59 PM'));
  });

  group('formatDateTime', () {
    test('today', () {
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 15, 12, 48), now: now), 'Today · 12:48 PM');
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 15, 0, 0), now: now), 'Today · 12:00 AM');
    });
    test('yesterday (calendar day, not 24 hours)', () {
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 14, 21, 30), now: now), 'Yesterday · 9:30 PM');
      // 23:59 yesterday and 00:01 today are 2 minutes apart but different days.
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 14, 23, 59),
          now: DateTime(2026, 11, 15, 0, 1)), 'Yesterday · 11:59 PM');
    });
    test('two days ago and other year use the full date', () {
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 13, 8, 0), now: now), '13 Nov 2026 · 8:00 AM');
      expect(TimeFormat.formatDateTime(DateTime(2025, 3, 2, 16, 7), now: now), '2 Mar 2025 · 4:07 PM');
    });
    test('across a year boundary', () {
      expect(TimeFormat.formatDateTime(DateTime(2025, 12, 31, 23, 0), now: DateTime(2026, 1, 1, 0, 30)),
          'Yesterday · 11:00 PM');
    });
    test('a future date (clock moved back) shows the full date', () {
      expect(TimeFormat.formatDateTime(DateTime(2026, 11, 16, 9, 0), now: now), '16 Nov 2026 · 9:00 AM');
    });
    test('UTC input is shown in the device local time zone', () {
      final utc = DateTime.utc(2026, 11, 15, 6, 48);
      final local = utc.toLocal();
      expect(TimeFormat.formatDateTime(utc, now: DateTime(2030, 1, 1)), TimeFormat.absolute(local));
      expect(TimeFormat.absolute(utc), '${TimeFormat.date(local)} · ${TimeFormat.clock12(local)}');
    });
  });

  test('absolute and semantic forms', () {
    final t = DateTime(2026, 11, 15, 12, 48);
    expect(TimeFormat.absolute(t), '15 Nov 2026 · 12:48 PM');
    expect(TimeFormat.semantic(t), '15 Nov 2026 at 12:48 PM');
  });
}
