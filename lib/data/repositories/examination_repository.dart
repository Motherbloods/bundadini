import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/examination_model.dart';

class ExaminationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Simpan pemeriksaan baru
  Future<ExaminationModel> save(ExaminationModel exam) async {
    final id = exam.id.isEmpty ? _uuid.v4() : exam.id;
    final withId = exam.copyWith(id: id, createdAt: DateTime.now());
    await _db.collection('examinations').doc(id).set(withId.toJson());
    return withId;
  }

  /// Riwayat pemeriksaan satu pasien, terbaru dulu
  Future<List<ExaminationModel>> fetchByPatient(String patientId) async {
    final snap = await _db
        .collection('examinations')
        .where('patientId', isEqualTo: patientId)
        .orderBy('tanggal', descending: true)
        .get();
    return snap.docs
        .map((d) => ExaminationModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Satu pemeriksaan by ID
  Future<ExaminationModel?> fetchById(String examId) async {
    final doc = await _db.collection('examinations').doc(examId).get();
    if (!doc.exists) return null;
    return ExaminationModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Pemeriksaan terakhir satu pasien (untuk hitung kenaikan BB)
  Future<ExaminationModel?> fetchLatestByPatient(String patientId) async {
    final snap = await _db
        .collection('examinations')
        .where('patientId', isEqualTo: patientId)
        .orderBy('tanggal', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return ExaminationModel.fromJson({...d.data(), 'id': d.id});
  }

  /// Semua pemeriksaan dalam range tanggal (untuk export bidan)
  Future<List<ExaminationModel>> fetchByDateRange(
      DateTime from, DateTime to) async {
    final snap = await _db
        .collection('examinations')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('tanggal', descending: true)
        .get();
    return snap.docs
        .map((d) => ExaminationModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Hitung total pemeriksaan bulan ini
  Future<int> countThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final snap = await _db
        .collection('examinations')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('tanggal', isLessThan: Timestamp.fromDate(end))
        .count()
        .get();
    return snap.count ?? 0;
  }
}
