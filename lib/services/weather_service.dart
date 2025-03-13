import 'dart:convert';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:aqua_safe/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_service.dart';

class WeatherService {
  final BluetoothService _bluetoothService = BluetoothService();
  final LocationService _locationService = LocationService();
  bool _isFetching = false;

  Future<int?> getWeather() async {
    if (_isFetching) {
      print("⚠️ Weather request ignored (already fetching)");
      return null;
    }
    _isFetching = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      var position = await _locationService.getCurrentPosition();
      String latitude = position.latitude.toStringAsFixed(5);
      String longitude = position.longitude.toStringAsFixed(5);
      String? _lastRequestId;

      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      _lastRequestId = "$vesselId|$uniqueMsgId";

      String weatherData = jsonEncode(
          {"id": "$vesselId|$uniqueMsgId", "l": "$latitude|$longitude", "wr": 1});

      print("📡 Sending Weather Request: $weatherData");
      await _bluetoothService.sendWeatherRequest(weatherData);

      int? weatherResponse =
          await _bluetoothService.listenForWeatherUpdates(_lastRequestId);

      return weatherResponse;
    } catch (e) {
      print("❌ Error fetching weather: $e");
      return null;
    } finally {
      _isFetching = false;
    }
  }

  String getWeatherCondition(int percentage) {
    if (percentage >= 70) {
      return "High chance of rain";
    } else if (percentage >= 40) {
      return "Moderate chance of rain";
    } else {
      return "Low chance of rain";
    }
  }
}
