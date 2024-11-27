import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  // Logs all SharedPreferences to the console.
  static Future<void> printSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    if (keys.isEmpty) {
      print('No SharedPreferences found.');
      return;
    }

    print('---------- SharedPreferences ----------');
    for (String key in keys) {
      print('$key: ${prefs.get(key)}');
    }
    print('---------------------------------------');
  }
}
