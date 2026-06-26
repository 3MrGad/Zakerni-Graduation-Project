import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../theme/caregiver_theme.dart';

class Tracking extends StatefulWidget {
  const Tracking({super.key});
  @override
  State<Tracking> createState() => _TrackingState();
}

class _TrackingState extends State<Tracking> {
  GoogleMapController? _mapController;
  List<dynamic> _patients = [];
  dynamic _selectedPatient;
  Map<String, dynamic>? _patientLocation;
  bool _loading = true;
  bool _loadingLocation = false;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Timer? _refreshTimer;

  double _geofenceRadius = 200;
  LatLng? _patientLatLng;
  LatLng? _homeLatLng;
  bool _outsideGeofence = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final patients = await ApiService.getMyPatients();
      setState(() => _patients = patients);
      if (patients.isNotEmpty) {
        _selectedPatient = patients[0];
        await _loadPatientLocation();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPatientLocation() async {
    if (_selectedPatient == null) return;
    setState(() => _loadingLocation = true);

    try {
      Map<String, dynamic> loc;
      try {
        loc = await ApiService.getCaregiverPatientLocation();
      } catch (_) {
        loc = await ApiService.getPatientLocation(
          (_selectedPatient['patient_id'] as int),
        );
      }
      setState(() {
        _patientLocation = loc;
        _patientLatLng = LatLng(
          double.parse((loc['latitude'] ?? loc['lat']).toString()),
          double.parse((loc['longitude'] ?? loc['lng']).toString()),
        );
        if (loc['home_lat'] != null && loc['home_lng'] != null) {
          _homeLatLng = LatLng(
            double.parse(loc['home_lat'].toString()),
            double.parse(loc['home_lng'].toString()),
          );
        }
        _geofenceRadius =
            (loc['geofence_radius_meters'] as num?)?.toDouble() ?? 200;
        _outsideGeofence = loc['outside_geofence'] == true;
      });
      _updateMapMarkers();
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_patientLatLng!, 16));
    } catch (e) {
      setState(() => _patientLocation = null);
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  void _updateMapMarkers() {
    if (_patientLatLng == null) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('patient'),
          position: _patientLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: _selectedPatient?['name'] ?? 'Patient',
            snippet:
                'Last updated: ${_formatTime(_patientLocation?['recorded_at'])}',
          ),
        ),
      };
      _circles = {};
      if (_homeLatLng != null) {
        _circles.add(Circle(
          circleId: const CircleId('geofence'),
          center: _homeLatLng!,
          radius: _geofenceRadius,
          fillColor:
              (_outsideGeofence ? Colors.red : Colors.green).withOpacity(0.15),
          strokeColor: _outsideGeofence ? Colors.red : Colors.green,
          strokeWidth: 2,
        ));
      }
    });
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'Unknown';
    try {
      final dt = DateTime.parse(time.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _loadPatientLocation());
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('GPS Tracking',
            style: GoogleFonts.poppins(
                color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadPatientLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? _buildNoPatients()
              : Column(
                  children: [
                    // Patient selector
                    if (_patients.length > 1) _buildPatientSelector(),
                    // Map
                    SizedBox(
                      height: 300,
                      child: _patientLatLng == null
                          ? _buildNoLocationPlaceholder()
                          : kIsWeb
                              ? _buildWebLocationPreview()
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                      target: _patientLatLng!, zoom: 16),
                                  markers: _markers,
                                  circles: _circles,
                                  onMapCreated: (c) {
                                    _mapController = c;
                                    _startAutoRefresh();
                                  },
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: true,
                                ),
                    ),
                    // Info panel
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildLocationCard(),
                              const SizedBox(height: 16),
                              _buildSafeZoneCard(),
                              const SizedBox(height: 16),
                              _buildEmergencyButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPatientSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButton<dynamic>(
        isExpanded: true,
        value: _selectedPatient,
        underline: const SizedBox(),
        items: _patients
            .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p['name'] as String? ?? 'Patient',
                      style: GoogleFonts.inter()),
                ))
            .toList(),
        onChanged: (p) {
          setState(() => _selectedPatient = p);
          _loadPatientLocation();
        },
      ),
    );
  }

  Widget _buildWebLocationPreview() {
    if (_patientLatLng != null && _refreshTimer == null) {
      _startAutoRefresh();
    }
    return Container(
      color: const Color(0xFFE0F2F1),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: Color(0xFF4A7C59)),
          const SizedBox(height: 12),
          Text(
            'Map preview is limited in Edge/browser',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${_patientLatLng!.latitude.toStringAsFixed(5)}\nLng: ${_patientLatLng!.longitude.toStringAsFixed(5)}',
            style: GoogleFonts.inter(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${_formatTime(_patientLocation?['recorded_at'])}',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLocationPlaceholder() {
    return Container(
      color: const Color(0xFFE0F2F1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _loadingLocation
                ? const CircularProgressIndicator()
                : const Icon(Icons.location_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _loadingLocation ? 'Loading location...' : 'No location data yet',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
            ),
            if (!_loadingLocation) ...[
              const SizedBox(height: 8),
              Text(
                'Patient needs to open the app to share location',
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final name = _selectedPatient?['name'] as String? ?? 'Patient';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Location',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Safe Zone ✓',
                      style: GoogleFonts.inter(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_patientLocation != null) ...[
              Text(name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                'Lat: ${double.parse(_patientLocation!['latitude'].toString()).toStringAsFixed(5)}, '
                'Lng: ${double.parse(_patientLocation!['longitude'].toString()).toStringAsFixed(5)}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              ),
              Text(
                'Updated ${_formatTime(_patientLocation!['recorded_at'])}',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
            ] else
              Text('Location not available',
                  style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _setHomeFromCurrent() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await ApiService.setHomeLocation(
        homeLat: pos.latitude,
        homeLng: pos.longitude,
        geofenceRadiusMeters: _geofenceRadius.round(),
      );
      setState(() => _homeLatLng = LatLng(pos.latitude, pos.longitude));
      _updateMapMarkers();
      _showError('Home location saved');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Widget _buildSafeZoneCard() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CaregiverTheme.cardRadius)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _outsideGeofence
                      ? Icons.warning_amber
                      : Icons.shield_outlined,
                  color: _outsideGeofence ? Colors.red : CaregiverTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _outsideGeofence
                      ? 'Patient outside geofence'
                      : 'Geofence active',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _outsideGeofence
                          ? Colors.red
                          : CaregiverTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Radius: ${_geofenceRadius.round()} m',
                style: GoogleFonts.inter(fontSize: 12)),
            Slider(
              min: 50,
              max: 500,
              divisions: 9,
              value: _geofenceRadius.clamp(50, 500),
              label: '${_geofenceRadius.round()} m',
              activeColor: CaregiverTheme.primary,
              onChanged: (v) => setState(() => _geofenceRadius = v),
              onChangeEnd: (v) async {
                if (_homeLatLng == null) return;
                try {
                  await ApiService.setHomeLocation(
                    homeLat: _homeLatLng!.latitude,
                    homeLng: _homeLatLng!.longitude,
                    geofenceRadiusMeters: v.round(),
                  );
                } catch (e) {
                  _showError(e.toString());
                }
              },
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setHomeFromCurrent,
                style: ElevatedButton.styleFrom(
                    backgroundColor: CaregiverTheme.primary),
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('Set Home Location',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Emergency Call',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              content: Text(
                  'Call emergency services for ${_selectedPatient?['name'] ?? 'the patient'}?',
                  style: GoogleFonts.inter()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Call 911',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text('CALL EMERGENCY',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildNoPatients() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No patients assigned',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Ask a patient to register and link\nyour caregiver ID to their account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
