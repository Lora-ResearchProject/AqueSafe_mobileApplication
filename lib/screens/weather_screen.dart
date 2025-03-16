import 'package:aqua_safe/screens/weather_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/fishing_hotspot_service.dart';

class WeatherScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;

  const WeatherScreen({
    Key? key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int? weatherPercentage;
  String weatherCondition = "Fetching Weather...";
  String locationName = "Fetching location...";
  bool isFetching = false;
  bool isCurrentLocation = false;
  final WeatherService weatherService = WeatherService();
  final LocationService locationService = LocationService();
  final FishingHotspotService fishingHotspotService = FishingHotspotService();

  List<Map<String, dynamic>> hotspots = [];
  List<bool> isLoadingHotspots = [];
  String selectedNavItem = "Current"; // Default selection
  bool hasHotspotError = false;

  @override
  void initState() {
    super.initState();
    _fetchFishingHotspots();
    _updateWeatherForLocation();
  }

  Future<void> _fetchFishingHotspots() async {
    setState(() {
      isLoadingHotspots = List.filled(3, true); // Assume 3 slots are loading
      hotspots = []; // Ensure it's cleared initially
    });

    try {
      print("📡 Requesting hotspot data via BLE...");

      List<Map<String, dynamic>> fetchedHotspots =
          await fishingHotspotService.fetchSuggestedFishingHotspots();

      if (fetchedHotspots.isNotEmpty) {
        setState(() {
          hotspots = fetchedHotspots;
          isLoadingHotspots = List.filled(fetchedHotspots.length, false);
          hasHotspotError = false;
        });
        print("✅ Hotspots successfully received: ${hotspots.length} items.");
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

  Future<void> _updateWeatherForLocation() async {
    setState(() {
      weatherCondition = "Fetching Weather...";
      weatherPercentage = null;
      isFetching = true;
    });

    double latitude;
    double longitude;

    if (selectedNavItem == "Current") {
      isCurrentLocation = true;
      Position position = await locationService.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
      locationName =
          "${latitude.toStringAsFixed(5)}N, ${longitude.toStringAsFixed(5)}E";
    } else {
      isCurrentLocation = false;
      var hotspot = hotspots.firstWhere(
        (h) => "HS-${h['hotspotId']}" == selectedNavItem,
        orElse: () => {},
      );

      if (hotspot.isEmpty) return;

      latitude = hotspot["latitude"];
      longitude = hotspot["longitude"];
      locationName =
          "${latitude.toStringAsFixed(5)}N, ${longitude.toStringAsFixed(5)}E";
    }

    int? weatherData = await weatherService.fetchWeather(latitude, longitude,
        isCurrentLocation: isCurrentLocation);

    if (!mounted) return;

    setState(() {
      weatherPercentage = weatherData;
      // weatherPercentage = weatherData ?? 0;
      weatherCondition = weatherService.getWeatherCondition(weatherPercentage!);
      isFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151d67),
        title: const Text("Weather Forecast"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // View Hotspot Map Button (Right-Aligned)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeatherMapScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text("View Hotspot Map",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation Bar (Current & Hotspots with Loading State)
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 16, 78, 123),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              children: [
                _navItem("Current", isSelected: selectedNavItem == "Current"),
                // Check hotspots list is not empty before accessing it
                if (hotspots.isNotEmpty)
                  for (int i = 0; i < hotspots.length; i++)
                    _navItem(
                      isLoadingHotspots[i]
                          ? "Loading..."
                          : "HS-${hotspots[i]['hotspotId']}",
                      isSelected:
                          selectedNavItem == "HS-${hotspots[i]['hotspotId']}",
                      isLoading: isLoadingHotspots[i],
                    )
                else
                  // Show loading placeholders if hotspots are not loaded yet
                  for (int i = 0; i < 3; i++)
                    _navItem("Loading...", isSelected: false, isLoading: true),
              ],
            ),
          ),

          // Weather Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locationName,
                    style: const TextStyle(fontSize: 26, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  Icon(
                    Icons.cloudy_snowing, // Placeholder
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    weatherCondition,
                    style: const TextStyle(fontSize: 22, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text.rich(
                    TextSpan(
                      text: "Rain Prediction ",
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: weatherPercentage == null
                              ? "Fetching..."
                              : "$weatherPercentage%",
                          // text: "${weatherPercentage ?? 0}%",
                          style: TextStyle(
                            fontSize: weatherPercentage == null ? 30 : 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Forecast Timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _forecastCard("6 AM", Icons.cloudy_snowing),
                      _forecastCard("12 PM", Icons.cloud, isActive: true),
                      _forecastCard("6 PM", Icons.wb_sunny),
                      _forecastCard("12 AM", Icons.nights_stay),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: isFetching ? null : _updateWeatherForLocation,
                    icon: isFetching
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3)
                        : const Icon(Icons.refresh, size: 30),
                    label: Text(
                      "Refresh Weather",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isFetching ? Colors.grey[400] : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      backgroundColor: isFetching ? Colors.grey : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Item Widget
  Widget _navItem(String title,
      {bool isSelected = false, bool isLoading = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                setState(() {
                  selectedNavItem = title;
                });
                _updateWeatherForLocation();
              },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF151d67) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }

  // Forecast Card Widget
  Widget _forecastCard(String time, IconData icon, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 150,
            decoration: BoxDecoration(
              color: isActive ? Colors.purple : const Color(0xFF151d67),
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(
                      color: const Color.fromARGB(255, 255, 138, 255), width: 1)
                  : Border.all(
                      color: const Color.fromARGB(255, 70, 156, 254), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
