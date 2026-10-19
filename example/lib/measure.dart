// Measures flutter_tts and accessible_flutter_tts with the same calls, for GOALS.md.
// Run on a device: flutter run --release -t lib/measure.dart
// Each result is printed as "MEASURE|plugin|rate|start ms|duration ms|speak result" and shown
// on screen. The speak result is 1 when the sentence was read (with VoiceOver: when VoiceOver says so).
import 'dart:async';

import 'package:accessible_flutter_tts/flutter_tts.dart' as accessible;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart' as original;

// The sentence is in the phone's language (French or English): with VoiceOver, text in another
// language is read with that language's voice and speed, not the speed the user set.
bool get _phoneInFrench =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'fr';

String get _language => _phoneInFrench ? 'fr-FR' : 'en-US';

String get _sentence => _phoneInFrench
    ? 'Prochain arrêt, Gare de Lyon. Correspondance avec la ligne 1 du métro '
        'et le RER A. Préparez-vous à descendre.'
    : 'Next stop, Gare de Lyon. Change here for metro line 1 and the RER A. '
        'Please get ready to get off.';

void main() => runApp(const MaterialApp(home: MeasurePage()));

class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});

  @override
  State<MeasurePage> createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  final _results = <String>[];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final plugins = <String, _Plugin>{
      'flutter_tts': _OriginalPlugin(),
      'accessible_flutter_tts': _AccessiblePlugin(),
    };
    for (final plugin in plugins.values) {
      await plugin.configure();
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    final screenReader =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;
    debugPrint('MEASURE|screen reader on|$screenReader|language|$_language');
    setState(() => _results.add('screen reader on: $screenReader, language: $_language'));
    // Default rate, then a faster one: both plugins must honour the app's rate the same way.
    for (final rate in [0.5, 0.65]) {
      for (var round = 0; round < 2; round++) {
        for (final entry in plugins.entries) {
          final result = await _measure(entry.value, rate);
          final line =
              'MEASURE|${entry.key}|$rate|${result.start}|${result.duration}|${result.spoken}';
          debugPrint(line);
          setState(() => _results.add(line));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    debugPrint('MEASURE|done');
    setState(() => _results.add('done'));
  }

  Future<({int start, int duration, Object? spoken})> _measure(_Plugin plugin, double rate) async {
    await plugin.setSpeechRate(rate);
    final stopwatch = Stopwatch();
    final started = Completer<int>();
    final completed = Completer<int>();
    plugin.onStart(() {
      if (!started.isCompleted) started.complete(stopwatch.elapsedMilliseconds);
    });
    plugin.onComplete(() {
      if (!completed.isCompleted) completed.complete(stopwatch.elapsedMilliseconds);
    });
    stopwatch.start();
    final spoken = await plugin.speak(_sentence);
    final start = await started.future.timeout(const Duration(seconds: 30), onTimeout: () => -1);
    final end = await completed.future.timeout(const Duration(seconds: 30), onTimeout: () => -1);
    return (start: start, duration: end < 0 || start < 0 ? -1 : end - start, spoken: spoken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Measure')),
      body: ListView(children: [for (final line in _results) ListTile(title: Text(line))]),
    );
  }
}

/// The calls the measurement makes. The two plugins have the same API but separate types.
abstract class _Plugin {
  Future<void> configure();
  Future<void> setSpeechRate(double rate);
  Future<Object?> speak(String text);
  void onStart(VoidCallback handler);
  void onComplete(VoidCallback handler);
}

class _OriginalPlugin implements _Plugin {
  final _tts = original.FlutterTts();

  @override
  Future<void> configure() async {
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      original.IosTextToSpeechAudioCategory.playback,
      [original.IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(_language);
  }

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<Object?> speak(String text) async => await _tts.speak(text);

  @override
  void onStart(VoidCallback handler) => _tts.setStartHandler(handler);

  @override
  void onComplete(VoidCallback handler) => _tts.setCompletionHandler(handler);
}

class _AccessiblePlugin implements _Plugin {
  final _tts = accessible.FlutterTts();

  @override
  Future<void> configure() async {
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      accessible.IosTextToSpeechAudioCategory.playback,
      [accessible.IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(_language);
  }

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<Object?> speak(String text) async => await _tts.speak(text);

  @override
  void onStart(VoidCallback handler) => _tts.setStartHandler(handler);

  @override
  void onComplete(VoidCallback handler) => _tts.setCompletionHandler(handler);
}
