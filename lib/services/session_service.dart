import 'dart:async';
import '../utils/constants.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  Timer? _timer;
  VoidCallback? _onTimeout;

  void start({required VoidCallback onTimeout}) {
    _onTimeout = onTimeout;
    _resetTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void userActivityPing() {
    // call on every user interaction
    if (_onTimeout == null) return;
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: AppConstants.sessionTimeoutSeconds), () {
      _onTimeout?.call();
    });
  }
}

typedef VoidCallback = void Function();