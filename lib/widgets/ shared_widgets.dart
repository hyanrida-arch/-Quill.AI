import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/qai_theme.dart';

// ─── Primary CTA Button ───────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool disabled;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? QAI.disabledBtn : QAI.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: QAI.disabledBtn,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: disabled ? 0 : 4,
          shadowColor: QAI.ink.withOpacity(0.18),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.005 * 15.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Footer wrapper ──────────────────────────────────────────
class QFooter extends StatelessWidget {
  final Widget child;

  const QFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: child,
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────
class QTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget? trailing;
  final double? progress;

  const QTopBar({super.key, this.onBack, this.trailing, this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.chevron_left, size: 24, color: QAI.ink),
                  )
                else
                  const SizedBox(width: 24),
                if (trailing != null) trailing! else const SizedBox(),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: const Color(0xFFEFEDE7),
                valueColor: const AlwaysStoppedAnimation<Color>(QAI.ink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Headline block ──────────────────────────────────────────
class QHeadline extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign align;
  final double titleSize;

  const QHeadline({
    super.key,
    required this.title,
    this.subtitle,
    this.align = TextAlign.left,
    this.titleSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: align == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(title, style: QAI.headline(titleSize), textAlign: align),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: QAI.body(14),
              textAlign: align,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Selectable Card ─────────────────────────────────────────
class SelectCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets? padding;

  const SelectCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? QAI.cardSelected : Colors.white,
          border: Border.all(
            color: selected ? QAI.ink : QAI.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

// ─── Floating-label Field ────────────────────────────────────
class QField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChange;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final String? error;
  final bool readOnly;
  final VoidCallback? onTap;

  const QField({
    super.key,
    required this.label,
    required this.value,
    this.onChange,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
    this.error,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<QField> createState() => _QFieldState();
}

class _QFieldState extends State<QField> {
  late TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void didUpdateWidget(QField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _ctrl.text.length));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floating = _focused || widget.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: widget.error != null
                    ? const Color(0xFFC8442B)
                    : (_focused ? QAI.ink : QAI.border),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: 16,
                  top: floating ? 8 : 20,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: GoogleFonts.inter(
                      fontSize: floating ? 11 : 14,
                      fontWeight: floating ? FontWeight.w500 : FontWeight.w400,
                      color: _focused ? QAI.ink : QAI.muted,
                      letterSpacing: -0.005 * (floating ? 11 : 14),
                    ),
                    child: Text(widget.label),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: widget.trailing != null ? 48 : 16,
                  bottom: 0,
                  top: 22,
                  child: widget.readOnly
                      ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value,
                      style: QAI.label(15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                      : TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    obscureText: widget.obscure,
                    keyboardType: widget.keyboardType,
                    onChanged: widget.onChange,
                    style: QAI.label(15),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(child: widget.trailing!),
                  ),
              ],
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.error!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFC8442B),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Tick Slider ─────────────────────────────────────────────
class TickSlider extends StatelessWidget {
  final List<String> ticks;
  final int value;
  final ValueChanged<int> onChange;

  const TickSlider({
    super.key,
    required this.ticks,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            ticks[value],
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: QAI.ink,
              letterSpacing: -0.04 * 36,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: QAI.ink,
              inactiveTrackColor: QAI.trackBg,
              thumbColor: QAI.ink,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 4,
              overlayColor: QAI.ink.withOpacity(0.1),
            ),
            child: Slider(
              min: 0,
              max: (ticks.length - 1).toDouble(),
              divisions: ticks.length - 1,
              value: value.toDouble(),
              onChanged: (v) => onChange(v.round()),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ticks
                .asMap()
                .entries
                .map((e) => Text(
              e.value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: e.key == value ? QAI.ink : QAI.hint,
                letterSpacing: -0.005,
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Age Slider ──────────────────────────────────────────────
class AgeSlider extends StatelessWidget {
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChange;

  const AgeSlider({
    super.key,
    this.min = 13,
    this.max = 65,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [13, 20, 30, 40, 50, 65];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: QAI.ink,
              inactiveTrackColor: QAI.trackBg,
              thumbColor: QAI.ink,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 4,
              overlayColor: QAI.ink.withOpacity(0.1),
            ),
            child: Slider(
              min: min.toDouble(),
              max: max.toDouble(),
              value: value.toDouble(),
              onChanged: (v) => onChange(v.round()),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((l) => Text(
              l == 65 ? '65+' : '$l',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: (value - l).abs() ==
                    labels
                        .map((x) => (value - x).abs())
                        .reduce((a, b) => a < b ? a : b)
                    ? QAI.ink
                    : QAI.hint,
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Page Dots ───────────────────────────────────────────────
class PageDots extends StatelessWidget {
  final int count;
  final int active;

  const PageDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? QAI.ink : const Color(0xFFD8D6D0),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Icon Card Row (for calibration screens) ─────────────────
class IconCardRow extends StatelessWidget {
  final String id;
  final String label;
  final String? subtitle;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  const IconCardRow({
    super.key,
    required this.id,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? QAI.ink : const Color(0xFFF3F2EC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: selected ? Colors.white : QAI.ink,
                size: 20,
              ),
              child: icon,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: QAI.ink,
                      letterSpacing: -0.01 * 15,
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: QAI.muted,
                        letterSpacing: -0.005,
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RadioDot(selected: selected),
        ],
      ),
    );
  }
}

// ─── Text Card Row (for workflow, ai-pref) ───────────────────
class TextCardRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TextCardRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: QAI.ink,
                letterSpacing: -0.01 * 14.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RadioDot(selected: selected),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QAI.ink : const Color(0xFFD8D6D0),
          width: 1.5,
        ),
        color: selected ? QAI.ink : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 11, color: Colors.white)
          : null,
    );
  }
}

// ─── Skip text button ─────────────────────────────────────────
class SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const SkipButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Skip',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
          letterSpacing: -0.005,
        ),
      ),
    );
  }
}

// ─── Quill wordmark ───────────────────────────────────────────
class QWordmark extends StatelessWidget {
  final double size;

  const QWordmark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Quill',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: size,
            fontWeight: FontWeight.w500,
            color: QAI.ink,
            letterSpacing: -0.04 * size,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '.AI',
          style: GoogleFonts.inter(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w500,
            color: QAI.ink.withOpacity(0.7),
            letterSpacing: 0.02 * size * 0.5,
          ),
        ),
      ],
    );
  }
}