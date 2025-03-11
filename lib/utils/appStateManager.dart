import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();

  factory AppStateManager() => _instance;

  AppStateManager._internal();

  String? _id;
  String? _latitude;
  String? _longitude;
  String? _status;
  String? _timestamp;
  String? _sosTimeAgo;
  String? _sosDateTime;
  String? _vesselName;

  String? get id => _id;
  String? get latitude => _latitude;
  String? get longitude => _longitude;
  String? get status => _status;
  String? get timestamp => _timestamp;
  String? get sosTimeAgo => _sosTimeAgo;
  String? get sosDateTime => _sosDateTime;
  String? get vesselName => _vesselName;

  bool get isSOSInProgress => _status == "Active";

  void setLatestSOS(Map<String, dynamic> sosData) async {
    _id = sosData['id'];
    _latitude = sosData['latitude'];
    _longitude = sosData['longitude'];
    _status = sosData['status'];
    _timestamp = sosData['timestamp'];

    if (_timestamp != null) {
      DateTime sosTime = DateTime.parse(_timestamp!);
      _sosTimeAgo = timeago.format(sosTime, locale: 'en_short');
      _sosDateTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(sosTime);
    }

    if (_id != null) {
      await fetchVesselName(_id!);
    }
  }

  // Save SOS to SharedPreferences
  Future<void> saveSOSToLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_id != null) {
      await prefs.setString(
        'lastSOS',
        jsonEncode({
          'id': _id,
          'latitude': _latitude,
          'longitude': _longitude,
          'status': _status,
          'timestamp': _timestamp,
        }),
      );
    }
  }

  // Load SOS from SharedPreferences
  Future<void> loadSOSFromLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSOS = prefs.getString('lastSOS');

    if (lastSOS != null) {
      Map<String, dynamic> sosData = jsonDecode(lastSOS);
      setLatestSOS(sosData);
    }
  }

  Future<void> fetchVesselName(String vesselId) async {
    final String? baseUrl = dotenv.env['MAIN_API_BASE_URL'];

    if (baseUrl == null) {
      return;
    }

    final String apiUrl = "$baseUrl/api/vessel-auth/$vesselId";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _vesselName = data['vesselName'];
      } else {
        _vesselName = "Unknown Vessel";
      }
    } catch (e) {
      _vesselName = "Unknown Vessel";
    }
  }
}
