import 'package:shared_preferences/shared_preferences.dart';

class PluginStoreManager {
  final String _floatingDotPos = 'FloatingDotPos';

  Future<SharedPreferences> _sharedPref = SharedPreferences.getInstance();

  Future<String?> fetchFloatingDotPos() async {
    final SharedPreferences prefs = await _sharedPref;
    return prefs.getString(_floatingDotPos);
  }

  void storeFloatingDotPos(double x, double y) async {
    final SharedPreferences prefs = await _sharedPref;
    prefs.setString(_floatingDotPos, "$x,$y");
  }
}
