// lib/screens/home/coming_soon_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Placeholder body for features that aren't built yet.
class ComingSoonScreen extends StatelessWidget {
  final String feature;
  final VoidCallback onBack;
  final VoidCallback? onNotify;

  const ComingSoonScreen({
    super.key,
    required this.feature,
    required this.onBack,
    this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back header
        SizedBox(
          height: 56,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.chevron_left,
                    size: 28, color: AppColors.deepNavy),
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.lightTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 36, color: AppColors.teal),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "We're crafting this feature with care. It will be available "
                  "in the next version of Quill.AI.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.slateGray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: onNotify,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 16, color: AppColors.white),
                        SizedBox(width: 8),
                        Text(
                          'Notify me when ready',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onBack,
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slateGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}