class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field ini'} wajib diisi';
    }
    return null;
  }

  static String? nik(String? value) {
    if (value == null || value.trim().isEmpty) return 'NIK wajib diisi';
    if (value.trim().length != 16) return 'NIK harus 16 digit';
    if (!RegExp(r'^\d{16}$').hasMatch(value.trim())) {
      return 'NIK hanya boleh angka';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 6) return 'Kata sandi minimal 6 karakter';
    return null;
  }

  static String? noHp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nomor HP wajib diisi';
    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+62|62|0)[0-9]{8,12}$').hasMatch(clean)) {
      return 'Format nomor HP tidak valid';
    }
    return null;
  }

  static String? intRange(String? value, int min, int max, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    final n = int.tryParse(value.trim());
    if (n == null) return '$label harus berupa angka';
    if (n < min || n > max) return '$label harus antara $min–$max';
    return null;
  }

  static String? doubleRange(
      String? value, double min, double max, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    if (n == null) return '$label harus berupa angka';
    if (n < min || n > max) return '$label harus antara $min–$max';
    return null;
  }

  // Shortcut validators untuk form pemeriksaan
  static String? sistolik(String? v) => intRange(v, 60, 250, 'Sistolik');
  static String? diastolik(String? v) => intRange(v, 40, 180, 'Diastolik');
  static String? djj(String? v) => intRange(v, 50, 200, 'DJJ');
  static String? beratBadan(String? v) =>
      doubleRange(v, 20, 200, 'Berat badan');
  static String? tinggiBadan(String? v) =>
      doubleRange(v, 100, 250, 'Tinggi badan');
  static String? lingkarLengan(String? v) => doubleRange(v, 10, 50, 'LILA');
  static String? usiaKehamilan(String? v) =>
      intRange(v, 1, 45, 'Usia kehamilan');
}
