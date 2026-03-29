import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Column(
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('© 2026 Weird Brains',
                style: TextStyle(color: AppTheme.textSecondary)),
              const Text('gilbert@weirdbrains.ai',
                style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
