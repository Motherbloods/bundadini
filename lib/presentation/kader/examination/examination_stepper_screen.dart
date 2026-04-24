import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
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
  int _step = 0; // 0=usia, 1=tensi, 2=antropometri, 3=djj
  bool _isPasienBaru = false; // start from step 0 for new, 1 for existing

  // Step 1 — usia kehamilan
  final _usiaCtrl = TextEditingController();

  // Step 2 — tensi
  final _sistolikCtrl = TextEditingController();
  final _diastolikCtrl = TextEditingController();

  // Step 3 — antropometri
  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _lilaCtrl = TextEditingController();
  final _lpertCtrl = TextEditingController();
  double? _bmi;
  double? _kenaikanBb;

  // Step 4 — DJJ + keluhan
  final _djjCtrl = TextEditingController();
  final _keluhanCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  final _keys = List.generate(4, (_) => GlobalKey<FormState>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<PatientProvider>().selectedPatient;
      // Pasien baru = belum pernah diperiksa → mulai dari step 0
      final history = context.read<ExaminationProvider>().history;
      setState(() {
        _isPasienBaru = history.isEmpty;
        _step = _isPasienBaru ? 0 : 1;

        if (!_isPasienBaru && p != null) {
          final usia = DateTime.now().difference(p.hpht).inDays ~/ 7;
          _usiaCtrl.text = usia.toString();
        }
      });
    });

    // Auto-hitung BMI saat BB/TB berubah
    _bbCtrl.addListener(_hitungBmi);
    _tbCtrl.addListener(_hitungBmi);
  }

  @override
  void dispose() {
    for (final c in [
      _usiaCtrl,
      _sistolikCtrl,
      _diastolikCtrl,
      _bbCtrl,
      _tbCtrl,
      _lilaCtrl,
      _lpertCtrl,
      _djjCtrl,
      _keluhanCtrl,
      _catatanCtrl
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
    }
  }

  void _hitungKenaikanBb() {
    final bb = double.tryParse(_bbCtrl.text.replaceAll(',', '.'));
    final history = context.read<ExaminationProvider>().history;
    if (bb != null && history.isNotEmpty) {
      setState(() => _kenaikanBb = bb - history.first.beratBadan);
    }
  }

  // Navigasi antar step

  void _next() {
    if (!_keys[_step].currentState!.validate()) return;
    if (_step == 2) _hitungKenaikanBb();
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _simpan();
    }
  }

  void _prev() {
    if (_step > (_isPasienBaru ? 0 : 1)) setState(() => _step--);
  }

  // Simpa

  Future<void> _simpan() async {
    final auth = context.read<AuthProvider>();
    final rules = context.read<RulesProvider>().rules;

    final saved = await context.read<ExaminationProvider>().saveExamination(
          patientId: widget.patientId,
          kaderId: auth.currentUser!.id,
          kaderNama: auth.currentUser!.nama,
          usiaKehamilan: int.parse(_usiaCtrl.text.trim()),
          sistolik: int.parse(_sistolikCtrl.text.trim()),
          diastolik: int.parse(_diastolikCtrl.text.trim()),
          beratBadan: double.parse(_bbCtrl.text.trim().replaceAll(',', '.')),
          tinggiBadan: double.parse(_tbCtrl.text.trim().replaceAll(',', '.')),
          lingkarLengan:
              double.parse(_lilaCtrl.text.trim().replaceAll(',', '.')),
          lingkarPerut: _lpertCtrl.text.isNotEmpty
              ? double.tryParse(_lpertCtrl.text.trim().replaceAll(',', '.'))
              : null,
          djj: int.parse(_djjCtrl.text.trim()),
          keluhanIbu: _keluhanCtrl.text.trim().isEmpty
              ? null
              : _keluhanCtrl.text.trim(),
          catatanKader: _catatanCtrl.text.trim().isEmpty
              ? null
              : _catatanCtrl.text.trim(),
          rules: rules,
        );

    if (!mounted) return;

    if (saved != null) {
      await CetakDialog.show(
        context,
        onCetak: () => context.go(AppRoutes.examinationResult, extra: saved.id),
        onNanti: () {
          // Kembali ke detail pasien
          context.go('/kader/patients/${widget.patientId}');
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan pemeriksaan'),
          backgroundColor: AppColors.danger));
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ExaminationProvider>().isLoading;
    final patient = context.watch<PatientProvider>().selectedPatient;
    final steps = _isPasienBaru
        ? [
            AppStrings.step1Title,
            AppStrings.step2Title,
            AppStrings.step3Title,
            AppStrings.step4Title
          ]
        : [AppStrings.step2Title, AppStrings.step3Title, AppStrings.step4Title];
    final stepIndex = _isPasienBaru ? _step : _step - 1;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppStrings.periksa +
              (patient != null ? ' — ${patient.nama}' : '')),
        ),
        body: Column(children: [
          // Progress indicator
          _StepIndicator(steps: steps, currentIndex: stepIndex),

          // Form konten
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                if (_step > (_isPasienBaru ? 0 : 1)) ...[
                  Expanded(
                    child: CustomButton.outline(
                        label: 'Kembali',
                        onPressed: _prev,
                        icon: Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CustomButton(
                    label: _step == 3 ? AppStrings.simpanPemeriksaan : 'Lanjut',
                    onPressed: isLoading ? null : _next,
                    icon: _step == 3
                        ? Icons.save_rounded
                        : Icons.arrow_forward_rounded,
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
        return _Step1Usia(
            key: ValueKey(_step), formKey: _keys[0], ctrl: _usiaCtrl);
      case 1:
        return _Step2Tensi(
            key: ValueKey(_step),
            formKey: _keys[1],
            sistolikCtrl: _sistolikCtrl,
            diastolikCtrl: _diastolikCtrl);
      case 2:
        return _Step3Antropometri(
            key: ValueKey(_step),
            formKey: _keys[2],
            bbCtrl: _bbCtrl,
            tbCtrl: _tbCtrl,
            lilaCtrl: _lilaCtrl,
            lpertCtrl: _lpertCtrl,
            bmi: _bmi,
            kenaikanBb: _kenaikanBb);
      case 3:
        return _Step4Djj(
            key: ValueKey(_step),
            formKey: _keys[3],
            djjCtrl: _djjCtrl,
            keluhanCtrl: _keluhanCtrl,
            catatanCtrl: _catatanCtrl);
      default:
        return const SizedBox.shrink();
    }
  }
}

// Step Indicato
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
                    color: idx < currentIndex
                        ? AppColors.primary
                        : AppColors.divider));
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
                      width: 2),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              color:
                                  active ? Colors.white : AppColors.textSecond,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[idx],
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? AppColors.primary : AppColors.textSecond,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal)),
            ]),
          );
        }),
      ),
    );
  }
}

