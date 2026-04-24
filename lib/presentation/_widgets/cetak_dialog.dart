import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class CetakDialog extends StatelessWidget {
  final VoidCallback onCetak;
  final VoidCallback onNanti;

  const CetakDialog({
    super.key,
    required this.onCetak,
    required this.onNanti,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCetak,
    required VoidCallback onNanti,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CetakDialog(onCetak: onCetak, onNanti: onNanti),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon sukses
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.berhasilDisimpan,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.cetakSekarang,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text(AppStrings.cetakPdf),
                onPressed: () {
                  Navigator.pop(context);
                  onCetak();
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onNanti();
                },
                child: const Text(AppStrings.nantiSaja),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
