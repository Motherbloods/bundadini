import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/rule_engine.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../../domain/providers/rules_provider.dart';
import '../../_widgets/cetak_dialog.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/custom_text_field.dart';
import '../../_widgets/loading_overlay.dart';
import '../../_widgets/section_header.dart';

class ExaminationStepperScreen extends StatefulWidget {
  final String patientId;
  const ExaminationStepperScreen({super.key, required this.patientId});
  @override
  State<ExaminationStepperScreen> createState() =>
      _ExaminationStepperScreenState();
}

class _ExaminationStepperScreenState extends State<ExaminationStepperScreen> {
  // Step 0=tensi, 1=antropometri, 2=djj
  int _step = 0;

  // Step 1 — tensi
  final _sistolikCtrl = TextEditingController();
  final _diastolikCtrl = TextEditingController();

  // Step 2 — antropometri
  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _lilaCtrl = TextEditingController();
  final _lpertCtrl = TextEditingController();
  final _tfuCtrl = TextEditingController();

  double? _bmi;
  double? _kenaikanBb;

  // Step 3 — DJJ + keluhan
  final _djjCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _keluhanLainnyaCtrl = TextEditingController();
  final List<String> _selectedKeluhan = [];

  // 3 form keys untuk 3 step
  final _keys = List.generate(3, (_) => GlobalKey<FormState>());

  @override
  void initState() {
    super.initState();
    // Auto-hitung BMI dan kenaikan BB saat BB/TB berubah
    _bbCtrl.addListener(_hitungBmi);
    _tbCtrl.addListener(_hitungBmi);
    _bbCtrl.addListener(_hitungKenaikanBbRealtime);
  }

