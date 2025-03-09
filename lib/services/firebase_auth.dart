
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<String> getOrCreateAnonymousUser() async {
    try {

      if (_auth.currentUser != null) {
        return _auth.currentUser!.uid;
      }

      final userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        return userCredential.user!.uid;
      } else {
        throw Exception("Failed to create anonymous user - user is null");
      }
    } catch (e) {
      print("Error in getOrCreateAnonymousUser: $e");
      rethrow;
    }
  }


  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}