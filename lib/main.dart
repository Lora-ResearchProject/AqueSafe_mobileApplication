import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/hotspots.dart';
import 'services/gps_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/preferences_helper.dart';
import '../services/bluetooth_service.dart';
import 'screens/edit_account.dart';
import 'screens/change_password.dart';

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
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => Dashboard(),
        '/hotspots': (context) => HotspotsScreen(),
        '/splash': (context) => SplashScreen(),
        '/edit_account': (context) => const EditAccountScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
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
  bool _gpsStarted = false;
  String _loadingMessage = "Initializing Services...";

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
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() => _loadingMessage = "Connecting to Bluetooth...");
      final BluetoothService bluetoothService = BluetoothService();
      Future<bool> bleConnection = bluetoothService.scanAndConnect();
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _loadingMessage = "Starting GPS Scheduler...");
      await Future.delayed(const Duration(seconds: 2));

      final SchedulerService gpsScheduler = SchedulerService();
      await gpsScheduler.startScheduler().then((_) {
        setState(() {
          _gpsStarted = true;
          _loadingMessage = "✅ GPS Scheduler started successfully";
        });
      }).catchError((error) {
        setState(() {
          _gpsStarted = false;
          _loadingMessage = "⚠️ GPS Scheduler Failed";
        });
      });
      await Future.delayed(const Duration(seconds: 2));

      bool bluetoothConnected = await bleConnection;

      if (!bluetoothConnected) {
        setState(() {
          _loadingMessage = "⚠️ Bluetooth Failed. Reconnect in Dashboard.";
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "❌ Initialization Failed";
        });
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AquaSafe',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 26),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AquaSafe',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 26),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
