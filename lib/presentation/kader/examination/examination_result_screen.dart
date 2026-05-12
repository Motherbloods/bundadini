import 'package:bundadini/data/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/rule_engine.dart';
import '../../../data/models/examination_model.dart';
import '../../../data/services/pdf_service.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/loading_overlay.dart';
import '../../_widgets/section_header.dart';
import '../../_widgets/status_badge.dart';

class ExaminationResultScreen extends StatefulWidget {
  final String examinationId;
  const ExaminationResultScreen({super.key, required this.examinationId});
  @override
  State<ExaminationResultScreen> createState() =>
      _ExaminationResultScreenState();
}

class _ExaminationResultScreenState extends State<ExaminationResultScreen> {
  ExaminationModel? _exam;
  bool _loading = true;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exam = await context
        .read<ExaminationProvider>()
        .fetchById(widget.examinationId);
    if (mounted) {
      setState(() {
        _exam = exam;
        _loading = false;
      });
    }
  }

  Future<void> _cetakPdf() async {
    if (_exam == null) return;
    setState(() => _pdfLoading = true);
    try {
      final patient = context.read<PatientProvider>().selectedPatient;
      final auth = context.read<AuthProvider>();
      String namaPuskesmas =
          auth.currentUser?.namaPuskesmas ?? AppStrings.defaultPuskesmas;
      String bidanNama = '';
      if (auth.isBidan) {
        bidanNama = auth.currentUser?.nama ?? '';
      } else {
        final bidanId = auth.currentUser?.createdBy ?? '';
        if (bidanId.isNotEmpty) {
          final authRepo = AuthRepository();
          final bidan = await authRepo.fetchUserById(bidanId);
          bidanNama = bidan?.nama ?? '';
          if (namaPuskesmas == AppStrings.defaultPuskesmas &&
              bidan?.namaPuskesmas != null &&
              bidan!.namaPuskesmas!.trim().isNotEmpty) {
            namaPuskesmas = bidan.namaPuskesmas!;
          }
        }
      }
      await PdfService.generateAndPrint(
        exam: _exam!,
        patientNama: patient?.nama ?? '',
        patientNik: patient?.nik ?? '',
        patientTglLahir: patient != null
            ? DateFormatter.toDisplay(patient.tanggalLahir)
            : '',
        patientGolDarah: patient?.golonganDarah.name ?? '',
        patientAlamat: patient?.alamat ?? '',
        patientNoHp: patient?.noHp ?? '',
        patientHpht: patient?.hpht != null
            ? DateFormatter.toDisplay(patient!.hpht!)
            : 'Belum diisi',
        patientFotoUrl: patient?.fotoUrl ?? '',
        namaPuskesmas: namaPuskesmas,
        bidanNama: bidanNama,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal generate PDF: $e'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_exam == null) {
      return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.hasilPemeriksaan)),
          body: const Center(child: Text('Data tidak ditemukan')));
    }
    final exam = _exam!;

    return LoadingOverlay(
      isLoading: _pdfLoading,
      message: 'Membuat PDF...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.hasilPemeriksaan)),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewPadding.bottom + 100,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header tanggal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(DateFormatter.toDisplayWithDay(exam.tanggal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600))),
                Text('${exam.usiaKehamilan} ${AppStrings.minggu}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 14),

            // Card 1 — Tekanan Darah
            _ResultCard(
              title: 'Tekanan Darah',
              icon: Icons.favorite_rounded,
              iconColor: AppColors.danger,
              children: [
                _Row('Sistolik', '${exam.sistolik} mmHg',
                    sub: _tensiLabel(exam.sistolik, exam.diastolik)),
                _Row('Diastolik', '${exam.diastolik} mmHg'),
              ],
            ),
            const SizedBox(height: 12),

            // Card 2 — Antropometri
            _ResultCard(
              title: 'Antropometri',
              icon: Icons.monitor_weight_rounded,
              iconColor: AppColors.info,
              children: [
                _Row('Usia Kehamilan', '${exam.usiaKehamilan} minggu'),
                _Row('Berat Badan', '${exam.beratBadan.toStringAsFixed(1)} kg',
                    sub: exam.kenaikanBb != 0
                        ? '${exam.kenaikanBb >= 0 ? '+' : ''}${exam.kenaikanBb.toStringAsFixed(1)} kg'
                        : null),
                _Row('Tinggi Badan',
                    '${exam.tinggiBadan.toStringAsFixed(0)} cm'),
                _Row('LILA', '${exam.lingkarLengan.toStringAsFixed(1)} cm',
                    badge: LilaBadge(lila: exam.lingkarLengan)),
                _Row(
                  'BMI',
                  exam.bmi.toStringAsFixed(1),
                  sub: RuleEngine.kategoriBmi(exam.bmi),
                ),
                _Row(
                  "TFU",
                  exam.tfu == null ? '-' : '${exam.tfu!.toStringAsFixed(1)} cm',
                ),
                if (exam.lingkarPerut != null)
                  _Row('Lingkar Perut',
                      '${exam.lingkarPerut!.toStringAsFixed(1)} cm'),
              ],
            ),
            const SizedBox(height: 12),

            // Card 3 — DJJ
            _ResultCard(
              title: 'Denyut Jantung Janin (DJJ)',
              icon: Icons.monitor_heart_rounded,
              iconColor: AppColors.chartRed,
              children: [
                _Row('DJJ', '${exam.djj} bpm',
                    badge: StatusBadge(
                        status: exam.statusJanin, isJanin: true, large: true)),
              ],
            ),
            const SizedBox(height: 12),

            // Card 4 — Kesimpulan
            _KesimpulanCard(exam: exam),
            const SizedBox(height: 16),

            // Alert risiko tinggi
            if (exam.isRisikoTinggi)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.4))),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(AppStrings.segeraKonsul,
                          style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 15))),
                ]),
              ),
            if (exam.isRisikoTinggi) const SizedBox(height: 16),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.isBidan) ...[
                    CustomButton(
                      label: AppStrings.cetakPdf,
                      onPressed: _pdfLoading ? null : _cetakPdf,
                      isLoading: _pdfLoading,
                      icon: Icons.picture_as_pdf_rounded,
                    ),
                    const SizedBox(height: 10),
                  ],
                  CustomButton.outline(
                    label: AppStrings.kembaliBeranda,
                    onPressed: () => context.go(auth.isBidan
                        ? AppRoutes.bidanDashboard
                        : AppRoutes.kaderHome),
                    icon: Icons.home_rounded,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _tensiLabel(int sis, int dia) {
    if (sis >= 140 || dia >= 90) return 'Hipertensi';
    if (sis < 90 || dia < 60) return 'Hipotensi';
    return 'Normal';
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _ResultCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...children,
      ]),
    ));
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final String? sub;
  final Widget? badge;
  const _Row(this.label, this.value, {this.sub, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecond, fontSize: 14))),
        Expanded(
            child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              if (sub != null)
                Text('($sub)',
                    style: const TextStyle(
                        color: AppColors.textSecond, fontSize: 13)),
              if (badge != null) badge!,
            ])),
      ]),
    );
  }
}

