// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID, or create an anonymous account if none exists
  Future<String> getOrCreateAnonymousUser() async {
    try {
      // Check on main thread
      if (_auth.currentUser != null) {
        return _auth.currentUser!.uid;
      }

      // Create a new anonymous account with proper error handling
      final userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        return userCredential.user!.uid;
      } else {
        throw Exception("Failed to create anonymous user - user is null");
      }
    } catch (e) {
      print("Error in getOrCreateAnonymousUser: $e");
      rethrow; // Re-throw to handle it in the UI
    }
  }

  // Get current user ID or null if not signed in
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}