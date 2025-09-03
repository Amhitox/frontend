import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLoggedIn = 'logged_in';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool(keyFirstLaunch) ?? true;
    return firstLaunch;
  }

  static Future<void> setFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyFirstLaunch, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyLoggedIn, value);
  }
}
