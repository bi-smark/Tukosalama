import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../widgets/tuko_input.dart';
import '../widgets/tuko_button.dart';

class ReportIncidentPage extends StatefulWidget {
  final TukoUser user;
  const ReportIncidentPage({super.key, required this.user});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  String _selectedType = "Theft";
  bool _isLoading = false;

  // --- GET GPS LOCATION ---
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // --- SUBMIT FUNCTION ---
  Future<void> _submitReport() async {
    final locationName = _locController.text.trim();
    final description = _descController.text.trim();

    if (locationName.isEmpty || description.isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get real coordinates for the Tactical Map
      Position? position = await _getCurrentLocation();

      // Fallback to MKU Thika coordinates if GPS fails
      double latitude = position?.latitude ?? -1.0465;
      double longitude = position?.longitude ?? 37.0772;

      // 2. Create the Incident object with userName included
      final newIncident = Incident(
        id: '',
        reporterId: widget.user.uid,
        userName: widget.user.name, // Matches the new model field
        type: _selectedType,
        description: description,
        location: locationName,
        lat: latitude,
        lng: longitude,
        status: IncidentStatus.pending,
        isSOS: false,
        timestamp: DateTime.now(),
      );

      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('incidents')
          .add(newIncident.toMap());

      if (!mounted) return;

      Navigator.pop(context);
      _showSnackBar("Report Submitted Successfully", isError: false);
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Report Incident",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: "Incident Type",
                prefixIcon: Icon(Icons.category_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                "Theft",
                "Medical",
                "Harassment",
                "Fire",
                "Other",
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 20),
            TukoInput(
              controller: _locController,
              label: "Specific Location (e.g., MKU Main Gate)",
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),
            TukoInput(
              controller: _descController,
              label: "Describe the incident",
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF0D47A1))
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: TukoButton(
                      text: "SUBMIT REPORT",
                      onPressed: _submitReport,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
