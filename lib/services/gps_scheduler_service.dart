import 'dart:async';
import 'dart:convert';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/bluetooth_device_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class SchedulerService {
  final LocationService _locationService = LocationService();
  final BluetoothService _bluetoothService = BluetoothService();
  Timer? _gpsTimer;

  // Initialize the scheduler
  Future<void> startScheduler() async {
    try {
      // Access the device from the singleton
      DiscoveredDevice? device = BluetoothDeviceManager().device;

      if (device == null) {
        throw Exception("Discovered Device not found in Device Manager.");
      }

      // await _bluetoothService.initializeCharacteristics(device);

      print("Using Discovered Device: ${device.name} - ${device.id}");

      // Fetch `id` from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("Vessel ID not found in SharedPreferences");
      }

      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          var position = await _locationService.getCurrentPosition();
          String latitude = position.latitude.toStringAsFixed(5);
          String longitude = position.longitude.toStringAsFixed(5);

          String gpsData = jsonEncode({
            "id": "$vesselId-0000",
            "l": "$latitude-$longitude",
          });

          await _bluetoothService.sendGPSData(gpsData);

          print("GPS data send request sent with gps Data: $gpsData");
        } catch (e) {
          print("Error in GPS Scheduler: $e");

          // Attempt to reconnect if BLE is disconnected
          if (e.toString().contains("Disconnected")) {
            print("Attempting to reconnect...");
            await _bluetoothService.scanAndConnect();
          }
        }
      });

      print("GPS Scheduler was started successfully.");
    } catch (e) {
      print("Error initializing GPS Scheduler: $e");
    }
  }

  // Stop the scheduler
  void stopScheduler() {
    _gpsTimer?.cancel();
    print("GPS Scheduler stopped.");
  }
}
