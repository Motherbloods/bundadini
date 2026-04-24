import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/custom_text_field.dart';
import '../../_widgets/loading_overlay.dart';

class EditPatientScreen extends StatefulWidget {
  final String patientId;
  const EditPatientScreen({super.key, required this.patientId});
  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _tempatCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();

  PatientModel? _patient;
  DateTime? _tanggalLahir;
  DateTime? _hpht;
  GolonganDarah _golDarah = GolonganDarah.o;
  File? _newFoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  void _prefill() {
    final p = context.read<PatientProvider>().selectedPatient;
    if (p == null) return;
    setState(() {
      _patient = p;
      _namaCtrl.text = p.nama;
      _tempatCtrl.text = p.tempatLahir;
      _alamatCtrl.text = p.alamat;
      _noHpCtrl.text = p.noHp;
      _tanggalLahir = p.tanggalLahir;
      _hpht = p.hpht;
      _golDarah = p.golonganDarah;
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tempatCtrl.dispose();
    _alamatCtrl.dispose();
    _noHpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 75, maxWidth: 800);
    if (picked != null) setState(() => _newFoto = File(picked.path));
    if (mounted) Navigator.pop(context);
  }

  void _showFotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        ListTile(
            leading:
                const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            title: const Text(AppStrings.ambilFoto,
                style: TextStyle(fontSize: 16)),
            onTap: () => _pickFoto(ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppColors.primary),
            title: const Text(AppStrings.pilihGaleri,
                style: TextStyle(fontSize: 16)),
            onTap: () => _pickFoto(ImageSource.gallery)),
        const SizedBox(height: 16),
      ])),
    );
  }

  Future<void> _pickTanggal({required bool isHpht}) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isHpht
          ? (_hpht ?? now.subtract(const Duration(days: 60)))
          : (_tanggalLahir ?? DateTime(now.year - 25)),
      firstDate: isHpht ? DateTime(now.year - 1) : DateTime(now.year - 60),
      lastDate: isHpht ? now : DateTime(now.year - 10),
    );
    if (picked != null) {
      setState(() => isHpht ? _hpht = picked : _tanggalLahir = picked);
    }
  }

  Future<void> _simpan() async {
    if (_patient == null || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final updated = _patient!.copyWith(
      nama: _namaCtrl.text.trim(),
      tempatLahir: _tempatCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      tanggalLahir: _tanggalLahir,
      hpht: _hpht,
      golonganDarah: _golDarah,
      updatedAt: DateTime.now(),
    );
    final ok = await context
        .read<PatientProvider>()
        .updatePatient(updated, fotoFile: _newFoto);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Biodata berhasil diperbarui'),
          backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PatientProvider>().isLoading;
    if (_patient == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.editPasien)),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto
                  Center(
                    child: GestureDetector(
                      onTap: _showFotoPicker,
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _newFoto != null
                              ? Image.file(_newFoto!,
                                  width: 110, height: 110, fit: BoxFit.cover)
                              : (_patient!.fotoUrl.isNotEmpty
                                  ? Image.network(_patient!.fotoUrl,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover)
                                  : Container(
                                      width: 110,
                                      height: 110,
                                      color: AppColors.redPale,
                                      child: const Icon(Icons.person_rounded,
                                          color: AppColors.primary, size: 60))),
                        ),
                        Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NIK (read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider)),
                    child: Row(children: [
                      const Icon(Icons.badge_outlined,
                          color: AppColors.textSecond, size: 20),
                      const SizedBox(width: 10),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NIK (tidak dapat diubah)',
                                style: TextStyle(
                                    color: AppColors.textSecond, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(_patient!.nik,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ]),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                      controller: _namaCtrl,
                      label: AppStrings.namaLabel,
                      validator: (v) => Validators.required(v, 'Nama'),
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),
                  CustomTextField(
                      controller: _tempatCtrl,
                      label: AppStrings.tempatLahirLabel,
                      validator: (v) => Validators.required(v, 'Tempat lahir'),
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),
                  _buildDateField('Tanggal Lahir', _tanggalLahir,
                      () => _pickTanggal(isHpht: false)),
                  const SizedBox(height: 14),
                  CustomTextField(
                      controller: _alamatCtrl,
                      label: AppStrings.alamatLabel,
                      maxLines: 3,
                      validator: (v) => Validators.required(v, 'Alamat')),
                  const SizedBox(height: 14),
                  CustomTextField(
                      controller: _noHpCtrl,
                      label: AppStrings.noHpLabel,
                      keyboardType: TextInputType.phone,
                      validator: Validators.noHp,
                      textInputAction: TextInputAction.done),
                  const SizedBox(height: 14),
                  _buildDateField(
                    AppStrings.hphtLabel,
                    _hpht,
                    () => _pickTanggal(isHpht: true),
                    sub: _hpht != null
                        ? 'Usia kehamilan: ${DateFormatter.usiaKehamilanMinggu(_hpht!)} minggu'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<GolonganDarah>(
                    value: _golDarah,
                    decoration: const InputDecoration(
                        labelText: AppStrings.golDarahLabel,
                        filled: true,
                        fillColor: AppColors.surface),
                    items: GolonganDarah.values
                        .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.value,
                                style: const TextStyle(fontSize: 16))))
                        .toList(),
                    onChanged: (v) => setState(() => _golDarah = v!),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                      label: AppStrings.simpan,
                      onPressed: isLoading ? null : _simpan),
                  const SizedBox(height: 24),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap,
      {String? sub}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  value != null
                      ? DateFormatter.toDisplay(value)
                      : 'Ketuk untuk memilih',
                  style: TextStyle(
                      fontSize: 16,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint)),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600))
              ],
            ]),
      ),
    );
  }
}
