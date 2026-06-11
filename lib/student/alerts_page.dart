import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for your proposal's "geo-fenced alerts" [cite: 197, 291]
    final List<Map<String, String>> alerts = [
      {
        "title": "Heavy Police Activity",
        "area": "Near Main Gate",
        "time": "10 mins ago",
        "level": "High",
      },
      {
        "title": "Suspicious Person",
        "area": "Hostel Area Z",
        "time": "1 hour ago",
        "level": "Medium",
      },
      {
        "title": "Road Blockage",
        "area": "Thika Road Exit",
        "time": "2 hours ago",
        "level": "Low",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Safety Alerts",
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: alerts[index]['level'] == "High"
                    ? Colors.red
                    : Colors.orange,
              ),
              title: Text(
                alerts[index]['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${alerts[index]['area']} • ${alerts[index]['time']}",
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
