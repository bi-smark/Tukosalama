import 'package:tuko_salama/settings_page.dart';
import 'package:tuko_salama/widgets/safety_map.dart';
import 'package:flutter/material.dart';
import 'package:tuko_salama/models/user_model.dart';

class SuspendedUserPage extends StatefulWidget {
  final TukoUser user;
  const SuspendedUserPage({super.key, required this.user});

  @override
  State<SuspendedUserPage> createState() => _SuspendedUserPageState();
}

class _SuspendedUserPageState extends State<SuspendedUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ACCESS RESTRICTED"),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SafetyMap(role: MapUserRole.student),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(user: widget.user),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                "Account Suspended for ${widget.user.suspensionDuration} Days",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "REASON: ${widget.user.suspensionReason ?? 'Violation of community rules'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
