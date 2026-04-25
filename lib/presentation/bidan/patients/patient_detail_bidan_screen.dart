import 'package:bundadini/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/empty_state.dart';
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
    _tab = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PatientProvider>().loadPatient(widget.patientId);

      context.read<ExaminationProvider>().loadHistory(widget.patientId);

      await _fetchKaderNama();
    });
  }

  Future<void> _fetchKaderNama() async {
    print('Mencari nama kader untuk pasien ${widget.patientId}...');
    final patient = context.read<PatientProvider>().selectedPatient;
    print('Data pasien: ${patient?.nama}, Kader ID: ${patient?.kaderId}');
    if (patient == null) return;

    final kader = await _authRepo.fetchUserById(patient.kaderId);
    print('Kader ID: ${patient.kaderId}, Nama: ${kader?.nama}');
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
    final examProv = context.watch<ExaminationProvider>();
    final patient = patProv.selectedPatient;

    if (patient == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    // Kelompokkan riwayat pemeriksaan per kader
    final Map<String, List<_ExamGroup>> grouped = {};
    for (final e in examProv.history) {
      grouped.putIfAbsent(e.kaderId, () => []);
      grouped[e.kaderId]!.add(_ExamGroup(e.kaderNama, e));
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
            Tab(text: AppStrings.riwayat)
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Tab Biodata — info singkat
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoRow('NIK', patient.nik),
                _InfoRow('Tempat Lahir', patient.tempatLahir),
                _InfoRow('Tanggal Lahir',
                    DateFormatter.toDisplay(patient.tanggalLahir)),
                _InfoRow('Nomor HP', patient.noHp),
                _InfoRow('Alamat', patient.alamat),
                _InfoRow('Gol Darah', patient.golonganDarah.value),
                _InfoRow('HPHT', DateFormatter.toDisplay(patient.hpht)),
                _InfoRow('Usia Kehamilan',
                    '${DateFormatter.usiaKehamilanMinggu(patient.hpht)} minggu'),
                _InfoRow('Kader Saat Ini', _kaderNama),
                _InfoRow('Status', patient.status.label),
              ]),
            )),
          ]),
        ),

        // Tab Riwayat per kader
        examProv.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : examProv.history.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada riwayat pemeriksaan')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: grouped.entries.map((entry) {
                        final items = entry.value;
                        final kaderNama = items.first.kaderNama;
                        final dates = items.map((i) => i.exam.tanggal).toList()
                          ..sort();
                        final start = DateFormatter.toDisplay(dates.first);
                        final end = DateFormatter.toDisplay(dates.last);

                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                  title: 'Kader $kaderNama ($start – $end)'),
                              const SizedBox(height: 8),
                              ...items.map(
                                  (item) => _RiwayatBidanCard(exam: item.exam)),
                              const SizedBox(height: 16),
                            ]);
                      }).toList(),
                    ),
                  ),
      ]),
    );
  }
}

class _ExamGroup {
  final String kaderNama;
  final dynamic exam;
  _ExamGroup(this.kaderNama, this.exam);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecond, fontSize: 14))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15))),
      ]),
    );
  }
}

class _RiwayatBidanCard extends StatelessWidget {
  final dynamic exam;
  const _RiwayatBidanCard({required this.exam});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/shared/examine/result', extra: exam.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.textSecond),
            const SizedBox(width: 6),
            Text(DateFormatter.toDisplay(exam.tanggal),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 8),
            Text('${exam.usiaKehamilan} minggu',
                style:
                    const TextStyle(color: AppColors.textSecond, fontSize: 13)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecond, size: 18),
          ]),
        ),
      ),
    );
  }
}
