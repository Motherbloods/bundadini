class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Bunda Dini';
  static const String appTagline = 'Monitoring Kesehatan Ibu Hamil';

  // Auth
  static const String login = 'Masuk';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String loginButton = 'Masuk';
  static const String loginFailed = 'Email atau kata sandi salah.';
  static const String loginLoading = 'Sedang masuk...';
  static const String logoutConfirm = 'Apakah Anda yakin ingin keluar?';

  // Role
  static const String roleBidan = 'Bidan';
  static const String roleKader = 'Kader';

  // Patient
  static const String pasien = 'Pasien';
  static const String tambahPasien = 'Tambah Pasien Baru';
  static const String editPasien = 'Edit Biodata Pasien';
  static const String cariPasien = 'Cari nama atau NIK...';
  static const String pasienKosong = 'Belum ada pasien terdaftar';
  static const String nikLabel = 'NIK (16 digit)';
  static const String namaLabel = 'Nama Lengkap';
  static const String tempatLahirLabel = 'Tempat Lahir';
  static const String tglLahirLabel = 'Tanggal Lahir';
  static const String alamatLabel = 'Alamat Lengkap';
  static const String noHpLabel = 'Nomor HP';
  static const String hphtLabel = 'HPHT (Hari Pertama Haid Terakhir)';
  static const String golDarahLabel = 'Golongan Darah';
  static const String fotoLabel = 'Foto Pasien';
  static const String fotoWajib = 'Foto pasien wajib diisi';
  static const String ambilFoto = 'Ambil Foto';
  static const String pilihGaleri = 'Pilih dari Galeri';
  static const String nikDuplikat = 'NIK sudah terdaftar';
  static const String transferKader = 'Transfer ke Kader Saya';
  static const String batalTransfer = 'Batal';

  // Status Pasien
  static const String statusAktif = 'Aktif';
  static const String statusPindah = 'Pindah';
  static const String statusSelesai = 'Selesai';

  // Examination
  static const String periksa = 'Pemeriksaan';
  static const String periksaSekarang = 'Periksa Sekarang';
  static const String simpanPemeriksaan = 'Simpan Pemeriksaan';
  static const String riwayatPemeriksaan = 'Riwayat Pemeriksaan';
  static const String hasilPemeriksaan = 'Hasil Pemeriksaan';
  static const String step1Title = 'Usia Kehamilan';
  static const String step2Title = 'Tekanan Darah';
  static const String step3Title = 'Antropometri';
  static const String step4Title = 'DJJ & Keluhan';

  // Form Fields
  static const String usiaKehamilanLabel = 'Usia Kehamilan (minggu)';
  static const String sistolikLabel = 'Sistolik (mmHg)';
  static const String diastolikLabel = 'Diastolik (mmHg)';
  static const String beratBadanLabel = 'Berat Badan (kg)';
  static const String tinggiBadanLabel = 'Tinggi Badan (cm)';
  static const String lingkarLenganLabel = 'Lingkar Lengan Atas / LILA (cm)';
  static const String lingkarPerutLabel = 'Lingkar Perut (cm) — Opsional';
  static const String djjLabel = 'Denyut Jantung Janin / DJJ (bpm)';
  static const String keluhanLabel = 'Keluhan Ibu — Opsional';
  static const String catatanKaderLabel = 'Catatan Kader — Opsional';
  static const String bmiLabel = 'BMI (auto-hitung)';
  static const String kenaikanBbLabel =
      'Kenaikan BB dari pemeriksaan sebelumnya';
  static const String tfuLabel = 'TFU / Tinggi Fundus Uteri (cm) — Opsional';

  // Status Pemeriksaan
  static const String statusNormal = 'Normal';
  static const String statusPerluPerhatian = 'Perlu Perhatian';
  static const String statusRisikoTinggi = 'Risiko Tinggi';
  static const String statusDjjNormal = 'DJJ Normal';
  static const String statusDjjRendah = 'DJJ Rendah';
  static const String statusDjjTinggi = 'DJJ Tinggi';
  static const String statusKek = 'KEK';
  static const String statusLilaNormal = 'LILA Normal';

  // Result Labels
  static const String kondisiIbu = 'Kondisi Ibu';
  static const String kondisiJanin = 'Kondisi Janin';
  static const String rekomendasi = 'Rekomendasi';
  static const String segeraKonsul =
      '🚨 Segera konsultasikan ke tenaga kesehatan!';

  // PDF
  static const String cetakPdf = 'Cetak PDF';
  static const String nantiSaja = 'Nanti Saja';
  static const String cetakSekarang = 'Cetak laporan sekarang?';
  static const String berhasilDisimpan = '✅ Pemeriksaan Berhasil Disimpan!';
  static const String defaultPuskesmas = 'Posyandu Bunda Dini';
  static const String laporanPemeriksaan = 'LAPORAN PEMERIKSAAN IBU HAMIL';
  static const String diperiksaOleh = 'Diperiksa oleh';
  static const String mengetahuiBidan = 'Mengetahui, Bidan Pendamping';

  // Dashboard Bidan
  static const String totalIbu = 'Total Ibu';
  static const String pemeriksaanBulanIni = 'Pemeriksaan\nBulan Ini';
  static const String ibuRisikoTinggi = 'Ibu Risiko\nTinggi';
  static const String kaderAktif = 'Kader Aktif';
  static const String alertRisiko =
      'Ibu Risiko Tinggi — Memerlukan perhatian segera';
  static const String statistik6Bulan = 'Statistik 6 Bulan Terakhir';

  // Menu
  static const String kelolaKader = 'Kelola Kader';
  static const String exportExcel = 'Export Excel';
  static const String semuaPasien = 'Semua Pasien';
  static const String profilBidan = 'Profil Bidan';

  // Kader Management
  static const String tambahKader = 'Tambah Kader';
  static const String daftarKader = 'Daftar Kader';
  static const String kaderKosong = 'Belum ada kader terdaftar';
  static const String namaPuskesmasLabel = 'Nama Puskesmas (opsional)';

  // Export
  static const String eksporData = 'Export Data';
  static const String filterTanggal = 'Filter Tanggal';
  static const String tanggalMulai = 'Tanggal Mulai';
  static const String tanggalSelesai = 'Tanggal Selesai';
  static const String exportExcelBtn = 'Export Excel (.xlsx)';
  static const String exportPdfBtn = 'Export PDF Rekap';
  static const String prosesExport = 'Sedang menyiapkan file...';

  // Grafik
  static const String grafikTren = 'Grafik Tren';
  static const String grafikBb = 'Berat Badan';
  static const String grafikTensi = 'Tekanan Darah';
  static const String grafikDjj = 'DJJ';

  // General
  static const String simpan = 'Simpan';
  static const String batal = 'Batal';
  static const String hapus = 'Hapus';
  static const String edit = 'Edit';
  static const String ya = 'Ya';
  static const String tidak = 'Tidak';
  static const String kembali = 'Kembali';
  static const String kembaliBeranda = 'Kembali ke Beranda';
  static const String lanjut = 'Lanjut';
  static const String selesai = 'Selesai';
  static const String loading = 'Memuat...';
  static const String berhasilDisimpanGeneral = 'Data berhasil disimpan';
  static const String gagalSimpan = 'Gagal menyimpan data';
  static const String dataTidakDitemukan = 'Data tidak ditemukan';
  static const String wajibDiisi = 'Wajib diisi';
  static const String formatTidakValid = 'Format tidak valid';
  static const String pilihTanggal = 'Pilih Tanggal';
  static const String biodata = 'Biodata';
  static const String riwayat = 'Riwayat';
  static const String profil = 'Profil';
  static const String tanggal = 'Tanggal';
  static const String minggu = 'minggu';
  static const String kader = 'Kader';

  static const List<String> daftarKeluhan = [
    'Pusing / sakit kepala',
    'Mual / muntah',
    'Nyeri perut',
    'Sesak napas',
    'Bengkak pada kaki',
    'Bengkak pada tangan/wajah',
    'Perdarahan',
    'Gerak janin berkurang',
    'Nyeri punggung',
    'Susah tidur',
    'Lemas / mudah lelah',
    'Demam',
    'Gatal-gatal',
    'Keputihan abnormal',
  ];
}
