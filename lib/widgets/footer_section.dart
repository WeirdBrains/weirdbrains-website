import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 720;
    return Container(
      color: AppTheme.background,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 24 : 48, vertical: 64),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Do you have a weird ',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: isNarrow ? 20 : 26,
                      fontWeight: FontWeight.w600)),
              Text('🧠', style: TextStyle(fontSize: isNarrow ? 20 : 26)),
              Text('?',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: isNarrow ? 20 : 26,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/start'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Start a project',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 48),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 24),
          Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Weird Brains',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              if (isNarrow) const SizedBox(height: 16),
              const Text('© 2026 Weird Brains · hello@weirdbrains.com',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
