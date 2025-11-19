import 'package:duwitku/utils/go_router_refresh_stream.dart';
import 'package:duwitku/views/home/home_screen.dart';
import 'package:duwitku/views/login/login_screen.dart';
import 'package:duwitku/views/register/register_screen.dart';
import 'package:duwitku/views/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
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
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isAuth && !isLoggingIn) {
      return '/login';
    }

    if (isAuth && isLoggingIn) {
      return '/home';
    }

    return null;
  },
);
