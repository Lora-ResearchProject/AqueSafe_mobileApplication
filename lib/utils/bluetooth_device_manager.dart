import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothDeviceManager {
  // Step 1: Private static instance of the singleton class
  static final BluetoothDeviceManager _instance =
      BluetoothDeviceManager._internal();

  // The discovered device will be stored here
  DiscoveredDevice? _discoveredDevice;

  // Characteristics to be stored in the singleton
  QualifiedCharacteristic? _sosCharacteristic;
  QualifiedCharacteristic? _gpsCharacteristic;
  QualifiedCharacteristic? _chatCharacteristic;
  QualifiedCharacteristic? _weatherCharacteristic;

  // Private constructor
  BluetoothDeviceManager._internal();

  // Factory method to access the instance
  factory BluetoothDeviceManager() {
    return _instance;
  }

  DiscoveredDevice? get device => _discoveredDevice;

  QualifiedCharacteristic? get sosCharacteristic => _sosCharacteristic;

  QualifiedCharacteristic? get gpsCharacteristic => _gpsCharacteristic;

  QualifiedCharacteristic? get chatCharacteristic => _chatCharacteristic;

  QualifiedCharacteristic? get weatherCharacteristic => _weatherCharacteristic;

  void setDevice(DiscoveredDevice device) {
    _discoveredDevice = device;
  }

  // Set characteristics after connecting to the device
  void setCharacteristics(
      QualifiedCharacteristic sos,
      QualifiedCharacteristic gps,
      QualifiedCharacteristic chat,
      QualifiedCharacteristic weather) {
    _sosCharacteristic = sos;
    _gpsCharacteristic = gps;
    _chatCharacteristic = chat;
    _weatherCharacteristic = weather;
  }

  // Optional: Clear the device if needed
  void clearDevice() {
    _discoveredDevice = null;
    _sosCharacteristic = null;
    _gpsCharacteristic = null;
    _chatCharacteristic = null;
    _weatherCharacteristic = null;
  }
}
