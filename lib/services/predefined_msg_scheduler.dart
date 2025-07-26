import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatMessageScheduler {
  static final ChatMessageScheduler _instance =
      ChatMessageScheduler._internal();
  factory ChatMessageScheduler() => _instance;
  ChatMessageScheduler._internal();

  Timer? _fetchScheduler;

  void startScheduler() {
    // Run immediately
    print("✅ Predefined chat message scheduler started succesfully.");
    _runFetch();

    // Then schedule every 10 minutes
    _fetchScheduler =
        Timer.periodic(const Duration(minutes: 10), (timer) async {
      print("✅ Predefined chat message scheduler started succesfully.");
      _runFetch();
    });
  }

  void _runFetch() async {
    if (await _hasInternetConnection()) {
      await _fetchAndCacheChatMessages();
    } else {
      print("❌ No internet connection. Skipping chat message fetch.");
    }
  }

  void stopScheduler() {
    _fetchScheduler?.cancel();
  }

  Future<bool> _hasInternetConnection() async {
    print("Checking for internet connection to fetch predefined msgs.");
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

  Future<void> _fetchAndCacheChatMessages() async {
    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];
    if (baseUrl == null) {
      print("❌ API base URL not configured in .env file.");
      return;
    }
    final String apiUrl = "$baseUrl/messageData";
    print("🌍 Fetching predefined chat messages from API: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData["success"] == true &&
            responseData.containsKey("data")) {
          List<Map<String, dynamic>> messages =
              List<Map<String, dynamic>>.from(responseData["data"]);
          print(
              "📥 Received predefined chat messages: ${messages.length} items");

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cachedChatMessages', jsonEncode(messages));

          print("✅ Chat messages cached successfully.");
        } else {
          print("⚠️ Unexpected API response format.");
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception in chat message fetch: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getCachedChatMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('cachedChatMessages');

    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
    }
    return [];
  }
}
