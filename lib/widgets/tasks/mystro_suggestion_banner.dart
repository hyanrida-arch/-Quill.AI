// lib/widgets/tasks/mystro_suggestion_banner.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MystroSuggestionBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const MystroSuggestionBanner({
    super.key,
    required this.message,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightTeal,
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: BorderSide(color: AppColors.teal, width: 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.teal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.deepNavy,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Mystro suggests ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: message),
                  ],
                ),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.slateGray,
                ),
              ),
          ],
        ),
      ),
    );
  }
}