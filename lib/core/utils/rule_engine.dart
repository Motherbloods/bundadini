import '../../data/models/rule_model.dart';
import '../../data/models/examination_model.dart';

class ExaminationResult {
  final String statusIbu;
  final String statusJanin;
  final List<String> rekomendasi;
  final List<String> ruleTriggered;

  const ExaminationResult({
    required this.statusIbu,
    required this.statusJanin,
    required this.rekomendasi,
    required this.ruleTriggered,
  });
}

class RuleEngine {
  RuleEngine._();

  /// Evaluasi semua rules terhadap data pemeriksaan.
  /// Dipanggil sebelum menyimpan ke Firestore.
  static ExaminationResult evaluate({
    required int sistolik,
    required int diastolik,
    required double beratBadan,
    required double tinggiBadan,
    required double lingkarLengan,
    required double? lingkarPerut,
    required double bmi,
    required int djj,
    required List<RuleModel> rules,
  }) {
    String statusIbu = ExaminationStatus.normal;
    String statusJanin = JaninStatus.normal;
    final List<String> rekomendasiList = [];
    final List<String> triggeredRules = [];

    final fieldValues = <String, double>{
      'sistolik': sistolik.toDouble(),
      'diastolik': diastolik.toDouble(),
      'djj': djj.toDouble(),
      'lingkar_lengan': lingkarLengan,
      'bmi': bmi,
      'berat_badan': beratBadan,
    };

    for (final rule in rules) {
      if (!rule.aktif) continue;

      final val = fieldValues[rule.kondisiField];
      if (val == null) continue;

      bool triggered = false;
      switch (rule.kondisiOperator) {
        case '>':
          triggered = val > rule.kondisiValue;
          break;
        case '<':
          triggered = val < rule.kondisiValue;
          break;
        case '>=':
          triggered = val >= rule.kondisiValue;
          break;
        case '<=':
          triggered = val <= rule.kondisiValue;
          break;
        case '==':
          triggered = val == rule.kondisiValue;
          break;
      }

      if (triggered) {
        rekomendasiList.add(rule.rekomendasi);
        triggeredRules.add(rule.id);

        switch (rule.severity) {
          case RuleSeverity.danger:
            statusIbu = ExaminationStatus.risikoTinggi;
            break;
          case RuleSeverity.warning:
            if (statusIbu == ExaminationStatus.normal) {
              statusIbu = ExaminationStatus.perluPerhatian;
            }
            break;
          case RuleSeverity.info:
            break;
        }

        // DJJ evaluation
        if (rule.kondisiField == 'djj') {
          statusJanin =
              djj < 110 ? JaninStatus.djjRendah : JaninStatus.djjTinggi;
        }
      }
    }

    if (rekomendasiList.isEmpty) {
      rekomendasiList.add(
        'Hasil pemeriksaan normal. Pertahankan pola hidup sehat dan rutin kontrol kehamilan.',
      );
    }

    return ExaminationResult(
      statusIbu: statusIbu,
      statusJanin: statusJanin,
      rekomendasi: rekomendasiList,
      ruleTriggered: triggeredRules,
    );
  }

  /// Hitung BMI
  static double hitungBmi(double beratKg, double tinggiCm) {
    if (tinggiCm <= 0) return 0;
    final tinggiM = tinggiCm / 100;
    return beratKg / (tinggiM * tinggiM);
  }

  /// Kategori BMI
  static String kategoriBmi(double bmi) {
    if (bmi < 18.5) return 'Kurus (Kurang Energi)';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Kelebihan Berat';
    return 'Obesitas';
  }

  /// Status LILA
  static bool isKek(double lila) => lila < 23.5;
}
