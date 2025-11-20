import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPresenter {
  final BuildContext context;
  final VoidCallback? onLoadingChanged;

  AuthPresenter(this.context, {this.onLoadingChanged});

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);

      final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];
      if (webClientId == null) {
        throw Exception('GOOGLE_CLIENT_ID tidak ditemukan di .env');
      }

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: webClientId);

      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;

      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(<String>['email']);

      if (authorization == null) {
        throw Exception('No authorization found');
      }

      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    } on AuthException catch (e) {
      _showError('Google Sign-In failed: ${e.message}');
    } on Exception catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (onLoadingChanged != null) {
      onLoadingChanged!();
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
