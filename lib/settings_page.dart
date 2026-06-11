// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Ensure path is correct

class SettingsPage extends StatefulWidget {
  final TukoUser user; // Full user object passed from AppLayout
  final Function(bool)? onDutyChanged;

  const SettingsPage({super.key, required this.user, this.onDutyChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _courseController;
  late TextEditingController _hostelController;
  String? _selectedCampus;
  String? _selectedRank;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data from the TukoUser model
    _courseController = TextEditingController(text: widget.user.course);
    _hostelController = TextEditingController(text: widget.user.hostel);
    _selectedCampus = widget.user.campus;
    _selectedRank = widget.user.rank;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 25),

                  // --- SECTION 1: ROLE SPECIFIC INFO ---
                  _buildSectionHeader("Identification & Campus"),
                  _buildInformationCard([
                    if (widget.user.role == UserRole.student) ...[
                      _buildInputTile(
                        Icons.school_outlined,
                        "Course",
                        _courseController,
                      ),
                      _buildInputTile(
                        Icons.hotel_outlined,
                        "Hostel Residence",
                        _hostelController,
                      ),
                    ],
                    _buildCampusDropdown(),
                    if (widget.user.role == UserRole.security)
                      _buildRankDropdown(),
                    _buildSaveButton(),
                  ]),

                  const SizedBox(height: 25),

                  // --- SECTION 2: SECURITY & DUTY ---
                  _buildSectionHeader("System Protocol"),
                  _buildInformationCard([
                    _buildActionTile(
                      Icons.vpn_key_outlined,
                      "Update Credentials",
                      () => _showChangePasswordSheet(context),
                    ),
                    if (widget.user.role == UserRole.security)
                      _buildSwitchTile(
                        Icons.radar_outlined,
                        "Active Duty Mode",
                        "System awareness & live dispatch",
                        widget.user.isOnShift,
                        (val) => widget.onDutyChanged?.call(val),
                      ),
                  ]),

                  const SizedBox(height: 25),

                  // --- SECTION 3: SIGN OUT ---
                  _buildInformationCard([
                    _buildActionTile(
                      Icons.logout_rounded,
                      "Terminate Session",
                      () => _confirmExit(context),
                      isDestructive: true,
                    ),
                  ]),

                  const SizedBox(height: 40),
                  _buildFooterInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildSliverAppBar() {
    return const SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: Color(0xFF0D47A1),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "PROFILE & SAFETY",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
              'assets/profile.png',
            ), // Common student asset
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.user.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        Text(
          widget.user.email,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Chip(
          label: Text(
            widget.user.role.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: widget.user.role == UserRole.admin
              ? Colors.red
              : const Color(0xFF0D47A1),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildInformationCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputTile(
    IconData icon,
    String label,
    TextEditingController ctrl,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
      ),
      title: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCampusDropdown() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.location_city,
          color: Color(0xFF0D47A1),
          size: 20,
        ),
      ),
      title: DropdownButton<String>(
        value: _selectedCampus,
        isExpanded: true,
        hint: const Text("Select Campus", style: TextStyle(fontSize: 14)),
        underline: const SizedBox(),
        items: ["Thika Main", "Nairobi", "Mombasa", "Nakuru"]
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _selectedCampus = val),
      ),
    );
  }

  Widget _buildRankDropdown() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.military_tech_outlined,
          color: Color(0xFF0D47A1),
          size: 20,
        ),
      ),
      title: DropdownButton<String>(
        value: _selectedRank,
        isExpanded: true,
        hint: const Text("Select Guard Rank", style: TextStyle(fontSize: 14)),
        underline: const SizedBox(),
        items: ["Campus Security", "Police Officer"]
            .map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(r, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _selectedRank = val),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _updateProfile,
        child: const Text(
          "SAVE CHANGES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
            'course': _courseController.text.trim(),
            'hostel': _hostelController.text.trim(),
            'campus': _selectedCampus,
            'rank': _selectedRank,
            'lastProfileUpdate': FieldValue.serverTimestamp(),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Updated Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 25,
          left: 25,
          right: 25,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Security Verification",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Security Password",
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _executePasswordUpdate(
                  context,
                  currentPassCtrl.text,
                  newPassCtrl.text,
                  ctx,
                ),
                child: const Text(
                  "VERIFY & UPDATE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePasswordUpdate(
    BuildContext context,
    String oldPass,
    String newPass,
    BuildContext sheetCtx,
  ) async {
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password is too short"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'lastSecurityUpdate': FieldValue.serverTimestamp()},
      );

      if (mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated for real!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Secure Sign-Out?"),
        content: const Text("Your active session will be terminated."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("SIGN OUT", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : const Color(0xFF0D47A1))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF0D47A1),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0D47A1), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      value: value,
      // ignore: deprecated_member_use
      activeColor: const Color(0xFF0D47A1),
      onChanged: onChanged,
    );
  }

  Widget _buildFooterInfo() {
    return const Column(
      children: [
        Text(
          "TukoSalama • Security Framework v1.0.8",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
            fontSize: 11,
          ),
        ),
        Text(
          "Thika Main Campus Operations Hub",
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}
