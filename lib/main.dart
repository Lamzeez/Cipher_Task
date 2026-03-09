import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/database_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'utils/snack_bar.dart';
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
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _warningDialogOpen = false;
  bool _sessionRunning = false;
  bool _notificationReady = false;

  @override
  void initState() {
    super.initState();
    _initScreenProtection();
    _initNotifications();
  }

  @override
  void dispose() {
    SessionService.instance.stop();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notifications.initialize(initSettings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'session_warning_channel',
          'Session Warning',
          description: 'Notifications for session expiration reminders',
          importance: Importance.max,
          playSound: true,
        ),
      );

      _notificationReady = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> _showSessionReminderNotification() async {
    if (!_notificationReady) return;

    try {
      await _notifications.show(
        1001,
        'Session expiring soon',
        'Your session will end soon. Tap Stay signed in or Log out.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_warning_channel',
            'Session Warning',
            channelDescription: 'Notifications for session expiration reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            ticker: 'Session expiring soon',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Session reminder notification error: $e');
    }
  }

  Future<void> _cancelSessionReminderNotification() async {
    try {
      await _notifications.cancel(1001);
    } catch (e) {
      debugPrint('Cancel session reminder notification error: $e');
    }
  }

  Future<void> _performForcedLogout() async {
    final nav = _navKey.currentState;
    final context = _navKey.currentContext;
    if (nav == null || context == null) return;

    if (_warningDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _warningDialogOpen = false;
    }

    await _cancelSessionReminderNotification();
    await context.read<AuthViewModel>().logout();

    nav.popUntil((route) => route.isFirst);

    if (!mounted) return;
    showMiniSnackBar(
      context,
      'Session expired. You have been logged out.',
      success: false,
    );
  }

  void _startSessionIfNeeded(BuildContext ctx) {
    if (_sessionRunning) return;

    _sessionRunning = true;

    SessionService.instance.start(
      onTimeout: () async {
        await _performForcedLogout();
      },
      onWarning: () async {
        final context = _navKey.currentContext;
        if (context == null) return;

        await _showSessionReminderNotification();
        _showSessionWarningDialog(context);
      },
    );
  }

  void _stopSessionIfNeeded() {
    if (!_sessionRunning) return;

    final ctx = _navKey.currentContext;
    if (ctx != null && _warningDialogOpen) {
      Navigator.of(ctx, rootNavigator: true).pop();
      _warningDialogOpen = false;
    }

    _cancelSessionReminderNotification();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF2F73D9),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Session expiring soon',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You have been inactive for a while.',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD7E4FA),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF2F73D9),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will be logged out in $secondsLeft second${secondsLeft == 1 ? '' : 's'} unless you stay signed in.',
                            style: const TextStyle(
                              color: Color(0xFF1F1F1F),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    _warningDialogOpen = false;

                    await _cancelSessionReminderNotification();
                    await _performForcedLogout();
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F73D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    _warningDialogOpen = false;

                    await _cancelSessionReminderNotification();
                    SessionService.instance.userActivityPing();
                  },
                  child: const Text(
                    'Stay signed in',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
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
        theme: buildAppTheme(),
        home: Consumer<AuthViewModel>(
          builder: (ctx, auth, _) {
            if (auth.isAuthenticated) {
              _startSessionIfNeeded(ctx);
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) =>
                    SessionService.instance.userActivityPing(),
                child: const TodoListView(),
              );
            } else {
              _stopSessionIfNeeded();
              return const LoginView();
            }
          },
        ),
      ),
    );
  }
}