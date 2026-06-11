// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftSchedulerView extends StatefulWidget {
  const ShiftSchedulerView({super.key});

  @override
  State<ShiftSchedulerView> createState() => _ShiftSchedulerViewState();
}

class _ShiftSchedulerViewState extends State<ShiftSchedulerView> {
  String? selectedOfficer;
  String selectedLocation = "Main Gate";

  Future<void> _saveShift() async {
    if (selectedOfficer == null) return;

    await FirebaseFirestore.instance.collection('shifts').add({
      'officerName': selectedOfficer,
      'location': selectedLocation,
      'startTime': "08:00 AM",
      'endTime': "04:00 PM",
      'day': "Today",
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shift added to tactical calendar")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tactical Deployment",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 20),

          // OFFICER SELECTION (Live Stream of Security Personnel)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'security')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              var officers = snapshot.data!.docs
                  .map((d) => d['name'].toString())
                  .toList();

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Officer",
                  border: OutlineInputBorder(),
                ),
                items: officers
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedOfficer = val),
              );
            },
          ),

          const SizedBox(height: 15),

          // LOCATION SELECTION
          DropdownButtonFormField<String>(
            initialValue: selectedLocation,
            decoration: const InputDecoration(
              labelText: "Deployment Post",
              border: OutlineInputBorder(),
            ),
            items: ["Main Gate", "Hostel Area", "Library", "Admin Block"]
                .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                .toList(),
            onChanged: (val) => setState(() => selectedLocation = val!),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saveShift,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "ACTIVATE SHIFT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Active Duty Calendar",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // LIVE LIST OF SHIFTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shifts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var shift = snapshot.data!.docs[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.verified_user,
                        color: Colors.blue,
                      ),
                      title: Text(
                        shift['officerName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${shift['day']} • ${shift['startTime']} - ${shift['endTime']}",
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shift['location'],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
