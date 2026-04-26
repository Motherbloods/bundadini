import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_model.dart';
import '../models/kader_history_model.dart';
import '../services/cloudinary_service.dart';

class PatientRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<List<PatientModel>> fetchByKader(String kaderId) async {
    final snap = await _db
        .collection('patients')
        .where('kaderId', isEqualTo: kaderId)
        // .where('status', isEqualTo: 'aktif')
        .orderBy('nama')
        .get();
    return snap.docs
        .map((d) => PatientModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<List<PatientModel>> fetchAll(String bidanId) async {
    final snap = await _db
        .collection('patients')
        .where('bidanId', isEqualTo: bidanId)
        .orderBy('nama')
        .get();

    return snap.docs
        .map((d) => PatientModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<PatientModel?> findByNik(String nik) async {
    final snap = await _db
        .collection('patients')
        .where('nik', isEqualTo: nik)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return PatientModel.fromJson({...d.data(), 'id': d.id});
  }

  Future<PatientModel?> fetchById(String patientId) async {
    final doc = await _db.collection('patients').doc(patientId).get();
    if (!doc.exists) return null;
    return PatientModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<PatientModel> create(PatientModel patient, File fotoFile) async {
    final id = _uuid.v4();
    final fotoUrl = await _uploadFoto(id, fotoFile);
    final now = DateTime.now();

    final kaderDoc = await _db.collection('users').doc(patient.kaderId).get();
    final bidanId = kaderDoc.data()?['createdBy'] as String? ?? '';

    final newPatient = patient.copyWith(
      id: id,
      fotoUrl: fotoUrl,
      bidanId: bidanId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection('patients').doc(id).set(newPatient.toJson());

    await _addKaderHistory(id, patient.kaderId, '');

    return newPatient;
  }

  Future<PatientModel> update(PatientModel patient, {File? fotoFile}) async {
    String fotoUrl = patient.fotoUrl;
    if (fotoFile != null) {
      fotoUrl = await _uploadFoto(patient.id, fotoFile);
    }

    final updated =
        patient.copyWith(fotoUrl: fotoUrl, updatedAt: DateTime.now());
    await _db.collection('patients').doc(patient.id).update(updated.toJson());
    return updated;
  }

  Future<void> transferKader({
    required String patientId,
    required String newKaderId,
    required String newKaderNama,
    required String oldKaderId,
    String? alasan,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();
    final patRef = _db.collection('patients').doc(patientId);

    final newKaderDoc = await _db.collection('users').doc(newKaderId).get();
    final newBidanId = newKaderDoc.data()?['createdBy'] as String? ?? '';

    batch.update(patRef, {
      'kaderId': newKaderId,
      'bidanId': newBidanId,
      'status': 'aktif',
      'updatedAt': Timestamp.fromDate(now),
    });

    final histSnap = await _db
        .collection('patients')
        .doc(patientId)
        .collection('kader_history')
        .where('tanggalSelesai', isNull: true)
        .get();

    for (final doc in histSnap.docs) {
      batch.update(doc.reference, {
        'tanggalSelesai': Timestamp.fromDate(now),
        'alasanPindah': alasan ?? '',
      });
    }

    final newHistRef = _db
        .collection('patients')
        .doc(patientId)
        .collection('kader_history')
        .doc(_uuid.v4());

    final newHist = KaderHistoryModel(
      id: newHistRef.id,
      kaderId: newKaderId,
      kaderNama: newKaderNama,
      tanggalMulai: now,
    );

    batch.set(newHistRef, newHist.toJson());

    await batch.commit();
  }

  Future<List<KaderHistoryModel>> fetchKaderHistory(String patientId) async {
    final snap = await _db
        .collection('patients')
        .doc(patientId)
        .collection('kader_history')
        .orderBy('tanggalMulai', descending: true)
        .get();
    return snap.docs
        .map((d) => KaderHistoryModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<String> _uploadFoto(String patientId, File file) async {
    return CloudinaryService.uploadFoto(file, patientId);
  }

  Future<void> _addKaderHistory(
      String patientId, String kaderId, String kaderNama) async {
    final ref = _db
        .collection('patients')
        .doc(patientId)
        .collection('kader_history')
        .doc(_uuid.v4());
    final hist = KaderHistoryModel(
      id: ref.id,
      kaderId: kaderId,
      kaderNama: kaderNama,
      tanggalMulai: DateTime.now(),
    );
    await ref.set(hist.toJson());
  }

  Future<void> tandaiSelesai(String patientId) async {
    await _db.collection('patients').doc(patientId).update({
      'status': 'selesai',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
