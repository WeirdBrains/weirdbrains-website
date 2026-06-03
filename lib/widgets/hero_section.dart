import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'scroll_indicator.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 720;
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 24 : 48, vertical: 64),
      decoration: const BoxDecoration(color: AppTheme.background),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WEIRD BRAINS',
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                fontSize: isNarrow ? 13 : 14,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'The AI layer for companies\nthat know their domain cold.',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    height: 1.1,
                    fontSize: isNarrow ? 34 : 52,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'You bring the expertise. We build the AI that makes it 10x, '
              'from dental imaging to pipe inspection. Partner with us, or start '
              'a self-serve MVP and grow from there.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                    fontSize: isNarrow ? 16 : 18,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => context.go('/start'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Start a project',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'See our work',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            const ScrollIndicator(),
          ],
        ),
      ),
    );
  }
}
