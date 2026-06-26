import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  static Timer? _timer;
  static bool _running = false;

  // Call this when patient logs in
  static Future<void> startTracking({
    double? homeLat,
    double? homeLng,
    int intervalSeconds = 30,
  }) async {
    if (_running) return;

    // Browser testing: geolocator works in Edge if the user allows location.
    if (kIsWeb) {
      intervalSeconds = intervalSeconds < 60 ? 60 : intervalSeconds;
    }

    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    _running = true;

    // Send immediately
    await _sendLocation(homeLat: homeLat, homeLng: homeLng);

    // Then every N seconds
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      await _sendLocation(homeLat: homeLat, homeLng: homeLng);
    });
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  static Future<void> _sendLocation({double? homeLat, double? homeLng}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ApiService.patientUpdateLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (_) {
      // Silently fail — don't crash the app
    }
  }

  static Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }
}
