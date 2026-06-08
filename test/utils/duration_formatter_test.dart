import 'package:flutter_test/flutter_test.dart';
import 'package:doro/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    group('format()', () {
      test('formats zero duration as 00:00:00', () {
        expect(
          DurationFormatter.format(Duration.zero),
          equals('00:00:00'),
        );
      });

      test('formats seconds correctly', () {
        expect(
          DurationFormatter.format(const Duration(seconds: 5)),
          equals('00:00:05'),
        );
      });

      test('formats minutes correctly', () {
        expect(
          DurationFormatter.format(const Duration(minutes: 3, seconds: 45)),
          equals('00:03:45'),
        );
      });

      test('formats hours correctly', () {
        expect(
          DurationFormatter.format(
              const Duration(hours: 2, minutes: 30, seconds: 15)),
          equals('02:30:15'),
        );
      });

      test('pads single digit values', () {
        expect(
          DurationFormatter.format(
              const Duration(hours: 1, minutes: 5, seconds: 9)),
          equals('01:05:09'),
        );
      });

      test('handles 99+ hours', () {
        expect(
          DurationFormatter.format(const Duration(hours: 100)),
          equals('100:00:00'),
        );
      });
    });

    group('fromSeconds()', () {
      test('converts 0 seconds to 00:00:00', () {
        expect(DurationFormatter.fromSeconds(0), equals('00:00:00'));
      });

      test('converts 3661 seconds correctly', () {
        // 1 hour, 1 minute, 1 second
        expect(DurationFormatter.fromSeconds(3661), equals('01:01:01'));
      });

      test('converts 90 seconds to 00:01:30', () {
        expect(DurationFormatter.fromSeconds(90), equals('00:01:30'));
      });
    });

    group('formatShort()', () {
      test('shows MM:SS when under an hour', () {
        expect(
          DurationFormatter.formatShort(const Duration(minutes: 5, seconds: 30)),
          equals('05:30'),
        );
      });

      test('shows H:MM:SS when over an hour', () {
        expect(
          DurationFormatter.formatShort(
              const Duration(hours: 2, minutes: 5, seconds: 30)),
          equals('2:05:30'),
        );
      });
    });

    group('formatHuman()', () {
      test('shows Xm for minutes only', () {
        expect(
          DurationFormatter.formatHuman(const Duration(minutes: 45)),
          equals('45m'),
        );
      });

      test('shows Xh for hours only', () {
        expect(
          DurationFormatter.formatHuman(const Duration(hours: 3)),
          equals('3h'),
        );
      });

      test('shows Xh Ym for hours and minutes', () {
        expect(
          DurationFormatter.formatHuman(
              const Duration(hours: 1, minutes: 30)),
          equals('1h 30m'),
        );
      });

      test('shows Xs for seconds only', () {
        expect(
          DurationFormatter.formatHuman(const Duration(seconds: 45)),
          equals('45s'),
        );
      });
    });

    group('splitDigits()', () {
      test('returns list of three parts', () {
        final parts = DurationFormatter.splitDigits(
            const Duration(hours: 1, minutes: 30, seconds: 45));
        expect(parts.length, equals(3));
        expect(parts[0], equals('01'));
        expect(parts[1], equals('30'));
        expect(parts[2], equals('45'));
      });
    });
  });
}
