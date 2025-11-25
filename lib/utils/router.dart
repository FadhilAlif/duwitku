import 'package:duwitku/utils/go_router_refresh_stream.dart';
import 'package:duwitku/views/manage_categories/manage_categories_screen.dart';
import 'package:duwitku/views/chat_prompt/chat_prompt_screen.dart';
import 'package:duwitku/views/edit_profile/edit_profile_screen.dart';
import 'package:duwitku/views/login/login_screen.dart';
import 'package:duwitku/views/main_navigation/main_navigation_screen.dart';
import 'package:duwitku/views/register/register_screen.dart';
import 'package:duwitku/views/scan_struk/scan_struk_screen.dart';
import 'package:duwitku/views/splash/splash_screen.dart';
import 'package:duwitku/views/input_phone/input_phone_screen.dart';
import 'package:duwitku/views/transaction_form/transaction_form_screen.dart';
import 'package:duwitku/views/voice_input/voice_input_screen.dart';
import 'package:duwitku/views/wallet/add_edit_wallet_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:duwitku/models/transaction.dart' as t;
import 'package:duwitku/models/wallet.dart';

final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/manage_categories',
      builder: (context, state) => const ManageCategoriesScreen(),
    ),
    GoRoute(
      path: '/scan_struk',
      builder: (context, state) => const ScanStrukScreen(),
    ),
    GoRoute(
      path: '/voice_input',
      builder: (context, state) => const VoiceInputScreen(),
    ),
    GoRoute(
      path: '/chat_prompt',
      builder: (context, state) => const ChatPromptScreen(),
    ),
    GoRoute(
      path: '/transaction_form',
      builder: (context, state) {
        final transaction = state.extra as t.Transaction?;
        return TransactionFormScreen(transaction: transaction);
      },
    ),
    GoRoute(
      path: '/edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/input_phone',
      builder: (context, state) => const InputPhoneScreen(),
    ),
    GoRoute(
      path: '/add_edit_wallet',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        return AddEditWalletScreen(wallet: wallet);
      },
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isSplashing = state.matchedLocation == '/';
    final isLoggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isAuth && !isLoggingIn) {
      if (isSplashing) {
        return null;
      }
      return '/login';
    }

    if (isAuth && isLoggingIn) {
      return '/';
    }

    return null;
  },
);
