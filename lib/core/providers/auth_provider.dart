import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _emailKey = 'user_email';
  static const String _userTypeKey = 'user_type';

  String? _email;
  String? _userType;
  bool _isLoggedIn = false;
  Future<void>? _initFuture; // To await initialization

  String? get email => _email;
  String? get userType => _userType;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _initFuture = _loadAuthState();
  }

  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_emailKey);
    _userType = prefs.getString(_userTypeKey);
    _isLoggedIn = _email != null;
    notifyListeners();
  }

  Future<void> setAuthState(String email, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_userTypeKey, userType);

    _email = email;
    _userType = userType;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_userTypeKey);

    _email = null;
    _userType = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
