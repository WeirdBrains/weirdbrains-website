import 'dart:convert';

import 'package:http/http.dart' as http;

/// Talks to the portal backend: the first-pass read, the clarifying questions,
/// the sharpened brief, and sample-file uploads. The backend owns all
/// generation (deterministic today, a sovereign model in Phase 2); the portal
/// renders what it returns.
///
/// Base URL is injected at build time:
///   flutter build web --dart-define=PORTAL_API_BASE=https://api.weirdbrains.com
/// When unset or unreachable, each call degrades to a graceful local fallback so
/// the portal still works without a backend.
class PortalService {
  const PortalService();

  static const _base = String.fromEnvironment('PORTAL_API_BASE');

  Uri? _uri(String path) => _base.isEmpty ? null : Uri.parse('$_base$path');

  Future<Map<String, Object?>> _postJson(String path, Object body,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final uri = _uri(path);
    if (uri == null) throw _Unwired();
    final res = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(timeout);
    if (res.statusCode != 200) throw _Unwired();
    return (jsonDecode(res.body) as Map).cast<String, Object?>();
  }

  /// First-pass read surface (A2UI).
  Future<Map<String, Object?>> read(String problem) async {
    try {
      return await _postJson('/portal/read', {'problem': problem});
    } catch (_) {
      return _fallbackRead();
    }
  }

