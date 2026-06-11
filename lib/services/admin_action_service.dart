import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminActionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> injectUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: secondaryApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'username': '', // Tracked for missing info
        'isSuspended': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryApp.delete();
    } catch (e) {
      await secondaryApp.delete();
      throw e.toString();
    }
  }

  Future<void> suspendUser(String userId, int days, String reason) async {
    DateTime until = DateTime.now().add(Duration(days: days));
    await _db.collection('users').doc(userId).update({
      'isSuspended': true,
      'suspensionReason': reason,
      'suspendedUntil': Timestamp.fromDate(until),
      'suspensionDuration': days,
    });
  }

  Future<void> restoreUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isSuspended': false,
      'suspensionReason': null,
      'suspendedUntil': null,
    });
  }

  Future<void> removeUser(String userId, String reason) async {
    // Log the reason in an audit collection before deleting
    await _db.collection('deletion_logs').add({
      'userId': userId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(userId).delete();
  }
}
