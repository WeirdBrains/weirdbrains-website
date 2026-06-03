import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class _Project {
  final String name;
  final String tagline;
  final String status;
  final String url;
  final List<Color> grad;
  const _Project(this.name, this.tagline, this.status, this.url, this.grad);
}

const _projects = [
  _Project(
    'Mandible',
    'AI-powered case platform for dental specialists. Collaborative imaging, second opinions, HIPAA-grade.',
    'Live',
    'https://mandible.ai',
    [AppTheme.purpleBright, AppTheme.purple],
  ),
  _Project(
    'WickHackers',
    'Algorithmic trading across Coinbase perps, Kalshi, and prediction markets.',
    'Active',
    '',
    [AppTheme.gold, Color(0xFFF59E0B)],
  ),
  _Project(
    'Myelin / GYRI',
    'A Rust L1 blockchain with usage-adaptive tokenomics, built to amplify AI work.',
    'In development',
    '',
    [AppTheme.sky, Color(0xFF2563EB)],
  ),
];

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SectionShell(
      color: AppTheme.deepSpace,
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'Current projects',
            title: 'What we are building',
            subtitle:
                'Ventures we own or build alongside, each a wedge into a real domain.',
          ),
          SizedBox(height: narrow ? 40 : 64),
          if (narrow)
            Column(
              children: [
                for (final p in _projects) ...[
                  _ProjectCard(p),
                  const SizedBox(height: 20),
                ],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < _projects.length; i++) ...[
                    Expanded(child: _ProjectCard(_projects[i])),
                    if (i != _projects.length - 1) const SizedBox(width: 24),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final _Project p;
  const _ProjectCard(this.p);

  Future<void> _open() async {
    if (p.url.isEmpty) return;
    final uri = Uri.parse(p.url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = p.url.isNotEmpty;
    return Hoverable(
      onTap: hasLink ? _open : null,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -4 : 0, 0),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.surface,
          border:
              Border.all(color: h ? AppTheme.borderStrong : AppTheme.border),
          boxShadow: h
              ? [
                  BoxShadow(
                    color: p.grad.first.withValues(alpha: 0.18),
                    blurRadius: 40,
                    spreadRadius: -10,
                  )
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: p.grad),
                  ),
                  child: Text(p.name.characters.first,
                      style: AppTheme.heading(20, color: Colors.white)),
                ),
                const Spacer(),
                _statusChip(p.status, p.grad.first),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(p.name, style: AppTheme.heading(22)),
                if (hasLink) ...[
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: Offset(h ? 0.25 : 0, 0),
                    child: Icon(Icons.north_east_rounded,
                        size: 18,
                        color: h ? AppTheme.purpleBright : AppTheme.textMuted),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(p.tagline, style: AppTheme.body(15.5, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTheme.body(12, color: color, height: 1.0)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
