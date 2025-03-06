import 'package:flutter/material.dart';
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
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
    _startLocationUpdateTimer();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
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

  // Update location periodically
  void _startLocationUpdateTimer() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {}); // Refresh UI with latest SOS data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        title: const Text('SOS Alert', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C3D72),
        iconTheme: const IconThemeData(color: Colors.white),
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
              const SizedBox(height: 20),
              _buildMarkResolvedButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Builds SOS Details UI
  Widget _buildSOSDetails() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3D72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Sender:", AppStateManager().vesselName ?? "Unknown"),
          _buildDetailRow("Location:",
              "${AppStateManager().latitude}, ${AppStateManager().longitude}"),
          _buildDetailRow(
              "Time Sent:", AppStateManager().sosDateTime ?? "Unknown"),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Row(
      children: [
        const Text("Status:",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor:
              AppStateManager().isSOSInProgress ? Colors.green : Colors.red,
          radius: 6,
        ),
        const SizedBox(width: 6),
        Text(
          AppStateManager().isSOSInProgress ? "Active" : "Resolved",
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  /// Builds Map UI
  Widget _buildSOSMap() {
    return Expanded(
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 300),
        painter: SOSMapPainter(
          latitude: double.tryParse(AppStateManager().latitude ?? "0") ?? 0.0,
          longitude: double.tryParse(AppStateManager().longitude ?? "0") ?? 0.0,
          markerImage: markerImage,
        ),
      ),
    );
  }

  /// Builds "Mark as Resolved" Button
  Widget _buildMarkResolvedButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            AppStateManager().setLatestSOS({
              'id': AppStateManager().id,
              'latitude': AppStateManager().latitude,
              'longitude': AppStateManager().longitude,
              'status': 'Resolved',
              'timestamp': AppStateManager().timestamp,
            });
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          "Mark as Resolved",
          style: TextStyle(
              color: Color(0xFF151d67),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// **Custom Map Painter for SOS Location**
class SOSMapPainter extends CustomPainter {
  final double latitude;
  final double longitude;
  final ui.Image? markerImage;

  SOSMapPainter(
      {required this.latitude, required this.longitude, this.markerImage});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint mapPaint = Paint()..color = Colors.blue.shade300;
    final Paint sosPaint = Paint()..color = Colors.red.withOpacity(0.6);
    final Paint markerPaint = Paint()..color = Colors.red;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mapPaint);

    double centerX = size.width / 2;
    double centerY = size.height / 2;

    canvas.drawCircle(Offset(centerX, centerY), 20, sosPaint);
    canvas.drawCircle(Offset(centerX, centerY), 10, markerPaint);

    if (markerImage != null) {
      canvas.drawImage(
          markerImage!, Offset(centerX - 10, centerY - 20), Paint());
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
