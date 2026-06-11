import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import '../models/user_model.dart';
import '../widgets/safety_map.dart';
import '../settings_page.dart';
import 'report_incident_page.dart';
import 'alerts_page.dart';
import 'tips_page.dart';

class StudentDashboard extends StatefulWidget {
  final TukoUser user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  bool _isSendingSOS = false;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _buildHomeTab(),
      const SafetyMap(role: MapUserRole.student),
      SettingsPage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              "Tuko",
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const Text(
              "Salama",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSendingSOS)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0D47A1),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "Safety Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, ${widget.user.name.split(' ')[0].toUpperCase()}!",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Quick Security Actions",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildGridItem(
                Icons.visibility_off_outlined,
                "Anonymous Report",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportIncidentPage(user: widget.user),
                  ),
                ),
              ),
              _buildGridItem(
                Icons.notifications_active_outlined,
                "Safety Alerts",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                ),
              ),
              _buildGridItem(
                Icons.phone_in_talk_outlined,
                "Hotlines",
                () => _showHotlines(context),
              ),
              _buildGridItem(
                Icons.shield_outlined,
                "Safety Tips",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TipsPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- NEW: SOS TRIGGER SECTION ---
          const Text(
            "EMERGENCY",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.red,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onLongPress: () => _confirmSOS(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.emergency_share, color: Colors.red, size: 48),
                  SizedBox(height: 12),
                  Text(
                    "HOLD FOR SOS",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Alerts MKU Security immediately",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF0D47A1)),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // --- SOS LOCATION & FIREBASE LOGIC ---
  Future<void> _handleSOS() async {
    setState(() => _isSendingSOS = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // PUSH TO FIREBASE: This is how security "sees" it
      await FirebaseFirestore.instance.collection('incidents').add({
        'userId': widget.user.uid,
        'userName': widget.user.name,
        'type': 'EMERGENCY SOS',
        'location': 'Lat: ${position.latitude}, Lng: ${position.longitude}',
        'description': 'Student triggered emergency panic button.',
        'status': 'pending',
        'isSOS': true, // Essential for security dashboard filtering
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSOSSuccessPopup(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  void _showSOSSuccessPopup(double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("SOS SENT"),
          ],
        ),
        content: Text(
          "Emergency dispatch alerted.\n\nCoordinates:\n$lat, $lng",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _confirmSOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("CONFIRM SOS"),
        content: const Text("Broadcast your location to MKU Security?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "BROADCAST",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHotlines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              leading: Icon(Icons.security, color: Colors.blue),
              title: Text("MKU Security Main Gate"),
              subtitle: Text("0712 345 678"),
            ),
            ListTile(
              leading: Icon(Icons.local_hospital, color: Colors.red),
              title: Text("University Clinic"),
              subtitle: Text("0723 456 789"),
            ),
          ],
        ),
      ),
    );
  }
}
