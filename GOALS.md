# accessible_flutter_tts — goals

A fork of [flutter_tts](https://github.com/dlutton/flutter_tts) 4.2.5 that stays out of the way of
screen readers. This file is the reference for what "done" means. Update the status of each goal
whenever it changes, with the date and how it was checked.

Status: ✅ done and verified · 🟡 partly done or not verified · ❌ not done

## Packaging

### 1. The plugin is called `accessible_flutter_tts` ✅

- **Expected:** `name: accessible_flutter_tts` in `pubspec.yaml`, and the iOS/macOS Swift packages
  and podspecs use the same name.
- **Status (2026-10-10):** done. Package, Swift packages, podspecs, Android namespace
  (`fr.ezymob.accessiblefluttertts`), Windows target, platform channel and native classes
  (`AccessibleFlutterTtsPlugin`) are all renamed, so the plugin can sit next to flutter_tts.
- **Verified (2026-10-10):** the example app builds from the checkout with Swift Package Manager
  (the folder/package name mismatch error is gone).
- **How to check:** `grep '^name:' pubspec.yaml`; build an app that depends on the plugin, with
  Swift Package Manager on.

### 2. It can be added to any Flutter project 🟡

- **Expected:** a Flutter app adds the dependency, runs `flutter pub get`, and builds on Android and
  iOS (Swift Package Manager and CocoaPods), plus macOS, web and Windows as upstream does.
- **Status (2026-10-10):** a fresh app using a **git dependency** (local copy of the repo named
  `flutter_tts.git`, like the GitHub repo) builds for iOS with Swift Package Manager, iOS with
  CocoaPods, Android, macOS and web, also with flutter_tts 4.2.5 installed next to it.
  Not done: Windows build (needs a Windows machine); the branch isn't pushed or tagged yet, so the
  GitHub URL in the README doesn't resolve.
- **How to check:** a fresh `flutter create` app with a git dependency on the pushed fork builds
  for each platform.

### 3. It replaces flutter_tts with nothing else to change ✅

- **Expected:** swapping the dependency and the import line are the only changes (import change
  agreed on 2026-10-10). Same classes (`FlutterTts`, …), same methods, same arguments, same return
  values, same callbacks. The screen reader behaviour turns on by itself.
- **Status (2026-10-10):** done. The Dart API is identical to 4.2.5 (only the internal channel name
  differs); the opt-in methods were removed and the behaviour is automatic.
- **Verified (2026-10-10):** in the example, `_OriginalTts` (flutter_tts 4.2.5) and `_AccessibleTts`
  make the exact same calls; analyzer and widget test pass.
- **How to check:** take an app using flutter_tts 4.2.5, change only the dependency and import, and
  confirm it analyses, builds and behaves the same.

## Behaviour

### 4. No screen reader: same as flutter_tts 🟡

- **Expected:** with VoiceOver and TalkBack off, every call behaves exactly like flutter_tts 4.2.5,
  including the speech rate the app sets.
- **Status (2026-10-10):** without a screen reader, the code runs upstream's paths unchanged:
  the app's rate is kept (Android only restores it if a screen reader had changed it), no waiting,
  no announcements.
- **Verified on Android (2026-10-10)**, Nothing Phone (1), Android 14, example app, timings from the
  plugins' logs. Same results for flutter_tts 4.2.5 and accessible_flutter_tts:

  | Phone state | Tap → speech starts | Sentence lasts |
  |---|---|---|
  | Default speech speed | ≈ 550 ms (incl. the example's 300 ms delay) | ≈ 8.2 s |
  | Phone speech speed ×2 | ≈ 550 ms | ≈ 8.2 s (app's rate kept) |
  | Select to Speak on, phone speed ×2 | ≈ 550 ms | ≈ 8.2 s |

  The Select to Speak case found a bug, fixed on 2026-10-10: the plugin took any spoken-feedback
  service for a screen reader and switched to the phone's speed (4.5 s). It now checks touch
  exploration, which TalkBack turns on (checked) and Select to Speak doesn't.
- **iOS:** verified on 2026-10-06 with an earlier build (speech works, including in silent mode
  with the `playback` audio category); not re-checked with this build.
- **How to check:** with the screen reader off, the example app's two screens sound identical
  (or run the timing script: tap each screen's button, compare the `TTS` log timestamps).

### 5. Screen reader on: speech uses the screen reader's speed 🟡

- **Expected:** with VoiceOver or TalkBack on, the app's speech runs at the speed set for
  VoiceOver or TalkBack, whatever rate the app asked for.
- **Status (2026-10-10):**
  - iOS: in the foreground, VoiceOver reads the text itself (queued announcement), so it uses its
    own voice and speed. In the background, `prefersAssistiveTechnologySettings` applies VoiceOver's
    settings. Not verified on a device.
  - Android: a screen reader is detected by touch exploration (TalkBack turns it on). Speech then
    uses the system text-to-speech rate (`Settings.Secure.TTS_DEFAULT_RATE`). TalkBack's
    own speed slider may not be readable by apps; if it isn't, this goal can't be fully met on
    Android. Not verified: no Android device available on 2026-10-10.
- **How to check:** change the screen reader's speed, tap the button on the example's Accessible
  screen, and confirm the sentence follows it.

### 6. Screen reader on: speech starts only after the screen reader stops 🟡

- **Expected:** the app's speech never overlaps the screen reader. If the screen reader is talking,
  the app waits for it to finish, then speaks.
- **Status (2026-10-10):**
  - iOS: the text is handed to VoiceOver as a queued announcement while the app is in the
    foreground. The 2026-10-06 test (VoiceOver cut on tap) couldn't show waiting: a double-tap
    stops VoiceOver by itself. The example now makes the screen reader read a long text, then
    speaks 300 ms later, while it's still talking. To be tested on the iPhone.
  - Android: waits while accessibility audio is playing (300 ms of silence, 10 s at most).
    Not tested on a device.
  - Known limit, iOS background / locked screen: VoiceOver doesn't read announcements and iOS
    doesn't tell apps when VoiceOver talks, so the plugin speaks without waiting. Overlap is
    possible there (for example with VoiceOver reading a notification).
- **How to check:** with the screen reader on, tap the button on each screen of the example. On
  Original, both voices overlap; on Accessible, the sentence comes after the screen reader's text.

## Decisions

- 2026-10-10: changing the import line is acceptable (goal 3).
- 2026-10-10: apps get the plugin through a git dependency on `BLKKKBVSIK/flutter_tts`.
