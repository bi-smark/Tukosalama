import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/incident_model.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CREATE: Send a new Report or SOS to the cloud
  Future<void> reportIncident(Incident incident) async {
    try {
      await _db.collection('incidents').add(incident.toMap());
    } catch (e) {
      debugPrint("Database Error: $e");
      rethrow;
    }
  }

  // 2. READ: The "Live Stream" for Security Guards
  // This stays open and updates the UI automatically when a new SOS arrives
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

  // 3. UPDATE: Security "Accepts" or "Resolves" the incident
  Future<void> updateStatus(String docId, IncidentStatus newStatus) async {
    await _db.collection('incidents').doc(docId).update({
      'status': newStatus.name,
      if (newStatus == IncidentStatus.responding)
        'handlingStart': Timestamp.now(),
      if (newStatus == IncidentStatus.resolved) 'resolvedAt': Timestamp.now(),
    });
  }
}
