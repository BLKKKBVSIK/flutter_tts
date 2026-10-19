# VoiceOver demo

Two iOS apps that are identical except for their text-to-speech plugin:

| App on the home screen | Folder | Plugin |
|---|---|---|
| **TTS Original** (orange) | `flutter_tts_demo` | `flutter_tts` 4.2.5 |
| **TTS Accessible** (teal) | `accessible_flutter_tts_demo` | `accessible_flutter_tts`, tag `v4.2.5-ezymob.2` |

Both use the screen in `demo_screen`, and their `lib/main.dart` only differ by the import line and
the plugin's name and color.

## What the button does

1. VoiceOver reads the trip details (a long text), as it would be reading the screen.
2. Half a second later, while VoiceOver is still talking, the app announces the next stop at the
   speech rate it sets (0.5).

A double-tap makes VoiceOver stop talking, which is why the app makes VoiceOver read a text first.
The texts follow the phone's language (French or English): VoiceOver only applies the user's speed
to text in the phone's language.

## Demo script

With VoiceOver on, in each app, double-tap **Announce the next stop**:

- **TTS Original:** the next stop is announced on top of VoiceOver: two voices at once.
- **TTS Accessible:** VoiceOver finishes the trip details, then the next stop is announced.

Change VoiceOver's speed (rotor, or Settings › Accessibility › VoiceOver › Speaking Rate) and tap
again in each app:

- **TTS Original:** VoiceOver's text changes speed, the announcement doesn't.
- **TTS Accessible:** both change speed: the announcement uses VoiceOver's speed.

With VoiceOver off, the two apps sound the same.

## Build and install

From each app's folder, with an iPhone connected:

```sh
flutter run --release
```
