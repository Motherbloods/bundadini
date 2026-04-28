import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/logo.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bunda Dini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Deteksi Dini Risiko Ibu Hamil',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Versi 1.0.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                  const _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Bunda Dini',
                    children: [
                      _BodyText(
                        'Bunda Dini adalah aplikasi pemantauan kesehatan ibu hamil '
                        'yang dikembangkan untuk mendukung program pengabdian masyarakat.',
                      ),
                      SizedBox(height: 10),
                      _BodyText(
                        'Aplikasi ini membantu kader posyandu untuk mencatat dan memantau '
                        'kondisi ibu hamil secara terstruktur, serta memberikan rekomendasi '
                        'dini berdasarkan hasil pemeriksaan.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Pengguna Aplikasi',
                    children: [
                      _FeatureRow(
                        icon: Icons.medical_services_rounded,
                        color: AppColors.primary,
                        label: 'Bidan',
                        desc:
                            'Memantau seluruh data pasien, mengelola kader, dan mengekspor laporan.',
                      ),
                      SizedBox(height: 12),
                      _FeatureRow(
                        icon: Icons.people_rounded,
                        color: AppColors.info,
                        label: 'Kader Posyandu',
                        desc:
                            'Mendaftarkan ibu hamil, dan melakukan pemeriksaan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.star_rounded,
                    title: 'Fitur Utama',
                    children: [
                      _BulletItem('Pendataan ibu hamil dengan foto'),
                      _BulletItem('Pemeriksaan: tensi, BB, TB, LILA, DJJ'),
                      _BulletItem(
                          'Deteksi risiko otomatis berdasarkan rule engine'),
                      _BulletItem('Grafik tren kesehatan ibu hamil'),
                      _BulletItem('Cetak laporan PDF per pemeriksaan'),
                      _BulletItem('Export rekap Excel dan PDF untuk bidan'),
                      _BulletItem('Transfer pasien antar kader'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dibuat dengan ❤️ untuk mendukung kesehatan ibu hamil di Indonesia.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.redPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecond,
        height: 1.6,
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecond, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecond, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textSecond)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
