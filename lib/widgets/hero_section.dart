import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'scroll_indicator.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Weird Brains',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'AI ventures at the intersection of domain expertise\nand emerging technology.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          const SizedBox(height: 24),
          const ScrollIndicator(),
        ],
      ),
    );
  }
}
