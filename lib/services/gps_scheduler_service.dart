import 'dart:async';
import 'dart:convert';
import '../services/bluetooth_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class SchedulerService {
  final LocationService _locationService = LocationService();
  final BluetoothService _bluetoothService = BluetoothService();
  Timer? _gpsTimer;

  // Initialize the scheduler
  Future<void> startScheduler() async {
    try {
      // Initialize Bluetooth
      await _bluetoothService.initializeBluetooth();

      // Start the periodic scheduler for GPS data
      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          // Fetch GPS Data
          var position = await _locationService.getCurrentPosition();
          String latitude = position.latitude.toStringAsFixed(6);
          String longitude = position.longitude.toStringAsFixed(6);

          // Prepare GPS Data
          String gpsData = jsonEncode({
            "id": "${Constants.vesselId}-0000",
            "l": "$latitude-$longitude",
          });

          // Send GPS Data via Bluetooth
          await _bluetoothService.sendData(
            _bluetoothService.gpsCharacteristic,
            gpsData,
          );

          print("GPS data sent: $gpsData");
        } catch (e) {
          print("Error in GPS Scheduler: $e");
        }
      });

      print("GPS Scheduler started successfully.");
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
