import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  late StreamSubscription _sub;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Cek status awal
    final result = await Connectivity().checkConnectivity();
    _isOnline = _check(result);
    notifyListeners();

    // Listen perubahan koneksi
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final online = _check(result);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _check(List<ConnectivityResult> result) {
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