// Step 1: Usia Kehamilan
class _Step1Usia extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  const _Step1Usia({super.key, required this.formKey, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionHeader(title: AppStrings.step1Title),
          const SizedBox(height: 16),
          IntTextField(
              controller: ctrl,
              label: AppStrings.usiaKehamilanLabel,
              validator: Validators.usiaKehamilan,
              textInputAction: TextInputAction.done),
          const SizedBox(height: 12),
          const Text('Masukkan usia kehamilan dalam minggu (1–45).',
              style: TextStyle(color: AppColors.textSecond, fontSize: 14)),
        ]));
  }
}

// Step 2: Tekanan Darah
class _Step2Tensi extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController sistolikCtrl, diastolikCtrl;
  const _Step2Tensi(
      {super.key,
      required this.formKey,
      required this.sistolikCtrl,
      required this.diastolikCtrl});
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
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionHeader(title: AppStrings.step2Title),
          const SizedBox(height: 16),
          IntTextField(
              controller: widget.sistolikCtrl,
              label: AppStrings.sistolikLabel,
              validator: Validators.sistolik,
              onChanged: (_) => _check(),
              textInputAction: TextInputAction.next),
          const SizedBox(height: 14),
          IntTextField(
              controller: widget.diastolikCtrl,
              label: AppStrings.diastolikLabel,
              validator: Validators.diastolik,
              onChanged: (_) => _check(),
              textInputAction: TextInputAction.done),
          if (_tensiStatus != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _tensiColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _tensiColor.withValues(alpha: 0.3))),
              child: Text(_tensiStatus!,
                  style: TextStyle(
                      color: _tensiColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ],
        ]));
  }
}

