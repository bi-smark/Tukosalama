import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';

class FullAuditScreen extends StatelessWidget {
  final String title;
  const FullAuditScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Professional background
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Order by timestamp so the latest events are at the top
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No incident records found."));
          }

          // FILTERING LOGIC: filter the list based on the tapped StatCard
          final allDocs = snapshot.data!.docs;
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            final bool isSOS = data['isSOS'] == true || data['isSOS'] == 'true';

            if (title == "Resolved") {
              return status == 'resolved' || status == 'solved';
            } else if (title == "Critical SOS") {
              return isSOS && status != 'resolved' && status != 'solved';
            }
            return true; // "All Alerts"
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final incident = Incident.fromFirestore(filteredDocs[index]);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: (incident.isSOS ? Colors.red : Colors.blue)
                        .withValues(alpha: 0.1),
                    child: Icon(
                      incident.isSOS
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: incident.isSOS ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    incident.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Location: ${incident.location}\nStatus: ${incident.status.name.toUpperCase()}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                  onTap: () => _showAuditDetail(context, incident),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // PROFESSIONAL DETAIL DIALOG
  void _showAuditDetail(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("LOG REF: ${incident.id.toUpperCase().substring(0, 8)}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: ${incident.type}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Privacy logic: Only show name for SOS alerts
            Text(
              "Reporter: ${incident.isSOS ? (incident.userName) : 'Anonymous'}",
            ),
            const Divider(height: 30),
            const Text(
              "NARRATIVE:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(incident.description),
            const SizedBox(height: 15),
            Text(
              "Time: ${incident.formattedTime}",
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("DISMISS"),
          ),
        ],
      ),
    );
  }
}
