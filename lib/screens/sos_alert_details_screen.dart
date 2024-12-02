import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;

class SOSAlertDetailsScreen extends StatefulWidget {
  @override
  _SOSAlertDetailsScreenState createState() => _SOSAlertDetailsScreenState();
}

class _SOSAlertDetailsScreenState extends State<SOSAlertDetailsScreen> {
  GoogleMapController? mapController;
  LatLng _initialPosition = LatLng(0.0, 0.0); // Default position (0,0)

  @override
  void initState() {
    super.initState();
    _loadSOSLocation();
  }

  // Load SOS location from SharedPreferences
  Future<void> _loadSOSLocation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSOS = prefs.getString('lastSOS');

    if (lastSOS != null) {
      final sosData = jsonDecode(lastSOS);
      final double latitude = double.parse(sosData['latitude']);
      final double longitude = double.parse(sosData['longitude']);
      final String timestamp = sosData['timestamp'];
      final DateTime sosTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();

      final String timeAgo = timeago.format(sosTime, locale: 'en_short');

      setState(() {
        _initialPosition = LatLng(latitude, longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert Details'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('sos_location'),
            position: _initialPosition,
            infoWindow: InfoWindow(title: 'SOS Location'),
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}
