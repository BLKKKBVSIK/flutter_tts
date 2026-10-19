import 'dart:async';

import 'package:accessible_flutter_tts/flutter_tts.dart' as accessible;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart' as original;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TTS',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

/// Switches between the original flutter_tts and accessible_flutter_tts.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _index == 0
          ? SpeakScreen(
              key: const ValueKey('original'),
              title: 'flutter_tts',
              description: 'The original plugin: speaks right away, at the speed set by the app, '
                  'even while the screen reader is talking.',
              tts: _OriginalTts(),
            )
          : SpeakScreen(
              key: const ValueKey('accessible'),
              title: 'accessible_flutter_tts',
              description: 'Our plugin: with a screen reader on, waits for it to finish talking, '
                  'then speaks at its speed.',
              tts: _AccessibleTts(),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.record_voice_over_outlined), label: 'Original'),
          NavigationDestination(icon: Icon(Icons.accessibility_new), label: 'Accessible'),
        ],
      ),
    );
  }
}

/// The calls both screens make. The two plugins have the same API but separate types.
abstract class Tts {
  Future<void> configure();
  Future<void> speak(String text);
  Future<void> stop();
}

class _OriginalTts implements Tts {
  final _tts = original.FlutterTts();

  @override
  Future<void> configure() async {
    // Same audio session as the Ezymob app: "playback" isn't muted by the silent mode.
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      original.IosTextToSpeechAudioCategory.playback,
      [original.IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
  }

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}

/// Same calls as [_OriginalTts]: switching plugins needs no code change.
class _AccessibleTts implements Tts {
  final _tts = accessible.FlutterTts();

  @override
  Future<void> configure() async {
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      accessible.IosTextToSpeechAudioCategory.playback,
      [accessible.IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
  }

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}

class SpeakScreen extends StatefulWidget {
  const SpeakScreen({
    super.key,
    required this.title,
    required this.description,
    required this.tts,
  });

  final String title;
  final String description;
  final Tts tts;

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  static const _sentence = 'Prochain arrêt, Gare de Lyon. Correspondance avec la ligne 1 du métro '
      'et le RER A. Préparez-vous à descendre.';

  // Read by the screen reader just before the app speaks, like a screen reader reading the
  // screen when a "next stop" announcement arrives.
  static const _screenReaderText = 'Le lecteur d\'écran lit ce long texte. Le bus 91 en direction '
      'de la Gare Montparnasse arrive dans deux minutes, quai B, après la station Bastille.';

  @override
  void initState() {
    super.initState();
    widget.tts.configure();
  }

  Future<void> _speak() async {
    // A double-tap stops the screen reader, so it can't be talking when the button is
    // activated: make it talk, then speak while it still is.
    // Not awaited: on iOS, Flutter never answers this call.
    unawaited(SemanticsService.sendAnnouncement(View.of(context), _screenReaderText, TextDirection.ltr));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await widget.tts.speak(_sentence);
  }

  @override
  void dispose() {
    widget.tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(widget.description, style: textTheme.bodyLarge),
            const Spacer(),
            FilledButton(
              onPressed: _speak,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
              child: const Text(
                'Annoncer le prochain arrêt du bus 91 en direction de la Gare Montparnasse, '
                'avec la correspondance pour la ligne 6 du métro et le temps de marche '
                'jusqu\'à la sortie la plus proche',
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
