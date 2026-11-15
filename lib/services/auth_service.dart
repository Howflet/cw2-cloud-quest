import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

Future<UserCredential> register(String email, String password) =>
    auth.createUserWithEmailAndPassword(email: email, password: password);

Future<UserCredential> signIn(String email, String password) =>
    auth.signInWithEmailAndPassword(email: email, password: password);

Future<void> logOut() => auth.signOut();

/// Maps Auth error codes to short messages without leaking details such as
/// whether a particular email has an account.
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'email-already-in-use':
        return 'That email can\'t be used to register. Try signing in.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check that the emulators are running.';
    }
  }
  return 'Sign-in failed. Try again.';
}
