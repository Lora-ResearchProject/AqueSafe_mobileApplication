import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:flutter/material.dart';
import 'bluetooth_service.dart';
import '../utils/bluetooth_device_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../screens/dashboard.dart';
// import 'dart:async';
import 'dart:convert';

class SOSTriggerService {
  final LocationService _locationService = LocationService();

  void handleConfirm(BuildContext context, BluetoothService bluetoothService,
      BuildContext dialogContext,
      {required Function onUpdate}) async {
    try {
      // Access the device from the singleton
      DiscoveredDevice? device = BluetoothDeviceManager().device;

      if (device == null) {
        throw Exception("Discovered Device not found in Device Manager.");
      }

      print("Using Discovered Device: ${device.name} - ${device.id}");

      // Fetch `id` from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("Vessel ID not found in SharedPreferences");
      }

      var position = await _locationService.getCurrentPosition();
      String latitude = position.latitude.toStringAsFixed(5);
      String longitude = position.longitude.toStringAsFixed(5);

      // Generate a unique ID using the GenerateUniqueIdService
      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      String sosData = jsonEncode({
        "id": "$vesselId-$uniqueMsgId",
        "l": "$latitude|$longitude",
        "s": 1
      });

      // Send SOS and update UI immediately
      await bluetoothService.sendSOSAlert(sosData, onUpdate);

      // Show success dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("SOS Sent"),
          content: const Text("SOS alert sent successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(dialogContext).pop();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Dashboard()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error handling SOS confirmation: $e");
    }
  }
}
