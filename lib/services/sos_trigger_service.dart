import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/utils/snack_bar.dart';
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

      print("---- Sos send lat: ${latitude}, Lon: ${longitude}");
      // Generate a unique ID using the GenerateUniqueIdService
      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      String sosData = jsonEncode({
        "id": "$vesselId|$uniqueMsgId",
        "l": "$latitude|$longitude",
        "s": 1
      });

      await bluetoothService.sendSOSAlert(sosData, onUpdate);

      SnackbarUtils.showSuccessMessage(context, "SOS alert sent successfully.");
    } catch (e) {
      print("Error handling SOS confirmation: $e");
      SnackbarUtils.showErrorMessage(
          context, "Error occured while sending sos.");
    }
  }
}
