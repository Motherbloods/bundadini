import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isOffline ? 36 : 0,
        color: AppColors.warning,
        child: isOffline
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Tidak ada koneksi internet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
      Expanded(child: child),
    ]);
  }
}
