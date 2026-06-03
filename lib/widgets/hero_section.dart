import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'scroll_indicator.dart';
import 'starfield.dart';
import 'ui.dart';

/// QA-only override: set to a fixed pixel height so the full page can be
/// captured in one screenshot (the headless renderer can't scroll Flutter).
/// MUST be null in production so the hero fills the viewport.
const double? _qaHeight = null;

class HeroSection extends StatelessWidget {
  final VoidCallback onSeeWork;
  const HeroSection({super.key, required this.onSeeWork});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final h = MediaQuery.of(context).size.height;
    // Explicit height (not minHeight): the hero lives inside a scroll view, so
    // an unbounded height would collapse the bottom-aligned scroll indicator.
    final heroH = _qaHeight ?? (h < 700 ? 700.0 : h);
    return Container(
      height: heroH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00224A), AppTheme.background, AppTheme.deepSpace],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  narrow ? 24 : 48, 120, narrow ? 24 : 48, 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Chip2('AI VENTURE STUDIO', dot: AppTheme.gold),
                    SizedBox(height: narrow ? 24 : 30),
                    GradientText(
                      'The AI layer for companies\nthat know their domain cold.',
                      style: AppTheme.display(narrow ? 36 : 60),
                    ),
                    SizedBox(height: narrow ? 20 : 26),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 660),
                      child: Text(
                        'You bring the expertise. We build the AI that makes it 10x, '
                        'from dental imaging to pipe inspection. Partner with us, or '
                        'start a self-serve MVP and grow from there.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(narrow ? 16 : 18.5),
                      ),
                    ),
                    SizedBox(height: narrow ? 32 : 40),
                    Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        PrimaryButton(
                          label: 'Start a project',
                          icon: Icons.arrow_forward_rounded,
                          onTap: () => context.go('/start'),
                        ),
                        GhostButton(
                          label: 'See our work',
                          icon: Icons.grid_view_rounded,
                          onTap: onSeeWork,
                        ),
                      ],
                    ),
                    SizedBox(height: narrow ? 40 : 52),
                    _trustRow(narrow),
                  ],
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: ScrollIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustRow(bool narrow) {
    return Column(
      children: [
        Text('CURRENTLY BUILDING',
            style: AppTheme.eyebrow()
                .copyWith(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 3)),
        const SizedBox(height: 14),
        Wrap(
          spacing: narrow ? 20 : 36,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final n in ['Mandible', 'WickHackers', 'Myelin / GYRI'])
              Text(n,
                  style: AppTheme.heading(narrow ? 15 : 17,
                      color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}
