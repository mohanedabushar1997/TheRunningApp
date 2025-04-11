import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });
}

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    // For demo purposes, auto-login with mock user
    _mockLogin();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock login for development purposes
  Future<void> _mockLogin() async {
    _setLoading(true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = User(
      id: 'user123',
      name: 'John Runner',
      email: 'john.runner@example.com',
      photoUrl:
          'https://ui-avatars.com/api/?name=John+Runner&background=random',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );

    _setLoading(false);
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      if (email == 'test@example.com' && password == 'password') {
        _currentUser = User(
          id: 'user123',
          name: 'John Runner',
          email: email,
          photoUrl:
              'https://ui-avatars.com/api/?name=John+Runner&background=random',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        );
        return true;
      } else {
        _error = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register a new user
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: 'user${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        photoUrl:
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
        createdAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout the current user
  Future<void> logout() async {
    _setLoading(true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    if (_currentUser == null) return false;

    _setLoading(true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      _currentUser = User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        createdAt: _currentUser!.createdAt,
      );
      return true;
    } catch (e) {
      _error = 'Profile update failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
