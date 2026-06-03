import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/intake_service.dart';
import '../widgets/starfield.dart';
import '../widgets/ui.dart';

/// Multi-step consultation intake. Captures enough to qualify a lead, then
/// hands off to the backend (which records it in the brain repo for triage).
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const _budgets = ['< \$10k', '\$10k–\$50k', '\$50k–\$150k', '\$150k+', 'Not sure yet'];
  static const _timelines = ['ASAP', '1–3 months', '3–6 months', 'Exploring'];

  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _project = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();

  String _budget = _budgets.first;
  String _timeline = _timelines.first;

  int _step = 0; // 0 project, 1 scope, 2 contact
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _company.dispose();
    _project.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _step0Valid =>
      _company.text.trim().isNotEmpty && _project.text.trim().length >= 12;

  void _next() {
    setState(() => _error = null);
    if (_step == 0 && !_step0Valid) {
      setState(() => _error = 'Tell us your company and a sentence or two about the project.');
      return;
    }
    setState(() => _step++);
  }

  void _back() => setState(() {
        _error = null;
        _step--;
      });

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final err = await const IntakeService().submit(IntakeRequest(
      company: _company.text.trim(),
      projectDescription: _project.text.trim(),
      budgetRange: _budget,
      timeline: _timeline,
      contactName: _name.text.trim(),
      contactEmail: _email.text.trim(),
    ));

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (err == null) {
        _done = true;
      } else {
        _error = err;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // subtle cosmic backdrop ties the form into the rest of the site
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.4, child: const Starfield()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _done ? _buildDone(context) : _buildForm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 60,
              spreadRadius: -20),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackToHome(),
            const SizedBox(height: 28),
            Text('Start a project', style: AppTheme.heading(30)),
            const SizedBox(height: 10),
            Text('Tell us what you do and where AI could help. We read every one.',
                style: AppTheme.body(15)),
            const SizedBox(height: 30),
            _StepBar(current: _step, total: 3),
            const SizedBox(height: 30),
            ..._buildStep(context),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTheme.body(14, color: const Color(0xFFFF8585), height: 1.4)),
            ],
            const SizedBox(height: 30),
            _buildNav(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return [
          _field(_company, 'Company', hint: 'Acme Grading Co.'),
          const SizedBox(height: 20),
          _field(
            _project,
            'What are you building?',
            hint: 'We run sliplining inspections and want AI to classify pipe condition from video.',
            maxLines: 4,
          ),
        ];
      case 1:
        return [
          const _Label('Budget range'),
          const SizedBox(height: 12),
          _chips(_budgets, _budget, (v) => setState(() => _budget = v)),
          const SizedBox(height: 28),
          const _Label('Timeline'),
          const SizedBox(height: 12),
          _chips(_timelines, _timeline, (v) => setState(() => _timeline = v)),
        ];
      default:
        return [
          _field(_name, 'Your name', hint: 'Jane Doe', validator: _required),
          const SizedBox(height: 20),
          _field(_email, 'Email', hint: 'jane@acme.com', validator: _email_),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppTheme.purpleBright),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A human reviews every request before we reach out. No spam, no autoresponders.',
                    style: AppTheme.body(13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Widget _buildNav(BuildContext context) {
    final isLast = _step == 2;
    return Row(
      children: [
        if (_step > 0)
          Hoverable(
            onTap: _submitting ? null : _back,
            builder: (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text('Back',
                  style: AppTheme.body(15,
                      color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
                      height: 1.0)),
            ),
          ),
        const Spacer(),
        if (_submitting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(colors: AppTheme.ctaGradient),
            ),
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          )
        else
          PrimaryButton(
            label: isLast ? 'Send request' : 'Continue',
            icon: isLast ? Icons.send_rounded : Icons.arrow_forward_rounded,
            onTap: isLast ? _submit : _next,
          ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppTheme.ctaGradient),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.purple.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: -6)
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 28),
          Text('Got it.', style: AppTheme.heading(30)),
          const SizedBox(height: 12),
          Text(
            'Your request is in. A human at Weird Brains will review it and reach out, '
            'usually within a day or two. If it is urgent, email hello@weirdbrains.com.',
            style: AppTheme.body(15.5),
          ),
          const SizedBox(height: 30),
          Hoverable(
            onTap: () => context.go('/'),
            builder: (h) => Text('← Back to home',
                style: AppTheme.body(15,
                    color: h ? AppTheme.purpleBright : AppTheme.purple,
                    height: 1.0)),
          ),
        ],
      ),
    );
  }

  // ---- small helpers ----

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 10),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          validator: validator,
          style: AppTheme.body(15.5, color: AppTheme.textPrimary, height: 1.4),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body(15, color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.background.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8585)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8585)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips(List<String> options, String selected, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final isSel = o == selected;
        return Hoverable(
          onTap: () => onPick(o),
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSel
                  ? AppTheme.purple.withValues(alpha: 0.16)
                  : (h ? Colors.white.withValues(alpha: 0.05) : AppTheme.background.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSel ? AppTheme.purple : AppTheme.border),
            ),
            child: Text(
              o,
              style: AppTheme.body(14.5,
                  color: isSel ? AppTheme.purpleBright : AppTheme.textSecondary,
                  height: 1.0).copyWith(
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? _email_(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.heading(15.5));
}

class _StepBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            height: 4,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [AppTheme.purpleBright, AppTheme.sky])
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _BackToHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: () => context.go('/'),
      builder: (h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('Weird Brains',
              style: AppTheme.body(14,
                  color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
                  height: 1.0)),
        ],
      ),
    );
  }
}
