import 'package:flutter/material.dart';
import '../theme/qai_theme.dart';
import '../widgets/ shared_widgets.dart';

// ─── 3A.1 Focus Span ─────────────────────────────────────────
class FocusSpanScreen extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const FocusSpanScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const ticks = ['15m', '30m', '45m', '60m', '90m', '120m+'];
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.33),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Maximize Your Focus.',
              subtitle:
              'What is your typical continuous focus time before distraction?',
            ),
            Expanded(
              child: Center(
                child: TickSlider(
                  ticks: ticks,
                  value: value,
                  onChange: onChange,
                ),
              ),
            ),
            QFooter(child: PrimaryButton(label: 'Continue', onPressed: onNext)),
          ],
        ),
      ),
    );
  }
}

// ─── 3A.2 Learning Style ─────────────────────────────────────
class LearningStyleScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const LearningStyleScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'visual', 'label': 'Visual', 'sub': 'Diagrams, charts, color cues', 'icon': Icons.visibility_outlined},
      {'id': 'auditory', 'label': 'Auditory', 'sub': 'Lectures and discussion', 'icon': Icons.hearing_outlined},
      {'id': 'reading', 'label': 'Reading & Writing', 'sub': 'Notes, articles, summaries', 'icon': Icons.menu_book_outlined},
      {'id': 'kinetic', 'label': 'Kinesthetic & Practice', 'sub': 'Hands-on, problem solving', 'icon': Icons.front_hand_outlined},
    ];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.66),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Define Your Input.',
              subtitle: 'How do you naturally absorb academic information best?',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconCardRow(
                        id: item['id'] as String,
                        label: item['label'] as String,
                        subtitle: item['sub'] as String,
                        icon: Icon(item['icon'] as IconData),
                        selected: value == item['id'],
                        onTap: () => onChange(item['id'] as String),
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

// ─── 3A.3 Workflow ───────────────────────────────────────────
class WorkflowScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const WorkflowScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'planner', 'label': 'I prefer planning ahead and starting early.'},
      {'id': 'pressure', 'label': 'I perform best under pressure near the deadline.'},
      {'id': 'procrast', 'label': 'I frequently struggle with procrastination.'},
    ];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.99),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Calibrate Workflow.',
              subtitle: 'How do you generally handle imminent deadlines?',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextCardRow(
                        label: item['label'] as String,
                        selected: value == item['id'],
                        onTap: () => onChange(item['id'] as String),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(
                    label: 'Complete Calibration',
                    onPressed: onNext,
                    disabled: value == null)),
          ],
        ),
      ),
    );
  }
}

// ─── 3B.1 Workload ───────────────────────────────────────────
class WorkloadScreen extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const WorkloadScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const ticks = ['1-2h', '4h', '6h', '8h', '10h+'];
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.33),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Optimize Your Workflow.',
              subtitle:
              'On average, how many hours do you spend daily on grading and lesson preparation?',
            ),
            Expanded(
              child: Center(
                child: TickSlider(
                  ticks: ticks,
                  value: value,
                  onChange: onChange,
                ),
              ),
            ),
            QFooter(child: PrimaryButton(label: 'Continue', onPressed: onNext)),
          ],
        ),
      ),
    );
  }
}

// ─── 3B.2 Challenges ─────────────────────────────────────────
class ChallengesScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ChallengesScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'motivation', 'label': 'Student Motivation', 'sub': 'Engagement and retention', 'icon': Icons.star_border_outlined},
      {'id': 'admin', 'label': 'Administrative Load', 'sub': 'Paperwork and reporting', 'icon': Icons.folder_outlined},
      {'id': 'digital', 'label': 'Digital Integration', 'sub': 'Tools and tech in class', 'icon': Icons.laptop_outlined},
      {'id': 'class', 'label': 'Large Class Sizes', 'sub': 'Personalization at scale', 'icon': Icons.people_outline},
    ];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.66),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Identify Challenges.',
              subtitle:
              'What is the primary obstacle in your current teaching environment?',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconCardRow(
                        id: item['id'] as String,
                        label: item['label'] as String,
                        subtitle: item['sub'] as String,
                        icon: Icon(item['icon'] as IconData),
                        selected: value == item['id'],
                        onTap: () => onChange(item['id'] as String),
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

// ─── 3B.3 AI Preference ──────────────────────────────────────
class AIPrefScreen extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const AIPrefScreen({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'grading', 'label': 'Automated Grading & Feedback.'},
      {'id': 'content', 'label': 'Smart Content & Lesson Planning.'},
      {'id': 'analytics', 'label': 'Behavioral & Performance Analytics.'},
    ];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: onBack, progress: 0.99),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Customize Your AI.',
              subtitle: 'How would you like the AI to assist your teaching most?',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextCardRow(
                        label: item['label'] as String,
                        selected: value == item['id'],
                        onTap: () => onChange(item['id'] as String),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(
                    label: 'Complete Calibration',
                    onPressed: onNext,
                    disabled: value == null)),
          ],
        ),
      ),
    );
  }
}