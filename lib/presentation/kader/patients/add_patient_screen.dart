import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/custom_text_field.dart';
import '../../_widgets/loading_overlay.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});
  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _tempatCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();

  DateTime? _tanggalLahir;
  DateTime? _hpht;
  GolonganDarah _golDarah = GolonganDarah.o;
  File? _fotoFile;
  bool _nikLoading = false;

  final FocusNode _blankFocus = FocusNode();

  @override
  void dispose() {
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _tempatCtrl.dispose();
    _alamatCtrl.dispose();
    _noHpCtrl.dispose();
    _blankFocus.dispose();
    super.dispose();
  }

  Future<void> _pickFoto(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 75, maxWidth: 800);
    if (picked != null) setState(() => _fotoFile = File(picked.path));
    if (mounted) Navigator.pop(context);
  }

  void _showFotoPicker() {
    FocusScope.of(context).requestFocus(_blankFocus);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading:
                const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            title: const Text(AppStrings.ambilFoto,
                style: TextStyle(fontSize: 16)),
            onTap: () => _pickFoto(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppColors.primary),
            title: const Text(AppStrings.pilihGaleri,
                style: TextStyle(fontSize: 16)),
            onTap: () => _pickFoto(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _pickTanggal({required bool isHpht}) async {
    FocusScope.of(context).requestFocus(_blankFocus);

    await Future.delayed(const Duration(milliseconds: 150));

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isHpht
          ? now.subtract(const Duration(days: 60))
          : DateTime(now.year - 25),
      firstDate: isHpht ? DateTime(now.year - 1) : DateTime(now.year - 60),
      lastDate: isHpht ? now : DateTime(now.year - 10),
      helpText: isHpht ? 'Pilih Tanggal HPHT' : 'Pilih Tanggal Lahir',
    );
    if (picked != null) {
      setState(() => isHpht ? _hpht = picked : _tanggalLahir = picked);
    }
  }

  Future<void> _checkNik() async {
    final err = Validators.nik(_nikCtrl.text);
    if (err != null) return;
    setState(() => _nikLoading = true);
    final existing =
        await context.read<PatientProvider>().checkNik(_nikCtrl.text.trim());
    setState(() => _nikLoading = false);
    if (existing != null && mounted) _showTransferSheet(existing);
  }

  void _showTransferSheet(PatientModel existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.85, // ← max 85% layar
          ),
          child: SingleChildScrollView(
            // ← bisa scroll jika konten panjang
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 28),
                  const SizedBox(width: 10),
                  Text(AppStrings.nikDuplikat,
                      style: Theme.of(context).textTheme.titleLarge),
                ]),
                const SizedBox(height: 12),
                Text('${existing.nama} (NIK: ${existing.nik}) sudah terdaftar.',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text('Apakah ingin memindahkan pasien ini ke kader Anda?',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecond)),
                const SizedBox(height: 20),
                CustomButton(
                  label: AppStrings.transferKader,
                  onPressed: () async {
                    Navigator.pop(context);
                    final auth = context.read<AuthProvider>();
                    final ok =
                        await context.read<PatientProvider>().transferKader(
                              patientId: existing.id,
                              newKaderId: auth.currentUser!.id,
                              newKaderNama: auth.currentUser!.nama,
                              oldKaderId: existing.kaderId,
                            );
                    if (mounted && ok) context.pop();
                  },
                ),
                const SizedBox(height: 10),
                CustomButton.outline(
                    label: AppStrings.batalTransfer,
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final tanggalErr = DateFormatter.tanggalLahir(_tanggalLahir);
    if (tanggalErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tanggalErr),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_fotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(AppStrings.fotoWajib),
          backgroundColor: AppColors.danger));
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final now = DateTime.now();
    final patient = PatientModel(
      id: '',
      nik: _nikCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      tempatLahir: _tempatCtrl.text.trim(),
      tanggalLahir: _tanggalLahir!,
      alamat: _alamatCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      hpht: _hpht,
      golonganDarah: _golDarah,
      fotoUrl: '',
      kaderId: auth.currentUser!.id,
      bidanId: '',
      status: StatusPasien.aktif,
      createdAt: now,
      updatedAt: now,
    );
    final existing =
        await context.read<PatientProvider>().checkNik(_nikCtrl.text.trim());
    if (existing != null) {
      _showTransferSheet(existing);
      return;
    }
    final ok =
        await context.read<PatientProvider>().addPatient(patient, _fotoFile!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pasien berhasil didaftarkan'),
          backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<PatientProvider>().errorMessage ??
              'Gagal menyimpan'),
          backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PatientProvider>().isLoading;
    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Menyimpan data...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.tambahPasien)),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24 + 40,
              ),
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
                            child: _fotoFile != null
                                ? Image.file(_fotoFile!,
                                    width: 120, height: 120, fit: BoxFit.cover)
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: AppColors.redPale,
                                    child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_rounded,
                                              color: AppColors.primary,
                                              size: 36),
                                          SizedBox(height: 6),
                                          Text('Tambah Foto *',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                        ]),
                                  ),
                          ),
                          if (_fotoFile != null)
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

                    // NIK + cek duplikat
                    Row(children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _nikCtrl,
                          label: AppStrings.nikLabel,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16)
                          ],
                          validator: Validators.nik,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _checkNik(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _nikLoading
                          ? const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.primary))
                          : IconButton(
                              icon: const Icon(Icons.manage_search_rounded,
                                  size: 28, color: AppColors.primary),
                              onPressed: _checkNik,
                              tooltip: 'Cek NIK'),
                    ]),
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
                        validator: (v) =>
                            Validators.required(v, 'Tempat lahir'),
                        textInputAction: TextInputAction.next),
                    const SizedBox(height: 14),

                    // Tanggal Lahir
                    _buildDateField('Tanggal Lahir *', _tanggalLahir,
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

                    // HPHT
                    _buildDateField(
                      'HPHT — Opsional',
                      _hpht,
                      () => _pickTanggal(isHpht: true),
                      sub: _hpht != null
                          ? 'Usia kehamilan: ${DateFormatter.usiaKehamilanFormatted(_hpht)}\n'
                              'HPL: ${DateFormatter.hplFormatted(_hpht)}'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jika ibu tidak ingat HPHT, bisa diisi nanti melalui Edit Biodata.',
                      style: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Golongan Darah
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
