import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SectionShell(
      color: AppTheme.deepSpace,
      top: 64,
      bottom: 48,
      child: Column(
        children: [
          Flex(
            direction: narrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                narrow ? CrossAxisAlignment.start : CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: narrow ? 0 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🧠', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text('Weird Brains', style: AppTheme.heading(18)),
                    ]),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'The AI layer for companies that know their domain cold.',
                        style: AppTheme.body(14.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (narrow) const SizedBox(height: 36),
              _col('Studio', [
                _L('Work', null),
                _L('Approach', null),
                _L('Start a project', () => _go(context, '/start')),
              ]),
              if (narrow) const SizedBox(height: 28),
              _col('Contact', [
                _L('hello@weirdbrains.com',
                    () => _mail('hello@weirdbrains.com')),
                _L('weirdbrains.com', null),
              ]),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 22),
          Flex(
            direction: narrow ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('© 2026 Weird Brains. All rights reserved.',
                  style: AppTheme.body(13, color: AppTheme.textMuted)),
              if (narrow) const SizedBox(height: 10),
              Text('Built with agents, gated by humans.',
                  style: AppTheme.body(13, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _col(String title, List<_L> links) {
    return Expanded(
      flex: 0,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: AppTheme.eyebrow()
                    .copyWith(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 16),
            for (final l in links) ...[
              Hoverable(
                onTap: l.onTap,
                builder: (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l.label,
                      style: AppTheme.body(14.5,
                          color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
                          height: 1.0)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _go(BuildContext context, String path) => context.go(path);

  static Future<void> _mail(String addr) async {
    final uri = Uri.parse('mailto:$addr');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _L {
  final String label;
  final VoidCallback? onTap;
  const _L(this.label, this.onTap);
}
