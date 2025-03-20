import 'dart:async';
import 'dart:convert';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_background/flutter_background.dart';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  final LocationService _locationService = LocationService();
  final BluetoothService _bluetoothService = BluetoothService();
  Timer? _gpsTimer;

  bool _isRunning = false;

  Future<void> startScheduler() async {
    if (_isRunning) {
      print("⚠️ GPS Scheduler is already running.");
      return;
    }
    _isRunning = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      _gpsTimer = Timer.periodic(const Duration(seconds: 180), (timer) async {
        try {
          var position = await _locationService.getCurrentPosition();
          String latitude = position.latitude.toStringAsFixed(5);
          String longitude = position.longitude.toStringAsFixed(5);

          String gpsData = jsonEncode({
            "id": "$vesselId",
            "l": "$latitude|$longitude",
          });

          await _bluetoothService.sendGPSData(gpsData);
        } catch (e) {
          print("Error in GPS Scheduler: $e");
        }
      });

      print("✅ GPS Scheduler was started successfully.");
    } catch (e) {
      print("❌ Error initializing GPS Scheduler: $e");
    }
  }

  void stopScheduler() {
    if (_isRunning) {
      _gpsTimer?.cancel();
      _isRunning = false;
      print("🛑 GPS Scheduler stopped.");
    }
  }
}
