import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentStatus { pending, responding, resolved }

class Incident {
  final String id;
  final String reporterId;
  final String userName; // NEW: Added to fix the 'getter not defined' error
  final String type;
  final String description;
  final String location;
  final bool isSOS;
  final DateTime timestamp;

  // Numerical coordinates for Google Maps
  final double lat;
  final double lng;

  // Security-specific fields
  IncidentStatus status;
  String threatLevel;
  String backupRequested;
  DateTime? handlingStart;
  DateTime? resolvedAt;

  Incident({
    required this.id,
    required this.reporterId,
    required this.userName, // Added here
    required this.type,
    required this.description,
    required this.location,
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.isSOS = false,
    this.status = IncidentStatus.pending,
    this.threatLevel = "Medium",
    this.backupRequested = "None",
    this.handlingStart,
    this.resolvedAt,
  });

  String get formattedTime =>
      "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'userName': userName, // Added here
      'type': type,
      'description': description,
      'location': location,
      'isSOS': isSOS,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      'threatLevel': threatLevel,
      'backupRequested': backupRequested,
      'timestamp': Timestamp.fromDate(timestamp),
      'handlingStart': handlingStart != null
          ? Timestamp.fromDate(handlingStart!)
          : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      userName:
          data['userName'] ??
          'Unknown Student', // Catches the name from Firestore
      type: data['type'] ?? 'General',
      description: data['description'] ?? '',
      location: data['location'] ?? 'Unknown',
      isSOS: data['isSOS'] ?? false,
      // Robust coordinate parsing
      lat: (data['lat'] as num?)?.toDouble() ?? -1.0465,
      lng: (data['lng'] as num?)?.toDouble() ?? 37.0772,
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => IncidentStatus.pending,
      ),
      threatLevel: data['threatLevel'] ?? 'Medium',
      backupRequested: data['backupRequested'] ?? 'None',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      handlingStart: (data['handlingStart'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
