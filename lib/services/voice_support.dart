import 'dart:js_interop';

// Web-only feature detection for the browser SpeechRecognition API. The site
// targets web, so dart:js_interop is always available here. This is gesture-
// free (it just checks whether the constructor exists), so we can decide
// whether to show the mic before the user does anything.

@JS('window.SpeechRecognition')
external JSAny? get _speechRecognition;

@JS('window.webkitSpeechRecognition')
external JSAny? get _webkitSpeechRecognition;

bool speechRecognitionSupported() {
  try {
    return _speechRecognition != null || _webkitSpeechRecognition != null;
  } catch (_) {
    return false;
  }
}
