import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
// import '../../../data/models/examination_model.dart';
import '../../../data/models/patient_model.dart';
// import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
// import '../../_widgets/empty_state.dart';
import '../../_widgets/section_header.dart';
// import '../../_widgets/status_badge.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<PatientProvider>().loadPatient(widget.patientId);
    // context.read<ExaminationProvider>().loadHistory(widget.patientId);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patProv = context.watch<PatientProvider>();
    // final examProv = context.watch<ExaminationProvider>();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Biodata',
            onPressed: () => context.push('/kader/patients/${patient.id}/edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: AppStrings.biodata),
            Tab(text: AppStrings.riwayat),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BiodataTab(patient: patient),
          // _RiwayatTab(patientId: patient.id, examProv: examProv),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.medical_services_rounded),
            label: const Text(AppStrings.periksaSekarang),
            onPressed: () =>
                context.push('/kader/patients/${patient.id}/examine'),
          ),
        ),
      ),
    );
  }
}

// Tab Biodata
class _BiodataTab extends StatelessWidget {
  final PatientModel patient;
  const _BiodataTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Foto + nama
        Center(
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: patient.fotoUrl.isNotEmpty
                  ? Image.network(patient.fotoUrl,
                      width: 110, height: 110, fit: BoxFit.cover)
                  : Container(
                      width: 110,
                      height: 110,
                      color: AppColors.redPale,
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 60)),
            ),
            const SizedBox(height: 12),
            Text(patient.nama,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.redPale,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(patient.status.label,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
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
          _InfoItem('HPHT', DateFormatter.toDisplay(patient.hpht)),
          _InfoItem('Taksiran Persalinan',
              DateFormatter.toDisplay(DateFormatter.taksiran(patient.hpht))),
          _InfoItem('Usia Kehamilan Saat Ini',
              '${DateFormatter.usiaKehamilanMinggu(patient.hpht)} minggu'),
        ]),
        const SizedBox(height: 80),
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

// Tab Riwayat
// class _RiwayatTab extends StatelessWidget {
//   final String patientId;
//   final ExaminationProvider examProv;
//   const _RiwayatTab({required this.patientId, required this.examProv});

//   @override
//   Widget build(BuildContext context) {
//     if (examProv.isLoading) {
//       return const Center(
//           child: CircularProgressIndicator(color: AppColors.primary));
//     }
//     if (examProv.history.isEmpty) {
//       return const EmptyState(
//         icon: Icons.assignment_outlined,
//         title: 'Belum ada riwayat pemeriksaan',
//         subtitle: 'Ketuk "Periksa Sekarang" untuk mulai',
//       );
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//       itemCount: examProv.history.length,
//       itemBuilder: (ctx, i) => _ExamCard(exam: examProv.history[i]),
//     );
//   }
// }

// class _ExamCard extends StatelessWidget {
//   final ExaminationModel exam;
//   const _ExamCard({required this.exam});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 10),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () => context.push('/kader/examine/result', extra: exam.id),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child:
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Row(children: [
//               const Icon(Icons.calendar_today_rounded,
//                   size: 16, color: AppColors.textSecond),
//               const SizedBox(width: 6),
//               Text(DateFormatter.toDisplay(exam.tanggal),
//                   style: const TextStyle(
//                       fontWeight: FontWeight.w600, fontSize: 15)),
//               const Spacer(),
//               Text('${exam.usiaKehamilan} ${AppStrings.minggu}',
//                   style: const TextStyle(
//                       color: AppColors.textSecond, fontSize: 14)),
//             ]),
//             const SizedBox(height: 6),
//             Text('Kader: ${exam.kaderNama}',
//                 style:
//                     const TextStyle(color: AppColors.textSecond, fontSize: 13)),
//             const SizedBox(height: 10),
//             Row(children: [
//               Expanded(
//                   child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                     const Text('Kondisi Ibu',
//                         style: TextStyle(
//                             fontSize: 12, color: AppColors.textSecond)),
//                     const SizedBox(height: 4),
//                     StatusBadge(status: exam.statusIbu),
//                   ])),
//               Expanded(
//                   child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                     const Text('Kondisi Janin',
//                         style: TextStyle(
//                             fontSize: 12, color: AppColors.textSecond)),
//                     const SizedBox(height: 4),
//                     StatusBadge(status: exam.statusJanin, isJanin: true),
//                   ])),
//               const Icon(Icons.chevron_right_rounded,
//                   color: AppColors.textSecond),
//             ]),
//           ]),
//         ),
//       ),
//     );
//   }
// }
