import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

enum DateRange { week, month, ytd, custom }

extension DateRangeLabel on DateRange {
  String get label {
    switch (this) {
      case DateRange.week:
        return 'Week';
      case DateRange.month:
        return 'Month';
      case DateRange.ytd:
        return 'This Year';
      case DateRange.custom:
        return 'Custom';
    }
  }
}

class DateRangeState {
  final DateRange range;
  final DateTime? customStart;
  final DateTime? customEnd;

  const DateRangeState({
    this.range = DateRange.week,
    this.customStart,
    this.customEnd,
  });

  DateRangeState copyWith({
    DateRange? range,
    DateTime? customStart,
    DateTime? customEnd,
    bool clearCustom = false,
  }) {
    return DateRangeState(
      range: range ?? this.range,
      customStart: clearCustom ? null : (customStart ?? this.customStart),
      customEnd: clearCustom ? null : (customEnd ?? this.customEnd),
    );
  }

  /// Returns the [from, to] DateTime bounds for the selected range.
  (DateTime, DateTime) get bounds {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (range) {
      case DateRange.week:
        return (today.subtract(const Duration(days: 7)), today);
      case DateRange.month:
        return (
          DateTime(now.year, now.month - 1, now.day),
          today,
        );
      case DateRange.ytd:
        return (DateTime(now.year, 1, 1), today);
      case DateRange.custom:
        return (
          customStart ?? today.subtract(const Duration(days: 30)),
          customEnd ?? today,
        );
    }
  }
}

class DateRangeNotifier extends StateNotifier<DateRangeState> {
  DateRangeNotifier() : super(const DateRangeState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(AppConstants.prefDateRangeIndex) ?? 0;
    final range = DateRange.values[idx.clamp(0, DateRange.values.length - 1)];
    state = state.copyWith(range: range);
  }

  Future<void> setRange(DateRange range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefDateRangeIndex, range.index);
    state = state.copyWith(range: range, clearCustom: range != DateRange.custom);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      range: DateRange.custom,
      customStart: start,
      customEnd: end,
    );
  }
}

final dateRangeProvider =
    StateNotifierProvider<DateRangeNotifier, DateRangeState>(
  (ref) => DateRangeNotifier(),
);
