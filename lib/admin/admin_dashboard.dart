import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in your pubspec.yaml
import 'package:tuko_salama/models/user_model.dart';
import '../widgets/stat_card.dart';
import '../models/incident_model.dart';
import 'full_audit_screen.dart';
import 'user_management_view.dart';
import '../widgets/safety_map.dart';
import '../settings_page.dart';
import 'shift_scheduler_view.dart'; // Ensure this file is in your admin folder

// --- THE FIX: UPDATED PARENT CLASS WITH 4 TABS ---
class AdminDashboard extends StatefulWidget {
  final TukoUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // INCREASED LENGTH TO 4 TO INCLUDE THE SCHEDULER
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            const Text(
              " | ADMIN",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0D47A1)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(user: widget.user),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Optimized for Samsung A15 screen width
          labelColor: const Color(0xFF0D47A1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0D47A1),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: "STATS"),
            Tab(
              icon: Icon(Icons.calendar_month_outlined),
              text: "SHIFTS",
            ), // NEW TAB
            Tab(icon: Icon(Icons.map_outlined), text: "TACTICAL"),
            Tab(icon: Icon(Icons.manage_accounts_outlined), text: "USERS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminStatsView(
            tabController: _tabController,
          ), // Pass controller for bridge
          const ShiftSchedulerView(), // YOUR SCHEDULER VIEW
          const SafetyMap(role: MapUserRole.security),
          const UserManagementView(),
        ],
      ),
    );
  }
}

// --- UPDATED STATS VIEW WITH SCHEDULER BRIDGE ---
class AdminStatsView extends StatefulWidget {
  final TabController tabController;
  const AdminStatsView({super.key, required this.tabController});

  @override
  State<AdminStatsView> createState() => _AdminStatsViewState();
}

class _AdminStatsViewState extends State<AdminStatsView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
      builder: (context, snapshot) {
        int total = 0, resolved = 0, critical = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'resolved') resolved++;
            if ((data['isSOS'] ?? false) && data['status'] != 'resolved') {
              critical++;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveHeader(), // Replaces static 9/4 with real-time clock
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: "TOTAL",
                      value: "$total",
                      color: Colors.blue,
                      onTap: () => _viewCategory(context, "All Alerts"),
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: "SOLVED",
                      value: "$resolved",
                      color: Colors.green,
                      onTap: () => _viewCategory(context, "Resolved"),
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: "CRITICAL",
                      value: "$critical",
                      color: Colors.red,
                      onTap: () => _viewCategory(context, "SOS Alerts"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const Text(
                "Campus Safety Trends",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              _buildTrendGraph(
                total,
                resolved,
                critical,
              ), // Your original visual analytics remains intact
              // --- SEAMLESS BRIDGE TO THE SCHEDULER ---
              const SizedBox(height: 25),
              _buildDeploymentCard(),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live Audit Logs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => _viewCategory(context, "Full System Log"),
                    child: const Text("SEE ALL"),
                  ),
                ],
              ),
              const Divider(),

              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: snapshot.data!.docs.take(3).map((doc) {
                    final incident = Incident.fromFirestore(doc);
                    return _buildAuditRow(
                      context,
                      incident,
                    ); // Professional "Read More" tiles remain intact
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // BRIDGE CARD: Jumps to Tab index 1 (Shifts)
  Widget _buildDeploymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_outlined, color: Color(0xFF0D47A1)),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Strategic Deployment",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  "Manage active duty security shifts",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.tabController.animateTo(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "MANAGE",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeader() {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "System Performance",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0D47A1),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "LIVE: ${now.day}/${now.month}/${now.year}",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendGraph(int t, int s, int c) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: t.toDouble(),
                  color: Colors.blue,
                  width: 16,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: s.toDouble(),
                  color: Colors.green,
                  width: 16,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: c.toDouble(),
                  color: Colors.red,
                  width: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditRow(BuildContext context, Incident incident) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => _showDetailedAudit(context, incident),
        leading: Icon(
          incident.isSOS ? Icons.warning_amber_rounded : Icons.info_outline,
          color: incident.isSOS ? Colors.red : Colors.blue,
        ),
        title: Text(
          "REF: ${incident.id.substring(0, 5).toUpperCase()}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(incident.type, style: const TextStyle(fontSize: 12)),
        trailing: const Text(
          "READ MORE",
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _viewCategory(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullAuditScreen(title: title)),
    );
  }

  void _showDetailedAudit(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("AUDIT LOG: ${incident.id.toUpperCase().substring(0, 8)}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: ${incident.type}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Reporter: ${incident.isSOS ? incident.userName : 'Anonymous'}",
            ), // Privacy logic remains intact
            const Divider(),
            Text(incident.description),
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
