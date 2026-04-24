import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../_widgets/custom_button.dart';
import '../../_widgets/custom_text_field.dart';
import '../../_widgets/loading_overlay.dart';

class AddKaderScreen extends StatefulWidget {
  const AddKaderScreen({super.key});
  @override
  State<AddKaderScreen> createState() => _AddKaderScreenState();
}

class _AddKaderScreenState extends State<AddKaderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.registerKader(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      nama: _namaCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kader berhasil didaftarkan'),
          backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.errorMessage ?? 'Gagal mendaftarkan kader'),
          backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mendaftarkan kader...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.tambahKader)),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3))),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.info, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Kader akan dapat login menggunakan email dan kata sandi yang didaftarkan di sini.',
                              style: TextStyle(
                                  color: AppColors.info, fontSize: 14))),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _namaCtrl,
                    label: 'Nama Lengkap Kader',
                    prefixIcon: Icons.person_rounded,
                    validator: (v) => Validators.required(v, 'Nama'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _emailCtrl,
                    label: AppStrings.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _passCtrl,
                    label: 'Kata Sandi',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscure,
                    validator: Validators.password,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _simpan(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecond),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Minimal 6 karakter. Kader bisa mengubah sendiri setelah login.',
                      style:
                          TextStyle(color: AppColors.textSecond, fontSize: 13)),
                  const SizedBox(height: 28),

                  CustomButton(
                      label: 'Daftarkan Kader',
                      onPressed: isLoading ? null : _simpan,
                      icon: Icons.person_add_rounded),
                  const SizedBox(height: 24),
                ]),
          ),
        ),
      ),
    );
  }
}
