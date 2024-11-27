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
      await _bluetoothService.scanAndConnect();

      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          var position = await _locationService.getCurrentPosition();
          String latitude = position.latitude.toStringAsFixed(6);
          String longitude = position.longitude.toStringAsFixed(6);

          String gpsData = jsonEncode({
            "id": "${Constants.vesselId}-0000",
            "l": "$latitude-$longitude",
          });

          await _bluetoothService.sendGPSData(gpsData);

          print(
              "------------------------ GPS data send request sent with gps Data: $gpsData");
        } catch (e) {
          print("------------------------ Error in GPS Scheduler: $e");

          // Attempt to reconnect if BLE is disconnected
          if (e.toString().contains("Disconnected")) {
            print("------------------------ Attempting to reconnect...");
            await _bluetoothService.scanAndConnect();
          }
        }
      });

      print("------------------------ GPS Scheduler was started successfully.");
    } catch (e) {
      print("------------------------ Error initializing GPS Scheduler: $e");
    }
  }

  // Stop the scheduler
  void stopScheduler() {
    _gpsTimer?.cancel();
    print("------------------------ GPS Scheduler stopped.");
  }
}
