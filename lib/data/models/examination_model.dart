import 'package:cloud_firestore/cloud_firestore.dart';

/// Status kondisi ibu
class ExaminationStatus {
  static const String normal = 'normal';
  static const String perluPerhatian = 'perlu_perhatian';
  static const String risikoTinggi = 'risiko_tinggi';

  static String label(String status) {
    switch (status) {
      case normal:
        return 'Normal';
      case perluPerhatian:
        return 'Perlu Perhatian';
      case risikoTinggi:
        return 'Risiko Tinggi';
      default:
        return 'Normal';
    }
  }
}

/// Status kondisi janin (DJJ)
class JaninStatus {
  static const String normal = 'normal';
  static const String djjRendah = 'djj_rendah';
  static const String djjTinggi = 'djj_tinggi';

  static String label(String status) {
    switch (status) {
      case normal:
        return 'Normal';
      case djjRendah:
        return 'DJJ Rendah';
      case djjTinggi:
        return 'DJJ Tinggi';
      default:
        return 'Normal';
    }
  }
}

class ExaminationModel {
  final String id;
  final String patientId;
  final String kaderId;
  final String kaderNama;
  final String bidanId;
  final DateTime tanggal;
  final int usiaKehamilan;

  // Tensi
  final int sistolik;
  final int diastolik;

  // Antropometri
  final double beratBadan;
  final double tinggiBadan;
  final double lingkarLengan;
  final double? lingkarPerut;
  final double bmi; // auto-hitung
  final double kenaikanBb; // dari pemeriksaan sebelumnya

  // DJJ & Keluhan
  final int djj;
  final String? keluhanIbu;
  final String? catatanKader;
  final double? tfu;
  final List<String> keluhanList;
  final String? keluhanLainnya;

  // Output Rule Engine
  final String statusIbu;
  final String statusJanin;
  final List<String> rekomendasi;
  final List<String> ruleTriggered;

  final DateTime createdAt;

  const ExaminationModel({
    required this.id,
    required this.patientId,
    required this.kaderId,
    required this.kaderNama,
    required this.bidanId,
    required this.tanggal,
    required this.usiaKehamilan,
    required this.sistolik,
    required this.diastolik,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.lingkarLengan,
    this.lingkarPerut,
    required this.bmi,
    required this.kenaikanBb,
    required this.djj,
    this.keluhanIbu,
    this.catatanKader,
    this.tfu,
    required this.keluhanList,
    this.keluhanLainnya,
    required this.statusIbu,
    required this.statusJanin,
    required this.rekomendasi,
    required this.ruleTriggered,
    required this.createdAt,
  });

  bool get isRisikoTinggi => statusIbu == ExaminationStatus.risikoTinggi;
  bool get isDjjAbnormal => statusJanin != JaninStatus.normal;

