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

### 2. It can be added to any Flutter project ✅

- **Expected:** a Flutter app adds the git dependency, runs `flutter pub get`, and builds on
  **Android and iOS** (Swift Package Manager and CocoaPods). Only these two platforms are targeted
  (decided 2026-10-10); macOS, web and Windows keep upstream's code but aren't required.
- **Verified (2026-10-10):** a fresh `flutter create` app with a git dependency on
  `https://github.com/BLKKKBVSIK/flutter_tts.git`, branch `ezymob/screen-reader-aware`, builds for
  iOS (Swift Package Manager) and Android. With a local copy of the repo, it also built for iOS with
  CocoaPods, and with flutter_tts 4.2.5 installed next to it.
- **Release:** apps install the tag `v4.2.5-ezymob.2` (2026-10-19), which includes every fix
  verified in this file.
- **How to check:** a fresh `flutter create` app with the git dependency builds for Android and iOS.

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

### 4. No screen reader: same as flutter_tts ✅

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
- **Verified on iOS (2026-10-10)**, iPhone 17 Pro, iOS 27.2, VoiceOver off (checked by the app),
  `example/lib/measure.dart`: same calls on both plugins, two rounds per rate, timed from
  `speak` to the start and completion callbacks. Same results for both plugins:

  | App's rate | Call → speech starts | Sentence lasts |
  |---|---|---|
  | 0.5 (default) | ≈ 3 ms (23 ms on the very first call) | 7.8 – 8.2 s |
  | 0.65 | ≈ 3 ms | ≈ 4.86 s |

  iOS only switches behaviour when `UIAccessibility.isVoiceOverRunning`; other features such as
  Spoken Content don't change it (by code).
- **How to check:** with the screen reader off, the example app's two screens sound identical.
  Android: tap each screen's button over adb and compare the `TTS` log timestamps.
  iOS: `flutter run --release -t lib/measure.dart` and read the `MEASURE|…` lines in the device log.

### 5. Screen reader on: speech uses the screen reader's speed ✅

- **Expected:** with VoiceOver or TalkBack on, the app's speech runs at the speed set for
  VoiceOver or TalkBack, whatever rate the app asked for.
- **Status (2026-10-19):** done and verified on iOS and Android.
  - iOS: in the foreground, VoiceOver reads the text itself (queued announcement), so it uses its
    own voice and speed. In the background, `prefersAssistiveTechnologySettings` applies VoiceOver's
    settings.
    **Verified (2026-10-19)** ✅, iPhone 17 Pro, iOS 27.2 (phone in English), VoiceOver on,
    `example/lib/measure.dart`, screen recordings analysed. Times from the plugins' callbacks:

    | | VoiceOver fast | VoiceOver slow |
    |---|---|---|
    | accessible_flutter_tts, app rate 0.5 | 1.69 s · 1.63 s | 10.20 s · 10.14 s |
    | accessible_flutter_tts, app rate 0.65 | 1.63 s · 1.64 s | 10.14 s · 10.14 s |
    | flutter_tts, app rate 0.5 | 7.20 s · 7.22 s | 7.25 s · 7.21 s |
    | flutter_tts, app rate 0.65 | 4.39 s · 4.39 s | 4.40 s · 4.40 s |

    Our sentence follows VoiceOver's speed and ignores the app's; flutter_tts does the opposite.
    **Fixed (2026-10-19):** naming the text's language made VoiceOver use that language's own voice
    and speed (our sentence stayed at 6.56 s whatever the VoiceOver speed). The language is now only
    named when it differs from the phone's.
    **Known limit:** text in another language than the phone's is read at that language's VoiceOver
    speed, not the user's current one. iOS offers no way around it.
  - Android: a screen reader is detected by touch exploration (TalkBack turns it on). Speech then
    uses the system text-to-speech rate (`Settings.Secure.TTS_DEFAULT_RATE`), which **TalkBack's own
    speed slider writes** (checked 2026-10-19: moving it changed the setting 3.69× → 0.10× → 1.58×).
    **Verified (2026-10-19)** ✅, Nothing Phone (1), Android 14 (phone in English), TalkBack on,
    `example/lib/measure.dart`, times from the plugins' callbacks:

    | | TalkBack 3.69× | TalkBack "normal" (1.58×) |
    |---|---|---|
    | accessible_flutter_tts, app rate 0.5 | 2.08 s · 2.07 s | 4.60 s · 4.61 s |
    | accessible_flutter_tts, app rate 0.65 | 2.07 s · 2.10 s | 4.61 s · 4.64 s |
    | flutter_tts, app rate 0.5 | 7.20 s · 7.23 s | 7.18 s · 7.22 s |
    | flutter_tts, app rate 0.65 | 5.61 s · 5.60 s | 5.59 s · 5.63 s |

    Our sentence follows TalkBack's speed and ignores the app's; flutter_tts does the opposite.
