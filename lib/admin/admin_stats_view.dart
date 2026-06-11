import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tuko_salama/admin/full_audit_screen.dart'; // Verify this path
import '../widgets/stat_card.dart';
import '../models/incident_model.dart';

class AdminStatsView extends StatefulWidget {
  const AdminStatsView({super.key});

  @override
  State<AdminStatsView> createState() => _AdminStatsViewState();
}

class _AdminStatsViewState extends State<AdminStatsView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int resolved = 0;
        int critical = 0;

        if (snapshot.hasData && snapshot.data != null) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            final bool isSOS = data['isSOS'] == true || data['isSOS'] == 'true';

            if (status == 'resolved' || status == 'solved') {
              resolved++;
            } else if (isSOS) {
              critical++;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: "TOTAL",
                      value: "$total",
                      color: Colors.blue,
                      onTap: () => _showAuditScreen(context, "All Alerts"),
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: "SOLVED",
                      value: "$resolved",
                      color: Colors.green,
                      onTap: () => _showAuditScreen(context, "Resolved"),
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: "CRITICAL",
                      value: "$critical",
                      color: Colors.red,
                      onTap: () => _showAuditScreen(context, "Critical SOS"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const Text(
                "Incident Trends",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              _buildIncidentGraph(total, resolved, critical),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live Audit Logs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showAuditScreen(context, "Full Audit Log"),
                    child: const Text("SEE ALL"),
                  ),
                ],
              ),
              const Divider(),

              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.data!.docs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No incident data available"),
                  ),
                )
              else
                Column(
                  children: snapshot.data!.docs.take(3).map((doc) {
                    final incident = Incident.fromFirestore(doc);
                    return _buildAuditTile(context, incident);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 5),
              Text(
                "LIVE: ${now.day}/${now.month}/${now.year}",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentGraph(int total, int solved, int crit) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(10),
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
                  toY: total.toDouble(),
                  color: Colors.blue,
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: solved.toDouble(),
                  color: Colors.green,
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: crit.toDouble(),
                  color: Colors.red,
                  width: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTile(BuildContext context, Incident incident) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => _showDetailDialog(context, incident),
        leading: Icon(
          incident.isSOS ? Icons.warning : Icons.info,
          color: incident.isSOS ? Colors.red : Colors.blue,
          size: 20,
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

  void _showAuditScreen(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FullAuditScreen(title: title)),
    );
  }

  void _showDetailDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("AUDIT REF: ${incident.id.toUpperCase()}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: ${incident.type}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Reporter: ${incident.isSOS ? (incident.userName) : 'Anonymous'}",
            ),
            const Divider(),
            Text(incident.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}
