import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'app_theme_name.dart';

class ThemeController extends ChangeNotifier {
  ThemeController();

  static const _key = 'app.theme';

  AppThemeName _current = AppThemeName.defaultTheme;
  AppThemeName get current => _current;

  AppTheme get theme => AppTheme.forName(_current);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      for (final name in AppThemeName.values) {
        if (name.name == stored) {
          _current = name;
          break;
        }
      }
    }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeName name) async {
    if (_current == name) return;
    _current = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name.name);
  }
}
