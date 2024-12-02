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
      BuildContext dialogContext) async {
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

      var position = await _locationService.getCurrentPosition();
      String latitude = position.latitude.toStringAsFixed(5);
      String longitude = position.longitude.toStringAsFixed(5);

      String sosData = jsonEncode(
          {"id": "$vesselId-0000", "l": "$latitude|$longitude", "s": 1});

      await bluetoothService.sendSOSAlert(sosData);

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

  // final BluetoothService _bluetoothService;

  // SOSTriggerService(this._bluetoothService);

  // Future<void> handleSOSTrigger(BuildContext context) async {
  //   try {
  //     // Check if Bluetooth is connected
  //     bool isConnected = await _bluetoothService.checkConnectionState();
  //     if (!isConnected) {
  //       _showConnectingDialog(context);

  //       await _bluetoothService.scanAndConnect();

  //       Navigator.of(context).pop();
  //     }

  //     // Send SOS Alert
  //     String sosData = "SOS Triggered!";
  //     await _bluetoothService.sendSOSAlert(sosData);

  //     // Show success message
  //     _showSuccessDialog(context, "SOS Alert Sent Successfully!");
  //   } catch (e) {
  //     print("Error during SOS trigger: $e");
  //     _showErrorDialog(context, "Failed to send SOS Alert.");
  //   }
  // }

  // void _showConnectingDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text("Connecting"),
  //       content: const Text("Connecting to Bluetooth device..."),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(),
  //           child: const Text("Cancel"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _showSuccessDialog(BuildContext context, String message, BuildContext dialogContex) {
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text("Success"),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(ctx).pop();
  //             Navigator.of(dialogContext).pop();

  //             // Navigate to Dashboard to show the alert in progress
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => Dashboard()),
  //             );
  //           },
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _showErrorDialog(BuildContext context, String message) {
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text("Error"),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(),
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
