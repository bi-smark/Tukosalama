// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../widgets/safety_map.dart';
import '../settings_page.dart';
import '../security/incident_service.dart';

class SecurityDashboard extends StatefulWidget {
  final TukoUser user;
  const SecurityDashboard({super.key, required this.user});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  int _currentIndex = 0;
  bool _isOnline = false;
  final IncidentService _incidentService = IncidentService();

  @override
  void initState() {
    super.initState();
    // Initialize duty status from the user model
    _isOnline = widget.user.isOnShift;
  }

  @override
  Widget build(BuildContext context) {
    // --- THE FIX: PASSING TUKOUSER OBJECT CORRECTLY ---
    final List<Widget> tabs = [
      _buildOperationsTab(),
      const SafetyMap(role: MapUserRole.security),
      SettingsPage(
        user: widget.user, // Corrected parameter
        onDutyChanged: (val) async {
          setState(() => _isOnline = val);
          // Sync to Firestore so Admin knows you are active
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .update({'isOnShift': val});
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildTacticalAppBar(),
      body: tabs[_currentIndex],
      bottomNavigationBar: _buildTacticalNavBar(),
    );
  }

  PreferredSizeWidget _buildTacticalAppBar() {
    return AppBar(
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
          const Spacer(),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOnline ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: _isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? "ON DUTY" : "OFF DUTY",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: "Ops",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Tactical",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isOnline ? _buildLiveTacticalGrid() : _buildStandbyState(),
    );
  }

  Widget _buildLiveTacticalGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
      builder: (context, snapshot) {
        int sosCount = 0;
        int reportCount = 0;
        int ongoingCount = 0;
        int solvedCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            final dynamic rawSOS = data['isSOS'];
            final bool isSOS = rawSOS == true || rawSOS == 'true';

            if (status == 'resolved' || status == 'solved') {
              solvedCount++;
            } else if (status == 'responding') {
              ongoingCount++;
            } else if (isSOS) {
              sosCount++;
            } else if (status == 'pending') {
              reportCount++;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "UNIT: ${widget.user.name.toUpperCase()}",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildTacticalButton(
                      "SOS ALERTS",
                      Icons.emergency_share,
                      Colors.red,
                      sosCount,
                      () => _showList("New SOS Alerts", "sos_only"),
                    ),
                    _buildTacticalButton(
                      "REPORTS",
                      Icons.assignment_late_outlined,
                      Colors.orange,
                      reportCount,
                      () => _showList("New Reports", "reports_only"),
                    ),
                    _buildTacticalButton(
                      "ONGOING",
                      Icons.radar_outlined,
                      Colors.blue,
                      ongoingCount,
                      () => _showList("Ongoing Assistance", "ongoing"),
                    ),
                    _buildTacticalButton(
                      "HISTORY",
                      Icons.fact_check_outlined,
                      Colors.green,
                      solvedCount,
                      () => _showList("Resolved History", "history"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTacticalButton(
    String label,
    IconData icon,
    Color color,
    int count,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: count > 0
                ? color.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Color(0xFF0D47A1),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandbyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              size: 60,
              color: Colors.blueGrey.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "OFFLINE STANDBY",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D47A1),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Switch to 'Active Duty' in Profile to begin session.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showList(String title, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('incidents')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final bool isSOS =
                  data['isSOS'] == true || data['isSOS'] == 'true';
              final String status = (data['status'] ?? 'pending')
                  .toString()
                  .toLowerCase();

              switch (category) {
                case "sos_only":
                  return isSOS && status == 'pending';
                case "reports_only":
                  return !isSOS && status == 'pending';
                case "ongoing":
                  return status == 'responding';
                case "history":
                  return status == 'resolved' || status == 'solved';
                default:
                  return false;
              }
            }).toList();

            return Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                          child: Text(
                            "No items to display",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final incident = Incident.fromFirestore(
                              docs[index],
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    (incident.isSOS ? Colors.red : Colors.blue)
                                        .withValues(alpha: 0.1),
                                child: Icon(
                                  incident.isSOS ? Icons.emergency : Icons.info,
                                  color: incident.isSOS
                                      ? Colors.red
                                      : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                incident.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${incident.location}\nStatus: ${incident.status.name.toUpperCase()}",
                              ),
                              onTap: () => _showIncidentDetails(incident),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showIncidentDetails(Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          incident.type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reporter: ${incident.userName}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "LOCATION:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            Text(
              incident.location,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            Text(incident.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BACK"),
          ),
          if (incident.status == IncidentStatus.pending)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                await _incidentService.updateStatus(
                  incident.id,
                  IncidentStatus.responding,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "DISPATCH/RESPOND",
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (incident.status == IncidentStatus.responding)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                await _incidentService.updateStatus(
                  incident.id,
                  IncidentStatus.resolved,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "MARK RESOLVED",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
