// Checks that speech doesn't overlap the screen reader, for GOALS.md (goal 6).
// Run on a device with the screen reader on: flutter run --release -t lib/overlap.dart
// For each plugin, the screen reader reads a long text, and `speak` is called while it's still
// talking. Events are printed as "OVERLAP|plugin|round|event|ms since the screen reader text".
import 'dart:async';

import 'package:accessible_flutter_tts/flutter_tts.dart' as accessible;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart' as original;

bool get _phoneInFrench =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'fr';

String get _language => _phoneInFrench ? 'fr-FR' : 'en-US';

// Read by the screen reader, like the screen it reads when an announcement arrives.
String get _screenReaderText => _phoneInFrench
    ? 'Le lecteur d\'écran lit ce long texte. Le bus 91 en direction de la Gare Montparnasse '
        'arrive dans deux minutes, quai B, après la station Bastille.'
    : 'The screen reader is reading this long text. Bus 91 towards Gare Montparnasse arrives '
        'in two minutes at platform B, after Bastille station.';

String get _sentence => _phoneInFrench
    ? 'Prochain arrêt, Gare de Lyon. Préparez-vous à descendre.'
    : 'Next stop, Gare de Lyon. Please get ready to get off.';

void main() => runApp(const MaterialApp(home: OverlapPage()));

class OverlapPage extends StatefulWidget {
  const OverlapPage({super.key});

  @override
  State<OverlapPage> createState() => _OverlapPageState();
}

class _OverlapPageState extends State<OverlapPage> {
  final _lines = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _log(String line) {
    debugPrint(line);
    setState(() => _lines.add(line));
  }

  Future<void> _run() async {
    final plugins = <String, _Plugin>{
      'flutter_tts': _OriginalPlugin(),
      'accessible_flutter_tts': _AccessiblePlugin(),
    };
    for (final plugin in plugins.values) {
      await plugin.configure();
    }
    final screenReader =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;
    _log('OVERLAP|screen reader on|$screenReader|language|$_language');
    // Let the screen reader finish reading the screen that just opened.
    await Future<void>.delayed(const Duration(seconds: 6));
    for (var round = 1; round <= 2; round++) {
      for (final entry in plugins.entries) {
        await _test(entry.key, entry.value, round);
        // Leave time for the screen reader to finish if the app talked over it.
        await Future<void>.delayed(const Duration(seconds: 8));
      }
    }
    _log('OVERLAP|done');
  }

  Future<void> _test(String name, _Plugin plugin, int round) async {
    final stopwatch = Stopwatch()..start();
    void event(String what) => _log('OVERLAP|$name|$round|$what|${stopwatch.elapsedMilliseconds}');

    plugin.onStart(() => event('speech started'));
    plugin.onComplete(() => event('speech done'));
    event('screen reader text');
    if (!mounted) return;
    // Not awaited: on iOS, Flutter never answers this call.
    unawaited(SemanticsService.sendAnnouncement(View.of(context), _screenReaderText, TextDirection.ltr));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    event('speak called');
    await plugin.speak(_sentence);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlap')),
      body: ListView(children: [for (final line in _lines) Text(line)]),
    );
  }
}

/// The calls the test makes. The two plugins have the same API but separate types.
abstract class _Plugin {
  Future<void> configure();
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
    await _tts.setSpeechRate(0.5);
  }

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
    await _tts.setSpeechRate(0.5);
  }

  @override
  Future<Object?> speak(String text) async => await _tts.speak(text);

  @override
  void onStart(VoidCallback handler) => _tts.setStartHandler(handler);

  @override
  void onComplete(VoidCallback handler) => _tts.setCompletionHandler(handler);
}
