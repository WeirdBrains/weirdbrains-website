import 'dart:convert';
import 'package:http/http.dart' as http;

/// Submits consultation requests to the WeirdBrains intake backend.
///
/// The endpoint is injected at build time:
///   flutter build web --dart-define=INTAKE_ENDPOINT=https://api.weirdbrains.com/intake
///
/// When unset (local dev with no backend), [submit] short-circuits to a
/// simulated success so the form flow stays testable without secrets.
class IntakeService {
  static const String _endpoint =
      String.fromEnvironment('INTAKE_ENDPOINT', defaultValue: '');
  static const String _base =
      String.fromEnvironment('PORTAL_API_BASE', defaultValue: '');

  const IntakeService();

  /// Prefer an explicit INTAKE_ENDPOINT; otherwise derive from PORTAL_API_BASE.
  String? get _url => _endpoint.isNotEmpty
      ? _endpoint
      : (_base.isNotEmpty ? '$_base/intake' : null);

  bool get hasBackend => _url != null;

  /// Returns null on success, or a human-readable error string on failure.
  Future<String?> submit(IntakeRequest request) async {
    final url = _url;
    if (url == null) {
      // No backend wired yet — simulate the round-trip so the UI is testable.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      return 'Submission failed (${response.statusCode}). Try again or email hello@weirdbrains.com.';
    } catch (_) {
      return 'Could not reach our servers. Try again or email hello@weirdbrains.com.';
    }
  }
}

class IntakeRequest {
  final String company;
  final String projectDescription;
  final String budgetRange;
  final String timeline;
  final String contactName;
  final String contactEmail;
  final List<Map<String, Object?>> discovery;
  final List<Map<String, Object?>> files;

  const IntakeRequest({
    required this.company,
    required this.projectDescription,
    required this.budgetRange,
    required this.timeline,
    required this.contactName,
    required this.contactEmail,
    this.discovery = const [],
    this.files = const [],
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'project_description': projectDescription,
        'budget_range': budgetRange,
        'timeline': timeline,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'discovery': discovery,
        'files': files,
        'source': 'web_form',
      };
}
