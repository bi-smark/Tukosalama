import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerStudent({
    required String email,
    required String password,
    required String name,
    required String username,
    required String idNumber,
    required String phone,
  }) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedUsername = username.trim().toLowerCase();

      // 1. Pre-Auth Validation
      if (!(trimmedEmail.endsWith('@gmail.com') ||
          trimmedEmail.endsWith('@outlook.com'))) {
        throw "Use @gmail.com or @outlook.com only.";
      }

      // 2. Create Auth Account FIRST
      // This grants the 'auth != null' permission needed for the next step
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      // 3. Post-Auth Username Check
      final usernameCheck = await _db
          .collection('users')
          .where('username', isEqualTo: trimmedUsername)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        // Cleanup if username taken
        await res.user?.delete();
        throw "Username already exists.";
      }

      // 4. Create Model and Save
      TukoUser newUser = TukoUser(
        uid: res.user!.uid,
        email: trimmedEmail,
        username: trimmedUsername,
        name: name.trim(),
        role: UserRole.student,
        idNumber: idNumber.trim(),
        phoneNumber: phone.trim(),
        createdAt: DateTime.now(),
        isFirstLogin: false,
      );

      await _db.collection('users').doc(res.user!.uid).set(newUser.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<TukoUser?> getTukoUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return TukoUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
