import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int? weatherPercentage;
  String weatherCondition = "Fetching Weather...";
  String locationName = "Fetching location...";
  bool isFetching = false;
  final WeatherService weatherService = WeatherService();
  final LocationService locationService = LocationService();
  String activeTime = "12 PM";

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchWeather();
  }

  Future<void> _fetchLocation() async {
    Position? position;
    try {
      position = await locationService.getCurrentPosition();
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      setState(() {
        locationName = (placemarks.isNotEmpty &&
                placemarks.first.locality != null)
            ? placemarks.first.locality!
            : "${position!.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}"; // Fallback to GPS coordinates
      });
    } catch (e) {
      setState(() {
        locationName = (position != null) // Check if position is available
            ? "GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}"
            : "Location Unavailable"; // If GPS fetch failed
      });
      print("Error fetching location: $e");
    }
  }

  Future<void> _fetchWeather() async {
    if (isFetching) return;

    setState(() {
      isFetching = true;
      weatherCondition = "Fetching Weather...";
      weatherPercentage = null;
    });

    int? weatherData = await weatherService.getWeather();
    print("Fetched weather percentage: $weatherData");

    if (!mounted) return;

    setState(() {
      isFetching = false;
      if (weatherData != null) {
        weatherPercentage = weatherData;
        weatherCondition = _getWeatherCondition(weatherData);
      } else {
        weatherCondition = "Failed to fetch weather. Tap Refresh.";
      }
    });
  }

  String _getWeatherCondition(int percentage) {
    if (percentage >= 70) {
      return "High chance of rain";
    } else if (percentage >= 40) {
      return "Moderate chance of rain";
    } else {
      return "Low chance of rain";
    }
  }

  IconData _getWeatherIcon(int percentage) {
    if (percentage >= 70) {
      return Icons.cloudy_snowing;
    } else if (percentage >= 40) {
      return Icons.cloud;
    } else {
      return Icons.wb_sunny;
    }
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
      body: Center(
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
                _getWeatherIcon(weatherPercentage ?? 0),
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
                      text: "${weatherPercentage ?? 0}%",
                      style: const TextStyle(
                        fontSize: 60,
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

              // Large Refresh Button
              ElevatedButton.icon(
                onPressed: isFetching ? null : _fetchWeather,
                icon: isFetching
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3)
                    : const Icon(Icons.refresh, size: 30),
                label: const Text(
                  "Refresh Weather",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
