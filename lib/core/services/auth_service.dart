import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around Google Sign-In so the rest of the app doesn't depend on
/// the package directly.
class AuthService {
  AuthService._();

  static GoogleSignIn _signIn() => GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
        clientId: AppConstants.googleWebClientId.isEmpty
            ? null
            : AppConstants.googleWebClientId,
      );

  /// Returns the Google ID token, or null if the user cancelled the dialog.
  static Future<String?> signInWithGoogle() async {
    final google = _signIn();
    await google.signOut(); // ensure account picker shows every time
    final account = await google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<void> signOutGoogle() async {
    final google = _signIn();
    try {
      await google.disconnect();
    } catch (_) {
      // disconnect can throw if not signed in — fall back to signOut
    }
    try {
      await google.signOut();
    } catch (_) {
      // ignore — account may already be signed out
    }
  }
}
