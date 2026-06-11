import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_model.dart';
import '../widgets/app_layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  // --- REAL-TIME USERNAME VALIDATION FIELDS ---
  Timer? _debounce;
  bool _isUsernameValidating = false;
  bool _usernameAvailable = false;
  String _usernameMessage = "";

  @override
  void initState() {
    super.initState();
    // Listen to changes in the username field as the user types
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- REAL-TIME DEBOUNCED VALIDATION LOGIC ---
  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = false;
        _usernameMessage = "";
      });
      return;
    }

    setState(() {
      _isUsernameValidating = true;
      _usernameMessage = "Checking availability...";
    });

    // Debounce for 500ms to avoid overwhelming Firebase with requests per keystroke
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
          _usernameMessage = "Could not verify username status";
        });
      }
    });
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Safety Terms & Conditions",
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "1. EMERGENCY USE: The SOS button is for immediate danger only. Misuse or hoaxes will result in immediate account termination.\n\n"
            "2. GPS TRACKING: TukoSalama requires 5-meter GPS precision during alerts to coordinate response effectively.\n\n"
            "3. ANONYMITY: Reports are anonymous to students, but verified by MKU Security to prevent abuse.\n\n"
            "4. PRIVACY: Data is encrypted and used strictly for campus safety coordination under Kenyan Law.",
            style: TextStyle(fontSize: 14),
          ),
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

  Future<void> _handleRegistration() async {
    final email = _emailController.text.trim().toLowerCase();
    final phoneNumber = _phoneController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (_nameController.text.isEmpty || username.isEmpty || email.isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    if (!_usernameAvailable) {
      _showSnackBar("Please select a valid, unique username", isError: true);
      return;
    }

    if (!(email.endsWith('@gmail.com') || email.endsWith('@outlook.com'))) {
      _showSnackBar("Use @gmail.com or @outlook.com only", isError: true);
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      _showSnackBar("Phone number must contain digits only", isError: true);
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar("You must agree to the Safety Terms", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User Authentication profile
      UserCredential res = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          );

      // 2. Map structural model layout rules
      TukoUser newUser = TukoUser(
        uid: res.user!.uid,
        name: _nameController.text.trim(),
        username: username,
        email: email,
        idNumber: _idController.text.trim(),
        phoneNumber: phoneNumber,
        role: UserRole.student, // Base auto-lock setup tier assignment
        createdAt: DateTime.now(),
        isFirstLogin: false,
      );

      // 3. Automate collection record creation securely
      await FirebaseFirestore.instance
          .collection('users')
          .doc(res.user!.uid)
          .set(newUser.toMap());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppLayout(user: newUser)),
      );
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    // Button accessibility check rule
    bool isRegisterButtonButtonEnabled =
        _agreedToTerms && _usernameAvailable && !_isUsernameValidating;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TukoSalama Registration"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            SvgPicture.asset('lib/assets/images/app_icon.svg', height: 80),
            const SizedBox(height: 20),
            _buildTextField(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 15),

            // --- USERNAME TRACKER CELL WITH SUB-VALIDATOR ---
            _buildTextField(
              _usernameController,
              "Unique Username",
              Icons.alternate_email,
            ),
            if (_usernameMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (_isUsernameValidating)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _usernameAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _usernameAvailable ? Colors.green : Colors.red,
                          size: 14,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _usernameMessage,
                        style: TextStyle(
                          fontSize: 12,
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

            const SizedBox(height: 15),
            _buildTextField(_idController, "Registration ID", Icons.badge),
            const SizedBox(height: 15),
            _buildTextField(
              _phoneController,
              "Phone Number",
              Icons.phone,
              isDigit: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _emailController,
              "Email (@gmail or @outlook)",
              Icons.email,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _passwordController,
              "Password",
              Icons.lock,
              isPass: true,
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: const Color(0xFF0D47A1),
                  onChanged: (val) => setState(() => _agreedToTerms = val!),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsDialog,
                    child: const Text.rich(
                      TextSpan(
                        text: "I agree to the ",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        children: [
                          TextSpan(
                            text: "Safety Terms and Conditions",
                            style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: isRegisterButtonButtonEnabled
                        ? _handleRegistration
                        : null, // Disables button automatically if invalid
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      disabledBackgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        color: isRegisterButtonButtonEnabled
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPass = false,
    bool isDigit = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isDigit ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
