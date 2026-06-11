import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/incident_model.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CREATE: Send a new Report or SOS
  Future<void> reportIncident(Incident incident) async {
    try {
      // Use set instead of add if you want to control the doc ID,
      // but add is fine for auto-generated IDs.
      await _db.collection('incidents').add(incident.toMap());
    } catch (e) {
      debugPrint("Database Error: $e");
      rethrow;
    }
  }

  // 2. READ: Real-time Live Stream for Security
  Stream<List<Incident>> getLiveIncidentFeed() {
    return _db
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList(),
        );
  }

  // 3. UPDATE: Security status changes
  Future<void> updateStatus(String docId, IncidentStatus newStatus) async {
    try {
      await _db.collection('incidents').doc(docId).update({
        'status': newStatus.name,
        if (newStatus == IncidentStatus.responding)
          'handlingStart': FieldValue.serverTimestamp(),
        if (newStatus == IncidentStatus.resolved)
          'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Update Error: $e");
      rethrow;
    }
  }
}
