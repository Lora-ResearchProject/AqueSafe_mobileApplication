import 'package:aqua_safe/screens/weather_map.dart';
import 'package:aqua_safe/screens/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/hotspots.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/preferences_helper.dart';
import '../services/bluetooth_service.dart';
import 'screens/edit_account.dart';
import 'screens/change_password.dart';
import '../services/sos_history_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await SharedPreferences.getInstance();
  PreferencesHelper.printSharedPreferences();

  runApp(const AquaSafeApp());
}

class AquaSafeApp extends StatelessWidget {
  const AquaSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSafe',
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        if (settings.name == '/weather') {
          final args = settings.arguments;

          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) => WeatherScreen(
                locationName: args['locationName'] ?? "Unknown Location",
                latitude: args['latitude'] ?? 0.0,
                longitude: args['longitude'] ?? 0.0,
              ),
            );
          } else {
            // Handle the case where arguments are missing
            print(
                "⚠️ Warning: Missing or invalid arguments for /weather route.");
            return MaterialPageRoute(
              builder: (context) => const WeatherScreen(
                locationName: "Unknown",
                latitude: 0.0,
                longitude: 0.0,
              ),
            );
          }
        }
        return null;
      },
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => Dashboard(),
        '/hotspots': (context) => HotspotsScreen(),
        '/splash': (context) => SplashScreen(),
        '/edit_account': (context) => const EditAccountScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/weather_map': (context) => const WeatherMapScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String _loadingMessage = "Starting Services...";
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? vesselId = prefs.getString('vesselId');

      if (vesselId == null) {
        _navigateToLogin();
        return;
      }

      // Start both services in parallel
      setState(() =>
          _loadingMessage = "Connecting to Bluetooth & Starting Services...");

      final BluetoothService bluetoothService = BluetoothService();
      Future<bool> bleConnection = bluetoothService.scanAndConnect();

      final SOSHistoryScheduler sosScheduler = SOSHistoryScheduler();
      sosScheduler.startScheduler(onSOSUpdate: () {
        print("🔄 UI updated: SOS status changed");
      });

      // Wait for both to finish
      await Future.wait([bleConnection]);

      bool bluetoothConnected = await bleConnection;

      if (!bluetoothConnected) {
        print("⚠️ Bluetooth connection failed.");
      }

      _navigateToDashboard();
    } catch (e) {
      print("❌ Error during initialization: $e");
      _navigateToDashboard();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AquaSafe',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 26),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
