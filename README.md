# 🤖 AI Story Buddy & Quiz

A playful, child-friendly Flutter feature built for the **Peblo** edutainment
platform. Meet **Pip** — a friendly robot who reads a story aloud, then asks a
fun quiz and celebrates with confetti when the child gets it right.

> Built for ages **5–12**: big tap targets, bright colours, soft shadows, gentle
> animations, and zero dead-ends.

---

## Features

- Interactive story experience
- AI Buddy guidance
- Text-to-speech narration
- Quiz-based learning
- Animated feedback
- Riverpod state management
- Responsive Flutter UI

## 1. Project Overview

The feature is a single, self-contained flow:

```
Launch → Story visible → Tap "Read Me A Story" → Loading → Pip narrates (TTS)
       → Narration finishes → Quiz slides up → Answer
            ├─ Wrong  → shake + haptic + "Almost! Try again!" (quiz stays)
            └─ Right  → confetti + success card + happy Pip
```

Everything is driven by state machines, so the UI is a pure function of state.
Nothing is hard-coded that a content team would want to change — the quiz comes
from JSON.

---

## 2. Why Flutter

- **One codebase, both platforms** — important for a small product team shipping
  to iOS and Android at once.
- **60 FPS by default** — Skia/Impeller renders the custom vector buddy and all
  animations on the GPU, which matters on low-RAM Android devices.
- **`CustomPaint`** lets us draw Pip as pure vectors — no image assets, tiny APK,
  crisp at any density.
- **Rich animation toolkit** (`flutter_animate`, implicit animations) gives a
  polished, "real product" feel quickly.
- **Strong typing + null safety** catches whole classes of bugs at compile time.

---

## 3. Architecture

Clean separation of concerns. **No business logic lives in widgets.**

```
lib/
├── main.dart                  # entry, ProviderScope, Material 3 theme
├── models/
│   └── quiz_model.dart        # immutable, JSON-driven model + validation
├── services/
│   └── tts_service.dart       # pure-Dart wrapper around flutter_tts (testable)
├── providers/
│   ├── tts_provider.dart      # narration state machine (AudioState)
│   └── quiz_provider.dart     # async JSON load + answer state machine
├── screens/
│   └── story_screen.dart      # composition + derivation only (wires providers)
├── widgets/
│   ├── buddy_widget.dart      # vector robot, CustomPaint, mood states
│   ├── story_card.dart        # fade-in story display
│   ├── quiz_card.dart         # dynamic option renderer + shake
│   ├── animated_button.dart   # reusable CTA (press scale + loading)
│   └── success_card.dart      # confetti + success banner
├── constants/
│   ├── colors.dart            # brand palette, shadows, gradients
│   └── strings.dart           # all user-facing copy (l10n-ready)
└── utils/
    ├── audio_state.dart       # AudioState enum
    └── buddy_state.dart       # BuddyState enum
```

**Data flow:** `JSON / TTS engine` → `services` → `providers (state)` →
`widgets (render)`. Widgets read state and emit intents; they never decide
business outcomes.

---

## 4. State Management (Riverpod)

Three small, focused providers — each a single source of truth:

| Provider | Type | Responsibility |
|---|---|---|
| `ttsControllerProvider` | `NotifierProvider<TtsController, AudioState>` | Narration lifecycle |
| `quizProvider` | `FutureProvider<QuizModel>` | Async-load + parse JSON |
| `quizAnswerProvider` | `NotifierProvider<QuizAnswerController, QuizAnswerState>` | Answer evaluation |

Why Riverpod: compile-safe (no `BuildContext` lookups that fail at runtime),
trivially testable (override providers in tests), and `.select()` lets widgets
subscribe to *just* the slice they need to minimise rebuilds.

---

## 5. Audio Lifecycle

`AudioState` is the contract:

```dart
enum AudioState { idle, loading, speaking, completed, error }
```

- Tapping the CTA → `loading` (button disabled, friendly message shown).
- Engine initialises once (`_ensureInit`), wiring native callbacks.
- TTS start handler → `speaking` (button shows "Pip is reading…", buddy = narrating).
- **TTS completion handler → `completed`** — and only then is the quiz built.
- Any failure (init, speech, unexpected) → `error`, with a retry path.

The quiz gate is literally `if (audio.isCompleted)`, and `completed` is set
**only** inside the native completion callback — so the quiz can never appear
before narration finishes.

---

## 6. Quiz Rendering Strategy

The quiz is **not** hard-coded. It is loaded from `assets/quiz.json`, parsed by
`QuizModel.fromJson`, and rendered by iterating `quiz.options`. Swapping the JSON
(or pointing `quizProvider` at an API) changes the quiz with **zero UI edits**.

---

## 7. Dynamic Option Handling

`QuizCard` does:

```dart
for (final option in quiz.options) _OptionTile(...)
```

So 3, 4, 5 — or any N — options render automatically, and any question string
fits (the text wraps). Correctness is decided by the model (`quiz.isCorrect`),
never by index or position, so reordering options is safe.

---

## 8. Error Handling

