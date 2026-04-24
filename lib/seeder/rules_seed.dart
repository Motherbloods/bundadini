import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedRules() async {
  final db = FirebaseFirestore.instance;

  final rules = <String, dynamic>{
    "rule_001": {
      "kondisiField": "sistolik",
      "kondisiOperator": ">=",
      "kondisiValue": 140,
      "namaRule": "Hipertensi Sistolik",
      "rekomendasi":
          "Tekanan darah sistolik tinggi. Segera rujuk ke bidan atau puskesmas.",
      "severity": "danger",
      "aktif": true,
    },
    "rule_002": {
      "kondisiField": "sistolik",
      "kondisiOperator": "<",
      "kondisiValue": 90,
      "namaRule": "Hipotensi Sistolik",
      "rekomendasi":
          "Tekanan darah rendah. Anjurkan istirahat dan minum air putih cukup.",
      "severity": "warning",
      "aktif": true,
    },
    "rule_003": {
      "kondisiField": "diastolik",
      "kondisiOperator": ">=",
      "kondisiValue": 90,
      "namaRule": "Hipertensi Diastolik",
      "rekomendasi":
          "Tekanan diastolik tinggi. Pantau tekanan darah setiap hari.",
      "severity": "danger",
      "aktif": true,
    },
    "rule_004": {
      "kondisiField": "djj",
      "kondisiOperator": "<",
      "kondisiValue": 110,
      "namaRule": "DJJ Rendah",
      "rekomendasi":
          "DJJ di bawah normal. Segera konsultasi ke tenaga kesehatan.",
      "severity": "danger",
      "aktif": true,
    },
    "rule_005": {
      "kondisiField": "djj",
      "kondisiOperator": ">",
      "kondisiValue": 160,
      "namaRule": "DJJ Tinggi",
      "rekomendasi":
          "DJJ di atas normal. Anjurkan istirahat dan periksa ke bidan.",
      "severity": "danger",
      "aktif": true,
    },
    "rule_006": {
      "kondisiField": "lingkar_lengan",
      "kondisiOperator": "<",
      "kondisiValue": 23.5,
      "namaRule": "KEK",
      "rekomendasi":
          "Risiko KEK. Tingkatkan asupan gizi dan konsultasi ahli gizi.",
      "severity": "warning",
      "aktif": true,
    },
    "rule_007": {
      "kondisiField": "bmi",
      "kondisiOperator": "<",
      "kondisiValue": 18.5,
      "namaRule": "BMI Kurang",
      "rekomendasi": "Berat badan kurang. Tingkatkan asupan kalori.",
      "severity": "warning",
      "aktif": true,
    },
    "rule_008": {
      "kondisiField": "bmi",
      "kondisiOperator": ">=",
      "kondisiValue": 30,
      "namaRule": "Obesitas",
      "rekomendasi": "BMI tinggi. Konsultasi diet aman selama kehamilan.",
      "severity": "warning",
      "aktif": true,
    },
  };

  for (final entry in rules.entries) {
    await db.collection('rules').doc(entry.key).set(entry.value);
  }

  print("🔥 Rules berhasil di-seed");
}
