import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/qai_theme.dart';
import '../widgets/ shared_widgets.dart';
import 'app_data.dart';

// ─── Splash ───────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const SplashScreen({super.key, required this.onContinue});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onContinue,
      child: Scaffold(
        backgroundColor: QAI.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Quill icon
                    CustomPaint(size: const Size(36, 36), painter: _QuillPainter()),
                    const SizedBox(height: 18),
                    const QWordmark(size: 42),
                    const SizedBox(height: 14),
                    Text(
                      'THE ACADEMIC COMPANION',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: QAI.muted,
                        letterSpacing: 0.18 * 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Loading bar
              Positioned(
                bottom: 92,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 84,
                    height: 2,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _PulseBarPainter(_ctrl.value),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = QAI.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(28, 6)
      ..cubicTo(25, 12, 19, 17, 13, 20)
      ..lineTo(9, 29)
      ..lineTo(18, 25)
      ..cubicTo(21, 19, 26, 13, 32, 10)
      ..close();
    canvas.drawPath(path1, paint);

    canvas.drawLine(
        const Offset(9, 29), const Offset(14, 24), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PulseBarPainter extends CustomPainter {
  final double t;
  _PulseBarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = QAI.ink.withOpacity(0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(2)),
      bgPaint,
    );

    final w = size.width * 0.4;
    final left = (size.width + w) * t - w;
    final rect = Rect.fromLTWH(
      left.clamp(0.0, size.width),
      0,
      (left + w).clamp(0.0, size.width) - left.clamp(0.0, size.width),
      size.height,
    );
    if (rect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = QAI.ink,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseBarPainter old) => old.t != t;
}

// ─── Onboarding Shell ────────────────────────────────────────
class OnboardingScreen extends StatelessWidget {
  final int index;
  final Widget hero;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingScreen({
    super.key,
    required this.index,
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
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
            QTopBar(
              trailing: SkipButton(onTap: onSkip),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: hero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                    child: Column(
                      children: [
                        QHeadline(
                          title: title,
                          subtitle: subtitle,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        PageDots(count: 3, active: index),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            QFooter(child: PrimaryButton(label: ctaLabel, onPressed: onNext)),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Illustrations ───────────────────────────────────────
class HeroFocusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = QAI.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    // Rings
    for (final (r, op) in [(92.0, 0.12), (68.0, 0.20)]) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = QAI.ink.withOpacity(op)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Beams
    final angles = [-60, -40, -20, 0, 20, 40, 60];
    for (int i = 0; i < angles.length; i++) {
      final a = (angles[i] - 90) * pi / 180;
      final x = cx + cos(a) * 100;
      final y = cy + sin(a) * 100;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(x, y),
        Paint()
          ..color = QAI.ink
              .withOpacity(0.25 + (1 - angles[i].abs() / 60) * 0.5)
          ..strokeWidth = i == 3 ? 1.6 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = QAI.ink);
    canvas.drawCircle(
        Offset(cx, cy),
        11,
        Paint()
          ..color = QAI.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Horizon line
    canvas.drawLine(
        Offset(32, cy + 60),
        Offset(size.width - 32, cy + 60),
        Paint()
          ..color = QAI.ink.withOpacity(0.18)
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_) => false;
}

class HeroNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      const Offset(50, 60),
      const Offset(110, 38),
      const Offset(170, 70),
      const Offset(38, 130),
      const Offset(110, 110),
      const Offset(182, 140),
      const Offset(75, 180),
      const Offset(145, 178),
    ];
    final edges = [
      [0, 1], [1, 2], [0, 4], [1, 4], [2, 4],
      [3, 4], [5, 4], [6, 4], [7, 4], [3, 6],
      [5, 7], [0, 3], [2, 5], [6, 7],
    ];
    final radii = [4.0, 5.0, 4.0, 3.5, 7.0, 3.5, 4.0, 4.0];

    for (final e in edges) {
      final isCentral = e[0] == 4 || e[1] == 4;
      canvas.drawLine(
        nodes[e[0]],
        nodes[e[1]],
        Paint()
          ..color = QAI.ink.withOpacity(isCentral ? 0.55 : 0.22)
          ..strokeWidth = 1,
      );
    }
    for (int i = 0; i < nodes.length; i++) {
      if (i == 4) {
        canvas.drawCircle(
            nodes[i],
            radii[i] + 6,
            Paint()
              ..color = QAI.ink.withOpacity(0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      canvas.drawCircle(nodes[i], radii[i], Paint()..color = QAI.ink);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class HeroControlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cx = 110.0;
    const cy = 110.0;
    final circlePaint = Paint()
      ..color = QAI.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(const Offset(cx, cy), 78, circlePaint);

    // Ticks
    for (int i = 0; i < 12; i++) {
      final a = (i * 30 - 90) * pi / 180;
      final r1 = 70.0;
      final r2 = 76.0;
      canvas.drawLine(
        Offset(cx + cos(a) * r1, cy + sin(a) * r1),
        Offset(cx + cos(a) * r2, cy + sin(a) * r2),
        Paint()
          ..color = QAI.ink
          ..strokeWidth = i % 3 == 0 ? 1.6 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hands
    canvas.drawLine(
        const Offset(cx, cy),
        const Offset(cx, cy - 48),
        Paint()
          ..color = QAI.ink
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        const Offset(cx, cy),
        const Offset(cx + 38, cy),
        Paint()
          ..color = QAI.ink
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(cx, cy), 3.5, Paint()..color = QAI.ink);
  }

  @override
  bool shouldRepaint(_) => false;
}