import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../_widgets/custom_button.dart';
import '../_widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;

    if (ok) {
      final dest = auth.currentUser?.role == UserRole.bidan
          ? AppRoutes.bidanDashboard
          : AppRoutes.kaderHome;

      context.go(dest);
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: _hideKeyboard,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 56),

                          // Header
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 95,
                                  height: 95,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/icons/logo.jpg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppStrings.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.appTagline,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecond,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Masuk ke Akun Anda',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 20),

                                  // Email
                                  CustomTextField(
                                    controller: _emailCtrl,
                                    label: AppStrings.email,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: Validators.email,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  CustomTextField(
                                    controller: _passCtrl,
                                    label: AppStrings.password,
                                    obscureText: _obscure,
                                    prefixIcon: Icons.lock_outline,
                                    validator: Validators.password,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textSecond,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Error message
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) {
                                      if (auth.errorMessage == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4, bottom: 4),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerLight,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: AppColors.danger,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  auth.errorMessage!,
                                                  style: const TextStyle(
                                                    color: AppColors.danger,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Tombol Masuk
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) => CustomButton(
                                      label: auth.isLoading
                                          ? AppStrings.loginLoading
                                          : AppStrings.loginButton,
                                      onPressed: auth.isLoading ? null : _login,
                                      isLoading: auth.isLoading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          Column(
                            children: [
                              Text(
                                'Hubungi bidan jika lupa kata sandi',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecond),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _FooterLink(
                                    label: 'Tentang Aplikasi',
                                    icon: Icons.info_outline_rounded,
                                    onTap: () => context.push(AppRoutes.about),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.textSecond,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _FooterLink(
                                    label: 'Kebijakan Pengguna',
                                    icon: Icons.shield_outlined,
                                    onTap: () =>
                                        context.push(AppRoutes.privacy),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ));
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
