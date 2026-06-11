import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSetupPage extends StatefulWidget {
  final String uid;
  const AccountSetupPage({super.key, required this.uid});

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final _userController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regController =
      TextEditingController(); // Controller for Registration Number
  bool _loading = false;

  // --- REAL-TIME USERNAME VALIDATION STATES ---
  Timer? _debounce;
  bool _isUsernameValidating = false;
  bool _usernameAvailable = false;
  String _usernameMessage = "";

  @override
  void initState() {
    super.initState();
    _userController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _userController.removeListener(_onUsernameChanged);
    _userController.dispose();
    _phoneController.dispose();
    _regController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- DEBOUNCED USERNAME VALIDATION LOGIC ---
  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final username = _userController.text.trim().toLowerCase();
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = false;
        _usernameMessage = "";
      });
      return;
    }

    setState(() {
      _isUsernameValidating = true;
      _usernameMessage = "Verifying unique username...";
    });

    // 500ms debounce to minimize unnecessary Firestore document evaluations
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        setState(() {
          _isUsernameValidating = false;
          if (querySnapshot.docs.isEmpty) {
            _usernameAvailable = true;
            _usernameMessage = "Username is available!";
          } else {
            _usernameAvailable = false;
            _usernameMessage = "Username is already taken";
          }
        });
      } catch (e) {
        setState(() {
          _isUsernameValidating = false;
          _usernameAvailable = false;
          _usernameMessage = "Network error tracking validation";
        });
      }
    });
  }

  Future<void> _completeSetup() async {
    final username = _userController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final regNumber = _regController.text.trim();

    if (username.isEmpty || phone.isEmpty || regNumber.isEmpty) {
      _showSnackBar("Please fill in all layout data fields", isError: true);
      return;
    }

    if (!_usernameAvailable) {
      _showSnackBar(
        "Please pick a valid, unique username first",
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
            'username': username,
            'phoneNumber': phone, // Matches model property key
            'idNumber': regNumber, // Updates the registration number attribute
            'setupCompletedAt': FieldValue.serverTimestamp(),
          });

      // AppLayout stream wrapper handles background context re-routing onto update completion
    } catch (e) {
      _showSnackBar("Failed to save data setup: $e", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Evaluation rules to decide if the CTA module can be pressed
    bool isFinishButtonEnabled =
        _usernameAvailable &&
        !_isUsernameValidating &&
        _phoneController.text.isNotEmpty &&
        _regController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Finalize Account",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please complete your profile details to gain access.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 35),

              // --- USERNAME TEXT FIELD ---
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Create Username",
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: Color(0xFF0D47A1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),

              // --- DYNAMIC VISUAL FEEDBACK ANIMATION STATE BADGE ---
              if (_usernameMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 6.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        if (_isUsernameValidating)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0D47A1),
                            ),
                          )
                        else
                          Icon(
                            _usernameAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _usernameAvailable
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _usernameMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isUsernameValidating
                                ? Colors.grey
                                : (_usernameAvailable
                                      ? Colors.green
                                      : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // --- REGISTRATION ID FIELD ---
              TextField(
                controller: _regController,
                onChanged: (_) =>
                    setState(() {}), // Refresh button enablement dynamically
                decoration: const InputDecoration(
                  labelText: "Registration Number / Student ID",
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF0D47A1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- PHONE NUMBER FIELD ---
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) =>
                    setState(() {}), // Refresh button enablement dynamically
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF0D47A1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: isFinishButtonEnabled ? _completeSetup : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: const Color(0xFF0D47A1),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isFinishButtonEnabled ? 4 : 0,
                      ),
                      child: Text(
                        "FINISH SETUP",
                        style: TextStyle(
                          color: isFinishButtonEnabled
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
