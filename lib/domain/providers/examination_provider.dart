import 'package:flutter/foundation.dart';
import '../../data/models/examination_model.dart';
import '../../data/repositories/examination_repository.dart';
import '../../data/models/rule_model.dart';
import '../../core/utils/rule_engine.dart';

class ExaminationProvider extends ChangeNotifier {
  final ExaminationRepository _repo = ExaminationRepository();

  List<ExaminationModel> _history = [];
  ExaminationModel? _lastSaved;
  bool _isLoading = false;
  String? _errorMessage;

  List<ExaminationModel> get history => _history;
  ExaminationModel? get lastSaved => _lastSaved;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load riwayat

  Future<void> loadHistory(String patientId) async {
    _setLoading(true);
    try {
      _history = await _repo.fetchByPatient(patientId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat pemeriksaan.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Simpan pemeriksaan

  Future<ExaminationModel?> saveExamination({
    required String patientId,
    required String kaderId,
    required String kaderNama,
    required String bidanId,
    required int usiaKehamilan,
    required int sistolik,
    required int diastolik,
    required double beratBadan,
    required double tinggiBadan,
    required double lingkarLengan,
    double? lingkarPerut,
    required int djj,
    double? tfu,
    required List<String> keluhanList,
    String? keluhanLainnya,
    String? catatanKader,
    required List<RuleModel> rules,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      // Hitung BMI
      final bmi = RuleEngine.hitungBmi(beratBadan, tinggiBadan);

      // Hitung kenaikan BB dari pemeriksaan sebelumnya
      final latest = await _repo.fetchLatestByPatient(patientId);
      final kenaikanBb = latest != null ? beratBadan - latest.beratBadan : 0.0;

      // Evaluasi rule engine
      final result = RuleEngine.evaluate(
        sistolik: sistolik,
        diastolik: diastolik,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
        lingkarLengan: lingkarLengan,
        lingkarPerut: lingkarPerut,
        bmi: bmi,
        djj: djj,
        rules: rules,
      );

      final exam = ExaminationModel(
        id: '',
        patientId: patientId,
        kaderId: kaderId,
        kaderNama: kaderNama,
        bidanId: bidanId,
        tanggal: DateTime.now(),
        usiaKehamilan: usiaKehamilan,
        sistolik: sistolik,
        diastolik: diastolik,
        beratBadan: beratBadan,
        tinggiBadan: tinggiBadan,
        lingkarLengan: lingkarLengan,
        lingkarPerut: lingkarPerut,
        bmi: bmi,
        kenaikanBb: kenaikanBb,
        tfu: tfu,
        djj: djj,
        keluhanList: keluhanList,
        keluhanLainnya: keluhanLainnya,
        catatanKader: catatanKader,
        statusIbu: result.statusIbu,
        statusJanin: result.statusJanin,
        rekomendasi: result.rekomendasi,
        ruleTriggered: result.ruleTriggered,
        createdAt: DateTime.now(),
      );

      final saved = await _repo.save(exam);
      _lastSaved = saved;
      _history.insert(0, saved);
      notifyListeners();
      return saved;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pemeriksaan: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<ExaminationModel?> fetchById(String examId) async {
    return _repo.fetchById(examId);
  }

  // Data grafik

  List<double> getTrendBb() =>
      _history.reversed.map((e) => e.beratBadan).toList();
  List<int> getTrendSistolik() =>
      _history.reversed.map((e) => e.sistolik).toList();
  List<int> getTrendDiastolik() =>
      _history.reversed.map((e) => e.diastolik).toList();
  List<int> getTrendDjj() => _history.reversed.map((e) => e.djj).toList();

  void clearError() => _clearError();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;
}
