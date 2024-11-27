import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/user_model.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'services/gps_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences to ensure readiness
  await SharedPreferences.getInstance();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  // await Hive.deleteBoxFromDisk('users'); // Uncomment this to reset the database
  await Hive.openBox('users');

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
      },
    );
  }
}
