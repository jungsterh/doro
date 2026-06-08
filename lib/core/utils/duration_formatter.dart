class DurationFormatter {
  DurationFormatter._();

  /// Formats duration as HH:MM:SS
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';
  }

  /// Formats duration as H:MM:SS (no leading zero on hours if single digit)
  static String formatShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${_pad(minutes)}:${_pad(seconds)}';
    }
    return '${_pad(minutes)}:${_pad(seconds)}';
  }

  /// Formats duration as human readable string e.g. "2h 30m"
  static String formatHuman(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Formats seconds as HH:MM:SS
  static String fromSeconds(int totalSeconds) {
    return format(Duration(seconds: totalSeconds));
  }

  static String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// Splits HH:MM:SS into its components as a list of strings
  /// Returns [hh, mm, ss]
  static List<String> splitDigits(Duration duration) {
    final formatted = format(duration);
    final parts = formatted.split(':');
    return parts; // ['HH', 'MM', 'SS']
  }
}
