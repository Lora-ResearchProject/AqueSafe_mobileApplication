import 'package:aqua_safe/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/fishing_hotspot_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final List<Map<String, dynamic>> destinations = [];

  Map<String, double>? userLocation;
  ui.Image? markerImage;
  late Timer _locationUpdateTimer;
  double _zoom = 500.0;
  Offset _panOffset = Offset.zero;

  double _previousScale = 500.0;
  Offset _previousOffset = Offset.zero;
  Offset _scaleFocalPoint = Offset.zero;

  Map<String, dynamic>? selectedHotspot;
  ui.Image? navigationIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
    _loadSelectedHotspot(); // Load selected if exists
    _startLocationUpdateTimer();
    _fetchFishingHotspots();
  }

  @override
  void dispose() {
    _locationUpdateTimer.cancel();
    super.dispose();
  }

  _loadSelectedHotspot() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('selectedHotspot');
    if (saved != null) {
      final Map<String, dynamic> selected = jsonDecode(saved);
      setState(() {
        selectedHotspot = {
          'lat': selected['lat'],
          'lng': selected['lng'],
        };
        destinations.clear();
        destinations.add(selectedHotspot!);
      });
    }
  }

  void _showNavigateDialog(Map<String, dynamic> hotspot) {
    debugPrint("Hotspots: $hotspots");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151d67),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Navigate?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        content: Text(
          "Do you want to navigate to this hotspot\nat ${hotspot['latitude']?.toStringAsFixed(4)}, ${hotspot['longitude']?.toStringAsFixed(4)}?",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(179, 229, 229, 229),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        actionsPadding: const EdgeInsets.only(bottom: 20),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  side: const BorderSide(color: Color(0xFF151d67), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFF151d67), fontSize: 18),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final selected = {
                    'lat': hotspot['latitude'],
                    'lng': hotspot['longitude']
                  };

                  // Store in SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setString('selectedHotspot', jsonEncode(selected));

                  setState(() {
                    selectedHotspot = selected;
                    destinations.clear();
                    destinations.add(selected);
                  });

                  if (hotspot.containsKey('hotspotId')) {
                    await BluetoothService()
                        .sendLinkingData(hotspot['hotspotId'].toString());
                  }

                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 18, 115, 194),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Navigate",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    if (selectedHotspot != null)
      return; // Prevent further selection if one is active

    final Size screenSize = MediaQuery.of(context).size;
    final double centerX = screenSize.width / 2 + _panOffset.dx;
    final double centerY = screenSize.height / 2 + _panOffset.dy;

    final double scalePerLng = (screenSize.width * _zoom) / 360;
    final double scalePerLat = (screenSize.height * _zoom) / 180;

    for (var hotspot in hotspots) {
      final double latDiff = hotspot['latitude']! - userLocation!['lat']!;
      final double lngDiff = hotspot['longitude']! - userLocation!['lng']!;

      final double destX = centerX + (lngDiff / 360) * screenSize.width * _zoom;
      final double destY =
          centerY + (-latDiff / 180) * screenSize.height * _zoom;

      const double markerHeight = 30.0; // Same as used in CustomPainter
      const double markerTouchRadius = 30.0;

      final Offset markerCenter = Offset(destX, destY - markerHeight / 2);

      // Check if tap is near marker
      if ((tapPosition - markerCenter).distance < markerTouchRadius) {
        _showNavigateDialog(hotspot);
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
    final marker = await _loadImage('assets/marker_vessel.png');
    final navIcon = await _loadImage('assets/navigation_icon.png');

    setState(() {
      markerImage = marker;
      navigationIcon = navIcon;
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
        width: 70,
        height: 70,
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
          size: 30,
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
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        // NEW Save Location button
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.bookmark_add, color: Colors.white),
        //     tooltip: "Save Fishing Location",
        //     onPressed: () async {
        //       await fishingHotspotService.saveFishingLocation();
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(
        //           content: Text("📍 Fishing location saved via Bluetooth"),
        //           duration: Duration(seconds: 2),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: userLocation == null
          ? Container(
              color: Colors.blue.shade100,
              child: const Center(child: CircularProgressIndicator()),
            )
          : Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) => _handleMapTap(details.localPosition),
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
                        navigationIcon: navigationIcon,
                        zoom: _zoom,
                        panOffset: _panOffset,
                        selectedHotspot: selectedHotspot),
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

                // Cancel Navigation Button (Top-Right)
                if (selectedHotspot != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD71313),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.remove('selectedHotspot');

                        // Unlink the selected hotspot
                        await BluetoothService().sendUnlinkingData();

                        setState(() {
                          selectedHotspot = null;
                          destinations.clear();
                          destinations.addAll(hotspots.map((hotspot) {
                            return {
                              'lat': hotspot['latitude'] as double,
                              'lng': hotspot['longitude'] as double,
                            };
                          }).toList());
                        });

                        // 🔁 Re-fetch suggested hotspots
                        // await _fetchFishingHotspots();
                      },
                      icon: const Icon(Icons.cancel,
                          color: Colors.white, size: 28),
                      label: const Text(
                        "Cancel Navigation",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, dynamic>> destinations;
  final ui.Image? markerImage;
  final double zoom;
  final Offset panOffset;
  final Map<String, dynamic>? selectedHotspot;
  final ui.Image? navigationIcon;

  MapPainter({
    required this.userLocation,
    required this.destinations,
    this.markerImage,
    this.navigationIcon,
    required this.zoom,
    required this.panOffset,
    this.selectedHotspot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (userLocation == null || markerImage == null) return;

    final Paint backgroundPaint = Paint()..color = Colors.blue.shade100;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final centerX = size.width / 2 + panOffset.dx;
    final centerY = size.height / 2 + panOffset.dy;

    // Converts lat/lng differences into pixel offsets
    double lngToOffset(double lngDiff) => (lngDiff / 360) * size.width * zoom;
    double latToOffset(double latDiff) => (-latDiff / 180) * size.height * zoom;

    final Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final textStyle = TextStyle(color: Colors.black, fontSize: 12);

    for (final destination in destinations) {
      // Skip others if a specific hotspot is selected
      if (selectedHotspot != null &&
          (destination['lat'] != selectedHotspot!['lat'] ||
              destination['lng'] != selectedHotspot!['lng'])) {
        continue;
      }

      final double latDiff = destination['lat']! - userLocation!['lat']!;
      final double lngDiff = destination['lng']! - userLocation!['lng']!;

      final double destX = centerX + lngToOffset(lngDiff);
      final double destY = centerY + latToOffset(latDiff);

      // 🔹 Draw line from user to hotspot
      canvas.drawLine(
          Offset(centerX, centerY), Offset(destX, destY), linePaint);

      // 🔹 Draw marker image
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

      // Debug: Show clickable zone
      canvas.drawCircle(
        Offset(destX, destY - markerHeight / 2),
        30.0, // Same as markerTouchRadius
        Paint()..color = Colors.blue.withOpacity(0.2),
      );

      // 🔹 Draw distance label
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

    // Draw user location as a circle
    const double userRadius = 6.0;
    canvas.drawCircle(
      Offset(centerX, centerY),
      userRadius + 1,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      userRadius,
      Paint()..color = const Color.fromARGB(255, 26, 86, 191),
    );

    // Draw arrow to selected hotspot
    if (selectedHotspot != null && navigationIcon != null) {
      final double latDiff = selectedHotspot!['lat']! - userLocation!['lat']!;
      final double lngDiff = selectedHotspot!['lng']! - userLocation!['lng']!;
      final double destX = centerX + lngToOffset(lngDiff);
      final double destY = centerY + latToOffset(latDiff);

      final double dx = destX - centerX;
      final double dy = destY - centerY;
      final double angle = math.atan2(dy, dx) + (math.pi);

      const double iconSize = 30.0;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(angle);

      // Draw the rotated image centered
      canvas.drawImageRect(
        navigationIcon!,
        Rect.fromLTWH(
          0,
          0,
          navigationIcon!.width.toDouble(),
          navigationIcon!.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset(0, 0),
          width: iconSize,
          height: iconSize,
        ),
        Paint(),
      );

      canvas.restore();
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
