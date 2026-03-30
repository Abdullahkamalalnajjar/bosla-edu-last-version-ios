import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '938189024020-1od68s5nkft44f5vud0jkt49p7sfn3jl.apps.googleusercontent.com',
  );

  /// Sign in with Google and return the ID token
  Future<String?> signInWithGoogle() async {
    try {
      // Force account picker by ensuring previous session is cleared
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Return the ID token
      return googleAuth.idToken;
    } catch (error) {
      print('Error signing in with Google: $error');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
