import 'dart:convert';
import 'package:aqua_safe/services/generate_unique_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_service.dart';

class WeatherService {
  final BluetoothService _bluetoothService = BluetoothService();

  String getWeatherCondition(int percentage) {
    if (percentage >= 70) {
      return "High chance of rain";
    } else if (percentage >= 40) {
      return "Moderate chance of rain";
    } else {
      return "Low chance of rain";
    }
  }

  Future<int?> fetchWeather(double latitude, double longitude,
      {bool isCurrentLocation = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        throw Exception("❌ Vessel ID not found in SharedPreferences");
      }

      String? _lastRequestId;

      GenerateUniqueIdService idService = GenerateUniqueIdService();
      String uniqueMsgId = idService.generateId();

      _lastRequestId = "$vesselId";

      String weatherData = jsonEncode({
        "id": "$vesselId|$uniqueMsgId",
        "l": "$latitude|$longitude",
        "wr": 1
      });

      if (isCurrentLocation) {
        print(
            "📡 Sending Weather Request for **current location**: $weatherData");
      } else {
        print("📡 Sending Weather Request for **hotspot**: $weatherData");
      }

      await _bluetoothService.sendWeatherRequest(weatherData);

      await Future.delayed(Duration(seconds: 10));

      if (isCurrentLocation) {
        print("📡 Listening weather for **current location**: $weatherData");
      } else {
        print("📡 Listening weather for **hotspot**: $weatherData");
      }

      int? weatherResponse =
          await _bluetoothService.listenForWeatherUpdates(_lastRequestId);

      if (weatherResponse == null) {
        print("⚠️ Weather Response was null.");
      }

      if (isCurrentLocation) {
        print(
            "✅ Successfully fetched weather for **current location** : $weatherData");
      } else {
        print("✅ Successfully fetched weather for **hotspot**: $weatherData");
      }

      return weatherResponse;
    } catch (e) {
      print("❌ Error fetching weather for hotspot: $e");
      return null;
    }
  }
}
