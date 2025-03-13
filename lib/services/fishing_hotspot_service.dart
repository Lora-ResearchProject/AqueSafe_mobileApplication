import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Fetch weather for a specific hotspot
  Future<int?> fetchWeatherForHotspot(double latitude, double longitude) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      String? _lastRequestId;

      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      _lastRequestId = "$vesselId|$uniqueMsgId";

      String weatherData = jsonEncode(
          {"id": "$vesselId|$uniqueMsgId", "l": "$latitude|$longitude", "wr": 1});

      print("📡 Sending Weather Request: $weatherData");
      await _bluetoothService.sendWeatherRequest(weatherData);

      print("📡 Fetching weather for hotspot: $weatherData");

      int? weatherResponse =
          await _bluetoothService.listenForWeatherUpdates(_lastRequestId);

      return weatherResponse;
    } catch (e) {
      print("❌ Error fetching weather for hotspot: $e");
      return null;
    }
  }
}
