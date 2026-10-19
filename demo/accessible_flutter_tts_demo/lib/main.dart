import 'package:demo_screen/demo_screen.dart';
import 'package:flutter/material.dart';
import 'package:accessible_flutter_tts/flutter_tts.dart';

void main() => runApp(DemoApp(pluginName: 'accessible_flutter_tts', color: Colors.teal, tts: _Tts()));

/// The same calls in both demo apps: only the import above differs.
class _Tts implements DemoTts {
  final _tts = FlutterTts();

  @override
  Future<void> configure({required String language, required double rate}) async {
    // "playback" isn't muted by the silent mode, like in the Ezymob app.
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}
