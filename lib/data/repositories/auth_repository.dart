import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get firebaseUser => _auth.currentUser;

  /// Login dengan email & password, return UserModel
  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _fetchUserModel(cred.user!.uid);
  }

  /// Logout
  Future<void> logout() async => _auth.signOut();

  /// Fetch UserModel dari Firestore berdasarkan uid
  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Data pengguna tidak ditemukan.');
    return UserModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Ambil UserModel saat ini (untuk re-auth setelah app restart)
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserModel(user.uid);
    } catch (_) {
      return null;
    }
  }

  /// Bidan mendaftarkan kader baru
  Future<void> registerKader({
    required String email,
    required String password,
    required String nama,
    required String createdBy,
  }) async {
    // Buat akun Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // Simpan data ke Firestore
    final kader = UserModel(
      id: uid,
      email: email.trim(),
      nama: nama.trim(),
      role: UserRole.kader,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      isActive: true,
    );
    await _db.collection('users').doc(uid).set(kader.toJson());
  }

  /// Ambil semua kader milik bidan ini
  Future<List<UserModel>> fetchKaders(String bidanId) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'kader')
        .where('createdBy', isEqualTo: bidanId)
        .get();
    return snap.docs
        .map((d) => UserModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Update profil pengguna (nama, namaPuskesmas, photoUrl)
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Nonaktifkan kader (soft delete)
  Future<void> deactivateKader(String kaderId) async {
    await _db.collection('users').doc(kaderId).update({'isActive': false});
  }
}
