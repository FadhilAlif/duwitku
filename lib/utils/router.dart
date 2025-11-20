import 'package:duwitku/utils/go_router_refresh_stream.dart';
import 'package:duwitku/views/add_transaction/add_transaction_screen.dart';
import 'package:duwitku/views/chat_prompt/chat_prompt_screen.dart';
import 'package:duwitku/views/login/login_screen.dart';
import 'package:duwitku/views/main_navigation/main_navigation_screen.dart';
import 'package:duwitku/views/register/register_screen.dart';
import 'package:duwitku/views/scan_struk/scan_struk_screen.dart';
import 'package:duwitku/views/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final router = GoRouter(
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
        path: '/add_transaction',
        builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/scan_struk',
      builder: (context, state) => const ScanStrukScreen(),
    ),
    GoRoute(
      path: '/chat_prompt',
      builder: (context, state) => const ChatPromptScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isSplashing = state.matchedLocation == '/';
    final isLoggingIn =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isAuth && !isLoggingIn) {
      if (isSplashing) {
        return null;
      }
      return '/login';
    }

    if (isAuth && (isLoggingIn || isSplashing)) {
      return '/main';
    }

    return null;
  },
);
