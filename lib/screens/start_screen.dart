import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/intake_service.dart';

/// Multi-step consultation intake. Captures enough to qualify a lead, then
/// hands off to the backend (which scores it and routes to Telegram for
/// human approval before any follow-up is sent).
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _done ? _buildDone(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackToHome(),
          const SizedBox(height: 32),
          Text(
            'Start a project',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us what you do and where AI could help. We read every one.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          _StepDots(current: _step, total: 3),
          const SizedBox(height: 32),
          ..._buildStep(context),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF7A7A), height: 1.4)),
          ],
          const SizedBox(height: 32),
          _buildNav(context),
        ],
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
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'A human reviews every request before we reach out. No spam, no autoresponders.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
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
          TextButton(
            onPressed: _submitting ? null : _back,
            child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _submitting ? null : (isLast ? _submit : _next),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isLast ? 'Send request' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_rounded, color: AppTheme.accent, size: 30),
        ),
        const SizedBox(height: 28),
        Text(
          'Got it.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your request is in. A human at Weird Brains will review it and reach out, '
          'usually within a day or two. If it is urgent, email hello@weirdbrains.com.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('← Back to home', style: TextStyle(color: AppTheme.accent)),
        ),
      ],
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
          style: const TextStyle(color: AppTheme.textPrimary),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A5A5A)),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF7A7A)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF7A7A)),
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
        return GestureDetector(
          onTap: () => onPick(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? AppTheme.accent : Colors.white10),
            ),
            child: Text(
              o,
              style: TextStyle(
                color: isSel ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
              ),
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      );
}

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppTheme.accent : Colors.white12,
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
    return TextButton(
      onPressed: () => context.go('/'),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: const Text('← Weird Brains', style: TextStyle(color: AppTheme.textSecondary)),
    );
  }
}
