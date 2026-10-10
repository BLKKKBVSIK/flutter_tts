# accessible_flutter_tts — goals

A fork of [flutter_tts](https://github.com/dlutton/flutter_tts) 4.2.5 that stays out of the way of
screen readers. This file is the reference for what "done" means. Update the status of each goal
whenever it changes, with the date and how it was checked.

Status: ✅ done and verified · 🟡 partly done or not verified · ❌ not done

## Packaging

### 1. The plugin is called `accessible_flutter_tts` ❌

- **Expected:** `name: accessible_flutter_tts` in `pubspec.yaml`, and the iOS/macOS Swift packages
  and podspecs use the same name.
- **Status (2026-10-10):** the package is still named `flutter_tts` (`pubspec.yaml`,
  `ios/flutter_tts/`, `macos/flutter_tts/`, both podspecs).
- **Note:** renaming also fixes the Swift Package Manager error seen when the plugin folder name
  (`accessible_flutter_tts`) doesn't match the package name (`flutter_tts`).
- **How to check:** `grep '^name:' pubspec.yaml`; build an app that depends on the plugin, with
  Swift Package Manager on.

### 2. It can be added to any Flutter project 🟡

- **Expected:** a Flutter app adds the dependency, runs `flutter pub get`, and builds on Android and
  iOS (Swift Package Manager and CocoaPods), plus macOS, web and Windows as upstream does.
- **Status (2026-10-10):** a scratch app depending on the fork by path builds for Android, iOS
  (SwiftPM and CocoaPods) and macOS. Not tested: a git dependency, web, Windows. Nothing is
  pushed yet: the work is on the local branch `ezymob/screen-reader-aware`.
- **How to check:** a fresh `flutter create` app with a git dependency on the pushed fork builds
  for each platform.

### 3. It replaces flutter_tts with nothing else to change 🟡

- **Expected:** swapping the dependency is the only change. Same classes (`FlutterTts`, …), same
  methods, same arguments, same return values, same callbacks. The screen reader behaviour below
  turns on by itself: no new call is needed.
- **Status (2026-10-10):**
  - The Dart API is unchanged from 4.2.5; two methods were added, none removed or changed.
  - The screen reader behaviour is **off by default** and needs `setUseSystemSpeechRate(true)` and
    `setWaitForScreenReader(true)`. That breaks this goal: it must become automatic.
  - Open question: with the package renamed, the dependency and the import line
    (`package:flutter_tts/…` → `package:accessible_flutter_tts/…`) change. Is that acceptable?
- **How to check:** take an app using flutter_tts 4.2.5, change only the dependency (and import if
  agreed), and confirm it analyses, builds and behaves the same.

## Behaviour

### 4. No screen reader: same as flutter_tts 🟡

- **Expected:** with VoiceOver and TalkBack off, every call behaves exactly like flutter_tts 4.2.5,
  including the speech rate the app sets.
- **Status (2026-10-10):** true today because the new options are off by default. Once the
  behaviour is automatic (goal 3), the rate and waiting must only apply while a screen reader is
  on. Today `setUseSystemSpeechRate` also changes the rate without a screen reader.
  Checked on an iPhone 17 Pro (iOS 27.2): speech works, including in silent mode with the
  `playback` audio category, like upstream.
- **How to check:** with the screen reader off, the example app's two screens sound identical, on
  Android and iOS.

### 5. Screen reader on: speech uses the screen reader's speed 🟡

- **Expected:** with VoiceOver or TalkBack on, the app's speech runs at the speed set for
  VoiceOver or TalkBack, whatever rate the app asked for.
- **Status (2026-10-10):**
  - iOS: speech goes through VoiceOver (queued announcement) or uses VoiceOver's settings
    (`prefersAssistiveTechnologySettings`). Implemented, not verified on a device.
  - Android: uses the system text-to-speech rate (`Settings.Secure.TTS_DEFAULT_RATE`). TalkBack's
    own speed slider may not be readable by apps; if it isn't, this goal can't be fully met on
    Android. Not verified on a device.
- **How to check:** change the screen reader's speed, trigger speech, and confirm it follows.

### 6. Screen reader on: speech starts only after the screen reader stops 🟡

- **Expected:** the app's speech never overlaps the screen reader. If the screen reader is talking,
  the app waits for it to finish, then speaks.
- **Status (2026-10-10):**
  - iOS: the text is handed to VoiceOver as a queued announcement while the app is in the
    foreground. On 2026-10-06, a device test on the example's Fork screen reported that VoiceOver
    was cut when the button was tapped. Not resolved: the double-tap gesture itself may stop
    VoiceOver, so the test needs speech triggered while VoiceOver is talking on its own.
  - Android: waits while accessibility audio is playing (300 ms of silence, 10 s at most).
    Not tested on a device.
  - Background / locked screen on iOS: VoiceOver announcements aren't read, so the plugin speaks
    with its own voice without waiting. Overlap is possible there.
- **How to check:** make the screen reader read a long text, trigger speech during it, and confirm
  the app speaks only after it.

## Open questions

- Is changing the import line acceptable when moving from flutter_tts (goal 3)?
- How will apps get the plugin: git dependency on `BLKKKBVSIK/flutter_tts`, or pub.dev?
