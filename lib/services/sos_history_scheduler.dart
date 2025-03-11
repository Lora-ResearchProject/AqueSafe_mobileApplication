import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SOSHistoryScheduler {
  static final SOSHistoryScheduler _instance = SOSHistoryScheduler._internal();
  factory SOSHistoryScheduler() => _instance;
  SOSHistoryScheduler._internal();

  Timer? _scheduler;

  void startScheduler() {
    _scheduler = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (await _hasInternetConnection()) {
        _fetchAndCacheSOSHistory();
      } else {
        print("❌ No internet connection. Skipping SOS fetch.");
      }
    });
  }

  void stopScheduler() {
    _scheduler?.cancel();
  }

  // Check if there is an actual internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));

      if (result.statusCode == 200) {
        print("✅ Internet is available.");
        return true;
      } else {
        print("⚠️ Internet test failed with status: ${result.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ No internet access: $e");
      return false;
    }
  }

  Future<void> _fetchAndCacheSOSHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');
      if (vesselId == null || vesselId.isEmpty) {
        print("❌ Vessel ID not found.");
        return;
      }

      final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
      if (baseUrl == null) {
        print("❌ API Base URL not set.");
        return;
      }

      final String apiUrl = "$baseUrl/sos/get_by_vessel_id/mobile/$vesselId";
      print("🌍 Fetching SOS history from API: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> alerts = responseData['alerts'];
          print("📥 Received SOS Alerts");

          await prefs.setString('cachedSOSHistory', jsonEncode(alerts));
          print("✅ SOS history cached successfully.");
        } else {
          print("⚠️ Failed to fetch SOS alerts: ${responseData['message']}");
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception in SOS fetch: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getCachedSOSHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('cachedSOSHistory');

    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
    }
    return [];
  }
}