// Step 3: Antropometri─
class _Step3Antropometri extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bbCtrl, tbCtrl, lilaCtrl, lpertCtrl;
  final double? bmi, kenaikanBb;
  const _Step3Antropometri(
      {super.key,
      required this.formKey,
      required this.bbCtrl,
      required this.tbCtrl,
      required this.lilaCtrl,
      required this.lpertCtrl,
      this.bmi,
      this.kenaikanBb});

  @override
  Widget build(BuildContext context) {
    final lilaVal = double.tryParse(lilaCtrl.text.replaceAll(',', '.'));
    final isKek = lilaVal != null && RuleEngine.isKek(lilaVal);

    return Form(
        key: formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionHeader(title: AppStrings.step3Title),
          const SizedBox(height: 16),
          DecimalTextField(
              controller: bbCtrl,
              label: AppStrings.beratBadanLabel,
              validator: Validators.beratBadan,
              textInputAction: TextInputAction.next),
          const SizedBox(height: 14),
          DecimalTextField(
              controller: tbCtrl,
              label: AppStrings.tinggiBadanLabel,
              validator: Validators.tinggiBadan,
              textInputAction: TextInputAction.next),
          if (bmi != null) ...[
            const SizedBox(height: 10),
            _InfoTile(
                'BMI',
                '${bmi!.toStringAsFixed(1)} — ${RuleEngine.kategoriBmi(bmi!)}',
                AppColors.info),
            if (kenaikanBb != null)
              _InfoTile(
                  'Kenaikan BB',
                  '${kenaikanBb! >= 0 ? '+' : ''}${kenaikanBb!.toStringAsFixed(1)} kg dari pemeriksaan sebelumnya',
                  kenaikanBb! < 0 ? AppColors.warning : AppColors.success),
          ],
          const SizedBox(height: 14),
          DecimalTextField(
              controller: lilaCtrl,
              label: AppStrings.lingkarLenganLabel,
              validator: Validators.lingkarLengan,
              textInputAction: TextInputAction.next),
          if (isKek) ...[
            const SizedBox(height: 8),
            const _InfoTile(
                'Status LILA', '⚠️ KEK — LILA < 23.5 cm', AppColors.warning),
          ],
          const SizedBox(height: 14),
          DecimalTextField(
              controller: lpertCtrl,
              label: AppStrings.lingkarPerutLabel,
              textInputAction: TextInputAction.done),
        ]));
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
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(children: [
        Text('$label: ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        Expanded(
            child: Text(value, style: TextStyle(color: color, fontSize: 14))),
      ]),
    );
  }
}

// Step 4: DJJ + Keluhan
class _Step4Djj extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController djjCtrl, keluhanCtrl, catatanCtrl;
  const _Step4Djj(
      {super.key,
      required this.formKey,
      required this.djjCtrl,
      required this.keluhanCtrl,
      required this.catatanCtrl});
  @override
  State<_Step4Djj> createState() => _Step4DjjState();
}

class _Step4DjjState extends State<_Step4Djj> {
  String? _djjStatus;
  Color _djjColor = AppColors.success;

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

  @override
  Widget build(BuildContext context) {
    return Form(
        key: widget.formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionHeader(title: AppStrings.step4Title),
          const SizedBox(height: 16),
          IntTextField(
              controller: widget.djjCtrl,
              label: AppStrings.djjLabel,
              validator: Validators.djj,
              onChanged: (_) => _check(),
              textInputAction: TextInputAction.next),
          if (_djjStatus != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _djjColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _djjColor.withValues(alpha: 0.3))),
              child: Text(_djjStatus!,
                  style: TextStyle(
                      color: _djjColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ],
          const SizedBox(height: 14),
          CustomTextField(
              controller: widget.keluhanCtrl,
              label: AppStrings.keluhanLabel,
              maxLines: 3),
          const SizedBox(height: 14),
          CustomTextField(
              controller: widget.catatanCtrl,
              label: AppStrings.catatanKaderLabel,
              maxLines: 3),
        ]));
  }
}
