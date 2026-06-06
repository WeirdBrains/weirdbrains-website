import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return SectionShell(
      color: AppTheme.deepSpace,
      top: 40,
      bottom: 40,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: narrow ? 28 : 64, vertical: narrow ? 48 : 72),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2A52), Color(0xFF120E33)],
          ),
          border: Border.all(color: AppTheme.borderStrong),
          boxShadow: [
            BoxShadow(
                color: AppTheme.purple.withValues(alpha: 0.22),
                blurRadius: 80,
                spreadRadius: -30),
          ],
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Do you have a weird ',
                    style: AppTheme.display(narrow ? 30 : 46)),
                Text('🧠', style: TextStyle(fontSize: narrow ? 30 : 46)),
                Text('?', style: AppTheme.display(narrow ? 30 : 46)),
              ],
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Tell us the problem. We will show you what agents can build, '
                'with you holding the gate the whole way.',
                textAlign: TextAlign.center,
                style: AppTheme.body(narrow ? 16 : 18),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Start a project',
              icon: Icons.arrow_forward_rounded,
              onTap: () => context.go('/start'),
            ),
          ],
        ),
      ),
    );
  }
}
