import 'dart:async';
import 'dart:convert';
import 'package:aqua_safe/services/gps_scheduler_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../utils/bluetooth_device_manager.dart';
import '../utils/appStateManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late QualifiedCharacteristic hotspotChracteristic;
  late QualifiedCharacteristic linkingCharacteristic;
  late QualifiedCharacteristic saveLocationCharacteristic;

  StreamSubscription<ConnectionStateUpdate>? connectionSubscription;
  StreamSubscription<List<int>>? chatSubscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  DiscoveredDevice? discoveredDevice;

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

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
          isConnectedNotifier.value = true; // ✅ Update notifier
          print("=== Device connected.");
          initializeCharacteristics(device);

          final services = await _ble.discoverServices(device.id);
          for (final service in services) {
            print('🔧 Service: ${service.serviceId}');
            for (final characteristic in service.characteristics) {
              print('   📍 Characteristic: ${characteristic.characteristicId}');
            }
          }

          await SchedulerService().startScheduler();

          int requestedMTU = 250;
          int mtu =
              await _ble.requestMtu(deviceId: device.id, mtu: requestedMTU);
          print("🔄 Requested MTU: $mtu");
        } else if (event.connectionState ==
            DeviceConnectionState.disconnected) {
          _isConnected = false;
          isConnectedNotifier.value = false; // ✅ Update notifier
          print("=== Device disconnected. Retrying...");
          SchedulerService().stopScheduler();
        }
      });
    } catch (e) {
      print(">>> Error connecting to device: $e");
      isConnectedNotifier.value = false; // ✅ Mark as disconnected on error
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

      hotspotChracteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.hotspotChracteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      linkingCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.linkingCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      saveLocationCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(Constants.saveLocationCharacteristicUuid),
        serviceId: Uuid.parse(Constants.serviceUuid),
        deviceId: device.id,
      );

      BluetoothDeviceManager().setCharacteristics(
          sosCharacteristic,
          gpsCharacteristic,
          chatCharacteristic,
          weatherCharacteristic,
          hotspotChracteristic,
          linkingCharacteristic,
          saveLocationCharacteristic);

      print(
          "✅ Save Fishing Location Characteristic initialized: ${saveLocationCharacteristic.characteristicId}");

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
    final chatCharacteristic = BluetoothDeviceManager().chatCharacteristic;

    if (chatCharacteristic == null) {
      print("❌ Chat characteristic is not initialized.");
      return;
    }

    if (message.isEmpty) {
      print("❌ Error: Chat message is empty.");
      return;
    }

    try {
      print("📲 Sending Chat Message via BLE");

      await _ble.writeCharacteristicWithoutResponse(
        chatCharacteristic,
        value: utf8.encode(message),
      );

      print("✅ Chat message sent via BLE successfully.");
    } catch (e) {
      print("❌ Error sending chat message via BLE: $e");
    }
  }

  void listenForChatMessages(Function(Map<String, dynamic>) onMessageReceived) {
    // Always cancel the previous subscription if it exists
    if (chatSubscription != null) {
      print("🔕 Cancelling existing subscription.");
      chatSubscription?.cancel();
    }

    // ✅ FIX: Save the new subscription
    chatSubscription =
        _ble.subscribeToCharacteristic(chatCharacteristic).listen(
      (data) {
        if (data.isNotEmpty) {
          String receivedData = utf8.decode(data);
          print("📲 Chat Message Received via BLE: $receivedData");

          try {
            Map<String, dynamic> receivedJson = jsonDecode(receivedData);

            if (receivedJson.containsKey("id") &&
                receivedJson.containsKey("m")) {
              onMessageReceived(receivedJson);
            } else {
              print("❌ Invalid chat message format: $receivedData");
            }
          } catch (e) {
            print("❌ Error decoding received chat message: $e");
          }
        }
      },
      onError: (e) {
        print("❌ Error receiving chat messages via BLE: $e");
      },
    );
  }

  Future<void> sendWeatherRequest(String weatherRequest) async {
    final weatherCharacteristic =
        BluetoothDeviceManager().weatherCharacteristic;

    try {
      if (weatherCharacteristic != null) {
        await _ble.writeCharacteristicWithResponse(
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
      String simpleId = receivedId.split('|')[0];

      if (simpleId != expectedId) {
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

  Future<List<Map<String, dynamic>>> listenForHotspotUpdates() async {
    final hotspotCharacteristic = BluetoothDeviceManager().hotspotChracteristic;

    if (hotspotCharacteristic == null) {
      print("❌ Hotspot characteristic is not initialized.");
      return [];
    }

    try {
      final responseData = await _ble.readCharacteristic(hotspotCharacteristic);

      if (responseData.isEmpty) {
        print("❌ Received empty hotspot data.");
        return [];
      }

      String response = utf8.decode(responseData);
      print("📍 Raw Hotspot Response: $response");

      // 🔹 Try parsing response safely
      final parsedResponse = jsonDecode(response);

      if (parsedResponse is List) {
        print("✅ Hotspot Data Received Successfully.");
        return parsedResponse.cast<Map<String, dynamic>>(); // Safe casting
      }

      print("❌ Invalid hotspot response format (expected a List).");
      return [];
    } catch (e) {
      print("❌ Error receiving hotspot data: $e");
      return [];
    }
  }

  Future<void> sendHotspotRequest(String hotspotRequest) async {
    final hotspotCharacteristic = BluetoothDeviceManager().hotspotChracteristic;

    try {
      if (hotspotCharacteristic != null) {
        await _ble.writeCharacteristicWithResponse(
          hotspotCharacteristic,
          value: utf8.encode(hotspotRequest),
        );
        print("📡✅ Hotspot request sent via Bluetooth: $hotspotRequest");
      } else {
        throw Exception("Hotspot characteristic not initialized.");
      }
    } catch (e) {
      print("❌ Error sending hotspot request: $e");
    }
  }

  Future<void> sendLinkingData(String hotspotId) async {
    final linkingCharacteristic =
        BluetoothDeviceManager().linkingCharacteristic;

    print(1);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      print(2);

      if (vesselId == null) {
        throw Exception("Vessel ID not found in SharedPreferences.");
      }

      print(3);
      // ✅ Create JSON object
      final Map<String, dynamic> linkingDataMap = {
        "vessel_id": vesselId,
        "hotspot_id": int.parse(hotspotId),
      };
      print(4);
      final String linkingDataJson = jsonEncode(linkingDataMap);

      if (linkingCharacteristic != null) {
        print(5);
        await _ble.writeCharacteristicWithResponse(
          linkingCharacteristic,
          value: utf8.encode(linkingDataJson),
        );
        print("📡✅ Linking data sent via Bluetooth: $linkingDataJson");
      } else {
        throw Exception("Linking characteristic not initialized.");
      }
    } catch (e) {
      print("❌ Error sending linking data: $e");
    }
  }

  Future<void> saveFishingLocation(String saveFishingRequest) async {
    final saveLocationCharacteristic =
        BluetoothDeviceManager().saveLocationCharacteristic;

    try {
      if (saveLocationCharacteristic != null) {
        print(
            "saveLocationCharacteristic not null: ${saveLocationCharacteristic.characteristicId}");
        await _ble.writeCharacteristicWithResponse(
          saveLocationCharacteristic,
          value: utf8.encode(saveFishingRequest),
        );
        print(
            "🐬✅ Save Fishing Location request sent via Bluetooth: $saveFishingRequest");
      } else {
        throw Exception("saveLocation characteristic not initialized.");
      }
    } catch (e) {
      print("❌ Error sending save fishing location request: $e");
    }
  }

  void dispose() {
    connectionSubscription?.cancel();
  }
}
