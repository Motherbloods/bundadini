import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class KonfirmasiDialog extends StatelessWidget {
  final String title;
  final String message;
  final String labelYa;
  final String labelTidak;
  final bool isDangerous;

  const KonfirmasiDialog({
    super.key,
    required this.title,
    required this.message,
    this.labelYa = AppStrings.ya,
    this.labelTidak = AppStrings.tidak,
    this.isDangerous = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String labelYa = AppStrings.ya,
    String labelTidak = AppStrings.tidak,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => KonfirmasiDialog(
        title: title,
        message: message,
        labelYa: labelYa,
        labelTidak: labelTidak,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(labelTidak),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDangerous
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          child: Text(labelYa),
        ),
      ],
    );
  }
}
