import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScrollIndicator extends StatefulWidget {
  const ScrollIndicator({super.key});

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _animation.value * 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCROLL',
              style: AppTheme.eyebrow().copyWith(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.7), width: 1.5),
                    bottom: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.7), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
