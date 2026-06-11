import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // List of incident types based on your proposal
  final List<String> _incidentTypes = [
    'Theft',
    'Harassment',
    'Suspicious Activity',
    'Medical Emergency',
    'Other',
  ];
  String _selectedType = 'Theft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Anonymous Report",
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Type of Incident:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: _incidentTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Description:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Provide details (Location, time, etc.)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Note: Your identity will remain anonymous to other students and responders.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                ),
                onPressed: () {
                  // This will eventually send data to your database
                  Navigator.pop(context); // Go back to dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Report Submitted Successfully!"),
                    ),
                  );
                },
                child: const Text(
                  "Submit Report",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
