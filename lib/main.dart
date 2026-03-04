import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screen_protector/screen_protector.dart';

import 'services/database_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/todo_list_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment (.env)
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

  @override
  void initState() {
    super.initState();

    _initScreenProtection();

    // Start the inactivity session timer with warning + timeout
    SessionService.instance.start(
      onTimeout: () {
        final nav = _navKey.currentState;
        final ctx = _navKey.currentContext;
        if (nav == null || ctx == null) return;

        // Close the warning dialog if it's still open
        if (_warningDialogOpen) {
          Navigator.of(ctx, rootNavigator: true).pop();
          _warningDialogOpen = false;
        }

        // Mark user as logged out
        ctx.read<AuthViewModel>().logout();

        // Go back to the first route; Consumer<AuthViewModel> there
        // will rebuild as LoginView because isAuthenticated == false.
        nav.popUntil((route) => route.isFirst);

        // Optional: show a SnackBar if still mounted somewhere
        // (safe guard: use root context if available)
        final messenger = ScaffoldMessenger.maybeOf(ctx);
        if (messenger != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Session expired. You have been logged out.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onWarning: () {
        final ctx = _navKey.currentContext;
        if (ctx == null) return;
        _showSessionWarningDialog(ctx);
      },
    );
  }

  @override
  void dispose() {
    SessionService.instance.stop();
    super.dispose();
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
            // Start countdown once
            countdownTimer ??= Timer.periodic(
              const Duration(seconds: 1),
              (timer) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }
                if (secondsLeft <= 1) {
                  timer.cancel();
                  setState(() {
                    secondsLeft = 0;
                  });
                  return;
                }
                setState(() {
                  secondsLeft--;
                });
              },
            );

            return AlertDialog(
              title: const Text('Session expiring soon'),
              content: Text(
                'You have been inactive for a while.\n\n'
                'You will be logged out in $secondsLeft seconds unless you '
                'continue using the app.',
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

                    // Treat this as user activity → reset full session timer
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
      // Dialog dismissed in any way
      _warningDialogOpen = false;
      countdownTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..loadUser()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
      ],
      // Any pointer tap/scroll resets idle timer
      child: Listener(
        onPointerDown: (_) => SessionService.instance.userActivityPing(),
        child: MaterialApp(
          navigatorKey: _navKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: buildCyberpunkTheme(), // 🔥 restore cyberpunk theme here
          home: Consumer<AuthViewModel>(
            builder: (_, auth, __) {
              return auth.isAuthenticated
                  ? const TodoListView()
                  : const LoginView();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _initScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      debugPrint('ScreenProtector error: $e');
    }
  }
}