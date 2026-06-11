// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_action_service.dart';

class UserManagementView extends StatefulWidget {
  final String? initialRole;
  const UserManagementView({super.key, this.initialRole});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  late String _currentFilter;
  final AdminActionService _adminService = AdminActionService();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialRole ?? 'student';
  }

  // --- FEATURE: CONTEXT-AWARE INJECTION ---
  void _injectUser() {
    if (_currentFilter == 'admin') {
      _verifyAdminPIN(() => _showInjectionForm());
    } else {
      _showInjectionForm();
    }
  }

  void _showInjectionForm() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("INJECT ${_currentFilter.toUpperCase()}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: "Assign Password"),
                obscureText: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setModalState(() => isLoading = true);
                      try {
                        await _adminService.injectUser(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          role: _currentFilter,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account Injected Successfully"),
                          ),
                        );
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: const Text("INJECT"),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW FEATURE: ADVANCED SUSPENSION DIALOG ---
  void _showSuspendDialog(String userId, String name) {
    int selectedDays = 3;
    String reason = "Violated community rules";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Suspend $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedDays,
              items: [1, 3, 7, 30]
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text("$d Days")),
                  )
                  .toList(),
              onChanged: (val) => selectedDays = val!,
              decoration: const InputDecoration(labelText: "Duration"),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (val) => reason = val,
              decoration: const InputDecoration(
                labelText: "Reason for Suspension",
                hintText: "e.g., Harassment",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminService.suspendUser(userId, selectedDays, reason);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name suspended for $selectedDays days"),
                ),
              );
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  // --- NEW FEATURE: DELETION WITH REASON ---
  void _showDeleteDialog(String userId, String name) {
    String reason = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "PERMANENT DELETION",
          style: TextStyle(color: Colors.red),
        ),
        content: TextField(
          onChanged: (val) => reason = val,
          decoration: const InputDecoration(
            labelText: "Reason for Removal",
            hintText: "Required",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reason.isNotEmpty) {
                await _adminService.removeUser(userId, reason);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User permanently removed")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a reason")),
                );
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verifyAdminPIN(VoidCallback onSuccess) {
    final TextEditingController pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ADMIN PIN REQUIRED"),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: "enter access password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinCtrl.text == "2005") {
                Navigator.pop(context);
                onSuccess();
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Invalid PIN")));
              }
            },
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "USER CONTROL",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _injectUser,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roleTab("STUDENTS", 'student'),
                _roleTab("SECURITY", 'security'),
                _adminTab(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: _currentFilter)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index];
                    Map<String, dynamic> data =
                        user.data() as Map<String, dynamic>;
                    bool isSuspended = data.containsKey('isSuspended')
                        ? data['isSuspended']
                        : false;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isSuspended
                              ? Colors.red.shade100
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuspended
                              ? Colors.red.shade400
                              : const Color(0xFF0D47A1),
                          child: Icon(
                            isSuspended ? Icons.block : Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['email'] ?? 'No Email'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // UPDATED BAN/RESTORE TOGGLE
                            IconButton(
                              icon: Icon(
                                isSuspended
                                    ? Icons.play_circle
                                    : Icons.pause_circle,
                                color: isSuspended
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              onPressed: () {
                                if (isSuspended) {
                                  _adminService.restoreUser(user.id);
                                } else {
                                  _showSuspendDialog(user.id, user['name']);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _showDeleteDialog(user.id, user['name']),
                            ),
                          ],
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

  Widget _roleTab(String label, String role) {
    bool isSelected = _currentFilter == role;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _adminTab() {
    bool isSelected = _currentFilter == 'admin';
    return GestureDetector(
      onTap: () => isSelected
          ? null
          : _verifyAdminPIN(() => setState(() => _currentFilter = 'admin')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          "ADMINS",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
