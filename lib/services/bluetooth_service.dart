import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../utils/constants.dart';

class BluetoothService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  late QualifiedCharacteristic gpsCharacteristic;
  late QualifiedCharacteristic sosCharacteristic;
  late QualifiedCharacteristic chatCharacteristic;
  late QualifiedCharacteristic weatherCharacteristic;

  // Initialize Bluetooth connection
  Future<void> initializeBluetooth() async {
    try {
      final connectionStream = _ble.connectToDevice(id: Constants.deviceUuid);
      connectionStream.listen((event) {
        print("Bluetooth connection state: ${event.connectionState}");
      });

      // Define characteristics for multiple services
      gpsCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.gpsCharacteristicUuid),
        serviceId: Uuid.parse(Constants.deviceUuid),
        deviceId: Constants.deviceUuid,
      );

      sosCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.sosCharacteristicUuid),
        serviceId: Uuid.parse(Constants.deviceUuid),
        deviceId: Constants.deviceUuid,
      );

      chatCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.chatCharacteristicUuid),
        serviceId: Uuid.parse(Constants.deviceUuid),
        deviceId: Constants.deviceUuid,
      );

      weatherCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.weatherCharacteristicUuid),
        serviceId: Uuid.parse(Constants.deviceUuid),
        deviceId: Constants.deviceUuid,
      );

      print("Bluetooth initialized successfully.");
    } catch (e) {
      print("Error initializing Bluetooth: $e");
    }
  }

  // Send data via a specific characteristic
  Future<void> sendData(
      QualifiedCharacteristic characteristic, String data) async {
    try {
      await _ble.writeCharacteristicWithoutResponse(
        characteristic,
        value: utf8.encode(data),
      );
      print("Data sent via Bluetooth: $data");
    } catch (e) {
      print("Error sending data via Bluetooth: $e");
    }
  }
}
