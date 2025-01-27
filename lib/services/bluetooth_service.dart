import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/bluetooth_device_manager.dart';

class BluetoothService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  late QualifiedCharacteristic gpsCharacteristic;
  late QualifiedCharacteristic sosCharacteristic;
  late QualifiedCharacteristic chatCharacteristic;
  late QualifiedCharacteristic weatherCharacteristic;

  StreamSubscription<ConnectionStateUpdate>? connectionSubscription;

  // Global state to manage Bluetooth connection
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  DiscoveredDevice? discoveredDevice;

  // check connection state manually
  Future<bool> checkConnectionState() async {
    try {
      return _isConnected;
    } catch (e) {
      print("Error checking Bluetooth connection state: $e");
      return false;
    }
  }

  // Monitor connection continuously every 5 seconds
  void monitorConnection() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        if (!_isConnected) {
          // print("Bluetooth is disconnected. Attempting to reconnect...");
          // await scanAndConnect();
        } else {
          print("Bluetooth is connected.");
        }
      } catch (e) {
        print("Error monitoring Bluetooth connection: $e");
      }
    });
  }

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
      print(">>>>>> Starting BLE scan...");
      bool deviceFound = false;

      scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(Constants.serviceUuid)]).listen(
        (device) async {
          if (device.name == "ESP32-MultiService") {
            print("Target ESP32 device found. Connecting...");
            deviceFound = true;

            await scanSubscription.cancel();
            await _connectToDevice(device);

            BluetoothDeviceManager().setDevice(device);
          }
        },
        onError: (e) {
          print("--- Error during BLE scan: $e");
        },
      );

      await Future.delayed(const Duration(seconds: 20));

      if (!deviceFound) {
        throw Exception("Target ESP32 device not found during scan.");
      }
    } catch (e) {
      print("--- Error during scan and connect: $e");
      rethrow;
    } finally {
      await scanSubscription.cancel();
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      print(">>> Connecting to device: ${device.name}...");

      connectionSubscription =
          _ble.connectToDevice(id: device.id).listen((event) {
        if (event.connectionState == DeviceConnectionState.connected) {
          _isConnected = true;
          print("=== Device connected.");

          initializeCharacteristics(device);
        } else if (event.connectionState ==
            DeviceConnectionState.disconnected) {
          _isConnected = false;
          print("=== Device disconnected.");
        }
      });
    } catch (e) {
      print(">>> Error connecting to device: $e");
      rethrow;
    }
  }

  // Method to initialize characteristics
  Future<void> initializeCharacteristics(DiscoveredDevice device) async {
    try {
      sosCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.sosCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      gpsCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.gpsCharacteristicUuid),
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

      // Store them in the singleton
      BluetoothDeviceManager().setCharacteristics(sosCharacteristic,
          gpsCharacteristic, chatCharacteristic, weatherCharacteristic);

      print("Device connected and characteristics initialized.");
    } catch (e) {
      print("Error initializing characteristics: $e");
    }
  }

  Future<void> sendGPSData(String gpsData) async {
    final gpsCharacteristic = BluetoothDeviceManager().gpsCharacteristic;
    try {
      if (gpsCharacteristic != null) {
        await _ble.writeCharacteristicWithoutResponse(
          gpsCharacteristic,
          value: utf8.encode(gpsData),
        );
        print("GPS data sent to ESP32: $gpsData");
      } else {
        throw Exception(
            "Device not connected or GPS characteristic not initialized.");
      }
    } catch (e) {
      print("Error sending GPS data: $e");
    }
  }

  // Fetch SOS alerts from the SOS characteristic (BLE read)
  Future<String> fetchSOSAlerts() async {
    final sosCharacteristic = BluetoothDeviceManager().sosCharacteristic;
    try {
      // Check if the SOS characteristic is initialized
      if (sosCharacteristic != null) {
        final characteristicValue =
            await _ble.readCharacteristic(sosCharacteristic);
        String sosAlertsData = utf8.decode(characteristicValue);
        print("SOS alerts data received from esp32: $sosAlertsData");
        return sosAlertsData;
      } else {
        throw Exception("SOS characteristic is not initialized.");
      }
    } catch (e) {
      print("Error fetching SOS alerts: $e");
      return '';
    }
  }

  Future<void> sendSOSAlert(String sosData, Function onUpdate) async {
    final sosCharacteristic = BluetoothDeviceManager().sosCharacteristic;
    try {
      // Ensure the device is connected and the characteristic is initialized
      // if (!_isConnected) {
      //   throw Exception("Bluetooth is not connected.");
      // }

      // Send SOS alert if the characteristic is initialized
      if (sosCharacteristic != null) {
        await _ble.writeCharacteristicWithoutResponse(
          sosCharacteristic,
          value: utf8.encode(sosData),
        );
        print("SOS alert sent via bluetooth: $sosData");

        // Store SOS data in SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> sosDataMap = jsonDecode(sosData);
        await prefs.setString(
            'lastSOS',
            jsonEncode({
              'id': sosDataMap['id'],
              'latitude': sosDataMap['l'].split('|')[0],
              'longitude': sosDataMap['l'].split('|')[1],
              'status': 'Active', // SOS status
              'timestamp': DateTime.now().toIso8601String()
            }));

        print("Latest SOS data saved locally.");

        // Trigger the UI update
        onUpdate();
      } else {
        throw Exception("SOS characteristic is not initialized.");
      }
    } catch (e) {
      print("Error sending SOS alert via bluetooth: $e");
    }
  }

  Future<void> sendChatMessage(String message) async {
    print("Sending SOS alert via chat method...");
    print("Chat Characteristic details: ");
    print("UUID: ${chatCharacteristic.characteristicId}");
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

  // Cancel the connection subscription when no longer needed
  void dispose() {
    connectionSubscription?.cancel();
  }
}
