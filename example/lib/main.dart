import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

/// Switches between the original behaviour and the fork's screen reader aware behaviour.
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
      // Not an IndexedStack: each screen applies its own options when it opens.
      body: _index == 0
          ? const SpeakScreen(
              key: ValueKey('original'),
              title: 'Original flutter_tts',
              description:
                  'Speaks right away, at the speech rate set by the app, even while the screen reader is talking.',
              screenReaderAware: false,
            )
          : const SpeakScreen(
              key: ValueKey('fork'),
              title: 'Our fork',
              description:
                  'Speaks at the phone\'s speech rate, and waits for TalkBack or VoiceOver to finish talking.',
              screenReaderAware: true,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.record_voice_over_outlined), label: 'Original'),
          NavigationDestination(icon: Icon(Icons.accessibility_new), label: 'Fork'),
        ],
      ),
    );
  }
}

class SpeakScreen extends StatefulWidget {
  const SpeakScreen({
    super.key,
    required this.title,
    required this.description,
    required this.screenReaderAware,
  });

  final String title;
  final String description;

  /// Turns on the fork's options: phone's speech rate and waiting for the screen reader.
  final bool screenReaderAware;

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  static const _sentence = 'Prochain arrêt, Gare de Lyon. Correspondance avec la ligne 1 du métro '
      'et le RER A. Préparez-vous à descendre.';

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  Future<void> _configure() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setUseSystemSpeechRate(widget.screenReaderAware);
    await _tts.setWaitForScreenReader(widget.screenReaderAware);
  }

  Future<void> _speak() async {
    setState(() => _speaking = true);
    await _tts.speak(_sentence);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _tts.stop();
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
            // The long label keeps the screen reader talking when the button is tapped,
            // so the app's speech starts while the screen reader is still reading it.
            FilledButton(
              onPressed: _speaking ? null : _speak,
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
