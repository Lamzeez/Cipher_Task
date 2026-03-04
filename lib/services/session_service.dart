import 'dart:async';
import '../utils/constants.dart';

typedef VoidCallback = void Function();

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  Timer? _timeoutTimer;
  Timer? _warningTimer;
  VoidCallback? _onTimeout;
  VoidCallback? _onWarning;

  /// Start session tracking.
  /// [onTimeout]  - called when the full session time elapses with no activity.
  /// [onWarning]  - (optional) called AppConstants.sessionWarningBeforeSeconds
  ///                before timeout.
  void start({
    required VoidCallback onTimeout,
    VoidCallback? onWarning,
  }) {
    _onTimeout = onTimeout;
    _onWarning = onWarning;
    _resetTimers();
  }

  void stop() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
  }

  /// Call this on every user interaction (tap / scroll etc.).
  void userActivityPing() {
    if (_onTimeout == null) return;
    _resetTimers();
  }

  void _resetTimers() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();

    final total = AppConstants.sessionTimeoutSeconds;
    final warnBefore = AppConstants.sessionWarningBeforeSeconds;

    // Schedule warning first (if provided and meaningful)
    if (_onWarning != null && warnBefore > 0 && total > warnBefore) {
      final delay = total - warnBefore;
      _warningTimer = Timer(Duration(seconds: delay), () {
        _onWarning?.call();
      });
    }

    // Schedule final timeout
    _timeoutTimer = Timer(Duration(seconds: total), () {
      _onTimeout?.call();
    });
  }
}