- **How to check:** with the screen reader on, run `flutter run --release -t lib/measure.dart` at
  two screen reader speeds (Android: read the `MEASURE|…` lines with `adb logcat -s flutter`;
  iOS: read them on screen). Our lines change with the screen reader's speed, flutter_tts's don't.

### 6. Screen reader on: speech starts only after the screen reader stops ✅

- **Expected:** the app's speech never overlaps the screen reader. If the screen reader is talking,
  the app waits for it to finish, then speaks.
- **Status (2026-10-19):** done and verified on iOS and Android, app in the foreground.
- **Test:** `example/lib/overlap.dart`. For each plugin, twice: the screen reader reads a long text,
  and `speak` is called 0.5 s later while it's still talking.
- **Verified on Android (2026-10-19)**, Nothing Phone (1), TalkBack on. Audio timeline polled on the
  phone (`dumpsys audio`, ~100 ms) next to the app's events:

  | Round | TalkBack talks | App talks |
  |---|---|---|
  | flutter_tts 1 | 0.05 – 4.03 s | 4.03 – 7.96 s |
  | accessible 1 | 0.05 – 4.01 s | 4.43 – 6.86 s (0.42 s after) |
  | flutter_tts 2 | 0.05 – 3.99 s | 3.99 – 7.90 s |
  | accessible 2 | 0.06 – 3.94 s | 4.28 – 6.79 s (0.34 s after) |

  No overlap with either plugin: TalkBack and the app used the same speech engine (Google's), which
  reads one request at a time, so even flutter_tts queued behind TalkBack. That only holds when both
  use the same engine; our plugin waits by watching what's actually playing, whatever the engine.
- **Verified on iOS (2026-10-19)**, iPhone 17 Pro, VoiceOver on at normal speed, screen recording
  analysed (audio segments + the app's events):

  | Round | VoiceOver talks | App talks |
  |---|---|---|
  | flutter_tts 1 | 16.38 – 28.05 s | 16.92 – 21.61 s (overlaps) |
  | accessible 1 | 29.60 – 41.27 s | 41.59 – 46.44 s (0.32 s after) |
  | flutter_tts 2 | 54.80 – 66.47 s | 55.30 – 60.04 s (overlaps) |
  | accessible 2 | 68.05 – 79.73 s | 80.05 – 84.89 s (0.32 s after) |

  flutter_tts talks over VoiceOver for its whole sentence; ours waits for VoiceOver to finish.
- **Known limit, iOS background / locked screen:** VoiceOver doesn't read announcements and iOS
  doesn't tell apps when VoiceOver talks, so the plugin speaks without waiting. Overlap is possible
  there (for example with VoiceOver reading a notification). Not tested.
- **How to check:** with the screen reader on, `flutter run --release -t lib/overlap.dart`.
  Android: poll `dumpsys audio` for `USAGE_ASSISTANCE_ACCESSIBILITY` (screen reader) and
  `USAGE_MEDIA` (app). iOS: screen recording, then compare the audio with the `OVERLAP|…` events.

## Decisions

- 2026-10-10: changing the import line is acceptable (goal 3).
- 2026-10-10: apps get the plugin through a git dependency on `BLKKKBVSIK/flutter_tts`.
- 2026-10-10: only Android and iOS are targeted (goal 2).
