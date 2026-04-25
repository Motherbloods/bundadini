import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  /// Bidan mendaftarkan kader baru.
  ///
  /// Menggunakan Secondary Firebase App agar sesi bidan TIDAK terganti
  /// saat [createUserWithEmailAndPassword] dipanggil.
  /// Firebase secara default akan auto sign-in ke akun yang baru dibuat —
  /// secondary app mengisolasi proses ini di instance terpisah.
  Future<void> registerKader({
    required String email,
    required String password,
    required String nama,
    required String createdBy,
  }) async {
    // Nama unik untuk secondary app — pakai timestamp agar tidak konflik
    // jika method ini dipanggil lebih dari sekali secara bersamaan.
    final appName = 'kader_register_${DateTime.now().millisecondsSinceEpoch}';

    FirebaseApp? secondaryApp;
    try {
      // 1. Inisialisasi secondary Firebase App dengan opsi yang sama
      //    dengan app utama — tidak perlu file konfigurasi tambahan.
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options, // pakai opsi dari app utama
      );

      // 2. Buat instance Auth yang terikat ke secondary app.
      //    Sesi bidan di instance utama (_auth) TIDAK terpengaruh.
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 3. Buat akun kader di secondary Auth — tidak mengganti sesi bidan.
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      // 4. Langsung sign-out dari secondary app —
      //    UID sudah didapat, sesi secondary tidak diperlukan lagi.
      await secondaryAuth.signOut();

      // 5. Simpan data kader ke Firestore (pakai _db utama, tidak masalah).
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
    } finally {
      // 6. Hapus secondary app dari memory — wajib agar tidak leak.
      //    Dilakukan di finally sehingga tetap bersih meski ada error.
      await secondaryApp?.delete();
    }
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

  Future<void> activateKader(String kaderId) async {
    await _db.collection('users').doc(kaderId).update({'isActive': true});
  }
}
