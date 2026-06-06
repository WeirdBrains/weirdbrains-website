import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class TopNav extends StatelessWidget {
  final bool scrolled;
  final VoidCallback onWork;
  final VoidCallback onApproach;
  const TopNav(
      {super.key,
      required this.scrolled,
      required this.onWork,
      required this.onApproach});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
          horizontal: narrow ? 20 : 40, vertical: scrolled ? 14 : 22),
      decoration: BoxDecoration(
        color: scrolled
            ? AppTheme.background.withValues(alpha: 0.9)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContent),
          child: Row(
            children: [
              _wordmark(context),
              const Spacer(),
              if (!narrow) ...[
                _link('Work', onWork),
                const SizedBox(width: 28),
                _link('Approach', onApproach),
                const SizedBox(width: 28),
                _link('Contact', () => context.go('/start')),
                const SizedBox(width: 28),
              ],
              PrimaryButton(
                label: 'Start a project',
                onTap: () => context.go('/start'),
                large: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordmark(BuildContext context) {
    return Hoverable(
      onTap: () => context.go('/'),
      builder: (h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text('Weird Brains',
              style: AppTheme.heading(18).copyWith(
                  color: h ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) {
    return Hoverable(
      onTap: onTap,
      builder: (h) => Text(
        label,
        style: AppTheme.body(15,
            color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
            height: 1.0),
      ),
    );
  }
}
