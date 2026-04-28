import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kebijakan Pengguna'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kebijakan Pengguna',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Text(
                          //   'Berlaku sejak: Januari 2025',
                          //   style:
                          //       TextStyle(color: Colors.white70, fontSize: 13),
                          // ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Harap baca kebijakan ini dengan seksama sebelum menggunakan aplikasi Bunda Dini.',
                      style: TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PolicySection(
                    number: '1',
                    icon: Icons.info_outline_rounded,
                    title: 'Penggunaan Aplikasi',
                    content: [
                      'Aplikasi Bunda Dini hanya diperuntukkan bagi kader posyandu '
                          'dan bidan yang terdaftar dalam program pemantauan kesehatan '
                          'ibu hamil di wilayah yang bersangkutan.',
                      'Akun pengguna bersifat pribadi dan tidak boleh dipinjamkan '
                          'atau dibagikan kepada orang lain.',
                      'Pengguna wajib menggunakan aplikasi sesuai fungsinya, yaitu '
                          'untuk pencatatan dan pemantauan kesehatan ibu hamil.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '2',
                    icon: Icons.lock_outline_rounded,
                    title: 'Kerahasiaan Data Pasien',
                    content: [
                      'Seluruh data ibu hamil yang dicatat dalam aplikasi ini '
                          'bersifat RAHASIA dan dilindungi.',
                      'Pengguna dilarang keras membagikan, menyebarluaskan, atau '
                          'memperlihatkan data pasien kepada pihak yang tidak berkepentingan.',
                      'Data pasien hanya boleh digunakan untuk keperluan pemantauan '
                          'kesehatan dalam program posyandu.',
                      'Foto dan informasi pribadi ibu hamil wajib dijaga kerahasiaannya '
                          'sesuai dengan etika pelayanan kesehatan.',
                    ],
                    isHighlight: true,
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '3',
                    icon: Icons.storage_rounded,
                    title: 'Penyimpanan & Keamanan Data',
                    content: [
                      'Data disimpan dengan aman dan hanya digunakan untuk keperluan pelayanan kesehatan.',
                      'Foto pasien disimpan secara terlindungi dan tidak dibagikan tanpa izin.',
                      'Pengguna bertanggung jawab menjaga kerahasiaan kata sandi akun masing-masing.',
                      'Jika kata sandi hilang atau akun dicurigai digunakan pihak lain, segera hubungi bidan penanggung jawab.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '4',
                    icon: Icons.medical_services_rounded,
                    title: 'Batasan Layanan Medis',
                    content: [
                      'Aplikasi ini adalah alat BANTU pemantauan, bukan pengganti '
                          'pemeriksaan medis oleh tenaga kesehatan profesional.',
                      'Rekomendasi yang dihasilkan aplikasi bersifat indikatif dan '
                          'harus dikonfirmasi oleh bidan atau dokter.',
                      'Jika ditemukan kondisi risiko tinggi, segera rujuk pasien ke '
                          'fasilitas kesehatan terdekat.',
                    ],
                    isHighlight: true,
                    highlightColor: AppColors.warning,
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '5',
                    icon: Icons.edit_note_rounded,
                    title: 'Akurasi Data',
                    content: [
                      'Pengguna wajib memasukkan data pemeriksaan dengan jujur '
                          'dan akurat sesuai hasil pengukuran yang sebenarnya.',
                      'Kesalahan input data dapat memengaruhi hasil deteksi risiko '
                          'dan membahayakan keselamatan ibu hamil.',
                      'Jika terjadi kesalahan input, segera hubungi bidan untuk '
                          'koreksi data.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '6',
                    icon: Icons.update_rounded,
                    title: 'Perubahan Kebijakan',
                    content: [
                      'Kebijakan ini dapat diperbarui sewaktu-waktu sesuai kebutuhan '
                          'program dan perkembangan regulasi.',
                      'Pengguna akan diberitahu mengenai perubahan kebijakan yang '
                          'signifikan melalui bidan penanggung jawab.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _PolicySection(
                    number: '7',
                    icon: Icons.contact_support_rounded,
                    title: 'Kontak & Bantuan',
                    content: [
                      'Untuk pertanyaan mengenai kebijakan ini atau masalah teknis '
                          'aplikasi, silakan hubungi bidan penanggung jawab di wilayah Anda.',
                      'Lupa kata sandi? Hubungi bidan untuk reset akun.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.primary, size: 32),
                        SizedBox(height: 10),
                        Text(
                          'Dengan menggunakan aplikasi Bunda Dini, Anda dianggap telah membaca, '
                          'memahami, dan menyetujui seluruh kebijakan penggunaan ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final List<String> content;
  final bool isHighlight;
  final Color highlightColor;

  const _PolicySection({
    required this.number,
    required this.icon,
    required this.title,
    required this.content,
    this.isHighlight = false,
    this.highlightColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isHighlight
              ? highlightColor.withValues(alpha: 0.3)
              : const Color(0xFFE0E0E0),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      color: isHighlight
          ? highlightColor.withValues(alpha: 0.04)
          : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon,
                    color: isHighlight ? highlightColor : AppColors.primary,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isHighlight ? highlightColor : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...content.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 6,
                            color: isHighlight
                                ? highlightColor
                                : AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecond,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
