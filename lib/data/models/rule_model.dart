/// Severity level sebuah rule
class RuleSeverity {
  static const String info = 'info';
  static const String warning = 'warning';
  static const String danger = 'danger';
}

class RuleModel {
  final String id;
  final String namaRule;
  final String
      kondisiField; // 'sistolik'|'diastolik'|'djj'|'lingkar_lengan'|'bmi'|'berat_badan'
  final String kondisiOperator; // '>'|'<'|'>='|'<='|'=='
  final double kondisiValue;
  final String rekomendasi;
  final String severity; // RuleSeverity
  final bool aktif;

  const RuleModel({
    required this.id,
    required this.namaRule,
    required this.kondisiField,
    required this.kondisiOperator,
    required this.kondisiValue,
    required this.rekomendasi,
    required this.severity,
    required this.aktif,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: json['id'] as String? ?? '',
      namaRule: json['namaRule'] as String? ?? '',
      kondisiField: json['kondisiField'] as String? ?? '',
      kondisiOperator: json['kondisiOperator'] as String? ?? '>',
      kondisiValue: (json['kondisiValue'] as num?)?.toDouble() ?? 0.0,
      rekomendasi: json['rekomendasi'] as String? ?? '',
      severity: json['severity'] as String? ?? RuleSeverity.info,
      aktif: json['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaRule': namaRule,
        'kondisiField': kondisiField,
        'kondisiOperator': kondisiOperator,
        'kondisiValue': kondisiValue,
        'rekomendasi': rekomendasi,
        'severity': severity,
        'aktif': aktif,
      };

  @override
  String toString() =>
      'RuleModel($namaRule: $kondisiField $kondisiOperator $kondisiValue [$severity])';
}

// ============================================================
// SEED DATA — upload manual ke Firebase Console
// ============================================================
//
// Collection: rules
//
// rules/rule_001 → Hipertensi Sistolik
//   kondisiField:    "sistolik"
//   kondisiOperator: ">="
//   kondisiValue:    140
//   namaRule:        "Hipertensi Sistolik"
//   rekomendasi:     "Tekanan darah sistolik tinggi. Segera rujuk ke bidan atau puskesmas."
//   severity:        "danger"
//   aktif:           true
//
// rules/rule_002 → Hipotensi Sistolik
//   kondisiField:    "sistolik"
//   kondisiOperator: "<"
//   kondisiValue:    90
//   namaRule:        "Hipotensi Sistolik"
//   rekomendasi:     "Tekanan darah rendah. Anjurkan istirahat dan minum air putih cukup."
//   severity:        "warning"
//   aktif:           true
//
// rules/rule_003 → Hipertensi Diastolik
//   kondisiField:    "diastolik"
//   kondisiOperator: ">="
//   kondisiValue:    90
//   namaRule:        "Hipertensi Diastolik"
//   rekomendasi:     "Tekanan diastolik tinggi. Pantau tekanan darah setiap hari."
//   severity:        "danger"
//   aktif:           true
//
// rules/rule_004 → DJJ Rendah
//   kondisiField:    "djj"
//   kondisiOperator: "<"
//   kondisiValue:    110
//   namaRule:        "DJJ Rendah"
//   rekomendasi:     "DJJ di bawah normal. Segera konsultasi ke tenaga kesehatan."
//   severity:        "danger"
//   aktif:           true
//
// rules/rule_005 → DJJ Tinggi
//   kondisiField:    "djj"
//   kondisiOperator: ">"
//   kondisiValue:    160
//   namaRule:        "DJJ Tinggi"
//   rekomendasi:     "DJJ di atas normal. Anjurkan ibu beristirahat dan segera periksakan ke bidan."
//   severity:        "danger"
//   aktif:           true
//
// rules/rule_006 → KEK (Kurang Energi Kronis)
//   kondisiField:    "lingkar_lengan"
//   kondisiOperator: "<"
//   kondisiValue:    23.5
//   namaRule:        "KEK - Kurang Energi Kronis"
//   rekomendasi:     "LILA < 23.5 cm menunjukkan risiko KEK. Tingkatkan asupan gizi dan konsultasi ahli gizi."
//   severity:        "warning"
//   aktif:           true
//
// rules/rule_007 → BMI Kurang
//   kondisiField:    "bmi"
//   kondisiOperator: "<"
//   kondisiValue:    18.5
//   namaRule:        "BMI Kurang"
//   rekomendasi:     "Berat badan kurang untuk usia kehamilan. Tingkatkan asupan kalori dan konsultasi gizi."
//   severity:        "warning"
//   aktif:           true
//
// rules/rule_008 → Obesitas
//   kondisiField:    "bmi"
//   kondisiOperator: ">="
//   kondisiValue:    30
//   namaRule:        "Obesitas"
//   rekomendasi:     "BMI menunjukkan obesitas. Konsultasi dokter untuk rencana diet aman selama kehamilan."
//   severity:        "warning"
//   aktif:           true
