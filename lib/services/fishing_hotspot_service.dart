import 'dart:convert';
import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FishingHotspotService {
  final BluetoothService _bluetoothService = BluetoothService();
  final LocationService _locationService = LocationService();

  // Fetch suggested fishing hotspots
  Future<List<Map<String, dynamic>>> fetchSuggestedFishingHotspots(
      double latitude, double longitude) async {
    try {
      print("📡 Requesting hotspot data via BLE...");

      String hotspotRequest =
          jsonEncode({"latitude": latitude, "longitude": longitude});

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

  // Save a fishing location
  Future<void> saveFishingLocation() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');

      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      var position = await _locationService.getCurrentPosition();
      String latitude = position.latitude.toStringAsFixed(5);
      String longitude = position.longitude.toStringAsFixed(5);

      // Construct the BLE request payload
      final Map<String, dynamic> requestPayload = {
        "id": "$vesselId|$uniqueMsgId",
        "l": "$latitude|$longitude",
        "f": 1,
      };

      final String saveFishingRequest = jsonEncode(requestPayload);

      print("📡 Sending Save Fishing Location via BLE: $saveFishingRequest");

      // Call the BluetoothService method to send the request
      await _bluetoothService.saveFishingLocation(saveFishingRequest);
    } catch (e) {
      print("❌ Error in saveFishingLocation service method: $e");
    }
  }
}
