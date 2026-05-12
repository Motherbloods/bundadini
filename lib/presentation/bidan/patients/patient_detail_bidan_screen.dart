import 'package:bundadini/data/repositories/auth_repository.dart';
import 'package:bundadini/presentation/_widgets/network_image_fallback.dart';
import 'package:bundadini/presentation/_widgets/photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/section_header.dart';

class PatientDetailBidanScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailBidanScreen({super.key, required this.patientId});
  @override
  State<PatientDetailBidanScreen> createState() =>
      _PatientDetailBidanScreenState();
}

class _PatientDetailBidanScreenState extends State<PatientDetailBidanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _authRepo = AuthRepository();
  String _kaderNama = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final patientProvider = context.read<PatientProvider>();
      final examProvider = context.read<ExaminationProvider>();

      await patientProvider.loadPatient(widget.patientId);
      examProvider.loadHistory(widget.patientId);

      if (!mounted) return;
      await _fetchKaderNama();
    });
  }

  Future<void> _fetchKaderNama() async {
    final patient = context.read<PatientProvider>().selectedPatient;
    if (patient == null) return;

    final kader = await _authRepo.fetchUserById(patient.kaderId);
    if (mounted) {
      setState(() {
        _kaderNama = kader?.nama ?? 'Tidak ditemukan';
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patProv = context.watch<PatientProvider>();
    final patient = patProv.selectedPatient;

    if (patProv.isLoading || patient == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: AppStrings.biodata),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tab,
          children: [
            _BiodataBidanTab(patient: patient, kaderNama: _kaderNama),
          ],
        ),
      ),
    );
  }
}

class _BiodataBidanTab extends StatelessWidget {
  final PatientModel patient;
  final String kaderNama;
  const _BiodataBidanTab({required this.patient, required this.kaderNama});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Column(children: [
            GestureDetector(
              onTap: () {
                if (patient.fotoUrl.isNotEmpty) {
                  PhotoViewer.show(
                    context,
                    imageUrl: patient.fotoUrl,
                    nama: patient.nama,
                    heroTag: 'bidan-patient-${patient.id}',
                  );
                }
              },
              child: Hero(
                tag: 'bidan-patient-${patient.id}',
                child: NetworkImageFallback(
                  url: patient.fotoUrl,
                  width: 110,
                  height: 110,
                  borderRadius: BorderRadius.circular(20),
                  fallbackIcon: Icons.person_rounded,
                ),
              ),
            ),
            if (patient.fotoUrl.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded,
                        size: 14, color: AppColors.textSecond),
                    SizedBox(width: 4),
                    Text(
                      'Ketuk foto untuk perbesar',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSecond),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              patient.nama,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.redPale,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                patient.status.label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Data Diri'),
        const SizedBox(height: 12),
        _InfoCard(items: [
          _InfoItem('NIK', patient.nik),
          _InfoItem('Tempat Lahir', patient.tempatLahir),
          _InfoItem(
              'Tanggal Lahir', DateFormatter.toDisplay(patient.tanggalLahir)),
          _InfoItem('Usia', DateFormatter.ageFromDate(patient.tanggalLahir)),
          _InfoItem('Golongan Darah', patient.golonganDarah.value),
          _InfoItem('Nomor HP', patient.noHp),
          _InfoItem('Alamat', patient.alamat),
        ]),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Data Kehamilan'),
        const SizedBox(height: 12),
        _InfoCard(items: [
          _InfoItem(
            'HPHT',
            patient.hpht != null
                ? DateFormatter.toDisplay(patient.hpht!)
                : 'Belum diisi',
          ),
          _InfoItem(
            'Taksiran Persalinan',
            patient.hpht != null
                ? DateFormatter.toDisplay(
                    DateFormatter.taksiran(patient.hpht!)!)
                : 'Tersedia setelah HPHT diisi',
          ),
          _InfoItem(
            'Usia Kehamilan Saat Ini',
            patient.hpht != null
                ? '${DateFormatter.usiaKehamilanMinggu(patient.hpht!)} minggu'
                : 'Tersedia setelah HPHT diisi',
          ),
        ]),
        if (patient.hpht == null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4))),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'HPHT belum diisi. Minta kader untuk melengkapi data pasien.',
                  style: TextStyle(color: AppColors.warning, fontSize: 13),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Data Penanganan'),
        const SizedBox(height: 12),
        _InfoCard(items: [
          _InfoItem('Kader Saat Ini', kaderNama),
          _InfoItem('Status Pasien', patient.status.label),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.bar_chart_rounded),
          label: const Text('Riwayat & Grafik Pemeriksaan'),
          onPressed: () =>
              context.push('/bidan/patients/${patient.id}/history'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (patient.status == StatusPasien.selesai)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✨ Pasien sudah melahirkan',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: items
              .map((item) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 140,
                                child: Text(item.label,
                                    style: const TextStyle(
                                        color: AppColors.textSecond,
                                        fontSize: 14))),
                            Expanded(
                                child: Text(item.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15))),
                          ]),
                    ),
                    if (item != items.last)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label, value;
  const _InfoItem(this.label, this.value);
}
