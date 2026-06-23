import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/qai_theme.dart';
import '../widgets/ shared_widgets.dart';
// ─── Gender screen ────────────────────────────────────────────
class GenderScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const GenderScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, trailing: SkipButton(onTap: onSkip)),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Tell us about yourself.',
              subtitle: 'Help us personalize your academic journey.',
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1 / 1.1,
                      child: _GenderCard(
                        label: 'Male',
                        selected: value == 'male',
                        icon: const Icon(Icons.person_outline,
                            size: 48, color: QAI.ink),
                        onTap: () => onChange('male'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1 / 1.1,
                      child: _GenderCard(
                        label: 'Female',
                        selected: value == 'female',
                        icon: const Icon(Icons.person_outline,
                            size: 48, color: QAI.ink),
                        onTap: () => onChange('female'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            QFooter(
                child: PrimaryButton(
                    label: 'Continue',
                    onPressed: onNext,
                    disabled: value == null)),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectCard(
      selected: selected,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 18),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: QAI.ink,
              letterSpacing: -0.01 * 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Age screen ───────────────────────────────────────────────
class AgeScreen extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const AgeScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final display = value >= 65 ? '65+' : '$value';
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'How old are you?',
              subtitle: "We'll tailor your experience to your academic stage.",
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    display,
                    style: GoogleFonts.inter(
                      fontSize: 96,
                      fontWeight: FontWeight.w700,
                      color: QAI.ink,
                      letterSpacing: -0.06 * 96,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YEARS OLD',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: QAI.muted,
                      letterSpacing: 0.04 * 13,
                    ),
                  ),
                  const SizedBox(height: 56),
                  AgeSlider(value: value, onChange: onChange),
                ],
              ),
            ),
            QFooter(child: PrimaryButton(label: 'Continue', onPressed: onNext)),
          ],
        ),
      ),
    );
  }
}

// ─── Role screen ──────────────────────────────────────────────
class RoleScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const RoleScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      {
        'id': 'student',
        'label': 'I am a Student',
        'sub': 'Personalized study paths.',
        'icon': Icons.school_outlined,
      },
      {
        'id': 'teacher',
        'label': 'I am a Teacher',
        'sub': 'Smart teaching tools.',
        'icon': Icons.cast_for_education_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'What is your role?',
              subtitle: "Choose how you'll use Quill.AI.",
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  children: roles.map((r) {
                    final sel = value == r['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SelectCard(
                        selected: sel,
                        onTap: () => onChange(r['id'] as String),
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: sel ? QAI.ink : const Color(0xFFF3F2EC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                r['icon'] as IconData,
                                size: 28,
                                color: sel ? Colors.white : QAI.ink,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: QAI.ink,
                                        letterSpacing: -0.015 * 16,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(r['sub'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: QAI.muted,
                                        letterSpacing: -0.005,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(
                    label: 'Continue',
                    onPressed: onNext,
                    disabled: value == null)),
          ],
        ),
      ),
    );
  }
}