  factory ExaminationModel.fromJson(Map<String, dynamic> json) {
    return ExaminationModel(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      kaderId: json['kaderId'] as String? ?? '',
      kaderNama: json['kaderNama'] as String? ?? '',
      bidanId: json['bidanId'] as String? ?? '',
      tanggal: (json['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usiaKehamilan: (json['usiaKehamilan'] as num?)?.toInt() ?? 0,
      sistolik: (json['sistolik'] as num?)?.toInt() ?? 0,
      diastolik: (json['diastolik'] as num?)?.toInt() ?? 0,
      beratBadan: (json['beratBadan'] as num?)?.toDouble() ?? 0.0,
      tinggiBadan: (json['tinggiBadan'] as num?)?.toDouble() ?? 0.0,
      lingkarLengan: (json['lingkarLengan'] as num?)?.toDouble() ?? 0.0,
      lingkarPerut: (json['lingkarPerut'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      kenaikanBb: (json['kenaikanBb'] as num?)?.toDouble() ?? 0.0,
      djj: (json['djj'] as num?)?.toInt() ?? 0,
      keluhanIbu: json['keluhanIbu'] as String?,
      catatanKader: json['catatanKader'] as String?,
      tfu: (json['tfu'] as num?)?.toDouble(),
      keluhanList: List<String>.from(json['keluhanList'] as List? ?? []),
      keluhanLainnya: json['keluhanLainnya'] as String?,
      statusIbu: json['statusIbu'] as String? ?? ExaminationStatus.normal,
      statusJanin: json['statusJanin'] as String? ?? JaninStatus.normal,
      rekomendasi: List<String>.from(json['rekomendasi'] as List? ?? []),
      ruleTriggered: List<String>.from(json['ruleTriggered'] as List? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'kaderId': kaderId,
        'kaderNama': kaderNama,
        'bidanId': bidanId,
        'tanggal': Timestamp.fromDate(tanggal),
        'usiaKehamilan': usiaKehamilan,
        'sistolik': sistolik,
        'diastolik': diastolik,
        'beratBadan': beratBadan,
        'tinggiBadan': tinggiBadan,
        'lingkarLengan': lingkarLengan,
        'lingkarPerut': lingkarPerut,
        'bmi': bmi,
        'kenaikanBb': kenaikanBb,
        'djj': djj,
        'keluhanIbu': keluhanIbu,
        'catatanKader': catatanKader,
        'tfu': tfu,
        'keluhanList': keluhanList,
        'keluhanLainnya': keluhanLainnya,
        'statusIbu': statusIbu,
        'statusJanin': statusJanin,
        'rekomendasi': rekomendasi,
        'ruleTriggered': ruleTriggered,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ExaminationModel copyWith({
    String? id,
    String? patientId,
    String? kaderId,
    String? kaderNama,
    String? bidanId,
    DateTime? tanggal,
    int? usiaKehamilan,
    int? sistolik,
    int? diastolik,
    double? beratBadan,
    double? tinggiBadan,
    double? lingkarLengan,
    double? lingkarPerut,
    double? bmi,
    double? kenaikanBb,
    int? djj,
    String? keluhanIbu,
    String? catatanKader,
    double? tfu,
    List<String>? keluhanList,
    String? keluhanLainnya,
    String? statusIbu,
    String? statusJanin,
    List<String>? rekomendasi,
    List<String>? ruleTriggered,
    DateTime? createdAt,
  }) {
    return ExaminationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      kaderId: kaderId ?? this.kaderId,
      kaderNama: kaderNama ?? this.kaderNama,
      bidanId: bidanId ?? this.bidanId,
      tanggal: tanggal ?? this.tanggal,
      usiaKehamilan: usiaKehamilan ?? this.usiaKehamilan,
      sistolik: sistolik ?? this.sistolik,
      diastolik: diastolik ?? this.diastolik,
      beratBadan: beratBadan ?? this.beratBadan,
      tinggiBadan: tinggiBadan ?? this.tinggiBadan,
      lingkarLengan: lingkarLengan ?? this.lingkarLengan,
      lingkarPerut: lingkarPerut ?? this.lingkarPerut,
      bmi: bmi ?? this.bmi,
      kenaikanBb: kenaikanBb ?? this.kenaikanBb,
      djj: djj ?? this.djj,
      keluhanIbu: keluhanIbu ?? this.keluhanIbu,
      catatanKader: catatanKader ?? this.catatanKader,
      tfu: tfu ?? this.tfu,
      keluhanList: keluhanList ?? this.keluhanList,
      keluhanLainnya: keluhanLainnya ?? this.keluhanLainnya,
      statusIbu: statusIbu ?? this.statusIbu,
      statusJanin: statusJanin ?? this.statusJanin,
      rekomendasi: rekomendasi ?? this.rekomendasi,
      ruleTriggered: ruleTriggered ?? this.ruleTriggered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ExaminationModel(id: $id, patientId: $patientId, tanggal: $tanggal, statusIbu: $statusIbu)';
}