class _KesimpulanCard extends StatelessWidget {
  final ExaminationModel exam;
  const _KesimpulanCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final statusColor = exam.statusIbu == ExaminationStatus.risikoTinggi
        ? AppColors.danger
        : exam.statusIbu == ExaminationStatus.perluPerhatian
            ? AppColors.warning
            : AppColors.success;

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: statusColor.withValues(alpha: 0.4), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'Kesimpulan Pemeriksaan'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text(AppStrings.kondisiIbu,
                      style:
                          TextStyle(color: AppColors.textSecond, fontSize: 13)),
                  const SizedBox(height: 6),
                  StatusBadge(status: exam.statusIbu, large: true),
                ])),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text(AppStrings.kondisiJanin,
                      style:
                          TextStyle(color: AppColors.textSecond, fontSize: 13)),
                  const SizedBox(height: 6),
                  StatusBadge(
                      status: exam.statusJanin, isJanin: true, large: true),
                ])),
          ]),
          if (exam.keluhanList.isNotEmpty || exam.keluhanLainnya != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Keluhan Ibu',
                style: TextStyle(
                    color: AppColors.textSecond,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...exam.keluhanList.map((k) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Text(k,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500)),
                    )),
                if (exam.keluhanLainnya != null &&
                    exam.keluhanLainnya!.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Text('Lainnya: ${exam.keluhanLainnya}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ],
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Label berbeda berdasarkan role
                  Row(children: [
                    const Icon(Icons.medical_information_rounded,
                        color: AppColors.info, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      auth.isBidan
                          ? 'Catatan Bidan'
                          : 'Catatan Bidan Pendamping',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Bidan: tampilkan form editable
                  if (auth.isBidan)
                    _CatatanBidanEditor(exam: exam)
                  // Kader: tampilkan read-only
                  else if (exam.catatanBidan != null &&
                      exam.catatanBidan!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3))),
                      child: Text(exam.catatanBidan!,
                          style: const TextStyle(fontSize: 15)),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider)),
                      child: const Text(
                          'Menunggu catatan dari bidan pendamping...',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecond,
                              fontStyle: FontStyle.italic)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(AppStrings.rekomendasi,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.25))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: exam.rekomendasi
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Expanded(
                                  child: Text(r,
                                      style: const TextStyle(
                                          fontSize: 15, height: 1.4))),
                            ]),
                      ))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CatatanBidanEditor extends StatefulWidget {
  final ExaminationModel exam;
  const _CatatanBidanEditor({required this.exam});
  @override
  State<_CatatanBidanEditor> createState() => _CatatanBidanEditorState();
}

