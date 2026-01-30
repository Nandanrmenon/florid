import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Web authentication service for managing user login and registration
class WebAuthService extends ChangeNotifier {
  // Backend API URL - Update this with your deployed backend URL
  static const String _baseUrl =
      kDebugMode ? 'http://localhost:3000' : 'https://florid-backend.example.com';

  String? _userId;
  String? _username;
  String? _authToken;
  bool _isAuthenticated = false;

  // Keys for SharedPreferences
  static const _userIdKey = 'web_user_id';
  static const _usernameKey = 'web_username';
  static const _authTokenKey = 'web_auth_token';

  WebAuthService() {
    _loadAuthData();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get authToken => _authToken;

  /// Load authentication data from storage
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _username = prefs.getString(_usernameKey);
      _authToken = prefs.getString(_authTokenKey);
      _isAuthenticated = _authToken != null && _authToken!.isNotEmpty;
      notifyListeners();
    } catch (e) {
      debugPrint('[WebAuthService] Error loading auth data: $e');
    }
  }

  /// Register a new user
  Future<bool> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(
          data['userId'] as String,
          data['username'] as String,
          data['token'] as String,
        );
        return true;
      } else {
        debugPrint('[WebAuthService] Registration failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[WebAuthService] Registration error: $e');
      return false;
    }
  }

  /// Login user
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(
          data['userId'] as String,
          data['username'] as String,
          data['token'] as String,
        );
        return true;
      } else {
        debugPrint('[WebAuthService] Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[WebAuthService] Login error: $e');
      return false;
    }
  }

  /// Save authentication data
  Future<void> _saveAuthData(
    String userId,
    String username,
    String authToken,
  ) async {
    _userId = userId;
    _username = username;
    _authToken = authToken;
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_authTokenKey, authToken);

    notifyListeners();
  }

  /// Logout user
  Future<void> logout() async {
    _userId = null;
    _username = null;
    _authToken = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_authTokenKey);

    notifyListeners();
  }

  /// Get authorization header for API requests
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
}
