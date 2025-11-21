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
        throw Exception('Otorisasi tidak ditemukan');
      }

      if (idToken == null) {
        throw Exception('ID Token tidak ditemukan');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    } on AuthException catch (e) {
      _showError('Gagal masuk dengan Google: ${e.message}');
    } on Exception catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError('Terjadi kesalahan tak terduga: $e');
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
