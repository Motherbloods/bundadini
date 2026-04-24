import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoggedIn = true;
    _userId = "dummy_user";
    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userId = null;
    notifyListeners();
  }
}
