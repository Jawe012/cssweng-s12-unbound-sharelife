import 'dart:async';
import 'package:flutter/widgets.dart';

typedef SessionCallback = Future<void> Function();

class SessionManager with WidgetsBindingObserver {
  SessionManager._private();

  static final SessionManager instance = SessionManager._private();

  Duration timeout = const Duration(minutes: 15);
  Duration warning = const Duration(seconds: 30);

  Timer? _timer;
  DateTime? _expiry;
  SessionCallback? onTimeout;
  SessionCallback? onWarning;

  void configure({required Duration timeoutDuration, Duration? warningDuration, SessionCallback? onTimeoutCallback, SessionCallback? onWarningCallback}) {
    timeout = timeoutDuration;
    if (warningDuration != null) warning = warningDuration;
    onTimeout = onTimeoutCallback;
    onWarning = onWarningCallback;
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);
    resetTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  void resetTimer() {
    _timer?.cancel();
    final now = DateTime.now();
    _expiry = now.add(timeout);

    final warningDelay = timeout - warning;
    if (warningDelay > Duration.zero) {
      _timer = Timer(warningDelay, () async {
        if (onWarning != null) await onWarning!();
        _timer = Timer(warning, () async {
          if (onTimeout != null) await onTimeout!();
        });
      });
    } else {
      _timer = Timer(timeout, () async {
        if (onTimeout != null) await onTimeout!();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      resetTimer();
    }
  }

  Duration? get remaining {
    if (_expiry == null) return null;
    return _expiry!.difference(DateTime.now());
  }
}
