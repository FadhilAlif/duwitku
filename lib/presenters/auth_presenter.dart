import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPresenter {
  final BuildContext context;

  AuthPresenter(this.context);

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize with serverClientId
      await googleSignIn.initialize(
        serverClientId:
            "253050485080-63ldsc989qjdq6v4lhhr07fnpdn0gifq.apps.googleusercontent.com",
      );

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
