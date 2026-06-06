import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches the portal's first-pass "read" as a GenUI A2UI surface from the
/// backend (`POST /portal/read`). The backend owns generation (deterministic
/// today, a sovereign model in Phase 2); the portal just renders what it sends.
///
/// Endpoint is injected at build time:
///   flutter build web --dart-define=PORTAL_READ_ENDPOINT=https://api.../portal/read
/// When unset or unreachable, [read] returns a graceful generic surface so the
/// portal still works without a backend.
class PortalReadService {
  const PortalReadService();

  static const _endpoint = String.fromEnvironment('PORTAL_READ_ENDPOINT');

  Future<Map<String, Object?>> read(String problem) async {
    if (_endpoint.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(_endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'problem': problem}),
            )
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          return (jsonDecode(res.body) as Map).cast<String, Object?>();
        }
      } catch (_) {
        // Fall through to the local fallback below.
      }
    }
    return _fallbackSurface();
  }

  /// A generic on-brand read used only when the backend is unavailable.
  Map<String, Object?> _fallbackSurface() => {
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
          {
            'id': 'domain',
            'type': 'DomainChip',
            'properties': {'label': 'Custom AI build'},
          },
          {
            'id': 'title',
            'type': 'SectionTitle',
            'properties': {'text': 'How we would approach it'},
          },
          {
            'id': 's0',
            'type': 'ApproachStep',
            'properties': {
              'index': 1,
              'text':
                  'Start from your data and your workflow, then build the smallest thing that moves the needle.',
            },
          },
          {
            'id': 's1',
            'type': 'ApproachStep',
            'properties': {
              'index': 2,
              'text':
                  'Agents do the heavy lifting; you approve at every gate that matters.',
            },
          },
          {
            'id': 's2',
            'type': 'ApproachStep',
            'properties': {
              'index': 3,
              'text':
                  'Ship on infrastructure you control, and grow it from a working wedge.',
            },
          },
          {
            'id': 'callout',
            'type': 'Callout',
            'properties': {
              'text':
                  'This is an instant first pass. A human refines it with you before anything gets built.',
            },
          },
        ],
      };
}
