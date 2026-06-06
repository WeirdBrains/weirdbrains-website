import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class _Step {
  final String n;
  final String title;
  final String body;
  const _Step(this.n, this.title, this.body);
}

const _steps = [
  _Step('01', 'Tell us the problem',
      'Describe your project and budget. An agent asks the sharp questions, so what we capture is real, not a vague brief.'),
  _Step('02', 'Agents scope and build',
      'Local agents research, scope, and build as far as they can on their own, often before you have spent a dollar.'),
  _Step('03', 'You approve, we ship',
      'Every gate is yours. Approve, and we deliver. Then you and the agents iterate together until it is right.'),
];

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SectionShell(
      color: AppTheme.background,
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'How it works',
            title: 'A ping-pong with agents',
            subtitle:
                'Agents do most of the work. You stay the gate in the middle, where the judgment lives.',
          ),
          SizedBox(height: narrow ? 44 : 72),
          if (narrow)
            Column(
              children: [
                for (int i = 0; i < _steps.length; i++) ...[
                  _StepBlock(_steps[i]),
                  if (i != _steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Icon(Icons.arrow_downward_rounded,
                          color: AppTheme.textMuted, size: 22),
                    ),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _steps.length; i++) ...[
                  Expanded(child: _StepBlock(_steps[i])),
                  if (i != _steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.textMuted, size: 22),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StepBlock extends StatelessWidget {
  final _Step step;
  const _StepBlock(this.step);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(step.n,
              align: TextAlign.start,
              style: AppTheme.display(40),
              colors: const [AppTheme.purpleBright, AppTheme.sky]),
          const SizedBox(height: 18),
          Text(step.title, style: AppTheme.heading(20)),
          const SizedBox(height: 12),
          Text(step.body, style: AppTheme.body(15.5, height: 1.65)),
        ],
      ),
    );
  }
}
