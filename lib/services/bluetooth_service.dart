import 'dart:async';
import 'dart:convert';
import 'package:aqua_safe/services/gps_scheduler_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../utils/bluetooth_device_manager.dart';
import '../utils/appStateManager.dart';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:android_intent_plus/flag.dart';

class BluetoothService {
  // ✅ Singleton instance
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal(); // Private constructor

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  late QualifiedCharacteristic gpsCharacteristic;
  late QualifiedCharacteristic sosCharacteristic;
  late QualifiedCharacteristic chatCharacteristic;
  late QualifiedCharacteristic weatherCharacteristic;

  StreamSubscription<ConnectionStateUpdate>? connectionSubscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  DiscoveredDevice? discoveredDevice;

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  // Future<bool> checkConnectionState() async {
  //   return _isConnected;
  // }

  // ✅ Monitor connection every 5 seconds and notify listeners
  // void monitorConnection() {
  //   int count = 0;
  //   Timer.periodic(const Duration(seconds: 1), (timer) async {
  //     count++;
  //     print("🔄 BLE connection check run #$count");

  //     bool isConnectedNow = await checkConnectionState();

  //     print("Is connected: $isConnected | Is Connected Now: $isConnectedNow");

  //     if (_isConnected != isConnectedNow) {
  //       _isConnected = isConnectedNow;
  //       isConnectedNotifier.value = _isConnected; // Notify UI
  //       print("📢 Notify changed");
  //     }
  //   });
  // }

  void monitorConnection() {
    _ble.statusStream.listen((status) {
      bool isConnectedNow = (status == BleStatus.ready) && _isConnected;

      if (_isConnected != isConnectedNow) {
        _isConnected = isConnectedNow;
        isConnectedNotifier.value = _isConnected;
        print("📢 BLE Connection Status Changed: $_isConnected");
      }
    });
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      // Permission.locationAlways,
      // Permission.ignoreBatteryOptimizations,
    ].request();

    // if (statuses[Permission.bluetooth]?.isDenied ?? true) {
    //   throw Exception("❌ Bluetooth permission denied.");
    // }
    if (statuses[Permission.bluetoothScan]?.isDenied ?? true) {
      throw Exception("❌ Bluetooth Scan permission denied.");
    }
    if (statuses[Permission.bluetoothConnect]?.isDenied ?? true) {
      throw Exception("❌ Bluetooth Connect permission denied.");
    }
    if (statuses[Permission.location]?.isDenied ?? true) {
      throw Exception(
          "❌ Location permission denied. BLE requires location access.");
    }
    // if (statuses[Permission.locationAlways]?.isDenied ?? true) {
    //   throw Exception(
    //       "❌ Background location permission denied. App cannot send GPS data in background.");
    // }

    // if (statuses[Permission.ignoreBatteryOptimizations]?.isDenied ?? true) {
    //   final intent = AndroidIntent(
    //     action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    //     data: 'package:com.example.aqua_safe',
    //     flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    //   );
    //   await intent.launch();
    //   throw Exception("❌ Ignore Battery Optimizations denied.");
    // }
  }

  Future<bool> scanAndConnect() async {
    await requestPermissions();

    late StreamSubscription<DiscoveredDevice> scanSubscription;
    try {
      print(">>>>>> Starting BLE scan...");
      bool deviceFound = false;

      scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(Constants.serviceUuid)]).listen(
        (device) async {
          if (device.name == "ESP32-MultiService") {
            print("✅ Target ESP32 device found. Connecting...");
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

      await Future.delayed(const Duration(seconds: 5));

      if (!deviceFound) {
        print("⚠️ Target ESP32 device not found during scan.");
        return false;
      }
      return true;
    } catch (e) {
      print("--- Error during scan and connect: $e");
      return false;
    } finally {
      await scanSubscription.cancel();
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      print(">>> Connecting to device: ${device.name}...");

      connectionSubscription =
          _ble.connectToDevice(id: device.id).listen((event) async {
        if (event.connectionState == DeviceConnectionState.connected) {
          _isConnected = true;
          print("=== Device connected.");
          initializeCharacteristics(device);

          await SchedulerService().startScheduler();

          // ✅ Request higher MTU (maximum 512 bytes, but actual depends on ESP32)
          int requestedMTU = 250;
          int mtu =
              await _ble.requestMtu(deviceId: device.id, mtu: requestedMTU);
          print("🔄 Requested MTU: $mtu");
        } else if (event.connectionState ==
            DeviceConnectionState.disconnected) {
          _isConnected = false;
          print("=== Device disconnected. Retrying...");
          SchedulerService().stopScheduler();
        }
      });
    } catch (e) {
      print(">>> Error connecting to device: $e");
      rethrow;
    }
  }

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
        await _ble.writeCharacteristicWithResponse(
          gpsCharacteristic,
          value: utf8.encode(gpsData),
        );
        print("GPS data sent to ESP32: $gpsData");
      } else {
        throw Exception(
            "Device not connected or GPS characteristic not initialized.");
      }
    } catch (e) {
      print("Error sending GPS data: ${e.toString().split(':').last.trim()}");
      print("Write failed: $e");
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

        final Map<String, dynamic> sosDataMap = jsonDecode(sosData);

        // Create the SOS object with additional fields
        Map<String, dynamic> formattedSOSData = {
          'id': sosDataMap['id'],
          'latitude': sosDataMap['l'].split('|')[0],
          'longitude': sosDataMap['l'].split('|')[1],
          'status': 'Active',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Save to State Manager
        AppStateManager().setLatestSOS(formattedSOSData);

        // Save to SharedPreferences (for persistence)
        // await AppStateManager().saveSOSToLocal();
        print("✅ Latest SOS saved in State Manager and SharedPreferences.");
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

  Future<void> sendWeatherRequest(String weatherRequest) async {
    final weatherCharacteristic =
        BluetoothDeviceManager().weatherCharacteristic;

    if (!_isConnected) {
      print("❌ Bluetooth is not connected. Cannot send request.");
      return;
    }

    try {
      if (weatherCharacteristic != null) {
        await _ble.writeCharacteristicWithoutResponse(
          weatherCharacteristic,
          value: utf8.encode(weatherRequest),
        );
        print("📡✅ Weather request sent via Bluetooth: $weatherRequest");
      } else {
        throw Exception("Weather characteristic not initialized.");
      }
    } catch (e) {
      print("❌ Error sending weather request: $e");
    }
  }

  Future<int?> listenForWeatherUpdates(String expectedId) async {
    final weatherCharacteristic =
        BluetoothDeviceManager().weatherCharacteristic;

    if (weatherCharacteristic == null) {
      print("❌ Weather characteristic is not initialized.");
      return null;
    }

    try {
      final responseData = await _ble.readCharacteristic(weatherCharacteristic);

      if (responseData.isEmpty) {
        print("❌ Received empty weather data.");
        return null;
      }

      String response = utf8.decode(responseData);
      print("🌤️ Raw Weather Response: $response");

      Map<String, dynamic> weatherResponse = jsonDecode(response);

      if (!weatherResponse.containsKey("id") ||
          !weatherResponse.containsKey("w")) {
        print("❌ Invalid weather response format.");
        return null;
      }

      String receivedId = weatherResponse["id"];

      if (receivedId != expectedId) {
        print("⚠️ Mismatched weather response. Ignoring.");
        return null;
      }

      print("✅ Matched Response: Weather Data = ${weatherResponse["w"]}%");
      return weatherResponse["w"];
    } catch (e) {
      print("❌ Error receiving weather data: $e");
      return null;
    }
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

  void dispose() {
    connectionSubscription?.cancel();
  }
}