  @override
  void dispose() {
    for (final c in [
      _sistolikCtrl,
      _diastolikCtrl,
      _bbCtrl,
      _tbCtrl,
      _lilaCtrl,
      _lpertCtrl,
      _tfuCtrl,
      _djjCtrl,
      _keluhanLainnyaCtrl,
      _catatanCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hitungBmi() {
    final bb = double.tryParse(_bbCtrl.text.replaceAll(',', '.'));
    final tb = double.tryParse(_tbCtrl.text.replaceAll(',', '.'));
    if (bb != null && tb != null && tb > 0) {
      setState(() => _bmi = RuleEngine.hitungBmi(bb, tb));
    } else {
      setState(() => _bmi = null);
    }
  }

  void _hitungKenaikanBbRealtime() {
    final bb = double.tryParse(_bbCtrl.text.replaceAll(',', '.'));
    final history = context.read<ExaminationProvider>().history;
    if (bb != null && history.isNotEmpty) {
      setState(() => _kenaikanBb = bb - history.first.beratBadan);
    } else {
      setState(() => _kenaikanBb = null);
    }
  }

  // Navigasi antar step

  void _next() {
    if (!_keys[_step].currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _simpan();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  // Simpan

  Future<void> _simpan() async {
    final auth = context.read<AuthProvider>();
    final rulesProvider = context.read<RulesProvider>();
    final patient = context.read<PatientProvider>().selectedPatient;

    // Pastikan rules sudah selesai di-load
    if (!rulesProvider.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sedang memuat data rules, coba lagi sebentar...'),
        backgroundColor: AppColors.warning,
      ));
      await rulesProvider.fetchRules();
      return;
    }

    if (rulesProvider.rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Data rules tidak ditemukan. Hubungi administrator.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    // Hitung usia kehamilan otomatis dari HPHT
    final usiaKehamilan = DateFormatter.usiaKehamilanMinggu(patient?.hpht) ?? 0;

    final saved = await context.read<ExaminationProvider>().saveExamination(
          patientId: widget.patientId,
          kaderId: auth.currentUser!.id,
          kaderNama: auth.currentUser!.nama,
          bidanId: auth.currentUser!.createdBy,
          usiaKehamilan: usiaKehamilan,
          sistolik: int.parse(_sistolikCtrl.text.trim()),
          diastolik: int.parse(_diastolikCtrl.text.trim()),
          beratBadan: double.parse(_bbCtrl.text.trim().replaceAll(',', '.')),
          tinggiBadan: double.parse(_tbCtrl.text.trim().replaceAll(',', '.')),
          lingkarLengan:
              double.parse(_lilaCtrl.text.trim().replaceAll(',', '.')),
          lingkarPerut: _lpertCtrl.text.isNotEmpty
              ? double.tryParse(_lpertCtrl.text.trim().replaceAll(',', '.'))
              : null,
          tfu: _tfuCtrl.text.isNotEmpty
              ? double.tryParse(_tfuCtrl.text.trim().replaceAll(',', '.'))
              : null,
          djj: int.parse(_djjCtrl.text.trim()),
          keluhanList: List.from(_selectedKeluhan),
          keluhanLainnya: _keluhanLainnyaCtrl.text.trim().isEmpty
              ? null
              : _keluhanLainnyaCtrl.text.trim(),
          catatanKader: _catatanCtrl.text.trim().isEmpty
              ? null
              : _catatanCtrl.text.trim(),
          rules: rulesProvider.rules,
        );

    if (!mounted) return;

    if (saved != null) {
      final isBidan = context.read<AuthProvider>().isBidan;
      if (isBidan) {
        await CetakDialog.show(
          context,
          onCetak: () =>
              context.go(AppRoutes.examinationResult, extra: saved.id),
          onNanti: () {
            context.read<ExaminationProvider>().loadHistory(widget.patientId);
            context.pop();
          },
        );
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppColors.successLight, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  '✅ Pemeriksaan Berhasil Disimpan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data pemeriksaan telah tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context
                          .read<ExaminationProvider>()
                          .loadHistory(widget.patientId);
                      context.pop();
                    },
                    child: const Text('Kembali ke Detail Pasien'),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        }
      }
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ExaminationProvider>().isLoading;
    final patient = context.watch<PatientProvider>().selectedPatient;

    // Selalu 3 step
    const steps = [
      AppStrings.step2Title, // Tekanan Darah
      AppStrings.step3Title, // Antropometri
      AppStrings.step4Title, // DJJ & Keluhan
    ];

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.periksa + (patient != null ? ' — ${patient.nama}' : ''),
          ),
        ),
        body: Column(children: [
          // Progress indicator
          _StepIndicator(steps: steps, currentIndex: _step),

          // Info usia kehamilan (dari HPHT)
          Builder(builder: (_) {
            final usia = DateFormatter.usiaKehamilanFormatted(patient?.hpht);

            if (usia == '-') return const SizedBox.shrink();

            return Container(
              color: AppColors.redPale,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.pregnant_woman_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usia kehamilan: $usia',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Form konten
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(),
              ),
            ),
          ),

          // Navigasi tombol
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(children: [
                if (_step > 0) ...[
                  Expanded(
                    child: CustomButton.outline(
                      label: 'Kembali',
                      onPressed: _prev,
                      icon: Icons.arrow_back_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Consumer<RulesProvider>(
                    builder: (_, rulesProvider, __) => CustomButton(
                      label: _step == 2
                          ? (rulesProvider.isLoaded
                              ? AppStrings.simpanPemeriksaan
                              : 'Memuat rules...')
                          : 'Lanjut',
                      onPressed:
                          (isLoading || (_step == 2 && !rulesProvider.isLoaded))
                              ? null
                              : _next,
                      icon: _step == 2
                          ? Icons.save_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step2Tensi(
          key: const ValueKey(0),
          formKey: _keys[0],
          sistolikCtrl: _sistolikCtrl,
          diastolikCtrl: _diastolikCtrl,
        );
      case 1:
        return _Step3Antropometri(
          key: const ValueKey(1),
          formKey: _keys[1],
          bbCtrl: _bbCtrl,
          tbCtrl: _tbCtrl,
          lilaCtrl: _lilaCtrl,
          lpertCtrl: _lpertCtrl,
          tfuCtrl: _tfuCtrl,
          bmi: _bmi,
          kenaikanBb: _kenaikanBb,
        );
      case 2:
        return _Step4Djj(
          key: const ValueKey(2),
          formKey: _keys[2],
          djjCtrl: _djjCtrl,
          selectedKeluhan: _selectedKeluhan,
          onKeluhanChanged: (list) => setState(() {
            // ← GANTI
            _selectedKeluhan
              ..clear()
              ..addAll(list);
          }),
          keluhanLainnyaCtrl: _keluhanLainnyaCtrl,
          catatanCtrl: _catatanCtrl,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// Step Indicator

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
  const _StepIndicator({required this.steps, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color:
                    idx < currentIndex ? AppColors.primary : AppColors.divider,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < currentIndex;
          final active = idx == currentIndex;
          return Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.success
                      : (active ? AppColors.primary : AppColors.background),
                  border: Border.all(
                    color: done
                        ? AppColors.success
                        : (active ? AppColors.primary : AppColors.divider),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.textSecond,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: TextStyle(
                  fontSize: 11,
                  color: active ? AppColors.primary : AppColors.textSecond,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

// Step 1: Tekanan Darah

class _Step2Tensi extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController sistolikCtrl, diastolikCtrl;
  const _Step2Tensi({
    super.key,
    required this.formKey,
    required this.sistolikCtrl,
    required this.diastolikCtrl,
  });
  @override
  State<_Step2Tensi> createState() => _Step2TensiState();
}

class _Step2TensiState extends State<_Step2Tensi> {
  String? _tensiStatus;
  Color _tensiColor = AppColors.success;

  void _check() {
    final s = int.tryParse(widget.sistolikCtrl.text);
    final d = int.tryParse(widget.diastolikCtrl.text);
    if (s == null || d == null) {
      setState(() => _tensiStatus = null);
      return;
    }
    setState(() {
      if (s >= 140 || d >= 90) {
        _tensiStatus = '🔴 Hipertensi — Risiko Tinggi';
        _tensiColor = AppColors.danger;
      } else if (s < 90 || d < 60) {
        _tensiStatus = '⚠️ Hipotensi — Perlu Perhatian';
        _tensiColor = AppColors.warning;
      } else {
        _tensiStatus = '✅ Normal';
        _tensiColor = AppColors.success;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHeader(title: AppStrings.step2Title),
        const SizedBox(height: 16),
        IntTextField(
          controller: widget.sistolikCtrl,
          label: AppStrings.sistolikLabel,
          validator: Validators.sistolik,
          onChanged: (_) => _check(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        IntTextField(
          controller: widget.diastolikCtrl,
          label: AppStrings.diastolikLabel,
          validator: Validators.diastolik,
          onChanged: (_) => _check(),
          textInputAction: TextInputAction.done,
        ),
        if (_tensiStatus != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _tensiColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _tensiColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _tensiStatus!,
              style: TextStyle(
                color: _tensiColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// Step 2: Antropometri

class _Step3Antropometri extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bbCtrl, tbCtrl, lilaCtrl, lpertCtrl;
  final TextEditingController tfuCtrl;
  final double? bmi, kenaikanBb;

  const _Step3Antropometri({
    super.key,
    required this.formKey,
    required this.bbCtrl,
    required this.tbCtrl,
    required this.lilaCtrl,
    required this.lpertCtrl,
    required this.tfuCtrl,
    this.bmi,
    this.kenaikanBb,
  });

  @override
  State<_Step3Antropometri> createState() => _Step3AntropometriState();
}

class _Step3AntropometriState extends State<_Step3Antropometri> {
  bool _isKek = false;

  @override
  void initState() {
    super.initState();
    widget.lilaCtrl.addListener(_checkKek);
    _checkKek();
  }

  void _checkKek() {
    final val = double.tryParse(widget.lilaCtrl.text.replaceAll(',', '.'));
    final kek = val != null && RuleEngine.isKek(val);
    if (kek != _isKek) setState(() => _isKek = kek);
  }

  @override
  void dispose() {
    widget.lilaCtrl.removeListener(_checkKek);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHeader(title: AppStrings.step3Title),
        const SizedBox(height: 16),
        DecimalTextField(
          controller: widget.bbCtrl,
          label: AppStrings.beratBadanLabel,
          validator: Validators.beratBadan,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        DecimalTextField(
          controller: widget.tbCtrl,
          label: AppStrings.tinggiBadanLabel,
          validator: Validators.tinggiBadan,
          textInputAction: TextInputAction.next,
        ),
        if (widget.bmi != null) ...[
          const SizedBox(height: 10),
          _InfoTile(
            'BMI',
            '${widget.bmi!.toStringAsFixed(1)} — ${RuleEngine.kategoriBmi(widget.bmi!)}',
            AppColors.info,
          ),
          if (widget.kenaikanBb != null)
            _InfoTile(
              'Kenaikan BB',
              '${widget.kenaikanBb! >= 0 ? '+' : ''}${widget.kenaikanBb!.toStringAsFixed(1)} kg dari pemeriksaan sebelumnya',
              widget.kenaikanBb! < 0 ? AppColors.warning : AppColors.success,
            ),
        ],
        const SizedBox(height: 14),
        DecimalTextField(
          controller: widget.lilaCtrl,
          label: AppStrings.lingkarLenganLabel,
          validator: Validators.lingkarLengan,
          textInputAction: TextInputAction.next,
        ),
        if (_isKek) ...[
          const SizedBox(height: 8),
          const _InfoTile(
            'Status LILA',
            '⚠️ KEK — LILA < 23.5 cm',
            AppColors.warning,
          ),
        ],
        const SizedBox(height: 14),
        DecimalTextField(
          controller: widget.lpertCtrl,
          label: AppStrings.lingkarPerutLabel,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 14),
        DecimalTextField(
          controller: widget.tfuCtrl,
          label: AppStrings.tfuLabel,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        const Text(
          'TFU normal: ±1 cm per minggu usia kehamilan (contoh: 28 minggu → ±28 cm)',
          style: TextStyle(
            color: AppColors.textSecond,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: color, fontSize: 14)),
        ),
      ]),
    );
  }
}

// Step 3: DJJ + Keluhan

class _Step4Djj extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController djjCtrl;

  // ← GANTI dari keluhanCtrl:
  final List<String> selectedKeluhan;
  final ValueChanged<List<String>> onKeluhanChanged;
  final TextEditingController keluhanLainnyaCtrl; // ← TAMBAH

  final TextEditingController catatanCtrl;

  const _Step4Djj({
    super.key,
    required this.formKey,
    required this.djjCtrl,
    required this.selectedKeluhan,
    required this.onKeluhanChanged,
    required this.keluhanLainnyaCtrl,
    required this.catatanCtrl,
  });

  @override
  State<_Step4Djj> createState() => _Step4DjjState();
}

class _Step4DjjState extends State<_Step4Djj> {
  String? _djjStatus;
  Color _djjColor = AppColors.success;
  bool _adaLainnya = false;

  void _check() {
    final v = int.tryParse(widget.djjCtrl.text);
    if (v == null) {
      setState(() => _djjStatus = null);
      return;
    }
    setState(() {
      if (v < 110) {
        _djjStatus = '🔴 DJJ Rendah — Segera konsultasi';
        _djjColor = AppColors.danger;
      } else if (v > 160) {
        _djjStatus = '🔴 DJJ Tinggi — Segera konsultasi';
        _djjColor = AppColors.danger;
      } else {
        _djjStatus = '✅ DJJ Normal (110–160 bpm)';
        _djjColor = AppColors.success;
      }
    });
  }

  void _toggleKeluhan(String keluhan) {
    final list = List<String>.from(widget.selectedKeluhan);
    if (list.contains(keluhan)) {
      list.remove(keluhan);
    } else {
      list.add(keluhan);
    }
    widget.onKeluhanChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: AppStrings.step4Title),
          const SizedBox(height: 16),
          IntTextField(
            controller: widget.djjCtrl,
            label: AppStrings.djjLabel,
            validator: Validators.djj,
            onChanged: (_) => _check(),
            textInputAction: TextInputAction.next,
          ),
          if (_djjStatus != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _djjColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _djjColor.withValues(alpha: 0.3)),
              ),
              child: Text(_djjStatus!,
                  style: TextStyle(
                      color: _djjColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Keluhan Ibu'),
          const SizedBox(height: 4),
          const Text(
            'Pilih semua keluhan yang dirasakan ibu (boleh lebih dari satu)',
            style: TextStyle(color: AppColors.textSecond, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ...AppStrings.daftarKeluhan.asMap().entries.map((entry) {
                  final keluhan = entry.value;
                  final isLast =
                      entry.key == AppStrings.daftarKeluhan.length - 1;
                  final selected = widget.selectedKeluhan.contains(keluhan);
                  return Column(children: [
                    InkWell(
                      onTap: () => setState(() => _toggleKeluhan(keluhan)),
                      borderRadius: BorderRadius.vertical(
                        top: entry.key == 0
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottom: isLast && !_adaLainnya
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(keluhan,
                              style: TextStyle(
                                fontSize: 15,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              )),
                        ]),
                      ),
                    ),
                    if (!isLast || _adaLainnya)
                      const Divider(height: 1, indent: 48),
                  ]);
                }),
                InkWell(
                  onTap: () => setState(() {
                    _adaLainnya = !_adaLainnya;
                    if (!_adaLainnya) {
                      widget.keluhanLainnyaCtrl.clear();
                    }
                  }),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _adaLainnya
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                              color: _adaLainnya
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _adaLainnya
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Lainnya...',
                          style: TextStyle(
                            fontSize: 15,
                            color: _adaLainnya
                                ? AppColors.primary
                                : AppColors.textSecond,
                            fontStyle: FontStyle.italic,
                          )),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (_adaLainnya) ...[
            const SizedBox(height: 10),
            CustomTextField(
              controller: widget.keluhanLainnyaCtrl,
              label: 'Keluhan lainnya',
              hint: 'Tuliskan keluhan lain yang tidak ada di daftar...',
              maxLines: 2,
            ),
          ],
          if (widget.selectedKeluhan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.selectedKeluhan.length} keluhan dipilih:',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedKeluhan.join(' · '),
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          CustomTextField(
            controller: widget.catatanCtrl,
            label: AppStrings.catatanKaderLabel,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
