import 'package:bundadini/data/models/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/examination_repository.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/services/excel_service.dart';
import '../../../data/services/pdf_service.dart';
import '../../../data/models/examination_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/loading_overlay.dart';
import '../../_widgets/section_header.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _examRepo = ExaminationRepository();
  final _patientRepo = PatientRepository();

  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = false;
  String? _statusMsg;

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: isFrom ? 'Tanggal Mulai' : 'Tanggal Selesai',
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  Future<void> _exportExcel() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Mengambil data...';
    });
    try {
      final exams = await _examRepo.fetchByDateRange(_from, _to);
      final patients = await _patientRepo.fetchAll();
      setState(() => _statusMsg = 'Membuat file Excel...');
      await ExcelService.exportAndShare(
          examinations: exams, patients: patients, from: _from, to: _to);
      if (mounted) _showSuccess('File Excel berhasil diekspor.');
    } catch (e) {
      if (mounted) _showError('Gagal ekspor Excel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMsg = null;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Mengambil data...';
    });
    try {
      final exams = await _examRepo.fetchByDateRange(_from, _to);

      if (exams.isEmpty) {
        if (mounted) _showError('Tidak ada data di rentang tanggal ini.');
        return;
      }

      // Ambil hanya patient ID yang unik agar tidak fetch berulang
      final patientIds = exams.map((e) => e.patientId).toSet();
      final patientMap = <String, PatientModel>{};
      for (final id in patientIds) {
        final p = await _patientRepo.fetchById(id);
        if (p != null) patientMap[id] = p;
      }

      setState(() => _statusMsg = 'Membuat PDF...');

      final auth = context.read<AuthProvider>();
      final namaPuskesmas =
          auth.currentUser?.namaPuskesmas ?? AppStrings.defaultPuskesmas;
      final bidanNama = auth.currentUser?.nama ?? '';

      await _generateRekapPdf(
        exams: exams,
        patientMap: patientMap,
        namaPuskesmas: namaPuskesmas,
        bidanNama: bidanNama,
      );
      if (mounted) _showSuccess('PDF rekap berhasil diekspor.');
    } catch (e) {
      if (mounted) _showError('Gagal ekspor PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMsg = null;
        });
      }
    }
  }

  /// Membuat PDF rekap untuk SEMUA pemeriksaan dalam range tanggal.
  /// PdfService.generateRekapAndPrint menerima list lengkap, bukan hanya satu record.
  Future<void> _generateRekapPdf({
    required List<ExaminationModel> exams,
    required Map<String, PatientModel> patientMap,
    required String namaPuskesmas,
    required String bidanNama,
  }) async {
    await PdfService.generateRekapAndPrint(
      examinations: exams,
      patientMap: patientMap,
      namaPuskesmas: namaPuskesmas,
      bidanNama: bidanNama,
      from: _from,
      to: _to,
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      message: _statusMsg ?? AppStrings.prosesExport,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.eksporData)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.info.withValues(alpha: 0.3))),
              child: const Row(children: [
                Icon(Icons.lock_rounded, color: AppColors.info, size: 20),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Fitur ekspor hanya tersedia untuk Bidan.',
                        style: TextStyle(color: AppColors.info, fontSize: 14))),
              ]),
            ),
            const SizedBox(height: 20),

            // Filter Tanggal
            const SectionHeader(title: AppStrings.filterTanggal),
            const SizedBox(height: 12),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _DateRow(
                  label: AppStrings.tanggalMulai,
                  value: _from,
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _pickDate(isFrom: true),
                ),
                const SizedBox(height: 14),
                _DateRow(
                  label: AppStrings.tanggalSelesai,
                  value: _to,
                  icon: Icons.event_rounded,
                  onTap: () => _pickDate(isFrom: false),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        'Periode: ${DateFormatter.toDisplay(_from)} — ${DateFormatter.toDisplay(_to)}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            )),
            const SizedBox(height: 20),

            // Export Options
            const SectionHeader(title: 'Format Ekspor'),
            const SizedBox(height: 12),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ExportOptionCard(
                      icon: Icons.table_chart_rounded,
                      color: AppColors.success,
                      title: AppStrings.exportExcelBtn,
                      subtitle: 'Semua data dalam 21 kolom, siap dianalisis',
                      columns: [
                        'No',
                        'Nama Ibu',
                        'NIK',
                        'Kader',
                        'Tanggal',
                        'Usia Kehamilan',
                        'Sistolik',
                        'Diastolik',
                        'Status Tensi',
                        'BB',
                        'TB',
                        'LILA',
                        'BMI',
                        'Status LILA',
                        'DJJ',
                        'Status DJJ',
                        'Status Ibu',
                        'Status Janin',
                        'Rekomendasi',
                        'Keluhan',
                        'Catatan Kader',
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text(AppStrings.exportExcelBtn),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      onPressed: _loading ? null : _exportExcel,
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const _ExportOptionCard(
                      icon: Icons.picture_as_pdf_rounded,
                      color: AppColors.danger,
                      title: AppStrings.exportPdfBtn,
                      subtitle:
                          'Laporan PDF rekap semua pemeriksaan, siap cetak & tandatangan',
                      columns: [
                        'Data pasien lengkap',
                        'Tabel rekap semua pemeriksaan',
                        'Taksiran Persalinan (TP)',
                        'Kesimpulan kondisi ibu & janin',
                        'Rekomendasi',
                        'Ruang tanda tangan bidan',
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text(AppStrings.exportPdfBtn),
                      onPressed: _loading ? null : _exportPdf,
                    ),
                  ]),
            )),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime value;
  final IconData icon;
  final VoidCallback onTap;
  const _DateRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecond, fontSize: 13)),
          const SizedBox(height: 2),
          Text(DateFormatter.toDisplay(value),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        const Icon(Icons.edit_calendar_rounded,
            color: AppColors.primary, size: 20),
      ]),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final List<String> columns;
  const _ExportOptionCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.columns});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 26)),
      const SizedBox(width: 14),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textSecond, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 6,
            runSpacing: 4,
            children: columns
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.divider)),
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecond)),
                    ))
                .toList()),
      ])),
    ]);
  }
}
