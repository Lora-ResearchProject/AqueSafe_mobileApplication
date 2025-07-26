import 'package:aqua_safe/screens/chat.dart';
import 'package:aqua_safe/screens/weather_map.dart';
import 'package:aqua_safe/screens/weather_screen.dart';
import 'package:aqua_safe/services/predefined_msg_scheduler.dart';
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
import 'screens/improvedChat.dart';

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
        '/chat': (context) => const ImprovedChatScreen()
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
        print("SOS history scheduler calling start");

      final ChatMessageScheduler chatMessageScheduler = ChatMessageScheduler();
      chatMessageScheduler.startScheduler();
      print("chatMessageScheduler calling start");

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFF151d67),
        child: SafeArea(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // space between top & bottom
            children: [
              // Empty container or spacer for top padding if needed
              const SizedBox(height: 1),

              // Centered main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'AquaSafe',
                          style: TextStyle(
                            fontSize: size.width * 0.12,
                            // fontWeight: FontWeight.bold,
                            fontFamily: 'Lobster',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/logo.png',
                          width: size.width * 0.2,
                          height: size.width * 0.2,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Stay in Touch, Stay Protected\nAnytime, Anywhere',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading message at bottom
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: size.width * 0.04,
                      height: size.width * 0.04,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