- `TtsService.init` throws a typed `TtsException` on engine failure.
- `TtsController.narrate` catches **everything** (`TtsException` + generic) and
  routes to `AudioState.error`.
- `quizProvider` surfaces parse errors as `AsyncError`, rendered as a gentle
  message — `QuizModel.fromJson` validates shape and that the answer is a valid
  option.
- Every error path shows kid-friendly copy and a **Retry** button. The app never
  crashes or freezes; the worst case is a tap-to-retry card.

---

## 9. Animation Design

| # | Animation | Where | How |
|---|---|---|---|
| 1 | Story card fade-in | `story_card.dart` | `flutter_animate` `.fadeIn().slideY()` |
| 2 | Quiz slide-up reveal | `story_screen.dart` | `.fadeIn().slideY(begin: 0.25)` |
| 3 | Wrong-answer shake | `quiz_card.dart` | `ShakeEffect`, re-keyed on `wrongAttempts` |
| 4 | Confetti celebration | `success_card.dart` | `confetti` `ConfettiController` |
| 5 | Buddy state transition | `buddy_widget.dart` | `CustomPaint` repaint + bob/bounce |

The shake retriggers by changing a `ValueKey(wrongAttempts)` — declarative, no
manual `AnimationController` plumbing in the UI.

---

## 10. Performance Optimization

- **`ConsumerWidget` + `.select()`** — `StoryScreen` watches only `isCorrect`,
  not the whole answer object, so unrelated state changes don't rebuild it.
- **`RepaintBoundary`** around the buddy isolates its perpetual animation; the
  ticking robot never repaints the story or quiz.
- **Single `AnimationController`** drives the buddy (one ticker, not several).
- **`const` everywhere** possible so Flutter skips rebuilding static subtrees.
- **`shouldRepaint`** on the painter returns `true` only when state/pulse change.
- **No image assets** — vector buddy = no decode cost, no texture memory.

---

## 11. Lightweight Device Strategy (≈3GB RAM Android)

- Vector-only visuals → near-zero image memory and no jank from image decode.
- One scroll view, shallow widget tree, no nested heavy lists.
- Animations are short and GPU-friendly (transforms/opacity, not layout thrash).
- TTS engine initialised lazily and exactly once, then reused.

---

## 12. Caching Strategy

- **TTS engine** is created once via `ttsServiceProvider` and reused for the app
  lifetime (re-initialising per tap would be slow) — disposed with the provider.
- **Quiz JSON** is read through `FutureProvider`, which **caches** the parsed
  `QuizModel` — it is decoded once and reused for the session.
- **Vector buddy** needs no asset cache at all.

For a production rollout, `quizProvider` would gain a small on-device cache
(e.g. `shared_preferences`/Hive) so the last fetched content works offline.

---

## 13. AI Usage

**Where AI was used**
- Scaffolding boilerplate (provider wiring, enum helpers) and drafting the
  `CustomPaint` math for the buddy's face, then hand-tuned.
- Drafting kid-appropriate copy variations.

**One AI suggestion rejected — and why**
- AI suggested optimistically setting `AudioState.completed` right after calling
  `speak()` (since `awaitSpeakCompletion(true)` makes `speak` await). **Rejected**:
  on some platforms/engines the await resolves before audio truly finishes, which
  would reveal the quiz early. The spec requires the quiz to appear *only* after
  the **completion callback** fires, so the completion handler — not the `await` —
  is the single source of truth for `completed`.

**A development issue & how it was solved**
- The wrong-answer shake only played the first time. Re-running a `flutter_animate`
  effect imperatively is awkward. **Solution:** wrap the options in `Animate` with
  `key: ValueKey(wrongAttempts)`. Each wrong answer increments the counter, the key
  changes, the subtree rebuilds, and the shake replays — fully declarative, no
  `AnimationController` in the widget.

---

## 14. Future Improvements

- Multiple questions / story chapters with progress and stars.
- Offline content cache (Hive) + remote content from Peblo's CMS.
- Per-word highlight synced to TTS (`flutter_tts` progress handler).
- Voice/face customisation for Pip; accessibility voice-over polish.
- Localisation (strings already centralised) and right-to-left support.
- Sound effects for taps/correct/wrong; settings to mute.

---

## 🚀 Setup & Run

```bash
# 1. Generate platform folders for this project (android/ios/etc.)
flutter create .

# 2. Get dependencies
flutter pub get

# 3. Run on a device/emulator
flutter run
```

> The repo ships the Dart source, `pubspec.yaml`, tests, and assets. Running
> `flutter create .` once in the project root scaffolds the native platform
> folders without touching `lib/`. TTS requires a **real device or an emulator
> with a TTS engine** (the iOS Simulator/desktop may have limited voices).

Run tests:

```bash
flutter test
```

---

## 🎨 Brand Palette

| Token | Hex |
|---|---|
| Primary Purple | `#6C63FF` |
| Sky Blue | `#00C2FF` |
| Sunny Yellow | `#FFD93D` |
| Success Green | `#4CAF50` |
| Background | `#F8FAFF` |

---

Built with Flutter • Riverpod • flutter_tts • confetti • flutter_animate • Material 3
