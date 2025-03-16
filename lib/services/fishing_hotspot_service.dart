import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';

class FishingHotspotService {
  final BluetoothService _bluetoothService = BluetoothService();

  // Fetch suggested fishing hotspots
  Future<List<Map<String, dynamic>>> fetchSuggestedFishingHotspots() async {
    try {
      print("📡 Requesting hotspot data via BLE...");

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
