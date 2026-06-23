// lib/widgets/home/mystro_insight_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MystroInsightCard extends StatelessWidget {
  final String message;
  final String primaryButtonLabel;
  final String secondaryButtonLabel;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  const MystroInsightCard({
    super.key,
    required this.message,
    this.primaryButtonLabel = 'Schedule it',
    this.secondaryButtonLabel = 'Not now',
    this.onPrimaryTap,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal),
              const SizedBox(width: 6),
              const Text(
                'MYSTRO · INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PillButton(
                label: primaryButtonLabel,
                onTap: onPrimaryTap,
                isPrimary: true,
              ),
              const SizedBox(width: 8),
              _PillButton(
                label: secondaryButtonLabel,
                onTap: onSecondaryTap,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _PillButton({
    required this.label,
    this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? AppColors.white : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPrimary ? AppColors.deepNavy : AppColors.white,
          ),
        ),
      ),
    );
  }
}