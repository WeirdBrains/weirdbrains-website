import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/intake_service.dart';
import '../services/voice_service.dart';
import '../services/voice_support.dart';
import '../services/portal_read_service.dart';
import '../widgets/starfield.dart';
import '../widgets/ui.dart';
import '../widgets/genui_read.dart';

/// The portal. Problem-first, voice-enabled, and it shows AI reducing friction
/// on the way to capturing a lead. State flows:
///   problem -> thinking -> scoped -> contact -> done
enum _Stage { problem, thinking, scoped, contact, done }

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _problem = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _voice = VoiceService();
  bool _voiceAvailable = false;
  bool _voiceInited = false;
  bool _listening = false;
  String _preVoiceText = '';

  _Stage _stage = _Stage.problem;
  Map<String, Object?>? _readSurface;
  bool _submitting = false;
  String? _error;

  static const _examples = [
    'Read dental x-rays and flag pathology',
    'Score pipe condition from drain-camera video',
    'Triage support tickets by urgency',
    'Catch defects on our production line',
  ];

  // Apple-style squircle (Flutter 3.44 superellipse) shared by the inputs.
  static const _fieldShape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)));

  @override
  void initState() {
    super.initState();
    // Gesture-free feature detection. Actual init happens on the mic click.
    _voiceAvailable = speechRecognitionSupported();
  }

  @override
  void dispose() {
    _voice.stop();
    _problem.dispose();
    _name.dispose();
    _email.dispose();
    _company.dispose();
    super.dispose();
  }

  bool get _problemValid => _problem.text.trim().length >= 12;

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    // Initialize on first use (the click is the required user gesture on web).
    if (!_voiceInited) {
      _voiceInited = true;
      final ok = await _voice.init();
      if (!ok) {
        if (mounted) {
          setState(() {
            _voiceAvailable = false;
            _error = 'Voice is not available in this browser. Try Chrome, or just type.';
          });
        }
        return;
      }
    }
    _preVoiceText = _problem.text.trim();
    setState(() {
      _listening = true;
      _error = null;
    });
    await _voice.start(
      onText: (text) {
        final combined = _preVoiceText.isEmpty ? text : '$_preVoiceText $text';
        _problem.text = combined;
        _problem.selection =
            TextSelection.collapsed(offset: _problem.text.length);
        setState(() {});
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  Future<void> _readProblem() async {
    if (!_problemValid) {
      setState(() => _error = 'Give us a sentence or two so we can read it.');
      return;
    }
    await _voice.stop();
    setState(() {
      _listening = false;
      _error = null;
      _stage = _Stage.thinking;
    });
    final surface = await const PortalReadService().read(_problem.text.trim());
    if (!mounted) return;
    setState(() {
      _readSurface = surface;
      _stage = _Stage.scoped;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await const IntakeService().submit(IntakeRequest(
      company: _company.text.trim().isEmpty
          ? '(not provided)'
          : _company.text.trim(),
      projectDescription: _problem.text.trim(),
      budgetRange: 'Not specified',
      timeline: 'Not specified',
      contactName: _name.text.trim(),
      contactEmail: _email.text.trim(),
    ));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (err == null) {
        _stage = _Stage.done;
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
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.4, child: const Starfield()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _card(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() {
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
      child: switch (_stage) {
        _Stage.problem => _problemStage(),
        _Stage.thinking => _thinkingStage(),
        _Stage.scoped => _scopedStage(),
        _Stage.contact => _contactStage(),
        _Stage.done => _doneStage(),
      },
    );
  }

  // ---- Stage 1: the problem (voice-first) ----
  Widget _problemStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backToHome(),
        const SizedBox(height: 26),
        Text('What do you want AI to solve?', style: AppTheme.heading(28)),
        const SizedBox(height: 10),
        Text(
          _voiceAvailable
              ? 'Describe the problem in your own words. Type it, or just talk.'
              : 'Describe the problem in your own words.',
          style: AppTheme.body(15),
        ),
        const SizedBox(height: 24),
        _problemInput(),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!,
              style: AppTheme.body(14, color: const Color(0xFFFF8585))),
        ],
        const SizedBox(height: 20),
        Text('TRY ONE', style: AppTheme.eyebrow().copyWith(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ex in _examples)
              Hoverable(
                onTap: () {
                  _problem.text = ex;
                  setState(() => _error = null);
                },
                builder: (h) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: h
                        ? AppTheme.purple.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: h
                            ? AppTheme.purple.withValues(alpha: 0.4)
                            : AppTheme.border),
                  ),
                  child: Text(ex,
                      style: AppTheme.body(13,
                          color: AppTheme.textSecondary, height: 1.0)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Spacer(),
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onTap: _readProblem,
            ),
          ],
        ),
      ],
    );
  }

  Widget _problemInput() {
    return Container(
      decoration: ShapeDecoration(
        color: AppTheme.background.withValues(alpha: 0.6),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: _listening ? AppTheme.purple : AppTheme.border,
            width: _listening ? 1.5 : 1,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _problem,
            maxLines: 4,
            minLines: 4,
            style: AppTheme.body(16, color: AppTheme.textPrimary, height: 1.5),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText:
                  'e.g. We run sliplining inspections and want AI to score pipe condition from our drain-camera video.',
              hintStyle: AppTheme.body(15, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                if (_voiceAvailable) _micButton(),
                const Spacer(),
                if (_listening)
                  Text('Listening...',
                      style: AppTheme.body(13, color: AppTheme.purpleBright)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _micButton() {
    return Hoverable(
      onTap: _toggleMic,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _listening
              ? AppTheme.purple.withValues(alpha: 0.2)
              : (h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: _listening ? AppTheme.purple : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _listening
                ? const PulseDot(color: AppTheme.purpleBright, size: 8)
                : const Icon(Icons.mic_none_rounded,
                    size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 7),
            Text(_listening ? 'Stop' : 'Speak',
                style: AppTheme.body(13.5,
                    color: _listening
                        ? AppTheme.purpleBright
                        : AppTheme.textSecondary,
                    height: 1.0)),
          ],
        ),
      ),
    );
  }

  // ---- Stage 2: thinking ----
  Widget _thinkingStage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.purpleBright),
              ),
              const SizedBox(width: 14),
              Text('Reading your problem...',
                  style: AppTheme.heading(18, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Stage 3: the agent's read (generated server-side, rendered via GenUI) ----
  Widget _scopedStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text('First-pass read',
                style: AppTheme.eyebrow().copyWith(color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 16),
        // The read is an A2UI tree built by the backend and rendered blindly
        // through the branded GenUI catalog. Deterministic now, model next.
        GenUiRead(surface: _readSurface!),
        const SizedBox(height: 26),
        Row(
          children: [
            Hoverable(
              onTap: () => setState(() => _stage = _Stage.problem),
              builder: (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text('Edit',
                    style: AppTheme.body(15,
                        color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
                        height: 1.0)),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Send to a human',
              icon: Icons.arrow_forward_rounded,
              onTap: () => setState(() => _stage = _Stage.contact),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Stage 4: contact ----
  Widget _contactStage() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do we send it?', style: AppTheme.heading(26)),
          const SizedBox(height: 10),
          Text('A human reviews every request. No spam, no autoresponders.',
              style: AppTheme.body(15)),
          const SizedBox(height: 26),
          _field(_name, 'Your name', hint: 'Jane Rivera', validator: _required),
          const SizedBox(height: 18),
          _field(_email, 'Email', hint: 'jane@acme.com', validator: _email_),
          const SizedBox(height: 18),
          _field(_company, 'Company (optional)', hint: 'Acme Grading Co.'),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!,
                style: AppTheme.body(14, color: const Color(0xFFFF8585))),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Hoverable(
                onTap: _submitting
                    ? null
                    : () => setState(() => _stage = _Stage.scoped),
                builder: (h) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text('Back',
                      style: AppTheme.body(15,
                          color:
                              h ? AppTheme.textPrimary : AppTheme.textSecondary,
                          height: 1.0)),
                ),
              ),
              const Spacer(),
              if (_submitting)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: AppTheme.ctaGradient),
                  ),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              else
                PrimaryButton(
                  label: 'Send request',
                  icon: Icons.send_rounded,
                  onTap: _submit,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Stage 5: done ----
  Widget _doneStage() {
    return Column(
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
          'Your problem is in front of a human now. We will review it and reach '
          'out, usually within a day or two. If it is urgent, email hello@weirdbrains.com.',
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
    );
  }

  // ---- helpers ----
  Widget _backToHome() {
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

  Widget _field(TextEditingController c, String label,
      {String? hint, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.heading(15.5)),
        const SizedBox(height: 10),
        TextFormField(
          controller: c,
          validator: validator,
          style: AppTheme.body(15.5, color: AppTheme.textPrimary, height: 1.4),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body(15, color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.background.withValues(alpha: 0.6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: const ShapedInputBorder(
              borderSide: BorderSide(color: AppTheme.border),
              shape: _fieldShape,
            ),
            focusedBorder: const ShapedInputBorder(
              borderSide: BorderSide(color: AppTheme.purple, width: 1.5),
              shape: _fieldShape,
            ),
            errorBorder: const ShapedInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF8585)),
              shape: _fieldShape,
            ),
            focusedErrorBorder: const ShapedInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF8585)),
              shape: _fieldShape,
            ),
          ),
        ),
      ],
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
