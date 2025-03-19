import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';

class FishingHotspotService {
  final BluetoothService _bluetoothService = BluetoothService();

  // Fetch suggested fishing hotspots
  Future<List<Map<String, dynamic>>> fetchSuggestedFishingHotspots(double latitude, double longitude) async {
    try {
      print("📡 Requesting hotspot data via BLE...");

        String hotspotRequest = jsonEncode({
        "latitude": latitude,
        "longitude": longitude
      });

      print("📡 Sending Hotspot Request via BLE: $hotspotRequest");

      // Send hotspot request to the BLE device
      await _bluetoothService.sendHotspotRequest(hotspotRequest);

      // Wait for the ESP32 to respond
      await Future.delayed(Duration(seconds: 5));

      List<Map<String, dynamic>> hotspotList =
          await _bluetoothService.listenForHotspotUpdates();

      if (hotspotList.isEmpty) {
        print("⚠️ No hotspots received.");
      } else {
        print("✅ Hotspots successfully received: ${hotspotList.length} items.");
      }

      return hotspotList;
    } catch (e) {
      print("❌ Error fetching hotspots via BLE: $e");
      return [];
    }
  }
}
