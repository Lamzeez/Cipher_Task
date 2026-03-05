import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/database_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/todo_list_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await DatabaseService.instance.init();

  runApp(const CipherTaskApp());
}

class CipherTaskApp extends StatefulWidget {
  const CipherTaskApp({super.key});

  @override
  State<CipherTaskApp> createState() => _CipherTaskAppState();
}

class _CipherTaskAppState extends State<CipherTaskApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  bool _warningDialogOpen = false;
  bool _sessionRunning = false;

  @override
  void initState() {
    super.initState();
    _initScreenProtection();
  }

  @override
  void dispose() {
    SessionService.instance.stop();
    super.dispose();
  }

  void _startSessionIfNeeded(BuildContext ctx) {
    if (_sessionRunning) return;

    _sessionRunning = true;

    SessionService.instance.start(
      onTimeout: () {
        final nav = _navKey.currentState;
        final context = _navKey.currentContext;
        if (nav == null || context == null) return;

        // Close warning dialog if still open
        if (_warningDialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _warningDialogOpen = false;
        }

        // Logout
        context.read<AuthViewModel>().logout();

        // Go back to login
        nav.popUntil((route) => route.isFirst);

        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Session expired. You have been logged out.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onWarning: () {
        final context = _navKey.currentContext;
        if (context == null) return;
        _showSessionWarningDialog(context);
      },
    );
  }

  void _stopSessionIfNeeded() {
    if (!_sessionRunning) return;

    // Close warning dialog if still open
    final ctx = _navKey.currentContext;
    if (ctx != null && _warningDialogOpen) {
      Navigator.of(ctx, rootNavigator: true).pop();
      _warningDialogOpen = false;
    }

    SessionService.instance.stop();
    _sessionRunning = false;
  }

  void _showSessionWarningDialog(BuildContext rootContext) {
    if (_warningDialogOpen) return;
    _warningDialogOpen = true;

    int secondsLeft = 30;
    Timer? countdownTimer;

    showDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            countdownTimer ??= Timer.periodic(
              const Duration(seconds: 1),
              (timer) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }
                if (secondsLeft <= 1) {
                  timer.cancel();
                  setState(() => secondsLeft = 0);
                  return;
                }
                setState(() => secondsLeft--);
              },
            );

            return AlertDialog(
              title: const Text('Session expiring soon'),
              content: Text(
                'You have been inactive for a while.\n\n'
                'You will be logged out in $secondsLeft seconds unless you continue using the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    _warningDialogOpen = false;
                  },
                  child: const Text('Ignore'),
                ),
                ElevatedButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    _warningDialogOpen = false;

                    // Reset full session timer
                    SessionService.instance.userActivityPing();
                  },
                  child: const Text('Stay signed in'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _warningDialogOpen = false;
      countdownTimer?.cancel();
    });
  }

  Future<void> _initScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      debugPrint('ScreenProtector error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..loadUser()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
      ],
      child: MaterialApp(
        navigatorKey: _navKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: buildCyberpunkTheme(),
        home: Consumer<AuthViewModel>(
          builder: (ctx, auth, _) {
            // Only run session when authenticated
            if (auth.isAuthenticated) {
              _startSessionIfNeeded(ctx);
              // Only ping session when authenticated
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) =>
                    SessionService.instance.userActivityPing(),
                child: const TodoListView(),
              );
            } else {
              // Stop session on login/register/otp pages
              _stopSessionIfNeeded();
              return const LoginView();
            }
          },
        ),
      ),
    );
  }
}