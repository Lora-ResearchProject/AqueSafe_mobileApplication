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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // Log all SharedPreferences
  PreferencesHelper.printSharedPreferences();

  // Initialize services, including GPS and Bluetooth
  // final BluetoothService bluetoothService = BluetoothService();
  // bluetoothService.monitorConnection();

  // final BluetoothService bluetoothService = BluetoothService();
  // await bluetoothService.scanAndConnect();

  // Start the GPS Scheduler
  final SchedulerService gpsScheduler = SchedulerService();
  await gpsScheduler.startScheduler();

  runApp(const AquaSafeApp());
}

class AquaSafeApp extends StatelessWidget {
  const AquaSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSafe',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => Dashboard(),
        '/hotspots': (context) => HotspotsScreen(),
      },
    );
  }
}
