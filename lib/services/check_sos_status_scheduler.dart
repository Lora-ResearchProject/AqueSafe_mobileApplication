import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CheckSOSStatusScheduler {
  Future<void> startScheduler(String vesselId, BuildContext context) async {
    Timer.periodic(Duration(minutes: 5), (timer) async {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        await _fetchSOSAlerts(vesselId, context );
      }
    });
  }

  // Fetch SOS alerts from the API
  Future<void> _fetchSOSAlerts(String vesselId, BuildContext context) async {
    // Access the base URL from the .env file
    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];

    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API base URL not configured.')),
      );
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/api/sos/get_by_vessel_id/$vesselId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> sosData = jsonDecode(response.body);

        // Store SOS alerts in SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('sosAlerts', jsonEncode(sosData));

        print(
            "Internet connection detected and SOS alerts fetched from server and saved in prefernces successfully");
      } else {
        print("Failed to fetch SOS alerts: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching SOS alerts: $e");
    }
  }
}
