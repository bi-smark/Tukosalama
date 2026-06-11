import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../security/incident_service.dart';
import '../models/incident_model.dart';

enum MapUserRole { student, security, admin }

class SafetyMap extends StatefulWidget {
  final MapUserRole role;
  const SafetyMap({super.key, required this.role});

  @override
  State<SafetyMap> createState() => _SafetyMapState();
}

class _SafetyMapState extends State<SafetyMap> {
  // ignore: unused_field
  GoogleMapController? _mapController;

  // Tactical data sets managed by Security/Admin
  final Set<Marker> _tacticalMarkers = {};
  final Set<Circle> _tacticalCircles = {};

  @override
  void initState() {
    super.initState();
    _addInitialZones();
  }

  void _addInitialZones() {
    _tacticalCircles.addAll([
      _createCircle(
        "thika_highway_hotzone",
        const LatLng(-1.0435, 37.0760),
        150,
        Colors.red,
      ),
      _createCircle(
        "student_center_safezone",
        const LatLng(-1.0485, 37.0780),
        100,
        Colors.green,
      ),
    ]);
  }

  // Helper to build interactive circles
  Circle _createCircle(String id, LatLng center, double radius, Color color) {
    return Circle(
      circleId: CircleId(id),
      center: center,
      radius: radius,
      fillColor: color.withValues(alpha: 0.25),
      strokeColor: color,
      strokeWidth: 2,
      consumeTapEvents: true, // REQUIRED FOR EDITING
      onTap: () => _showEditMenu(id, isCircle: true),
    );
  }

  // --- EDITING LOGIC ---
  void _showEditMenu(String id, {required bool isCircle}) {
    if (widget.role == MapUserRole.student) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "TACTICAL EDITOR",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isCircle) ...[
                      const Text(
                        "Adjust Zone Radius",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Slider(
                        value: _tacticalCircles
                            .firstWhere((c) => c.circleId.value == id)
                            .radius,
                        min: 50,
                        max: 800,
                        activeColor: const Color(0xFF0D47A1),
                        onChanged: (val) {
                          setState(() {
                            final old = _tacticalCircles.firstWhere(
                              (c) => c.circleId.value == id,
                            );
                            _tacticalCircles.remove(old);
                            _tacticalCircles.add(
                              old.copyWith(radiusParam: val),
                            );
                          });
                          setModalState(() {});
                        },
                      ),
                    ],
                    const Divider(height: 30),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        "Delete Element",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isCircle) {
                            _tacticalCircles.removeWhere(
                              (c) => c.circleId.value == id,
                            );
                          } else {
                            _tacticalMarkers.removeWhere(
                              (m) => m.markerId.value == id,
                            );
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- CREATION LOGIC ---
  void _onMapLongPress(LatLng position) {
    if (widget.role == MapUserRole.student) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "TACTICAL DEPLOYMENT",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _deployTile(ctx, "Security Post", Icons.security, Colors.blue, () {
              final id = "post_${DateTime.now().millisecondsSinceEpoch}";
              setState(
                () => _tacticalMarkers.add(
                  Marker(
                    markerId: MarkerId(id),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                    onTap: () => _showEditMenu(id, isCircle: false),
                  ),
                ),
              );
            }),
            _deployTile(ctx, "Hot Zone", Icons.dangerous, Colors.red, () {
              setState(
                () => _tacticalCircles.add(
                  _createCircle(
                    "hot_${DateTime.now().millisecondsSinceEpoch}",
                    position,
                    150,
                    Colors.red,
                  ),
                ),
              );
            }),
            _deployTile(ctx, "Safe Zone", Icons.gpp_good, Colors.green, () {
              setState(
                () => _tacticalCircles.add(
                  _createCircle(
                    "safe_${DateTime.now().millisecondsSinceEpoch}",
                    position,
                    100,
                    Colors.green,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _deployTile(
    BuildContext ctx,
    String t,
    IconData i,
    Color c,
    VoidCallback a,
  ) {
    return ListTile(
      leading: Icon(i, color: c),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        a();
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true, // FIX: Navigation bar overlap
        child: StreamBuilder<List<Incident>>(
          stream: IncidentService().getLiveIncidentFeed(),
          builder: (context, snapshot) {
            final displayIncidents = (snapshot.data ?? []).where((i) {
              if (widget.role == MapUserRole.student) {
                return i.status != IncidentStatus.resolved &&
                    (i.isSOS || i.threatLevel == "High");
              }
              return i.status != IncidentStatus.resolved ||
                  widget.role == MapUserRole.admin;
            }).toList();

            final Set<Marker> allMarkers = {
              ...displayIncidents.map(
                (h) => Marker(
                  markerId: MarkerId(h.id),
                  position: LatLng(h.lat, h.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    h.isSOS
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueYellow,
                  ),
                ),
              ),
              ..._tacticalMarkers,
            };

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-1.0465, 37.0772),
                    zoom: 16.2,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  markers: allMarkers,
                  circles: _tacticalCircles,
                  onLongPress: _onMapLongPress,
                ),
                Positioned(top: 15, left: 15, child: _buildMapLegend()),
                if (widget.role != MapUserRole.student)
                  _buildIncidentSheet(displayIncidents),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "LEGEND",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 6),
          _legendRow(Icons.circle, Colors.red.withAlpha(100), "Hot Zone"),
          _legendRow(Icons.circle, Colors.green.withAlpha(100), "Safe Zone"),
          _legendRow(Icons.location_on, Colors.blue, "Security Post"),
          _legendRow(Icons.location_on, Colors.red, "SOS Alert"),
        ],
      ),
    );
  }

  Widget _legendRow(IconData i, Color c, String l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(i, size: 12, color: c),
          const SizedBox(width: 8),
          Text(
            l,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentSheet(List<Incident> incidents) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.08,
      maxChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: incidents.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                );
              }
              final h = incidents[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (h.isSOS ? Colors.red : Colors.orange)
                      .withAlpha(30),
                  child: Icon(
                    h.isSOS ? Icons.emergency : Icons.warning,
                    color: h.isSOS ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                ),
                title: Text(
                  h.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  h.location,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
