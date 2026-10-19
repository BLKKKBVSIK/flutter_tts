/// The screen shared by the two demo apps. Each app passes its own [DemoTts], so the apps only
/// differ by their text-to-speech plugin.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The text-to-speech calls the demo makes. Both apps implement them with the exact same calls.
abstract class DemoTts {
  Future<void> configure({required String language, required double rate});
  Future<void> speak(String text);
  Future<void> stop();
}

/// Speech rate the app asks for, like the Ezymob app. A screen reader aware plugin ignores it
/// while VoiceOver is on.
const _appRate = 0.5;

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, required this.pluginName, required this.color, required this.tts});

  final String pluginName;
  final Color color;
  final DemoTts tts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: pluginName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: color),
      home: DemoScreen(pluginName: pluginName, tts: tts),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, required this.pluginName, required this.tts});

  final String pluginName;
  final DemoTts tts;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

enum _Step { idle, screenReader, announcement, done }

class _DemoScreenState extends State<DemoScreen> {
  _Step _step = _Step.idle;

  _Texts get _texts =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'fr' ? _french : _english;

  @override
  void initState() {
    super.initState();
    widget.tts.configure(language: _texts.language, rate: _appRate);
  }

  @override
  void dispose() {
    widget.tts.stop();
    super.dispose();
  }

  Future<void> _announce() async {
    // Not disabled while running: a disabled button makes VoiceOver read it again.
    if (_step == _Step.screenReader || _step == _Step.announcement) return;
    setState(() => _step = _Step.screenReader);
    // VoiceOver stops talking when the button is double-tapped, so make it read the trip
    // details, as it would be reading the screen when a "next stop" announcement arrives.
    // Not awaited: on iOS, Flutter never answers this call.
    unawaited(SemanticsService.sendAnnouncement(View.of(context), _texts.tripDetails, TextDirection.ltr));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _step = _Step.announcement);
    await widget.tts.speak(_texts.nextStop);
    if (mounted) setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final texts = _texts;
    final theme = Theme.of(context);
    final voiceOverOn = MediaQuery.accessibleNavigationOf(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.pluginName,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _InfoRow(
                icon: voiceOverOn ? Icons.record_voice_over : Icons.voice_over_off,
                text: voiceOverOn ? texts.voiceOverOn : texts.voiceOverOff,
              ),
              _InfoRow(icon: Icons.speed, text: texts.appRate),
              const SizedBox(height: 24),
              Text(texts.explanation, style: theme.textTheme.bodyLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: _announce,
                icon: const Icon(Icons.campaign, size: 32),
                label: Text(texts.button, textAlign: TextAlign.center),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                  textStyle: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                texts.step(_step),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
      ]),
    );
  }
}

class _Texts {
  const _Texts({
    required this.language,
    required this.tripDetails,
    required this.nextStop,
    required this.voiceOverOn,
    required this.voiceOverOff,
    required this.appRate,
    required this.explanation,
    required this.button,
    required this.steps,
  });

  /// Text in the phone's language: VoiceOver only applies the user's speed to that language.
  final String language;
  final String tripDetails;
  final String nextStop;
  final String voiceOverOn;
  final String voiceOverOff;
  final String appRate;
  final String explanation;
  final String button;
  final Map<_Step, String> steps;

  String step(_Step step) => steps[step] ?? '';
}

const _english = _Texts(
  language: 'en-US',
  tripDetails: 'Trip to Gare de Lyon. Bus 91 towards Gare Montparnasse, platform B. '
      'Next departure in two minutes, then change for metro line 1.',
  nextStop: 'Next stop, Gare de Lyon. Change here for metro lines 1 and 14, RER A and RER D, '
      'and the main line trains. The exit is on the right side of the bus. '
      'Please take all your belongings with you and get ready to get off.',
  voiceOverOn: 'VoiceOver is on',
  voiceOverOff: 'VoiceOver is off',
  appRate: 'Speech rate set by the app: 0.5',
  explanation: 'VoiceOver reads the trip details. Half a second later, while it is still '
      'talking, the app announces the next stop.',
  button: 'Announce the next stop',
  steps: {
    _Step.screenReader: 'VoiceOver reads the trip details…',
    _Step.announcement: 'The app announces the next stop…',
    _Step.done: 'Done',
  },
);

const _french = _Texts(
  language: 'fr-FR',
  tripDetails: 'Trajet vers la Gare de Lyon. Bus 91 en direction de la Gare Montparnasse, '
      'quai B. Prochain passage dans deux minutes, puis correspondance avec la ligne 1 du métro.',
  nextStop: 'Prochain arrêt, Gare de Lyon. Correspondance avec les lignes 1 et 14 du métro, '
      'les RER A et D, et les trains grandes lignes. La sortie se fait du côté droit du bus. '
      'Pensez à prendre toutes vos affaires et préparez-vous à descendre.',
  voiceOverOn: 'VoiceOver est activé',
  voiceOverOff: 'VoiceOver est désactivé',
  appRate: 'Vitesse demandée par l\'app : 0,5',
  explanation: 'VoiceOver lit les détails du trajet. Une demi-seconde plus tard, pendant qu\'il '
      'parle encore, l\'app annonce le prochain arrêt.',
  button: 'Annoncer le prochain arrêt',
  steps: {
    _Step.screenReader: 'VoiceOver lit les détails du trajet…',
    _Step.announcement: 'L\'app annonce le prochain arrêt…',
    _Step.done: 'Terminé',
  },
);
