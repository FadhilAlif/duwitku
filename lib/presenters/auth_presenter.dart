import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPresenter {
  final BuildContext context;

  AuthPresenter(this.context);

  Future<void> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];

      if (webClientId == null) {
        throw 'GOOGLE_CLIENT_ID tidak ditemukan di .env';
      }

      final googleSignIn = GoogleSignIn.instance;

      // Initialize with serverClientId
      await googleSignIn.initialize(serverClientId: webClientId);

      // Authenticate user
      final googleUser = await googleSignIn.authenticate();

      // Get ID token from authentication
      final idToken = googleUser.authentication.idToken;

      // Get access token from authorization client
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(<String>['email']);

      if (authorization == null) {
        throw 'No authorization found.';
      }

      final accessToken = authorization.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