class _CatatanBidanEditorState extends State<_CatatanBidanEditor> {
  late TextEditingController _ctrl;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Prefill: kalau sudah ada catatan sebelumnya, tampilkan
    // Kalau belum, generate template otomatis dari hasil rule engine
    _ctrl = TextEditingController(
      text: widget.exam.catatanBidan?.isNotEmpty == true
          ? widget.exam.catatanBidan!
          : _generateTemplate(),
    );
  }

  /// Generate template catatan berdasarkan hasil pemeriksaan
  String _generateTemplate() {
    final e = widget.exam;
    final lines = <String>[];
    final tanggal = DateFormatter.toDisplay(e.tanggal);

    lines.add('Hasil pemeriksaan tanggal $tanggal:');

    // Tensi
    if (e.sistolik >= 140 || e.diastolik >= 90) {
      lines.add('- Tekanan darah tinggi (${e.sistolik}/${e.diastolik} mmHg). '
          'Perlu pemantauan ketat dan konsultasi dokter.');
    } else if (e.sistolik < 90 || e.diastolik < 60) {
      lines.add('- Tekanan darah rendah (${e.sistolik}/${e.diastolik} mmHg). '
          'Anjurkan istirahat cukup dan konsumsi makanan bergizi.');
    } else {
      lines.add('- Tekanan darah normal (${e.sistolik}/${e.diastolik} mmHg).');
    }

    // LILA / KEK
    if (e.lingkarLengan < 23.5) {
      lines.add('- LILA ${e.lingkarLengan} cm (KEK). '
          'Perlu konsultasi ahli gizi dan peningkatan asupan kalori.');
    }

    // DJJ
    if (e.statusJanin == 'djj_rendah') {
      lines.add(
          '- DJJ rendah (${e.djj} bpm). Segera rujuk ke fasilitas kesehatan.');
    } else if (e.statusJanin == 'djj_tinggi') {
      lines.add(
          '- DJJ tinggi (${e.djj} bpm). Anjurkan ibu istirahat dan segera periksakan.');
    }

    // Status umum
    if (e.statusIbu == 'risiko_tinggi') {
      lines.add('- Status ibu: RISIKO TINGGI. Diperlukan penanganan segera.');
    } else if (e.statusIbu == 'perlu_perhatian') {
      lines.add('- Status ibu: Perlu Perhatian. Pantau kondisi lebih sering.');
    } else {
      lines.add('- Kondisi ibu dan janin dalam batas normal.');
      lines.add('- Anjurkan tetap rutin kontrol kehamilan.');
    }

    return lines.join('\n');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final teks = _ctrl.text.trim();
    if (teks.isEmpty) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await FirebaseFirestore.instance
          .collection('examinations')
          .doc(widget.exam.id)
          .update({'catatanBidan': teks});
      setState(() {
        _saving = false;
        _saved = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Catatan bidan berhasil disimpan'),
            backgroundColor: AppColors.success));
      }
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menyimpan catatan'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info template
        if (widget.exam.catatanBidan == null ||
            widget.exam.catatanBidan!.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.info, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Template catatan sudah dibuat otomatis '
                      'berdasarkan hasil pemeriksaan. '
                      'Anda bisa mengedit sesuai kebutuhan.',
                      style: TextStyle(color: AppColors.info, fontSize: 12))),
            ]),
          ),

        // Text editor
        TextField(
          controller: _ctrl,
          maxLines: 6,
          onChanged: (_) => setState(() => _saved = false),
          style: const TextStyle(fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Catatan atau rekomendasi bidan...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.info, width: 2)),
          ),
        ),
        const SizedBox(height: 8),

        // Tombol simpan
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(_saved ? Icons.check_rounded : Icons.save_rounded,
                    size: 18),
            label: Text(_saving
                ? 'Menyimpan...'
                : _saved
                    ? 'Tersimpan ✓'
                    : 'Simpan Catatan'),
            onPressed: (_saving || _saved) ? null : _simpan,
            style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? AppColors.success : AppColors.info,
                disabledBackgroundColor: _saved ? AppColors.success : null),
          ),
        ),
      ],
    );
  }
}
