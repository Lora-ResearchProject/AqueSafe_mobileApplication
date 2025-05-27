import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothDeviceManager {
  // Step 1: Private static instance of the singleton class
  static final BluetoothDeviceManager _instance =
      BluetoothDeviceManager._internal();

  DiscoveredDevice? _discoveredDevice;

  QualifiedCharacteristic? _sosCharacteristic;
  QualifiedCharacteristic? _gpsCharacteristic;
  QualifiedCharacteristic? _chatCharacteristic;
  QualifiedCharacteristic? _weatherCharacteristic;
  QualifiedCharacteristic? _hotspotChracteristic;
  QualifiedCharacteristic? _linkingCharacteristic;
  QualifiedCharacteristic? _saveLocationCharacteristic;
  QualifiedCharacteristic? _unlinkingCharacteristic;

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

  QualifiedCharacteristic? get hotspotChracteristic => _hotspotChracteristic;

  QualifiedCharacteristic? get linkingCharacteristic => _linkingCharacteristic;

  QualifiedCharacteristic? get unlinkingCharacteristic =>
      _unlinkingCharacteristic;

  QualifiedCharacteristic? get saveLocationCharacteristic =>
      _saveLocationCharacteristic;

  void setDevice(DiscoveredDevice device) {
    _discoveredDevice = device;
  }

  void setCharacteristics(
      QualifiedCharacteristic sos,
      QualifiedCharacteristic gps,
      QualifiedCharacteristic chat,
      QualifiedCharacteristic weather,
      QualifiedCharacteristic hotspot,
      QualifiedCharacteristic linking,
      QualifiedCharacteristic saveLocation,
      QualifiedCharacteristic unLinking) {
    _sosCharacteristic = sos;
    _gpsCharacteristic = gps;
    _chatCharacteristic = chat;
    _weatherCharacteristic = weather;
    _hotspotChracteristic = hotspot;
    _linkingCharacteristic = linking;
    _saveLocationCharacteristic = saveLocation;
    _unlinkingCharacteristic = unLinking;
  }

  // Optional: Clear the device if needed
  void clearDevice() {
    _discoveredDevice = null;
    _sosCharacteristic = null;
    _gpsCharacteristic = null;
    _chatCharacteristic = null;
    _weatherCharacteristic = null;
    _hotspotChracteristic = null;
    _linkingCharacteristic = null;
    _saveLocationCharacteristic = null;
    _unlinkingCharacteristic = null;
  }
}