  /// Discovery questions for the clarify step.
  Future<List<Map<String, Object?>>> clarify(String problem) async {
    try {
      final res = await _postJson('/portal/clarify', {'problem': problem});
      return ((res['questions'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => m.cast<String, Object?>())
          .toList();
    } catch (_) {
      return _fallbackQuestions();
    }
  }

  /// Sharpened brief surface (A2UI), built from the answers and any files.
  Future<Map<String, Object?>> brief(String problem,
      Map<String, String> answers, List<Map<String, Object?>> files) async {
    try {
      return await _postJson(
          '/portal/brief', {'problem': problem, 'answers': answers, 'files': files});
    } catch (_) {
      return _fallbackBrief(answers, files);
    }
  }

  /// One ping-pong refinement turn. Returns {reply, brief, done}.
  Future<Map<String, Object?>> refine(
      String problem,
      List<Map<String, Object?>> history,
      String message,
      List<Map<String, Object?>> files) async {
    try {
      return await _postJson(
        '/portal/refine',
        {
          'problem': problem,
          'history': history,
          'message': message,
          'files': files,
        },
        timeout: const Duration(seconds: 40),
      );
    } catch (_) {
      return {
        'reply': 'Noted. Add anything else, or send it to a human.',
        'brief': _fallbackBrief(const {}, files),
        'done': true,
      };
    }
  }

  /// The hardened Build Plan artifact (loop 1: generate, independent critique,
  /// one revision). Slow by design; returns null on failure because a paid
  /// artifact gets a retry, never a canned fallback.
  /// Shape: {planId, locked, surface, markdown, verdict, needsReview, door,
  /// prices?}. When the paywall is live, `surface` is the locked preview.
  Future<Map<String, Object?>?> plan(String problem,
      List<Map<String, Object?>> history, List<Map<String, Object?>> files) async {
    try {
      return await _postJson(
        '/portal/plan',
        {'problem': problem, 'history': history, 'files': files},
        timeout: const Duration(seconds: 300),
      );
    } catch (_) {
      return null;
    }
  }

  /// Start a Stripe Checkout for a stored plan. Returns the hosted payment
  /// URL, or null when payments are unavailable.
  Future<String?> checkout(String planId, String tier) async {
    try {
      final res = await _postJson(
        '/portal/checkout',
        {'planId': planId, 'tier': tier},
        timeout: const Duration(seconds: 30),
      );
      final url = res['url'];
      return url is String && url.isNotEmpty ? url : null;
    } catch (_) {
      return null;
    }
  }

  /// Verify payment and fetch the full artifact after the checkout redirect.
  Future<Map<String, Object?>?> unlock(String planId, String cs) async {
    try {
      return await _postJson(
        '/portal/unlock',
        {'planId': planId, 'cs': cs},
        timeout: const Duration(seconds: 30),
      );
    } catch (_) {
      return null;
    }
  }

  /// Upload one file's bytes; returns its metadata {id, name, size}.
  Future<Map<String, Object?>> upload(String name, List<int> bytes) async {
    final uri = _uri('/portal/upload?name=${Uri.encodeQueryComponent(name)}');
    if (uri != null) {
      try {
        final res = await http
            .post(uri,
                headers: {'Content-Type': 'application/octet-stream'},
                body: bytes)
            .timeout(const Duration(seconds: 60));
        if (res.statusCode == 200) {
          return (jsonDecode(res.body) as Map).cast<String, Object?>();
        }
      } catch (_) {
        // fall through
      }
    }
    return {'id': 'local', 'name': name, 'size': bytes.length};
  }

  // ---- Fallbacks (used only when the backend is unavailable) ----

  Map<String, Object?> _fallbackRead() => {
        'surfaceId': 'read',
        'catalogId': 'wb',
        'root': 'root',
        'components': [
          {
            'id': 'root',
            'type': 'ReadRoot',
            'properties': {
              'children': ['domain', 'title', 's0', 's1', 's2', 'callout'],
            },
          },
          {'id': 'domain', 'type': 'DomainChip', 'properties': {'label': 'Custom AI build'}},
          {'id': 'title', 'type': 'SectionTitle', 'properties': {'text': 'How we would approach it'}},
          {'id': 's0', 'type': 'ApproachStep', 'properties': {'index': 1, 'text': 'Start from your data and your workflow, then build the smallest thing that moves the needle.'}},
          {'id': 's1', 'type': 'ApproachStep', 'properties': {'index': 2, 'text': 'Agents do the heavy lifting; you approve at every gate that matters.'}},
          {'id': 's2', 'type': 'ApproachStep', 'properties': {'index': 3, 'text': 'Ship on infrastructure you control, and grow it from a working wedge.'}},
          {'id': 'callout', 'type': 'Callout', 'properties': {'text': 'This is an instant first pass. A human refines it with you before anything gets built.'}},
        ],
      };

  List<Map<String, Object?>> _fallbackQuestions() => [
        {'id': 'outcome', 'label': 'What does success look like in 90 days?', 'hint': 'The concrete outcome you want', 'type': 'longtext', 'optional': false},
        {'id': 'data', 'label': 'What data or systems would this build on?', 'hint': 'What you already have to work with', 'type': 'text', 'optional': false},
        {'id': 'timeline', 'label': 'What is your timeline?', 'type': 'choice', 'options': ['Just exploring', 'This quarter', 'Already underway', 'Urgent'], 'optional': false},
        {'id': 'samples', 'label': 'Attach sample data', 'hint': 'Sample footage, images, spec docs, a spreadsheet, whatever helps us understand it.', 'type': 'files', 'optional': true},
      ];

  Map<String, Object?> _fallbackBrief(
      Map<String, String> answers, List<Map<String, Object?>> files) {
    final timeline = answers['timeline'];
    final captured = (timeline != null && timeline.isNotEmpty)
        ? 'Captured: timeline: $timeline. '
        : '';
    final fileNote = files.isEmpty
        ? ''
        : '${files.length} sample file${files.length == 1 ? '' : 's'} attached. ';
    return {
      'surfaceId': 'brief',
      'catalogId': 'wb',
      'root': 'root',
      'components': [
        {
          'id': 'root',
          'type': 'ReadRoot',
          'properties': {
            'children': ['domain', 't', 'p1', 'p2', 'p3', 'sum'],
          },
        },
        {'id': 'domain', 'type': 'DomainChip', 'properties': {'label': 'Custom AI build'}},
        {'id': 't', 'type': 'SectionTitle', 'properties': {'text': 'Rough shape'}},
        {'id': 'p1', 'type': 'PhaseCard', 'properties': {'label': 'Phase 1', 'title': 'Prove it', 'text': 'A focused build on your data that has to clear an agreed accuracy bar before anything scales.'}},
        {'id': 'p2', 'type': 'PhaseCard', 'properties': {'label': 'Phase 2', 'title': 'Integrate', 'text': 'Fold it into the tools your team already uses, with a human gate on anything that matters.'}},
        {'id': 'p3', 'type': 'PhaseCard', 'properties': {'label': 'Phase 3', 'title': 'Scale', 'text': 'Grow from the working wedge, on infrastructure you control.'}},
        {'id': 'sum', 'type': 'Callout', 'properties': {'text': '$captured${fileNote}A human reviews this brief and follows up, usually within a day or two.'}},
      ],
    };
  }
}

class _Unwired implements Exception {}
