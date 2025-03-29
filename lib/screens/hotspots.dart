import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/fishing_hotspot_service.dart';
import '../services/location_service.dart';

class HotspotsScreen extends StatefulWidget {
  const HotspotsScreen({Key? key}) : super(key: key);

  @override
  _HotspotsScreenState createState() => _HotspotsScreenState();
}

class _HotspotsScreenState extends State<HotspotsScreen> {
  final FishingHotspotService fishingHotspotService = FishingHotspotService();
  final LocationService locationService = LocationService();
  List<Map<String, dynamic>> hotspots = [];
  List<bool> isLoadingHotspots = [];
  bool hasHotspotError = false;
  final List<Map<String, double>> destinations = [];
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  Map<String, double>? userLocation;
  ui.Image? markerImage;
  double arrowRotation = 0.0;
  late Timer _locationUpdateTimer;
  double _zoom = 500.0;
  Offset _panOffset = Offset.zero;

  double _previousScale = 500.0;
  Offset _previousOffset = Offset.zero;
  Offset _scaleFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
    _initializeSensors();
    _startLocationUpdateTimer();
    _fetchFishingHotspots();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel(); // Cancel this stream listener!
    _locationUpdateTimer.cancel();
    super.dispose();
  }

  void _showNavigateDialog(Map<String, dynamic> hotspot) {
    debugPrint("Hotspots: $hotspots");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Navigate?"),
          content: Text(
              "Do you want to navigate to this hotspot at ${hotspot['latitude']?.toStringAsFixed(4)}, ${hotspot['longitude']?.toStringAsFixed(4)}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  destinations.clear();
                  destinations.add({
                    'lat': hotspot['latitude'],
                    'lng': hotspot['longitude']
                  });
                });

                // ✅ Send linking data with hotspot ID
                if (hotspot.containsKey('hotspotId')) {
                  await BluetoothService()
                      .sendLinkingData(hotspot['hotspotId'].toString());
                }

                Navigator.of(context).pop();
              },
              child: Text("Navigate"),
            ),
          ],
        );
      },
    );
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLng = (lng2 - lng1) * (math.pi / 180);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _handleMapTap(Offset tapPosition) {
    final Size screenSize = MediaQuery.of(context).size;
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;

    // These scaling factors need to match what you're using in the painter:
    final double scalePerLng = (screenSize.width * _zoom) / 360;
    final double scalePerLat = (screenSize.height * _zoom) / 180;

    final double lngDiff = (tapPosition.dx - centerX) / scalePerLng;
    final double latDiff =
        (tapPosition.dy - centerY) / scalePerLat * -1; // invert Y axis

    final tappedLat = userLocation!['lat']! + latDiff;
    final tappedLng = userLocation!['lng']! + lngDiff;

    print("👉 Tap detected at: lat: $tappedLat, lng: $tappedLng");

    // Now your distance calculation will make sense!
    const double thresholdKm = 5;
    for (var hotspot in hotspots) {
      final double distance = _calculateDistance(
          tappedLat, tappedLng, hotspot['latitude']!, hotspot['longitude']!);
      if (distance < thresholdKm) {
        _showNavigateDialog(
            hotspot); // Pass the full object with `id`, `latitude`, `longitude`
        break;
      }
    }
  }

  Future<void> _fetchFishingHotspots() async {
    setState(() {
      isLoadingHotspots = List.filled(3, true); // Assume 3 slots are loading
      hotspots = [];
      destinations.clear(); // Clear existing destinations
    });

    try {
      Position position = await locationService.getCurrentPosition();
      double latitude = position.latitude;
      double longitude = position.longitude;

      print("📡 Requesting hotspot data via BLE...");
      List<Map<String, dynamic>> fetchedHotspots = await fishingHotspotService
          .fetchSuggestedFishingHotspots(latitude, longitude);

      if (fetchedHotspots.isNotEmpty) {
        setState(() {
          hotspots = fetchedHotspots;
          isLoadingHotspots = List.filled(fetchedHotspots.length, false);
          hasHotspotError = false;
          // Map the hotspot list to destinations
          destinations.clear();
          destinations.addAll(fetchedHotspots.map((hotspot) {
            return {
              'lat': hotspot['latitude'] as double,
              'lng': hotspot['longitude'] as double,
            };
          }).toList());
        });

        print(
            "✅ Hotspots successfully mapped to destinations: ${destinations.length} items.");
      } else {
        setState(() {
          hasHotspotError = true;
          isLoadingHotspots = List.filled(3, false);
        });
        print("⚠️ No hotspots received.");
      }
    } catch (e) {
      setState(() {
        hasHotspotError = true;
        isLoadingHotspots = List.filled(3, false);
      });
      print("❌ Error fetching hotspots: $e");
    }
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

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      userLocation = {'lat': position.latitude, 'lng': position.longitude};
    });
  }

  void _startLocationUpdateTimer() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCurrentLocation();
    });
  }

  void _initializeSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        arrowRotation = math.atan2(event.y, event.x);
      });
    });
  }

  Widget _buildZoomButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFF151d67),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildRecenterButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF151d67),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        elevation: 0,
        title: const Text(
          "Fishing Spots",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GestureDetector(
                  onScaleStart: (details) {
                    _previousScale = _zoom;
                    _previousOffset = _panOffset;
                    _scaleFocalPoint = details.focalPoint;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _zoom =
                          (_previousScale * details.scale).clamp(100.0, 2000.0);
                      final Offset delta =
                          details.focalPoint - _scaleFocalPoint;
                      _panOffset = _previousOffset + delta;
                    });
                  },
                  child: CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: MapPainter(
                      userLocation: userLocation,
                      destinations: destinations,
                      markerImage: markerImage,
                      arrowRotation: arrowRotation,
                      zoom: _zoom,
                      panOffset: _panOffset,
                    ),
                  ),
                ),

                // Zoom Controls
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  child: Column(
                    children: [
                      _buildZoomButton(
                        icon: Icons.add,
                        onTap: () {
                          setState(() {
                            _zoom = (_zoom * 1.2).clamp(100.0, 2000.0);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildZoomButton(
                        icon: Icons.remove,
                        onTap: () {
                          setState(() {
                            _zoom = (_zoom / 1.2).clamp(100.0, 2000.0);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Recenter Button
                Positioned(
                  left: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  child: _buildRecenterButton(
                    onTap: () {
                      setState(() {
                        _panOffset = Offset.zero;
                        _zoom = 500.0;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, double>> destinations;
  final ui.Image? markerImage;
  final double arrowRotation;
  final double zoom;
  final Offset panOffset; // add this

  MapPainter({
    required this.userLocation,
    required this.destinations,
    this.markerImage,
    required this.arrowRotation,
    this.zoom = 500.0,
    this.panOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (userLocation == null || markerImage == null) return;

    final Paint backgroundPaint = Paint()..color = Colors.blue.shade100;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final centerX = size.width / 2 + panOffset.dx;
    final centerY = size.height / 2 + panOffset.dy;

    // Convert lat/lng differences into pixel offsets
    double lngToOffset(double lngDiff) => (lngDiff / 360) * size.width * zoom;
    double latToOffset(double latDiff) => (-latDiff / 180) * size.height * zoom;

    // Draw user arrow at center
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(arrowRotation);
    final arrowPath = Path()
      ..moveTo(0, -20)
      ..lineTo(-10, 10)
      ..lineTo(10, 10)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.green);
    canvas.restore();

    final Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final textStyle = TextStyle(color: Colors.black, fontSize: 12);

    for (final destination in destinations) {
      final double latDiff = destination['lat']! - userLocation!['lat']!;
      final double lngDiff = destination['lng']! - userLocation!['lng']!;

      final double destX = centerX + lngToOffset(lngDiff);
      final double destY = centerY + latToOffset(latDiff);

      // Draw line to each destination
      canvas.drawLine(
          Offset(centerX, centerY), Offset(destX, destY), linePaint);

      // Draw marker image
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

      // Distance label
      double distance = calculateDistance(
        userLocation!['lat']!,
        userLocation!['lng']!,
        destination['lat']!,
        destination['lng']!,
      );

      final textPainter = TextPainter(
        text: TextSpan(
            text: '${distance.toStringAsFixed(2)} km', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final midX = (centerX + destX) / 2;
      final midY = (centerY + destY) / 2;
      textPainter.paint(canvas, Offset(midX, midY));
    }
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
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

  double _toRadians(double degree) => degree * (math.pi / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
