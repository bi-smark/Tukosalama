import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Define the Roles clearly
enum UserRole { student, security, admin }

class TukoUser {
  final String uid;
  final String email;
  final String username; // Critical for profile completion check
  final String name;
  final UserRole role;
  final String idNumber; // National ID or MKU Reg Number
  final String phoneNumber;
  final String? campus; // e.g., "Thika Main"
  final String? profileImageUrl;
  final bool isFirstLogin;
  final DateTime createdAt;

  // --- NEW FIELDS FOR SUSPENSION LOGIC ---
  final bool isSuspended;
  final String? suspensionReason;
  final int? suspensionDuration;
  final DateTime? suspendedUntil;

  // --- SPECIAL FIELDS FOR STUDENTS ---
  final String? hostel;
  final String? course;
  final String? emergencyContact;

  // --- SPECIAL FIELDS FOR SECURITY ---
  final bool isOnShift;
  final String? rank; // e.g., "Campus Security" or "Police Officer"

  TukoUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    required this.idNumber,
    required this.phoneNumber,
    this.campus,
    this.profileImageUrl,
    this.isFirstLogin = true,
    required this.createdAt,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspensionDuration,
    this.suspendedUntil,
    this.hostel,
    this.course,
    this.emergencyContact,
    this.isOnShift = false,
    this.rank,
  });

  // --- CONVERT FIREBASE SNAPSHOT TO USER OBJECT ---
  factory TukoUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};

    return TukoUser(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      name: data['name'] ?? '',
      role: _parseRole(data['role']),
      idNumber: data['idNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      campus: data['campus'],
      profileImageUrl: data['profileImageUrl'],
      isFirstLogin: data['isFirstLogin'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      // Mapping suspension fields from Firestore
      isSuspended: data['isSuspended'] ?? false,
      suspensionReason: data['suspensionReason'],
      suspensionDuration: data['suspensionDuration'],
      suspendedUntil: data['suspendedUntil'] != null
          ? (data['suspendedUntil'] as Timestamp).toDate()
          : null,
      hostel: data['hostel'],
      course: data['course'],
      emergencyContact: data['emergencyContact'],
      isOnShift: data['isOnShift'] ?? false,
      rank: data['rank'],
    );
  }

  // --- CONVERT USER OBJECT TO MAP (For Saving to Firebase) ---
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'name': name,
      'role': role.name,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'campus': campus,
      'profileImageUrl': profileImageUrl,
      'isFirstLogin': isFirstLogin,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspensionDuration': suspensionDuration,
      'suspendedUntil': suspendedUntil != null
          ? Timestamp.fromDate(suspendedUntil!)
          : null,
      'hostel': hostel,
      'course': course,
      'emergencyContact': emergencyContact,
      'isOnShift': isOnShift,
      'rank': rank,
    };
  }

  // Helper to convert the String in Firebase back to our Enum
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'security':
        return UserRole.security;
      default:
        return UserRole.student;
    }
  }
}
