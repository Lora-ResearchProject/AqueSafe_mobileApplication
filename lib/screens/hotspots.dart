import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class HotspotsScreen extends StatefulWidget {
  const HotspotsScreen({Key? key}) : super(key: key);

  @override
  _HotspotsScreenState createState() => _HotspotsScreenState();
}

class _HotspotsScreenState extends State<HotspotsScreen> {
  final List<Map<String, double>> destinations = [
    {'lat': -18.2871, 'lng': 147.6992},
    {'lat': 34.0522, 'lng': -118.2437},
    {'lat': 51.5074, 'lng': -0.1278},
  ];

  Map<String, double>? userLocation;
  ui.Image? markerImage;
  double arrowRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
    _getCurrentLocation();
    _initializeSensors();
  }

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

  Future<void> _getCurrentLocation() async {
    // Simulate user location for demonstration
    setState(() {
      userLocation = {'lat': 0.0, 'lng': 0.0};
    });
  }

  void _initializeSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate the rotation based on accelerometer data
      setState(() {
        arrowRotation = math.atan2(event.y, event.x);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fishing Spots',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : CustomPaint(
              size: MediaQuery.of(context).size,
              painter: MapPainter(
                userLocation: userLocation,
                destinations: destinations,
                markerImage: markerImage,
                arrowRotation: arrowRotation,
              ),
            ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, double>> destinations;
  final ui.Image? markerImage;
  final double arrowRotation;

  MapPainter({
    required this.userLocation,
    required this.destinations,
    this.markerImage,
    required this.arrowRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    // Draw the world map (a simple rectangle for demonstration purposes)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    if (userLocation == null || markerImage == null) return;

    // Convert lat/lng to canvas coordinates (basic scaling)
    double scaleX(double lng) => ((lng + 180) / 360) * size.width;
    double scaleY(double lat) => ((-lat + 90) / 180) * size.height;

    final double userX = scaleX(userLocation!['lng']!);
    final double userY = scaleY(userLocation!['lat']!);

    // Draw the rotating arrow at the user's location
    canvas.save();
    canvas.translate(userX, userY);
    canvas.rotate(arrowRotation);
    final arrowPath = Path()
      ..moveTo(0, -20) // Arrow tip
      ..lineTo(-10, 10) // Left bottom
      ..lineTo(10, 10) // Right bottom
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = Colors.green);
    canvas.restore();

    // Draw lines to each destination and display distances
    for (final destination in destinations) {
      final double destX = scaleX(destination['lng']!);
      final double destY = scaleY(destination['lat']!);

      // Draw line from user to destination
      canvas.drawLine(Offset(userX, userY), Offset(destX, destY), linePaint);

      // Draw destination marker
      const double markerWidth = 20;
      const double markerHeight = 30;

      canvas.drawImageRect(
        markerImage!,
        Rect.fromLTWH(0, 0, markerImage!.width.toDouble(),
            markerImage!.height.toDouble()),
        Rect.fromLTWH(destX - markerWidth / 2, destY - markerHeight,
            markerWidth, markerHeight),
        Paint(),
      );

      // Calculate distance
      double distance = calculateDistance(
        userLocation!['lat']!,
        userLocation!['lng']!,
        destination['lat']!,
        destination['lng']!,
      );

      // Display distance on the line
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${distance.toStringAsFixed(2)} km',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Position the text near the midpoint of the line
      final midpoint = Offset(
        (userX + destX) / 2,
        (userY + destY) / 2,
      );

      textPainter.paint(canvas, midpoint);
    }
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
