import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

class BluetoothService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  late QualifiedCharacteristic gpsCharacteristic;
  late QualifiedCharacteristic sosCharacteristic;
  late QualifiedCharacteristic chatCharacteristic;
  late QualifiedCharacteristic weatherCharacteristic;

  StreamSubscription<ConnectionStateUpdate>? connectionSubscription;

  Future<void> requestPermissions() async {
    if (await Permission.location.isDenied ||
        await Permission.bluetooth.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied) {
      var status = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (status[Permission.location]?.isDenied ?? true) {
        throw Exception("Location permission denied.");
      }
      // if (status[Permission.bluetooth]?.isDenied ?? true) {
      //   throw Exception("Bluetooth permission denied.");
      // }
      if (status[Permission.bluetoothScan]?.isDenied ?? true) {
        throw Exception("Bluetooth Scan permission denied.");
      }
      if (status[Permission.bluetoothConnect]?.isDenied ?? true) {
        throw Exception("Bluetooth Connect permission denied.");
      }
    }
  }

  Future<void> scanAndConnect() async {
    await requestPermissions();

    late StreamSubscription<DiscoveredDevice> scanSubscription;
    try {
      print(">>> Starting BLE scan...");
      bool deviceFound = false;

      scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(Constants.serviceUuid)]).listen(
        (device) async {
          if (device.name == "ESP32-MultiService") {
            print(">>> Target ESP32 device found. Connecting...");
            deviceFound = true;
            await scanSubscription.cancel();
            await _connectToDevice(device);
          }
        },
        onError: (e) {
          print(">>> Error during BLE scan: $e");
        },
      );

      await Future.delayed(const Duration(seconds: 20));

      if (!deviceFound) {
        throw Exception("Target ESP32 device not found during scan.");
      }
    } catch (e) {
      print(">>> Error during scan and connect: $e");
      rethrow;
    } finally {
      await scanSubscription.cancel();
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      print(">>> Connecting to device: ${device.name}...");

      // Listen for connection changes
      final connectionStream = _ble.connectToDevice(id: device.id);
      connectionStream.listen((event) {
        print(">>> Connection state: ${event.connectionState}");
      });

      gpsCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.gpsCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      sosCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.sosCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      chatCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.chatCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      weatherCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.weatherCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      print("Device connected. Characteristics initialized.");
    } catch (e) {
      print(">>> Error connecting to device: $e");
      rethrow;
    }
  }

  Future<void> sendGPSData(String gpsData) async {
    try {
      await _ble.writeCharacteristicWithoutResponse(
        gpsCharacteristic,
        value: utf8.encode(gpsData),
      );
      print("GPS data sent to handle via bluetooth: $gpsData");
    } catch (e) {
      print("Error sending GPS data via bluetooth: $e");
    }
  }

  Future<void> sendSOSAlert(String sosData) async {
    try {
      await _ble.writeCharacteristicWithoutResponse(
        sosCharacteristic,
        value: utf8.encode(sosData),
      );
      print("SOS alert sent to handle via bluetooth: $sosData");
    } catch (e) {
      print("Error sending SOS alert via bluetooth: $e");
    }
  }

  Future<void> sendChatMessage(String message) async {
    try {
      await _ble.writeCharacteristicWithoutResponse(
        chatCharacteristic,
        value: utf8.encode(message),
      );
      print("Chat message sent: $message");
    } catch (e) {
      print("Error sending chat message: $e");
    }
  }

  Future<void> listenForWeatherUpdates() async {
    _ble.subscribeToCharacteristic(weatherCharacteristic).listen(
      (data) {
        final weatherData = utf8.decode(data);
        print("Received weather data: $weatherData");
      },
      onError: (e) {
        print("Error receiving weather updates: $e");
      },
    );
  }

  Future<void> listenForChatMessages() async {
    _ble.subscribeToCharacteristic(chatCharacteristic).listen(
      (data) {
        final chatMessage = utf8.decode(data);
        print("Received chat message: $chatMessage");
      },
      onError: (e) {
        print("Error receiving chat messages: $e");
      },
    );
  }

  // Monitor BLE connection state
  Future<void> monitorConnection(String deviceId) async {
    connectionSubscription = _ble.connectToDevice(id: deviceId).listen((event) {
      if (event.connectionState == DeviceConnectionState.disconnected) {
        print(
            "------------------------ Device disconnected. Attempting to reconnect...");
        scanAndConnect();
      } else if (event.connectionState == DeviceConnectionState.connected) {
        print("------------------------ Device connected.");
      }
    });
  }

  // Cancel the connection subscription when no longer needed
  void dispose() {
    connectionSubscription?.cancel();
  }
}
