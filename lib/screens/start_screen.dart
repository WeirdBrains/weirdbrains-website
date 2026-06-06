import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/intake_service.dart';
import '../services/voice_service.dart';
import '../services/voice_support.dart';
import '../services/portal_service.dart';
import '../widgets/starfield.dart';
import '../widgets/ui.dart';
import '../widgets/genui_read.dart';

/// The portal. Problem-first, voice-enabled, agentic. The AI reads the problem,
/// asks clarifying questions (with file upload), assembles a brief, then hands a
/// real brief to a human. State flows:
///   problem -> thinking -> scoped -> clarify -> briefing -> brief -> contact -> done
enum _Stage { problem, thinking, scoped, clarify, briefing, brief, contact, done }

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
  List<Map<String, Object?>>? _questions;
  final Map<String, String> _answers = {};
  final List<Map<String, Object?>> _files = [];
  bool _uploading = false;
  Map<String, Object?>? _briefSurface;
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
    final surface = await const PortalService().read(_problem.text.trim());
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
      timeline: _answers['timeline'] ?? 'Not specified',
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
        _Stage.thinking => _loadingStage('Reading your problem...'),
        _Stage.scoped => _scopedStage(),
        _Stage.clarify => _clarifyStage(),
        _Stage.briefing => _loadingStage('Building your brief...'),
        _Stage.brief => _briefStage(),
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

  // ---- Loading (read / brief) ----
  Widget _loadingStage(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.purpleBright),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(label,
                style: AppTheme.heading(18, color: AppTheme.textSecondary)),
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
        GenUiRead(key: ValueKey(_readSurface), surface: _readSurface!),
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
              label: 'Sharpen this',
              icon: Icons.arrow_forward_rounded,
              onTap: _startClarify,
            ),
          ],
        ),
      ],
    );
  }

  // ---- Stage 4: clarify (AI discovery questions + file upload) ----
  Future<void> _startClarify() async {
    final qs = await const PortalService().clarify(_problem.text.trim());
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _error = null;
      _stage = _Stage.clarify;
    });
  }

  Future<void> _submitClarify() async {
    setState(() {
      _error = null;
      _stage = _Stage.briefing;
    });
    final surface = await const PortalService()
        .brief(_problem.text.trim(), _answers, _files);
    if (!mounted) return;
    setState(() {
      _briefSurface = surface;
      _stage = _Stage.brief;
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() => _uploading = true);
    for (final f in result.files) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      final meta = await const PortalService().upload(f.name, bytes);
      if (!mounted) return;
      setState(() => _files.add(meta));
    }
    if (mounted) setState(() => _uploading = false);
  }

  Widget _clarifyStage() {
    final qs = _questions ?? const <Map<String, Object?>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text('A few questions',
                style: AppTheme.eyebrow().copyWith(color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Help us sharpen it', style: AppTheme.heading(24)),
        const SizedBox(height: 8),
        Text('Answer what you can. Skip anything optional.',
            style: AppTheme.body(14.5)),
        const SizedBox(height: 24),
        for (final q in qs) ...[
          _questionField(q),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Hoverable(
              onTap: () => setState(() => _stage = _Stage.scoped),
              builder: (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text('Back',
                    style: AppTheme.body(15,
                        color: h ? AppTheme.textPrimary : AppTheme.textSecondary,
                        height: 1.0)),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Build my brief',
              icon: Icons.arrow_forward_rounded,
              onTap: _submitClarify,
            ),
          ],
        ),
      ],
    );
  }

  Widget _questionField(Map<String, Object?> q) {
    final id = q['id'] as String? ?? '';
    final label = q['label'] as String? ?? '';
    final hint = q['hint'] as String?;
    final type = q['type'] as String? ?? 'text';
    final optional = q['optional'] == true;

    Widget control;
    switch (type) {
      case 'files':
        control = _fileControl(hint);
      case 'choice':
        final options = ((q['options'] as List?) ?? const []).cast<String>();
        control = _choiceControl(id, options);
      case 'longtext':
        control = _textControl(id, lines: 3);
      default:
        control = _textControl(id, lines: 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(child: Text(label, style: AppTheme.heading(15.5))),
            if (optional) ...[
              const SizedBox(width: 8),
              Text('optional',
                  style:
                      AppTheme.body(12, color: AppTheme.textMuted, height: 1.0)),
            ],
          ],
        ),
        if (hint != null && type != 'files') ...[
          const SizedBox(height: 5),
          Text(hint, style: AppTheme.body(13, color: AppTheme.textMuted)),
        ],
        const SizedBox(height: 10),
        control,
      ],
    );
  }

  Widget _textControl(String id, {int lines = 1}) {
    return TextField(
      maxLines: lines,
      minLines: lines,
      style: AppTheme.body(15.5, color: AppTheme.textPrimary, height: 1.4),
      onChanged: (v) => _answers[id] = v,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.background.withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        enabledBorder: const ShapedInputBorder(
            borderSide: BorderSide(color: AppTheme.border), shape: _fieldShape),
        focusedBorder: const ShapedInputBorder(
            borderSide: BorderSide(color: AppTheme.purple, width: 1.5),
            shape: _fieldShape),
      ),
    );
  }

  Widget _choiceControl(String id, List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in options)
          Hoverable(
            onTap: () => setState(() => _answers[id] = opt),
            builder: (h) {
              final selected = _answers[id] == opt;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.purple.withValues(alpha: 0.2)
                      : (h
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected ? AppTheme.purple : AppTheme.border),
                ),
                child: Text(opt,
                    style: AppTheme.body(13.5,
                        color: selected
                            ? AppTheme.purpleBright
                            : AppTheme.textSecondary,
                        height: 1.0)),
              );
            },
          ),
      ],
    );
  }

  Widget _fileControl(String? hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint != null) ...[
          Text(hint, style: AppTheme.body(13, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
        ],
        Hoverable(
          onTap: _uploading ? null : _pickFiles,
          builder: (h) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: ShapeDecoration(
              color: h
                  ? AppTheme.purple.withValues(alpha: 0.06)
                  : AppTheme.background.withValues(alpha: 0.5),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: h
                        ? AppTheme.purple.withValues(alpha: 0.5)
                        : AppTheme.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    _uploading
                        ? Icons.hourglass_top_rounded
                        : Icons.upload_file_rounded,
                    size: 18,
                    color: AppTheme.textSecondary),
                const SizedBox(width: 10),
                Text(_uploading ? 'Uploading...' : 'Choose files',
                    style: AppTheme.body(14,
                        color: AppTheme.textSecondary, height: 1.0)),
              ],
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final file in _files)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 16, color: AppTheme.sky),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(file['name']?.toString() ?? 'file',
                        style: AppTheme.body(13.5,
                            color: AppTheme.textSecondary, height: 1.2),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(_fmtSize(file['size']),
                      style: AppTheme.body(12,
                          color: AppTheme.textMuted, height: 1.0)),
                  const SizedBox(width: 10),
                  Hoverable(
                    onTap: () => setState(() => _files.remove(file)),
                    builder: (h) => Icon(Icons.close_rounded,
                        size: 16,
                        color:
                            h ? const Color(0xFFFF8585) : AppTheme.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  String _fmtSize(Object? size) {
    final n = (size is num) ? size.toInt() : 0;
    if (n < 1024) return '${n}B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(0)}KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // ---- Stage 5: the brief (server-assembled, rendered via GenUI) ----
  Widget _briefStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text('Your brief',
                style: AppTheme.eyebrow().copyWith(color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 16),
        GenUiRead(key: ValueKey(_briefSurface), surface: _briefSurface!),
        const SizedBox(height: 26),
        Row(
          children: [
            Hoverable(
              onTap: () => setState(() => _stage = _Stage.clarify),
              builder: (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text('Edit answers',
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

  // ---- Stage 6: contact ----
  Widget _contactStage() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do we send your brief?', style: AppTheme.heading(26)),
          const SizedBox(height: 10),
          Text('A human reviews every brief. No spam, no autoresponders.',
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
                    : () => setState(() => _stage = _Stage.brief),
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
          'Your brief is in front of a human now. We will review it and reach '
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
