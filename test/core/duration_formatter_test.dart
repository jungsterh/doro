import 'package:flutter_test/flutter_test.dart';
import 'package:doro/core/utils/duration_formatter.dart';

void main() {
  // ---------------------------------------------------------------------------
  group('DurationFormatter.format', () {
    test('zero duration → 00:00:00', () {
      expect(DurationFormatter.format(Duration.zero), '00:00:00');
    });

    test('seconds only → 00:00:09', () {
      expect(DurationFormatter.format(const Duration(seconds: 9)), '00:00:09');
    });

    test('minutes and seconds → 00:05:03', () {
      expect(
        DurationFormatter.format(const Duration(minutes: 5, seconds: 3)),
        '00:05:03',
      );
    });

    test('hours, minutes, seconds → 01:30:45', () {
      expect(
        DurationFormatter.format(
            const Duration(hours: 1, minutes: 30, seconds: 45)),
        '01:30:45',
      );
    });

    test('double-digit hours → 10:00:00', () {
      expect(DurationFormatter.format(const Duration(hours: 10)), '10:00:00');
    });

    test('23:59:59', () {
      expect(
        DurationFormatter.format(
            const Duration(hours: 23, minutes: 59, seconds: 59)),
        '23:59:59',
      );
    });

    test('59 seconds → 00:00:59', () {
      expect(
          DurationFormatter.format(const Duration(seconds: 59)), '00:00:59');
    });

    test('60 seconds rolls over to 00:01:00', () {
      expect(
          DurationFormatter.format(const Duration(seconds: 60)), '00:01:00');
    });
  });

  // ---------------------------------------------------------------------------
  group('DurationFormatter.formatShort', () {
    test('zero → 00:00', () {
      expect(DurationFormatter.formatShort(Duration.zero), '00:00');
    });

    test('under 1 hour shows MM:SS', () {
      expect(
        DurationFormatter.formatShort(
            const Duration(minutes: 4, seconds: 7)),
        '04:07',
      );
    });

    test('exactly 1 hour shows H:MM:SS without leading zero', () {
      expect(
        DurationFormatter.formatShort(const Duration(hours: 1)),
        '1:00:00',
      );
    });

    test('1 hour with minutes and seconds', () {
      expect(
        DurationFormatter.formatShort(
            const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('multi-digit hours → 12:00:05', () {
      expect(
        DurationFormatter.formatShort(
            const Duration(hours: 12, minutes: 0, seconds: 5)),
        '12:00:05',
      );
    });

    test('59:59 under an hour', () {
      expect(
        DurationFormatter.formatShort(
            const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('DurationFormatter.formatHuman', () {
    test('zero → 0s', () {
      expect(DurationFormatter.formatHuman(Duration.zero), '0s');
    });

    test('seconds only', () {
      expect(
          DurationFormatter.formatHuman(const Duration(seconds: 45)), '45s');
    });

    test('minutes only (no seconds shown)', () {
      expect(
          DurationFormatter.formatHuman(const Duration(minutes: 30)), '30m');
    });

    test('minutes only even with stray seconds', () {
      // 30m 30s → 30m (minutes takes precedence over seconds)
      expect(
        DurationFormatter.formatHuman(
            const Duration(minutes: 30, seconds: 30)),
        '30m',
      );
    });

    test('hours only when minutes are zero', () {
      expect(DurationFormatter.formatHuman(const Duration(hours: 2)), '2h');
    });

    test('hours and minutes', () {
      expect(
        DurationFormatter.formatHuman(
            const Duration(hours: 1, minutes: 30)),
        '1h 30m',
      );
    });

    test('hours with zero minutes shows hours only', () {
      expect(
        DurationFormatter.formatHuman(
            const Duration(hours: 3, seconds: 59)),
        '3h',
      );
    });

    test('large value → correct hours and minutes', () {
      expect(
        DurationFormatter.formatHuman(
            const Duration(hours: 10, minutes: 5)),
        '10h 5m',
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('DurationFormatter.fromSeconds', () {
    test('0 seconds → 00:00:00', () {
      expect(DurationFormatter.fromSeconds(0), '00:00:00');
    });

    test('1 second → 00:00:01', () {
      expect(DurationFormatter.fromSeconds(1), '00:00:01');
    });

    test('3600 seconds → 01:00:00', () {
      expect(DurationFormatter.fromSeconds(3600), '01:00:00');
    });

    test('3661 seconds → 01:01:01', () {
      expect(DurationFormatter.fromSeconds(3661), '01:01:01');
    });

    test('59 seconds → 00:00:59', () {
      expect(DurationFormatter.fromSeconds(59), '00:00:59');
    });

    test('86399 seconds → 23:59:59', () {
      expect(DurationFormatter.fromSeconds(86399), '23:59:59');
    });
  });

  // ---------------------------------------------------------------------------
  group('DurationFormatter.splitDigits', () {
    test('always returns exactly 3 parts', () {
      final parts = DurationFormatter.splitDigits(
          const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(parts.length, 3);
    });

    test('parts are [HH, MM, SS]', () {
      final parts = DurationFormatter.splitDigits(
          const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(parts[0], '01');
      expect(parts[1], '02');
      expect(parts[2], '03');
    });

    test('zero duration → [00, 00, 00]', () {
      expect(DurationFormatter.splitDigits(Duration.zero), ['00', '00', '00']);
    });

    test('59:59 → [00, 59, 59]', () {
      final parts = DurationFormatter.splitDigits(
          const Duration(minutes: 59, seconds: 59));
      expect(parts, ['00', '59', '59']);
    });
  });
}
