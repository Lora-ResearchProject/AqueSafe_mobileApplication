import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/appStateManager.dart';
import 'dart:async';
import 'dart:ui' as ui;

class SOSDetailView extends StatefulWidget {
  const SOSDetailView({Key? key}) : super(key: key);

  @override
  _SOSDetailViewState createState() => _SOSDetailViewState();
}

class _SOSDetailViewState extends State<SOSDetailView> {
  ui.Image? markerImage;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
  }

  // Load vessel marker image
  Future<void> _loadMarkerImage() async {
    final image = await _loadImage('assets/marker_vessel.png');
    setState(() {
      markerImage = image;
    });
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        title: const Text('Recent SOS'),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF151d67),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSOSDetails(),
              const SizedBox(height: 16),
              _buildSOSMap(),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadLatestSOSFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSOSData = prefs.getString('lastSOS');

    if (lastSOSData == null) {
      print("⚠️ No SOS data found in SharedPreferences.");
      return null;
    }

    try {
      final sosData = jsonDecode(lastSOSData);

      // Fetch vessel name if missing
      //String vesselName = sosData['vesselName'] ?? "Unknown";
      // if (vesselName == "Unknown" && sosData['id'] != null) {
      //   vesselName = AppStateManager().fetchVesselName(sosData['id']);
      // }

      return {
        "id": sosData['id'],
        "latitude": sosData['latitude'],
        "longitude": sosData['longitude'],
        "timestamp": sosData['timestamp'],
        "vesselName": sosData['vesselName']
      };
    } catch (e) {
      print("❌ Error loading SOS data: $e");
      return null;
    }
  }

  Widget _buildSOSDetails() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadLatestSOSFromPrefs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        // If no SOS data is found, display a message
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text(
              "No SOS alert available.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        // Extract SOS details from the snapshot data
        final sosData = snapshot.data!;
        final vesselName = sosData['vesselName'] ?? "Unknown Vessel";
        final latitude = sosData['latitude'] ?? "Not Available";
        final longitude = sosData['longitude'] ?? "Not Available";
        final timeSent = sosData['timestamp'] != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(DateTime.parse(sosData['timestamp']))
            : "Unknown";

        return Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1C3D72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Sender:", vesselName),
              _buildDetailRow("Location:", "${latitude}N, ${longitude}M"),
              _buildDetailRow("Time Sent:", timeSent),
              _buildStatusBadge(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Row(
      children: [
        const Text("Status:",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(width: 8),
        const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 7,
        ),
        const SizedBox(width: 6),
        const Text(
          "Active",
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ],
    );
  }

  // Builds Map UI
  Widget _buildSOSMap() {
    return Expanded(
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 400),
        painter: SOSMapPainter(
          sosLatitude:
              double.tryParse(AppStateManager().latitude ?? "0") ?? 0.0,
          sosLongitude:
              double.tryParse(AppStateManager().longitude ?? "0") ?? 0.0,
          markerImage: markerImage,
        ),
      ),
    );
  }
}

/// **Custom Map Painter for SOS Location**
class SOSMapPainter extends CustomPainter {
  final double sosLatitude;
  final double sosLongitude;
  final ui.Image? markerImage;

  SOSMapPainter({
    required this.sosLatitude,
    required this.sosLongitude,
    this.markerImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint mapPaint = Paint()..color = Colors.blue.shade300;
    final Paint sosPaint = Paint()..color = Colors.red.withOpacity(0.6);
    final Paint markerPaint = Paint()..color = Colors.red;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mapPaint);

    double centerX = size.width / 2;
    double centerY = size.height / 2;

    // Draw SOS location as a red dot
    canvas.drawCircle(Offset(centerX, centerY - 50), 12, sosPaint);
    canvas.drawCircle(Offset(centerX, centerY - 50), 6, markerPaint);

    // Draw vessel icon with reduced size
    if (markerImage != null) {
      canvas.drawImageRect(
        markerImage!,
        Rect.fromLTWH(0, 0, markerImage!.width.toDouble(),
            markerImage!.height.toDouble()),
        Rect.fromLTWH(centerX - 12, centerY + 30, 24, 32), // Smaller size
        Paint(),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
