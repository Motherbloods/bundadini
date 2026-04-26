import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';

class UserSeeder {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Jalankan sekali untuk seed data awal
  Future<void> seed() async {
    // await _createBidan();
    await _createBidanLain();
    // await _createKaders();
    print("🔥 bidan dan kader berhasil di-seed");
  }

  Future<void> _createBidan() async {
    const email = 'bidan@demo.com';
    const password = 'password123';

    final existing = await _findUserByEmail(email);
    if (existing != null) return;

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final bidan = UserModel(
      id: uid,
      email: email,
      nama: 'Bidan Demo',
      role: UserRole.bidan,
      createdBy: '',
      createdAt: DateTime.now(),
      isActive: true,
      namaPuskesmas: 'Puskesmas Contoh',
    );

    await _db.collection('users').doc(uid).set(bidan.toJson());
  }

  Future<void> _createBidanLain() async {
    const email = 'bidan2@demo.com';
    const password = 'password123';

    final existing = await _findUserByEmail(email);
    if (existing != null) return;

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final bidan = UserModel(
      id: uid,
      email: email,
      nama: 'Bidan Dua',
      role: UserRole.bidan,
      createdBy: '',
      createdAt: DateTime.now(),
      isActive: true,
      namaPuskesmas: 'Puskesmas Contoh 2',
    );

    await _db.collection('users').doc(uid).set(bidan.toJson());
  }

  Future<void> _createKaders() async {
    const bidanEmail = 'bidan@demo.com';
    final bidan = await _findUserByEmail(bidanEmail);
    if (bidan == null) return;

    final kaderList = [
      {
        'email': 'kader1@demo.com',
        'nama': 'Kader Satu',
      },
      {
        'email': 'kader2@demo.com',
        'nama': 'Kader Dua',
      },
      {
        'email': 'kader3@demo.com',
        'nama': 'Kader Tiga',
      },
    ];

    for (final k in kaderList) {
      final existing = await _findUserByEmail(k['email']!);
      if (existing != null) continue;

      final cred = await _auth.createUserWithEmailAndPassword(
        email: k['email']!,
        password: 'password123',
      );

      final uid = cred.user!.uid;

      final kader = UserModel(
        id: uid,
        email: k['email']!,
        nama: k['nama']!,
        role: UserRole.kader,
        createdBy: bidan.id,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _db.collection('users').doc(uid).set(kader.toJson());
    }
  }

  Future<UserModel?> _findUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();

    return UserModel.fromJson({...data, 'id': snap.docs.first.id});
  }
}
