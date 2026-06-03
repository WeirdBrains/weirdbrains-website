import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class _Cap {
  final IconData icon;
  final List<Color> grad;
  final String title;
  final String body;
  const _Cap(this.icon, this.grad, this.title, this.body);
}

const _caps = [
  _Cap(
    Icons.center_focus_strong_rounded,
    [AppTheme.purpleBright, AppTheme.purple],
    'Domain-deep, not generic',
    'We build the AI wedge for companies that own a vertical. The platforms ship generic apps. We go deep where they will not, dental imaging, pipe inspection, the work that needs real domain knowledge.',
  ),
  _Cap(
    Icons.bolt_rounded,
    [AppTheme.gold, Color(0xFFF59E0B)],
    'Agents do the work',
    'You describe the problem. Agents scope it and build as far as they can. You approve at every gate, we ship. It is a ping-pong between you and the agents, not months of hand-holding.',
  ),
  _Cap(
    Icons.shield_moon_rounded,
    [AppTheme.sky, Color(0xFF2563EB)],
    'Yours, and sovereign',
    'It runs on your infrastructure when it has to. HIPAA-ready, on-prem capable, powered by local models. Your data never has to leave your walls, a door the big platforms cannot walk through.',
  ),
];

class CapabilitiesSection extends StatelessWidget {
  const CapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SectionShell(
      color: AppTheme.background,
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'What we do',
            title: 'We are the AI layer',
            subtitle:
                'Three things the platforms can\'t sell you, no matter how good their agents get.',
          ),
          SizedBox(height: narrow ? 40 : 64),
          if (narrow)
            Column(
              children: [
                for (final c in _caps) ...[
                  _Card(c),
                  const SizedBox(height: 20),
                ],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < _caps.length; i++) ...[
                    Expanded(child: _Card(_caps[i])),
                    if (i != _caps.length - 1) const SizedBox(width: 24),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final _Cap cap;
  const _Card(this.cap);

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -4 : 0, 0),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.surface,
          border: Border.all(
              color: h ? AppTheme.borderStrong : AppTheme.border),
          boxShadow: h
              ? [
                  BoxShadow(
                    color: cap.grad.first.withValues(alpha: 0.18),
                    blurRadius: 40,
                    spreadRadius: -10,
                  )
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: cap.grad),
                boxShadow: [
                  BoxShadow(
                      color: cap.grad.first.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: -6)
                ],
              ),
              child: Icon(cap.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 22),
            Text(cap.title, style: AppTheme.heading(21)),
            const SizedBox(height: 12),
            Text(cap.body, style: AppTheme.body(15.5, height: 1.65)),
          ],
        ),
      ),
    );
  }
}
