import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isBidan => _currentUser?.isBidan ?? false;
  bool get isKader => _currentUser?.isKader ?? false;

  AuthProvider() {
    _init();
  }

  /// Cek sesi yang tersimpan saat app dibuka
  Future<void> _init() async {
    _status = AuthStatus.unknown;
    notifyListeners();

    final user = await _repo.getCurrentUserModel();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _repo.login(email, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _parseError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _repo.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Daftarkan kader baru (dipanggil dari bidan)
  Future<bool> registerKader({
    required String email,
    required String password,
    required String nama,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _repo.registerKader(
        email: email,
        password: password,
        nama: nama,
        createdBy: _currentUser!.id,
      );
      return true;
    } on Exception catch (e) {
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh data user dari Firestore (misal setelah edit profil)
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final updated = await _repo.getCurrentUserModel();
    if (updated != null) {
      _currentUser = updated;
      notifyListeners();
    }
  }

  /// Update profil bidan (namaPuskesmas, nama, dll)
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      await _repo.updateProfile(_currentUser!.id, data);
      await refreshUser();
      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() => _clearError();

  // ── private helpers ───────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Email atau kata sandi salah.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Tidak ada koneksi internet. Coba lagi.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Email sudah terdaftar.';
    }
    if (raw.contains('user-disabled')) {
      return 'Akun ini dinonaktifkan. Hubungi bidan pendamping.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
