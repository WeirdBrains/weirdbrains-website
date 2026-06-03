/// A first-pass "read" of a prospect's problem: a domain label and a short
/// approach. Today this is a fast on-device heuristic so the portal works with
/// zero backend. The interface is intentionally a single async call so a real
/// model (your backend calling Vertex or a local model) can replace it without
/// touching the UI.
class ScopingService {
  const ScopingService();

  Future<ScopedRead> read(String problem) async {
    await Future<void>.delayed(const Duration(milliseconds: 900)); // "thinking"
    final p = problem.toLowerCase();

    bool has(List<String> kws) => kws.any(p.contains);

    if (has(['dental', 'x-ray', 'xray', 'radiograph', 'tooth', 'teeth',
        'endodontic', 'pathology', 'mri', 'ct scan', 'imaging', 'scan'])) {
      return const ScopedRead(
        domain: 'Medical imaging',
        approach: [
          'Train a model on your labeled images to flag findings, with confidence scores a clinician can trust.',
          'Wire it into your existing viewer or PACS so it shows up where you already work, not a separate tool.',
          'Run it on infrastructure you control. HIPAA-ready, your data never has to leave your walls.',
        ],
      );
    }
    if (has(['pipe', 'sliplining', 'drain', 'sewer', 'inspection', 'corrosion',
        'crack', 'weld', 'infrastructure', 'camera feed', 'footage', 'video'])) {
      return const ScopedRead(
        domain: 'Inspection + computer vision',
        approach: [
          'Build a vision model that scores condition straight from your camera footage, frame by frame.',
          'Fold it into your inspection workflow so a tech gets a ranked report, not raw video to scrub.',
          'Set a hard accuracy bar up front and gate the build on it, so it ships when it is actually good.',
        ],
      );
    }
    if (has(['ticket', 'support', 'triage', 'invoice', 'email', 'document',
        'classify', 'sort', 'intake', 'form', 'back office', 'ops'])) {
      return const ScopedRead(
        domain: 'Operations automation',
        approach: [
          'Stand up agents that read, classify, and route the work the way your best person would.',
          'Keep a human gate on anything that matters, so automation never goes rogue.',
          'Start with the one workflow that eats the most hours, prove it, then expand.',
        ],
      );
    }
    if (has(['defect', 'quality', 'manufacturing', 'detect', 'count',
        'conveyor', 'assembly', 'production line'])) {
      return const ScopedRead(
        domain: 'Quality + detection',
        approach: [
          'Train detection on your own line, your parts and your defects, not a generic dataset.',
          'Run it at the edge so it keeps up with the line and flags issues in real time.',
          'Tune the precision/recall tradeoff to your cost of a miss versus a false stop.',
        ],
      );
    }
    return const ScopedRead(
      domain: 'Custom AI build',
      approach: [
        'Start from your data and your workflow, then build the smallest thing that moves the needle.',
        'Agents do the heavy lifting; you approve at every gate that matters.',
        'Ship on infrastructure you control, and grow it from a working wedge.',
      ],
    );
  }
}

class ScopedRead {
  final String domain;
  final List<String> approach;
  const ScopedRead({required this.domain, required this.approach});
}
