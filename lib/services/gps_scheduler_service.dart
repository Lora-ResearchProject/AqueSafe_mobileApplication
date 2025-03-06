import 'dart:async';
import 'dart:convert';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/bluetooth_device_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:flutter_background/flutter_background.dart';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class SchedulerService {
  final LocationService _locationService = LocationService();
  final BluetoothService _bluetoothService = BluetoothService();
  Timer? _gpsTimer;

  Future<void> startScheduler() async {
    try {
      // ✅ Enable Background Execution
      // bool hasPermission = await FlutterBackground.hasPermissions;
      // if (!hasPermission) {
      //   await FlutterBackground.initialize();
      // }
      // await FlutterBackground.enableBackgroundExecution();

      // print("✅ Background Execution Enabled");

      // DiscoveredDevice? device = BluetoothDeviceManager().device;

      // if (device == null) {
      //   throw Exception("Discovered Device not found in Device Manager.");
      // }
      // print("Using Discovered Device: ${device.name} - ${device.id}");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      // Configure Background Location Tracking
    // await bg.BackgroundGeolocation.ready(bg.Config(
    //   desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH, // High Accuracy
    //   distanceFilter: 0, // Get updates as frequently as possible
    //   stationaryRadius: 0,
    //   stopTimeout: 0,
    //   heartbeatInterval: 5, // Force location update every 5 seconds
    //   foregroundService: true, // Run as a foreground service
    //   allowIdenticalLocations: true, // Don't filter out locations that haven't changed
    // ));

    //   bg.BackgroundGeolocation.onLocation((bg.Location location) async {
    //     try {
    //       String latitude = location.coords.latitude.toStringAsFixed(5);
    //       String longitude = location.coords.longitude.toStringAsFixed(5);

    //       String gpsData = jsonEncode({
    //         "id": "$vesselId",
    //         "l": "$latitude|$longitude",
    //       });

    //       await _bluetoothService.sendGPSData(gpsData);
    //       print("📡 GPS Data Sent in Background: $gpsData");
    //     } catch (e) {
    //       print("❌ Error in Background GPS Scheduler: $e");
    //     }
    //   });

      // Start Background Location Tracking
      // bg.BackgroundGeolocation.start();
      // print("✅ GPS Scheduler Started in Background");

      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
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

      print("GPS Scheduler was started successfully.");
    } catch (e) {
      print("❌ Error initializing GPS Scheduler: $e");
    }
  }

  // Stop the scheduler
  void stopScheduler() {
    // bg.BackgroundGeolocation.stop();
    _gpsTimer?.cancel();
    print("🛑 GPS Scheduler stopped.");
  }
}
