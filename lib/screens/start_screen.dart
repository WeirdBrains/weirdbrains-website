import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/intake_service.dart';
import '../services/voice_service.dart';
import '../services/voice_support.dart';
import '../services/portal_service.dart';
import '../widgets/starfield.dart';
import '../widgets/ui.dart';
import '../widgets/genui_read.dart';

/// The portal, running the WeirdBrains Method: describe the problem, HONE it
/// over a back-and-forth (voice and files throughout), then generate the
/// PLAN, a hardened build-plan artifact (drafted, independently critiqued by
/// a second model, revised once). Either path hands off to a human. The old
/// "first-pass read" interstitial is gone: the conversation opener proves
/// understanding and asks the first question in one beat. State flows:
///   problem -> conversation -> (planning -> plan) -> contact -> done
enum _Stage { problem, conversation, planning, plan, contact, done }

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, this.unlockPlanId, this.checkoutSession});

  /// Set when Stripe redirects back after payment: /start?unlock=...&cs=...
  final String? unlockPlanId;
  final String? checkoutSession;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _problem = TextEditingController();
  final _chatInput = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _voice = VoiceService();
  bool _voiceAvailable = false;
  bool _voiceInited = false;
  bool _listening = false; // problem-stage mic
  bool _chatListening = false; // conversation-stage mic
  String _preVoiceText = '';

  _Stage _stage = _Stage.problem;
  final List<Map<String, String>> _chat = []; // [{role: 'user'|'ai', text}]
  List<String> _choices = const []; // one-tap answers for the last AI question
  Map<String, Object?>? _artifact; // the living brief, updated each turn
  Map<String, Object?>? _planSurface; // the hardened plan artifact
  String _planMarkdown = '';
  bool _planNeedsReview = false;
  String? _planId;
  bool _planLocked = false;
  Map<String, Object?> _prices = const {};
  bool _checkingOut = false;
  bool _unlocking = false;
  Timer? _planTimer;
  int _planTick = 0;
  bool _copied = false;
  bool _sending = false;
  final List<Map<String, Object?>> _files = [];
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  static const _examples = [
    'Automate our client intake and scheduling',
    'Stop losing leads to slow follow-up',
    'Pull data out of PDFs into our system',
    'Build the first version of my product idea',
  ];

  // Apple-style squircle (Flutter 3.44 superellipse) shared by the inputs.
  static const _fieldShape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)));

  @override
  void initState() {
    super.initState();
    // Gesture-free feature detection. Actual init happens on the mic click.
    _voiceAvailable = speechRecognitionSupported();
    // Returning from Stripe: verify payment and open the full plan.
    final unlockId = widget.unlockPlanId;
    if (unlockId != null && unlockId.isNotEmpty) {
      _unlocking = true;
      _stage = _Stage.planning;
      _unlockPlan(unlockId, widget.checkoutSession ?? '');
    }
  }

  Future<void> _unlockPlan(String planId, String cs) async {
    final res = await const PortalService().unlock(planId, cs);
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      if (res == null || res['surface'] is! Map) {
        _stage = _Stage.problem;
        _error =
            'We could not confirm the payment yet. Give it a minute and reopen '
            'the link from your receipt, or email hello@weirdbrains.com.';
        return;
      }
      _planId = planId;
      _planLocked = false;
      _planSurface = (res['surface'] as Map).cast<String, Object?>();
      _planMarkdown = res['markdown']?.toString() ?? '';
      _planNeedsReview = res['needsReview'] == true;
      _stage = _Stage.plan;
    });
  }

  @override
  void dispose() {
    _planTimer?.cancel();
    _voice.stop();
    _problem.dispose();
    _chatInput.dispose();
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

  /// Straight from the problem into the conversation: the opener turn proves
  /// the machine understood (mirror) and starts the ping-pong (question) in
  /// a single wait.
  Future<void> _beginHoning() async {
    if (!_problemValid) {
      setState(() => _error = 'Give us a sentence or two so we can read it.');
      return;
    }
    await _voice.stop();
    setState(() {
      _listening = false;
      _error = null;
      _artifact = null;
      _chat.clear();
      _choices = const [];
      _sending = true;
      _stage = _Stage.conversation;
    });
    _openerTurn();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    // The whole ping-pong transcript travels to the human as the discovery,
    // and the generated plan (when there is one) rides along.
    final discovery = <Map<String, Object?>>[
      for (final m in _chat)
        {'q': m['role'] == 'ai' ? 'AI' : 'You', 'a': m['text'] ?? ''},
      if (_planMarkdown.isNotEmpty)
        {'q': 'AI Build Plan (markdown)', 'a': _planMarkdown},
    ];
    final err = await const IntakeService().submit(IntakeRequest(
      company: _company.text.trim().isEmpty
          ? '(not provided)'
          : _company.text.trim(),
      projectDescription: _problem.text.trim(),
      budgetRange: 'Not specified',
      timeline: 'Not specified',
      contactName: _name.text.trim(),
      contactEmail: _email.text.trim(),
      discovery: discovery,
      files: _files,
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
        _Stage.conversation => _conversationStage(),
        _Stage.planning => _planningStage(),
        _Stage.plan => _planStage(),
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
        Text('Describe the problem. Get a Build Plan.',
            style: AppTheme.heading(28)),
        const SizedBox(height: 10),
        Text(
          _voiceAvailable
              ? 'A real plan for the thing you keep working around: the fix, '
                  'what it costs, and what week one looks like. Type it, or just talk.'
              : 'A real plan for the thing you keep working around: the fix, '
                  'what it costs, and what week one looks like.',
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
              label: 'Sharpen my problem',
              icon: Icons.arrow_forward_rounded,
              onTap: _beginHoning,
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
                  'e.g. We lose 5+ hours a week re-typing orders from email into QuickBooks, and mistakes still slip through.',
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



  /// The AI opens the conversation with its first sharp question instead of
  /// waiting passively: ping-pong starts on turn zero.
  Future<void> _openerTurn() async {
    final res =
        await const PortalService().refine(_problem.text.trim(), const [], '', _files);
    if (!mounted || _stage != _Stage.conversation) return;
    setState(() {
      _sending = false;
      _chat.add({
        'role': 'ai',
        'text': res['reply']?.toString() ??
            "Quick one first: which number hurts most right now, new "
                'business, capacity, or cost?',
      });
      _choices = _stringList(res['choices']);
      final b = res['brief'];
      if (b is Map) _artifact = b.cast<String, Object?>();
    });
  }

  List<String> _stringList(Object? v) => v is List
      ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
      : const [];

  Future<void> _sendRefine() => _sendMessage(_chatInput.text.trim());

  /// One-tap chip answers: the easiest possible reply is a tap.
  Future<void> _sendChoice(String choice) => _sendMessage(choice);

  Future<void> _sendMessage(String msg) async {
    if (msg.isEmpty || _sending) return;
    await _voice.stop();
    final history = [
      for (final m in _chat) {'role': m['role'], 'text': m['text']},
    ];
    setState(() {
      _chat.add({'role': 'user', 'text': msg});
      _chatInput.clear();
      _chatListening = false;
      _choices = const [];
      _sending = true;
      _error = null;
    });
    final res = await const PortalService()
        .refine(_problem.text.trim(), history, msg, _files);
    if (!mounted) return;
    setState(() {
      _chat.add({'role': 'ai', 'text': res['reply']?.toString() ?? 'Updated.'});
      _choices = _stringList(res['choices']);
      final b = res['brief'];
      if (b is Map) _artifact = b.cast<String, Object?>();
      _sending = false;
    });
  }

  // ---- Stage 4b: the plan (loop 1: generate, critique, revise) ----
  // The labor illusion, honestly applied: narrate the real pipeline steps in
  // concrete verbs while the loop runs.
  static const _planSteps = [
    'Reading everything you told me, slowly...',
    'Choosing the smallest build that fixes it...',
    'Pricing the phases and flagging the risks...',
    'Running an independent check on every number...',
  ];

  Future<void> _generatePlan() async {
    await _voice.stop();
    _planTimer?.cancel();
    setState(() {
      _chatListening = false;
      _error = null;
      _planTick = 0;
      _stage = _Stage.planning;
    });
    // The loop takes a few minutes by design; narrate its real stages.
    _planTimer = Timer.periodic(const Duration(seconds: 28), (_) {
      if (!mounted) return;
      setState(() => _planTick = (_planTick + 1).clamp(0, _planSteps.length - 1));
    });
    final history = [
      for (final m in _chat) {'role': m['role'], 'text': m['text']},
    ];
    final res = await const PortalService()
        .plan(_problem.text.trim(), history, _files);
    _planTimer?.cancel();
    if (!mounted) return;
    if (res == null) {
      setState(() {
        _stage = _Stage.conversation;
        _error =
            'Plan generation is busy right now. Give it a minute and try again.';
      });
      return;
    }
    setState(() {
      final s = res['surface'];
      _planSurface = s is Map ? s.cast<String, Object?>() : null;
      _planMarkdown = res['markdown']?.toString() ?? '';
      _planNeedsReview = res['needsReview'] == true;
      _planId = res['planId']?.toString();
      _planLocked = res['locked'] == true;
      final p = res['prices'];
      _prices = p is Map ? p.cast<String, Object?>() : const {};
      _stage = _planSurface == null ? _Stage.conversation : _Stage.plan;
      if (_planSurface == null) {
        _error =
            'Plan generation is busy right now. Give it a minute and try again.';
      }
    });
  }

  Future<void> _startCheckout(String tier) async {
    final planId = _planId;
    if (planId == null || _checkingOut) return;
    setState(() {
      _checkingOut = true;
      _error = null;
    });
    final url = await const PortalService().checkout(planId, tier);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _checkingOut = false;
        _error = 'Could not start checkout. Try again in a moment.';
      });
      return;
    }
    // Same-tab redirect to Stripe; we come back via /start?unlock=...
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
    if (mounted) setState(() => _checkingOut = false);
  }

  String _price(String tier) {
    final cents = _prices[tier];
    final n = cents is num ? cents.toInt() : (tier == 'reviewed' ? 19900 : 7900);
    return '\$${(n / 100).round()}';
  }

  Widget _planningStage() {
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
              Flexible(
                child: Text(
                    _unlocking ? 'Opening your plan' : 'Building your plan',
                    style: AppTheme.heading(18, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _unlocking
                  ? 'Confirming the payment and unlocking the full artifact...'
                  : _planSteps[_planTick],
              key: ValueKey(_unlocking ? -1 : _planTick),
              style: AppTheme.body(14.5, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text('Your build plan',
                style: AppTheme.eyebrow().copyWith(color: AppTheme.gold)),
            const Spacer(),
            if (_chat.isNotEmpty)
              Hoverable(
                onTap: () => setState(() => _stage = _Stage.conversation),
                builder: (h) => Text('Back to the conversation',
                    style: AppTheme.body(13,
                        color: h ? AppTheme.textPrimary : AppTheme.textMuted,
                        height: 1.0)),
              ),
          ],
        ),
        if (_planNeedsReview) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              'The independent critique flagged parts of this plan, so a human '
              'will double-check it before anything moves.',
              style: AppTheme.body(13, color: AppTheme.gold, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_planLocked) ...[
          // Purchase column in descending price order: the $199 tier anchors,
          // $79 reads as the safe middle, and the free human path stays one
          // click away so the plan never blocks a real lead.
          Align(
            alignment: Alignment.centerRight,
            child: Hoverable(
              onTap: _checkingOut ? null : () => _startCheckout('reviewed'),
              builder: (h) => Text(
                '${_price('reviewed')}: plan + 30 minutes live with a founder, '
                'credited if we build it',
                textAlign: TextAlign.right,
                style: AppTheme.body(13.5,
                    color: h ? AppTheme.purpleBright : AppTheme.purple,
                    height: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              Opacity(
                opacity: _checkingOut ? 0.6 : 1,
                child: PrimaryButton(
                  label: 'Unlock my full plan, ${_price('plan')}',
                  icon: Icons.lock_open_rounded,
                  onTap: () {
                    if (!_checkingOut) _startCheckout('plan');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Hoverable(
              onTap: () => setState(() => _stage = _Stage.contact),
              builder: (h) => Text('or send it to a human, free',
                  style: AppTheme.body(13.5,
                      color:
                          h ? AppTheme.textPrimary : AppTheme.textSecondary,
                      height: 1.0)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_planSurface != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: ShapeDecoration(
              color: AppTheme.background.withValues(alpha: 0.4),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.border),
              ),
            ),
            child:
                GenUiRead(key: ValueKey(_planSurface), surface: _planSurface!),
          ),
        if (!_planLocked) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              _iconChip(
                _copied ? Icons.check_rounded : Icons.copy_all_rounded,
                _copied ? 'Copied' : 'Copy as markdown',
                () async {
                  await Clipboard.setData(ClipboardData(text: _planMarkdown));
                  if (!mounted) return;
                  setState(() => _copied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copied = false);
                  });
                },
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Build it with us',
                icon: Icons.arrow_forward_rounded,
                onTap: () => setState(() => _stage = _Stage.contact),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _toggleChatMic() async {
    if (_chatListening) {
      await _voice.stop();
      if (mounted) setState(() => _chatListening = false);
      return;
    }
    if (!_voiceInited) {
      _voiceInited = true;
      final ok = await _voice.init();
      if (!ok) {
        if (mounted) setState(() => _voiceAvailable = false);
        return;
      }
    }
    final pre = _chatInput.text.trim();
    setState(() => _chatListening = true);
    await _voice.start(
      onText: (t) {
        _chatInput.text = pre.isEmpty ? t : '$pre $t';
        _chatInput.selection =
            TextSelection.collapsed(offset: _chatInput.text.length);
        setState(() {});
      },
      onDone: () {
        if (mounted) setState(() => _chatListening = false);
      },
    );
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

  String _fmtSize(Object? size) {
    final n = (size is num) ? size.toInt() : 0;
    if (n < 1024) return '${n}B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(0)}KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _conversationStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text('Honing your brief',
                style: AppTheme.eyebrow().copyWith(color: AppTheme.gold)),
            const Spacer(),
            Hoverable(
              onTap: () => setState(() => _stage = _Stage.problem),
              builder: (h) => Text('Restart',
                  style: AppTheme.body(13,
                      color: h ? AppTheme.textPrimary : AppTheme.textMuted,
                      height: 1.0)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The two exits, pinned at the top so they never fall below the fold.
        Row(
          children: [
            Hoverable(
              onTap: () => setState(() => _stage = _Stage.contact),
              builder: (h) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Text('Send to a human',
                    style: AppTheme.body(14,
                        color:
                            h ? AppTheme.textPrimary : AppTheme.textSecondary,
                        height: 1.0)),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Get my Build Plan',
              icon: Icons.auto_awesome,
              onTap: _generatePlan,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Every answer below makes it sharper. You see the outline before paying.',
            style: AppTheme.body(12, color: AppTheme.textMuted, height: 1.2),
          ),
        ),
        const SizedBox(height: 14),
        // The living artifact: the brief, updated every turn. Height-capped
        // with its own scroll so the conversation (the engagement surface)
        // never falls below the fold.
        if (_artifact != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: ShapeDecoration(
                color: AppTheme.background.withValues(alpha: 0.4),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.border),
                ),
              ),
              child: SingleChildScrollView(
                child:
                    GenUiRead(key: ValueKey(_artifact), surface: _artifact!),
              ),
            ),
          ),
        const SizedBox(height: 22),
        // The dialogue: history dims, the live question owns the card.
        for (var i = 0; i < _chat.length; i++) ...[
          if (i == _chat.length - 1 && _chat[i]['role'] == 'ai' && !_sending)
            _liveQuestion(_chat[i]['text'] ?? '')
          else
            Opacity(
              opacity: i >= _chat.length - 2 ? 1 : 0.55,
              child:
                  _chatBubble(_chat[i]['role'] ?? 'ai', _chat[i]['text'] ?? ''),
            ),
          const SizedBox(height: 12),
        ],
        if (_sending) ...[
          _chatBubble('ai', 'Thinking...'),
          const SizedBox(height: 12),
        ],
        // One-tap answers: proper answer buttons, not tags.
        if (!_sending && _choices.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _choices)
                Hoverable(
                  onTap: () => _sendChoice(c),
                  builder: (h) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: ShapeDecoration(
                      color: h
                          ? AppTheme.purple.withValues(alpha: 0.28)
                          : AppTheme.purple.withValues(alpha: 0.14),
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: AppTheme.purple
                                .withValues(alpha: h ? 0.8 : 0.5),
                            width: 1.2),
                      ),
                    ),
                    child: Text(c,
                        style: AppTheme.body(15,
                                color: h ? Colors.white : AppTheme.purpleBright,
                                height: 1.0)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 2),
          for (final file in _files) _fileChip(file),
        ],
        const SizedBox(height: 8),
        _chatInputBar(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: AppTheme.body(14, color: const Color(0xFFFF8585))),
        ],
      ],
    );
  }

  /// The AI's latest turn, rendered as THE question rather than one more
  /// bubble: context line muted, the question itself large and bright.
  Widget _liveQuestion(String text) {
    var lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    var question = lines.isEmpty ? text : lines.removeLast();
    // Single-line replies carry reaction + question together: split at the
    // last sentence break before the question.
    if (lines.isEmpty && question.endsWith('?')) {
      final idx = question.lastIndexOf(RegExp(r'[.!…]'));
      if (idx > 12 && idx < question.length - 8) {
        lines = [question.substring(0, idx + 1).trim()];
        question = question.substring(idx + 1).trim();
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isNotEmpty) ...[
            Text(lines.join('\n'),
                style: AppTheme.body(14.5,
                    color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 10),
          ],
          Text(question,
              style: AppTheme.heading(20, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _chatBubble(String role, String text) {
    final isAi = role == 'ai';
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: isAi
                ? Colors.white.withValues(alpha: 0.04)
                : AppTheme.purple.withValues(alpha: 0.16),
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: isAi
                      ? AppTheme.border
                      : AppTheme.purple.withValues(alpha: 0.4)),
            ),
          ),
          child: Text(text,
              style: AppTheme.body(14.5,
                  color: isAi ? AppTheme.textSecondary : AppTheme.textPrimary,
                  height: 1.45)),
        ),
      ),
    );
  }

  Widget _fileChip(Map<String, Object?> file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 16, color: AppTheme.sky),
          const SizedBox(width: 8),
          Expanded(
            child: Text(file['name']?.toString() ?? 'file',
                style: AppTheme.body(13.5,
                    color: AppTheme.textSecondary, height: 1.2),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(_fmtSize(file['size']),
              style: AppTheme.body(12, color: AppTheme.textMuted, height: 1.0)),
          const SizedBox(width: 10),
          Hoverable(
            onTap: () => setState(() => _files.remove(file)),
            builder: (h) => Icon(Icons.close_rounded,
                size: 16,
                color: h ? const Color(0xFFFF8585) : AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _chatInputBar() {
    return Container(
      decoration: ShapeDecoration(
        color: AppTheme.background.withValues(alpha: 0.6),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _chatListening ? AppTheme.purple : AppTheme.border,
            width: _chatListening ? 1.5 : 1,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _chatInput,
            minLines: 1,
            maxLines: 4,
            style: AppTheme.body(15, color: AppTheme.textPrimary, height: 1.45),
            onSubmitted: (_) => _sendRefine(),
            decoration: InputDecoration(
              hintText: 'Answer, push back, or ask me something...',
              hintStyle: AppTheme.body(14.5, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                _iconChip(
                    _uploading
                        ? Icons.hourglass_top_rounded
                        : Icons.attach_file_rounded,
                    _uploading ? 'Uploading' : 'Attach',
                    _uploading ? null : _pickFiles),
                const SizedBox(width: 8),
                if (_voiceAvailable)
                  _iconChip(
                      _chatListening
                          ? Icons.stop_rounded
                          : Icons.mic_none_rounded,
                      _chatListening ? 'Stop' : 'Speak',
                      _toggleChatMic,
                      active: _chatListening),
                const Spacer(),
                _sendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconChip(IconData icon, String label, VoidCallback? onTap,
      {bool active = false}) {
    return Hoverable(
      onTap: onTap,
      builder: (h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.purple.withValues(alpha: 0.2)
              : (h ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: active ? AppTheme.purple : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppTheme.purpleBright : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTheme.body(13,
                    color:
                        active ? AppTheme.purpleBright : AppTheme.textSecondary,
                    height: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _sendButton() {
    return Hoverable(
      onTap: _sending ? null : _sendRefine,
      builder: (h) => Opacity(
        opacity: _sending ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppTheme.ctaGradient),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send',
                  style: AppTheme.body(13.5, color: Colors.white, height: 1.0)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward_rounded,
                  size: 15, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Stage 5: contact ----
  Widget _contactStage() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do we send your brief?', style: AppTheme.heading(26)),
          const SizedBox(height: 10),
          Text(
              'A real person reads it and replies, usually within a day. '
              'No spam, no autoresponders.',
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
                    : () => setState(() => _stage = _Stage.conversation),
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

  // ---- Stage 6: done ----
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
