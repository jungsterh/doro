import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake during an active session and dims it to a
/// power-saving level after a period of no interaction. The session stays
/// visible — only the backlight is lowered — and full brightness is restored
/// on the next interaction.
///
/// All platform calls are guarded: brightness control is unsupported on some
/// devices, and a failure here must never crash a running session.
class ScreenPowerService {
  ScreenPowerService({
    Duration idleTimeout = const Duration(seconds: 30),
    double dimLevel = 0.1,
  })  : _idleTimeout = idleTimeout,
        _dimLevel = dimLevel;

  final Duration _idleTimeout;
  final double _dimLevel;
  final ScreenBrightness _brightness = ScreenBrightness();

  Timer? _idleTimer;
  double? _restoreBrightness;
  bool _dimmed = false;
  bool _engaged = false;

  /// Whether the screen is currently dimmed for power saving.
  bool get isDimmed => _dimmed;

  /// Begin managing the screen: hold the wakelock, capture the current
  /// brightness so it can be restored, and start the inactivity countdown.
  Future<void> engage() async {
    if (_engaged) return;
    _engaged = true;
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('ScreenPowerService: wakelock enable failed: $e');
    }
    try {
      _restoreBrightness = await _brightness.application;
    } catch (e) {
      debugPrint('ScreenPowerService: read brightness failed: $e');
      _restoreBrightness = null;
    }
    _resetIdleTimer();
  }

  /// Register a user interaction: restore full brightness if dimmed and
  /// restart the inactivity countdown.
  void registerActivity() {
    if (!_engaged) return;
    if (_dimmed) {
      _restore();
    }
    _resetIdleTimer();
  }

  /// Pause power management (e.g. the session was paused). The screen is
  /// restored to full brightness and no further dimming occurs until [engage]
  /// or [registerActivity] runs again.
  void suspend() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (_dimmed) _restore();
  }

  /// Stop managing the screen entirely: restore brightness and release the
  /// wakelock. Safe to call more than once.
  Future<void> release() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    _engaged = false;
    if (_dimmed) _restore();
    try {
      await _brightness.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('ScreenPowerService: reset brightness failed: $e');
    }
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('ScreenPowerService: wakelock disable failed: $e');
    }
    _dimmed = false;
    _restoreBrightness = null;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _dim);
  }

  Future<void> _dim() async {
    if (!_engaged || _dimmed) return;
    _dimmed = true;
    try {
      await _brightness.setApplicationScreenBrightness(_dimLevel);
    } catch (e) {
      debugPrint('ScreenPowerService: dim failed: $e');
      _dimmed = false;
    }
  }

  Future<void> _restore() async {
    _dimmed = false;
    try {
      final target = _restoreBrightness;
      if (target != null) {
        await _brightness.setApplicationScreenBrightness(target);
      } else {
        await _brightness.resetApplicationScreenBrightness();
      }
    } catch (e) {
      debugPrint('ScreenPowerService: restore brightness failed: $e');
    }
  }
}
