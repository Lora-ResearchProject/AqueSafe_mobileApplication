import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class HotspotsScreen extends StatefulWidget {
  const HotspotsScreen({Key? key}) : super(key: key);

  @override
  _HotspotsScreenState createState() => _HotspotsScreenState();
}

class _HotspotsScreenState extends State<HotspotsScreen> {
  // Example array of lat/lng points (dummy data)
  final List<Map<String, double>> destinations = [
    {'lat': -18.2871, 'lng': 147.6992},
    {'lat': 34.0522, 'lng': -118.2437},
    {'lat': 51.5074, 'lng': -0.1278},
  ];

  Map<String, double>? userLocation; // User's current location
  ui.Image? markerImage;

  @override
  void initState() {
    super.initState();
    // Simulate fetching GPS location (replace with real GPS fetching logic)
    userLocation = {
      'lat': 0.0,
      'lng': 0.0
    }; // Replace with actual GPS fetching logic
    _loadMarkerImage();
  }

  Future<void> _loadMarkerImage() async {
    // Load the marker image
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
      appBar: AppBar(
        title: const Text('Fishing Spots'),
        backgroundColor: const Color(0xFF151d67),
      ),
      body: Center(
        child: CustomPaint(
          size: const Size(400, 400), // Define map size
          painter: MapPainter(
            userLocation: userLocation,
            destinations: destinations,
            markerImage: markerImage,
          ),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, double>> destinations;
  final ui.Image? markerImage;

  MapPainter({
    required this.userLocation,
    required this.destinations,
    this.markerImage,
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

    // Draw user location
    canvas.drawCircle(Offset(userX, userY), 5, Paint()..color = Colors.green);

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

  /// Calculate the distance between two geographical points using the Haversine formula
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
    return true; // Repaint whenever user location or destinations change
  }
}
