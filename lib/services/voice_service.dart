import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper over speech_to_text for the portal's mic input.
///
/// On web this uses the browser's built-in SpeechRecognition API (Chrome and
/// Edge support it well; Safari partial; Firefox not). [available] reflects
/// whether the browser can do it, so the UI can hide the mic gracefully.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  void Function()? _onDone;

  bool get available => _available;
  bool get isListening => _speech.isListening;

  /// Call once. Returns true if speech recognition is usable in this browser.
  Future<bool> init() async {
    try {
      _available = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') _onDone?.call();
        },
        onError: (_) => _onDone?.call(),
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Streams recognized words to [onText]; calls [onDone] when listening stops.
  Future<void> start({
    required void Function(String text) onText,
    void Function()? onDone,
  }) async {
    if (!_available) return;
    _onDone = onDone;
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }
}
