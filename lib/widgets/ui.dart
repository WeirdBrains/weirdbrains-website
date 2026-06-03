import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared building blocks so every section shares one visual language.

bool isNarrow(BuildContext c) =>
    MediaQuery.of(c).size.width < AppTheme.mobileBreak;

/// Gradient-filled text (gold -> purple -> gold by default).
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;
  final List<Color> colors;
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.align = TextAlign.center,
    this.colors = AppTheme.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(text, textAlign: align, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// Lifts + brightens a child on hover. Used for cards and buttons.
class Hoverable extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  final VoidCallback? onTap;
  const Hoverable({super.key, required this.builder, this.onTap});

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap, child: widget.builder(_h)),
    );
  }
}

/// Primary gradient pill button with hover lift + glow.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool large;
  const PrimaryButton(
      {super.key, required this.label, required this.onTap, this.icon, this.large = true});

  @override
  Widget build(BuildContext context) {
    final padV = large ? 18.0 : 13.0;
    final padH = large ? 30.0 : 22.0;
    return Hoverable(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -2 : 0, 0),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: AppTheme.ctaGradient),
          boxShadow: [
            BoxShadow(
              color: AppTheme.purple.withValues(alpha: h ? 0.6 : 0.4),
              blurRadius: h ? 36 : 24,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTheme.body(large ? 16 : 14.5,
                        color: Colors.white, height: 1.0)
                    .copyWith(fontWeight: FontWeight.w600)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: large ? 18 : 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ghost (outlined) pill button with hover fill.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool large;
  const GhostButton(
      {super.key, required this.label, required this.onTap, this.icon, this.large = true});

  @override
  Widget build(BuildContext context) {
    final padV = large ? 18.0 : 13.0;
    final padH = large ? 30.0 : 22.0;
    return Hoverable(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          border: Border.all(
              color: Colors.white.withValues(alpha: h ? 0.4 : 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: large ? 18 : 16, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: AppTheme.body(large ? 16 : 14.5,
                    color: AppTheme.textPrimary, height: 1.0)),
          ],
        ),
      ),
    );
  }
}

/// Small bordered chip, e.g. an eyebrow badge.
class Chip2 extends StatelessWidget {
  final String text;
  final Color dot;
  const Chip2(this.text, {super.key, this.dot = AppTheme.gold});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Text(text, style: AppTheme.eyebrow().copyWith(color: AppTheme.textSecondary, letterSpacing: 2.5, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Centers content to maxContent with responsive padding + vertical rhythm.
class SectionShell extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double top;
  final double bottom;
  const SectionShell(
      {super.key, required this.child, this.color, this.top = 112, this.bottom = 112});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.fromLTRB(
          narrow ? 24 : 48, narrow ? top * 0.7 : top, narrow ? 24 : 48, narrow ? bottom * 0.7 : bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContent),
          child: child,
        ),
      ),
    );
  }
}

/// Consistent section header: eyebrow + gradient title + optional subtitle.
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final CrossAxisAlignment align;
  const SectionHeader(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.subtitle,
      this.align = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final center = align == CrossAxisAlignment.center;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTheme.eyebrow()),
        const SizedBox(height: 16),
        GradientText(
          title,
          align: center ? TextAlign.center : TextAlign.start,
          style: AppTheme.heading(narrow ? 30 : 42),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxText),
            child: Text(subtitle!,
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: AppTheme.body(narrow ? 16 : 18)),
          ),
        ],
      ],
    );
  }
}
