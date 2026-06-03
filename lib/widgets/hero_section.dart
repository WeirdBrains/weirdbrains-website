import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'scroll_indicator.dart';
import 'starfield.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 720;
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF002247), AppTheme.background, AppTheme.deepSpace],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 24 : 48, vertical: 64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _eyebrow(isNarrow),
                    const SizedBox(height: 28),
                    _gradientHeadline(context, isNarrow),
                    const SizedBox(height: 24),
                    Text(
                      'You bring the expertise. We build the AI that makes it 10x, '
                      'from dental imaging to pipe inspection. Partner with us, or '
                      'start a self-serve MVP and grow from there.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                            fontSize: isNarrow ? 16 : 18,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buttons(context),
                    const SizedBox(height: 56),
                    const ScrollIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(bool isNarrow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🧠', style: TextStyle(fontSize: isNarrow ? 16 : 18)),
        const SizedBox(width: 10),
        Text(
          'WEIRD BRAINS',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            fontSize: isNarrow ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _gradientHeadline(BuildContext context, bool isNarrow) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: AppTheme.brandGradient,
      ).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(
        'The AI layer for companies\nthat know their domain cold.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white, // masked by the gradient
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.1,
              fontSize: isNarrow ? 34 : 52,
            ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        // Primary: filled purple pill.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purple.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: () => context.go('/start'),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Start a project',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.purple,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
        // Secondary: ghost pill.
        OutlinedButton.icon(
          onPressed: () => Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 1),
          ),
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: const Text('See our work', style: TextStyle(fontSize: 16)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ],
    );
  }
}
