import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'services/session_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/todo_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();

    // Start the inactivity session timer
    SessionService.instance.start(onTimeout: () {
      final nav = _navKey.currentState;
      final ctx = _navKey.currentContext;
      if (nav == null || ctx == null) return;

      // 1) Mark user as logged out
      ctx.read<AuthViewModel>().logout();

      // 2) Go back to the first route; that route's Consumer<AuthViewModel>
      //    will now rebuild as LoginView because isAuthenticated == false.
      nav.popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    SessionService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..loadUser()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
      ],
      // Every tap / scroll resets idle timer
      child: Listener(
        onPointerDown: (_) {
          SessionService.instance.userActivityPing();
        },
        child: MaterialApp(
          navigatorKey: _navKey,
          title: 'CipherTask',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blueGrey,
          ),
          // Single source of truth for "are we on Login or Home?"
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
}