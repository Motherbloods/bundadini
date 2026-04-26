import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/kader_history_model.dart';
import '../../data/repositories/patient_repository.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo = PatientRepository();

  List<PatientModel> _patients = [];
  PatientModel? _selectedPatient;
  List<KaderHistoryModel> _kaderHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PatientModel> get patients => _patients;
  PatientModel? get selectedPatient => _selectedPatient;
  List<KaderHistoryModel> get kaderHistory => _kaderHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load

  Future<void> loadByKader(String kaderId) async {
    _setLoading(true);
    try {
      _patients = await _repo.fetchByKader(kaderId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pasien.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAll(String bidanId) async {
    _setLoading(true);
    try {
      _patients = await _repo.fetchAll(bidanId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pasien.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPatient(String patientId) async {
    _setLoading(true);
    try {
      _selectedPatient = await _repo.fetchById(patientId);
      if (_selectedPatient != null) {
        _kaderHistory = await _repo.fetchKaderHistory(patientId);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pasien.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Cek NIK duplikat

  Future<PatientModel?> checkNik(String nik) async {
    return _repo.findByNik(nik);
  }

  // Create

  Future<bool> addPatient(PatientModel patient, File fotoFile) async {
    _setLoading(true);
    _clearError();
    try {
      final created = await _repo.create(patient, fotoFile);
      _patients.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pasien: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Biodata

  Future<bool> updatePatient(PatientModel patient, {File? fotoFile}) async {
    _setLoading(true);
    _clearError();
    try {
      final updated = await _repo.update(patient, fotoFile: fotoFile);
      final idx = _patients.indexWhere((p) => p.id == updated.id);
      if (idx != -1) _patients[idx] = updated;
      if (_selectedPatient?.id == updated.id) _selectedPatient = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui data: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Transfer Kader

  Future<bool> transferKader({
    required String patientId,
    required String newKaderId,
    required String newKaderNama,
    required String oldKaderId,
    String? alasan,
  }) async {
    _setLoading(true);
    try {
      await _repo.transferKader(
        patientId: patientId,
        newKaderId: newKaderId,
        newKaderNama: newKaderNama,
        oldKaderId: oldKaderId,
        alasan: alasan,
      );
      // Hapus dari list kader lama
      _patients.removeWhere((p) => p.id == patientId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal transfer kader.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helpers

  List<PatientModel> search(String query) {
    final q = query.toLowerCase();
    return _patients
        .where((p) => p.nama.toLowerCase().contains(q) || p.nik.contains(q))
        .toList();
  }

  void clearError() => _clearError();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clear() {
    _patients = [];
    _selectedPatient = null;
    _kaderHistory = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> tandaiSelesai(String patientId) async {
    _setLoading(true);
    try {
      await _repo.tandaiSelesai(patientId);
      // Update local state
      final idx = _patients.indexWhere((p) => p.id == patientId);
      if (idx != -1) {
        _patients[idx] = _patients[idx].copyWith(status: StatusPasien.selesai);
      }
      if (_selectedPatient?.id == patientId) {
        _selectedPatient =
            _selectedPatient?.copyWith(status: StatusPasien.selesai);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah status pasien.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
