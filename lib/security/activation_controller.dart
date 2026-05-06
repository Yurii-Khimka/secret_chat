import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activation.dart';

class ActivationController extends ChangeNotifier {
  static const _prefsKey = 'activation.code';
  bool _activated = false;
  String? _error;

  bool get activated => _activated;
  String? get error => _error;

  /// Loads any persisted code and re-verifies it. Called once at app startup
  /// before runApp(). If the persisted code fails to verify (corrupted,
  /// tampered, or pubkey rotated), it is cleared.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      final valid = await verifyActivationCode(stored);
      if (valid) {
        _activated = true;
      } else {
        await prefs.remove(_prefsKey);
      }
    }
    notifyListeners();
  }

  /// Verifies [code]; on success persists it and flips activated to true.
  /// On failure sets [error] = '[ERROR] code not valid' and returns false.
  Future<bool> activate(String code) async {
    final cleaned = code.replaceAll(RegExp(r'\s'), '');
    final valid = await verifyActivationCode(cleaned);
    if (valid) {
      _error = null;
      _activated = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, cleaned);
      notifyListeners();
      return true;
    } else {
      _error = '[ERROR] code not valid';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
