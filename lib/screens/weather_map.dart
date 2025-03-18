import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:aqua_safe/services/location_service.dart';

class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  _WeatherMapScreenState createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  final LocationService _locationService = LocationService();
  Map<String, double>? userLocation;
  List<Map<String, dynamic>> hotspots = [];
  ui.Image? fishIcon;
  Offset mapOffset = Offset.zero;
  double scale = 1.0;
  final double minScale = 0.8;
  final double maxScale = 3.0;
  Offset _focalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadFishIcon();
    _fetchCurrentLocation();
    _fetchFishingHotspots();
  }

  Future<void> _loadFishIcon() async {
    final image = await _loadImage('assets/fish_icon.png');
    setState(() {
      fishIcon = image;
    });
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _fetchCurrentLocation() async {
    var position = await _locationService.getCurrentPosition();
    setState(() {
      userLocation = {'lat': position.latitude, 'lng': position.longitude};
    });
  }

  Future<void> _fetchFishingHotspots() async {
    setState(() {
      hotspots = [
        {
          "hotspotId": 9,
          "latitude": -33.9189,
          "longitude": 151.2353,
          "weather": "sunny"
        },
        {
          "hotspotId": 10,
          "latitude": 11.667,
          "longitude": 92.7358,
          "weather": "rainy"
        },
        {
          "hotspotId": 11,
          "latitude": 43.0642,
          "longitude": 141.3469,
          "weather": "cloudy"
        },
      ];
    });
  }

  void _onHotspotTap(Map<String, dynamic> hotspot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151d67),
        title: Text(
          "Hotspot ${hotspot['hotspotId']}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Weather: ${hotspot['weather']}",
              style: const TextStyle(color: Colors.white),
            ),
            Icon(
              hotspot['weather'] == "sunny"
                  ? Icons.wb_sunny
                  : hotspot['weather'] == "rainy"
                      ? Icons.cloudy_snowing
                      : Icons.cloud,
              size: 40,
              color: Colors.yellowAccent,
            ),
          ],
        ),
        actions: [
          // TextButton(
          //   child: const Text("See Forecast", style: TextStyle(color: Colors.blueAccent)),
          //   onPressed: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         // builder: (context) => WeatherScreen(
          //         //   locationName: "Hotspot ${hotspot['hotspotId']}",
          //         //   latitude: hotspot['latitude'],
          //         //   longitude: hotspot['longitude'],
          //         // ),
          //         builder: (context) => WeatherForecastScreen())

          //     );
          //   },
          // ),
          TextButton(
            child:
                const Text("Close", style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      scale = (scale * 1.2).clamp(minScale, maxScale);
    });
  }

  void _zoomOut() {
    setState(() {
      scale = (scale / 1.2).clamp(minScale, maxScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        elevation: 0,
        title: const Text(
          "Fishing Hotspots",
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
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (TapUpDetails details) {
              final Offset tapPosition = details.localPosition;
              for (var hotspot in hotspots) {
                final double hotspotX = ((hotspot['longitude'] + 180) / 360) *
                        MediaQuery.of(context).size.width *
                        scale +
                    mapOffset.dx;
                final double hotspotY = ((90 - hotspot['latitude']) / 180) *
                        MediaQuery.of(context).size.height *
                        scale +
                    mapOffset.dy;

                if ((tapPosition - Offset(hotspotX, hotspotY)).distance < 15) {
                  _onHotspotTap(hotspot);
                  break;
                }
              }
            },
            onScaleStart: (details) {
              _focalPoint = details.focalPoint;
            },
            onScaleUpdate: (ScaleUpdateDetails details) {
              setState(() {
                scale = (scale * details.scale).clamp(minScale, maxScale);
                mapOffset += details.focalPoint - _focalPoint;
                _focalPoint = details.focalPoint;
              });
            },
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: WeatherMapPainter(
                userLocation: userLocation,
                hotspots: hotspots,
                fishIcon: fishIcon,
                mapOffset: mapOffset,
                scale: scale,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  onPressed: _zoomIn,
                  backgroundColor: const Color(0xFF151d67),
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  onPressed: _zoomOut,
                  backgroundColor: const Color(0xFF151d67),
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherMapPainter extends CustomPainter {
  final Map<String, double>? userLocation;
  final List<Map<String, dynamic>> hotspots;
  final ui.Image? fishIcon;
  final Offset mapOffset;
  final double scale;

  WeatherMapPainter({
    required this.userLocation,
    required this.hotspots,
    required this.fishIcon,
    required this.mapOffset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = Colors.blue;
    final Paint hotspotPaint = Paint()..color = Colors.redAccent;
    final Paint userPaint = Paint()..color = Colors.greenAccent;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    if (userLocation == null) return;

    double scaleX(double lng) => ((lng + 180) / 360) * size.width * scale;
    double scaleY(double lat) => ((90 - lat) / 180) * size.height * scale;

    final double userX = scaleX(userLocation!['lng']!) + mapOffset.dx;
    final double userY = scaleY(userLocation!['lat']!) + mapOffset.dy;
    canvas.drawCircle(Offset(userX, userY), 10, userPaint);

    for (final hotspot in hotspots) {
      final double hotspotX = scaleX(hotspot['longitude']) + mapOffset.dx;
      final double hotspotY = scaleY(hotspot['latitude']) + mapOffset.dy;
      double iconSize = (15 / scale).clamp(5, 15);

      canvas.drawCircle(Offset(hotspotX, hotspotY), iconSize, hotspotPaint);

      if (fishIcon != null) {
        canvas.drawImageRect(
          fishIcon!,
          Rect.fromLTWH(
              0, 0, fishIcon!.width.toDouble(), fishIcon!.height.toDouble()),
          Rect.fromLTWH(hotspotX - iconSize, hotspotY - iconSize, iconSize * 2,
              iconSize * 2),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
