import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class WeatherMapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, dynamic>> hotspots;
  final ui.Image? markerImage;
  final ui.Image? userMarkerImage;

  WeatherMapPainter({
    required this.userLocation,
    required this.hotspots,
    this.markerImage,
    this.userMarkerImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = Colors.blue.shade300;
    
    // ✅ Draw a more realistic ocean texture background
    final Paint oceanPaint = Paint();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    if (userLocation == null) return;

    double scaleX(double lng) => ((lng + 180) / 360) * size.width;
    double scaleY(double lat) => ((90 - lat) / 180) * size.height;

    final double userX = scaleX(userLocation!['lng']!);
    final double userY = scaleY(userLocation!['lat']!);

    // ✅ Draw User Marker (a boat icon instead of just a circle)
    if (userMarkerImage != null) {
      canvas.drawImageRect(
        userMarkerImage!,
        Rect.fromLTWH(0, 0, userMarkerImage!.width.toDouble(), userMarkerImage!.height.toDouble()),
        Rect.fromLTWH(userX - 15, userY - 15, 30, 30),
        Paint(),
      );
    } else {
      final Paint userPaint = Paint()..color = Colors.green;
      canvas.drawCircle(Offset(userX, userY), 12, userPaint);
    }

    // ✅ Draw Hotspots with icons and labels
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final hotspot in hotspots) {
      final double hotspotX = scaleX(hotspot['longitude']);
      final double hotspotY = scaleY(hotspot['latitude']);

      // ✅ Ensure the hotspot is within the screen bounds
      if (hotspotX < 0 || hotspotX > size.width || hotspotY < 0 || hotspotY > size.height) continue;

      // ✅ Draw hotspot marker
      if (markerImage != null) {
        canvas.drawImageRect(
          markerImage!,
          Rect.fromLTWH(0, 0, markerImage!.width.toDouble(), markerImage!.height.toDouble()),
          Rect.fromLTWH(hotspotX - 12, hotspotY - 12, 24, 24),
          Paint(),
        );
      } else {
        final Paint hotspotPaint = Paint()..color = Colors.red;
        canvas.drawCircle(Offset(hotspotX, hotspotY), 10, hotspotPaint);
      }

      // ✅ Draw hotspot label (e.g., "Hotspot 1")
      textPainter.text = TextSpan(
        text: "HS ${hotspot['hotspotId']}",
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(hotspotX - 10, hotspotY - 25));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
