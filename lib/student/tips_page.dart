import 'package:flutter/material.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // These tips align with your CPTED (Crime Prevention) goals [cite: 220]
    final List<Map<String, String>> tips = [
      {
        "title": "Walking at Night",
        "desc": "Avoid General Kago road alone after 9 PM. Use well-lit paths.",
      },
      {
        "title": "Using the SOS Button",
        "desc": "Only use the header SOS icon for immediate physical danger.",
      },
      {
        "title": "Reporting Anonymously",
        "desc":
            "Provide landmarks like 'near the green gate' for faster response.",
      },
      {
        "title": "Hostel Security",
        "desc":
            "Ensure your door is locked even when stepping out for a minute.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Safety Tips",
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            leading: const Icon(Icons.shield, color: Color(0xFF0D47A1)),
            title: Text(
              tips[index]['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(tips[index]['desc']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
