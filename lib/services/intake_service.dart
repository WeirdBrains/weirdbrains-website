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

  const IntakeService();

  bool get hasBackend => _endpoint.isNotEmpty;

  /// Returns null on success, or a human-readable error string on failure.
  Future<String?> submit(IntakeRequest request) async {
    if (!hasBackend) {
      // No backend wired yet — simulate the round-trip so the UI is testable.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
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

  const IntakeRequest({
    required this.company,
    required this.projectDescription,
    required this.budgetRange,
    required this.timeline,
    required this.contactName,
    required this.contactEmail,
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'project_description': projectDescription,
        'budget_range': budgetRange,
        'timeline': timeline,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'source': 'web_form',
      };
}
