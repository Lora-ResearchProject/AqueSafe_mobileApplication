import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SOSHistoryScheduler {
  static final SOSHistoryScheduler _instance = SOSHistoryScheduler._internal();
  factory SOSHistoryScheduler() => _instance;
  SOSHistoryScheduler._internal();

  Timer? _fetchScheduler;
  Timer? _checkScheduler;
  Function? _onSOSUpdate; // Callback to update UI

  void startScheduler({Function? onSOSUpdate}) {
    _onSOSUpdate = onSOSUpdate;

    _fetchScheduler =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (await _hasInternetConnection()) {
        _fetchAndCacheSOSHistory();
      } else {
        print("❌ No internet connection. Skipping SOS fetch.");
      }
    });

    _checkScheduler = Timer.periodic(const Duration(hours: 3), (timer) async {
      _checkLatestSOSStatus();
    });
  }

  void stopScheduler() {
    _fetchScheduler?.cancel();
    _checkScheduler?.cancel();
  }

  // Check if there is an actual internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 30));

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

  // Public method to allow external classes to fetch and cache SOS history
Future<void> fetchAndCacheSOSHistoryPublic() async {
  await _fetchAndCacheSOSHistory();
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

          final String lastUpdatedTimestamp = DateTime.now().toString();
          await prefs.setString('lastSOSUpdateTime', lastUpdatedTimestamp);

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

  // Check if latest SOS is still active
  Future<void> _checkLatestSOSStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSOSData = prefs.getString('lastSOS');
    final String? cachedHistory = prefs.getString('cachedSOSHistory');

    if (lastSOSData == null) return;

    Map<String, dynamic> lastSOS = jsonDecode(lastSOSData);
    String lastSOSId = lastSOS['id'].split('|')[1];

    if (cachedHistory == null || cachedHistory.isEmpty) {
      print("❌ No cached SOS history available. Clearing last SOS.");
      return; // Don't clear if no cache — we may just be offline
    }

    List<dynamic> alerts = jsonDecode(cachedHistory);

    if (alerts.isEmpty) {
      print("⚠️ Cached SOS history is empty. Clearing last SOS.");
      return; // Same: don't remove, just wait for next update
    }

    bool sosStillActive = alerts.any((alert) =>
        alert['sosId'] == lastSOSId && alert['sosStatus'] == "active");

    if (!sosStillActive) {
      print("❌ Latest SOS is no longer active. Removing from storage.");
      await _clearLastSOS();
    } else {
      print("✅ Latest SOS is still active.");
    }
  }

  // Clear latest SOS from storage
  Future<void> _clearLastSOS() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSOS');

    // Notify UI to update
    if (_onSOSUpdate != null) {
      _onSOSUpdate!();
    }
  }
}
