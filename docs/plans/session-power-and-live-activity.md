# Session Power Management & Live Activity

Battery-conscious behavior while a session is active, plus an OS-level live
timer when the user leaves the app.

> **Status (2026-07-01):** Phase 1 ✅ done (`screen_power_service.dart`, wired
> into `timer_page.dart`; device test in progress). **Next up: model change +
> Phase 2a.** Phase 2b blocked on macOS. See `docs/PROGRESS.md`.

## Goals

1. **Dim / power-saver** — keep the screen on during an active session, but drop
   to low brightness after 30s of no interaction so it doesn't drain the
   battery. Restore full brightness on touch. (Brightness-only; the clock UI
   stays unchanged.)
2. **Lock-screen live timer** — when the user swipes to the home screen / locks
   the phone, show a live countdown (timer) or elapsed count (stopwatch) on the
   lock screen with pause/stop controls, like the iOS Clock app.

## Key facts about the current code

- Active session UI: `lib/pages/timer/timer_page.dart` (landscape, `ConsumerStatefulWidget`,
  already a `WidgetsBindingObserver`).
- State: `activeSessionProvider` (`lib/providers/session_provider.dart`).
  - **Timer (Pomodoro)** when `targetDuration != null` → show `remaining`.
  - **Stopwatch (free-run)** when `targetDuration == null` → show `elapsed`.
- Elapsed comes from an in-process `Stopwatch` in `lib/services/session_service.dart`
  — NOT derived from absolute timestamps. `session.startTime` exists though.
- No wakelock today: the OS sleeps normally during a session.
- Lifecycle already routed through `didChangeAppLifecycleState` → `lockModeProvider`.

---

## Phase 1 — Dim / power-saver (pure Flutter, ships first)

**Packages**: `wakelock_plus`, `screen_brightness`.

**Approach** — a small `SessionScreenPowerController` (plain Dart, owned by
`_TimerPageState`), or inline in the State:

1. On enter (session running): `WakelockPlus.enable()`, capture
   `ScreenBrightness().current` as the restore value.
2. Start a 30s inactivity `Timer`. Any interaction on the page
   (`GestureDetector` tap / drag, control-drawer open) resets it.
3. On timeout → `ScreenBrightness().setScreenBrightness(0.1)` and flag
   `_dimmed = true`. On next interaction → restore captured brightness, restart
   the inactivity timer.
4. On pause: restore brightness (don't dim a paused session). Keep wakelock while
   the page is foreground; drop it when the app is backgrounded (the OS/Live
   Activity takes over — Phase 2).
5. On dispose / leaving the page: `ScreenBrightness().resetScreenBrightness()`,
   `WakelockPlus.disable()`.

**Edge cases**
- Restore brightness in `dispose`, on stop, on cancel, and on auto-complete.
- Guard against `screen_brightness` throwing on unsupported platforms (wrap in
  try/catch, `debugPrint` only — no crash).
- Don't fight the OS: if the app is backgrounded we stop managing brightness.

**Files**
- `pubspec.yaml` (+2 deps)
- `lib/pages/timer/timer_page.dart` (inactivity timer + dim hooks)
- optional `lib/services/screen_power_service.dart` if the logic grows.

---

## Phase 2 — Lock-screen live timer

### Model change (prerequisite for both platforms)

The OS renders the timer itself from absolute timestamps, so it keeps ticking
while the Dart isolate is suspended. Expose from the session:
- `DateTime startTime` (already on `Session`).
- For a countdown: `endTime = effectiveStart + targetDuration`.
- For pause/resume: recompute `effectiveStart = now - elapsed` on every
  update so the OS timer stays aligned with accumulated time.

Add helpers to `ActiveSessionState` (e.g. `effectiveStart`, `countdownEnd`) so
both the notification (Android) and Live Activity (iOS) read consistent values.

### Phase 2a — Android (buildable now on Windows)

**Package**: `flutter_foreground_task` (foreground service + ongoing
notification + action buttons + main-isolate comms).

- Start the foreground service on session start; stop on stop/cancel/complete.
- Notification uses a chronometer:
  - Timer → count-down chronometer to `countdownEnd`.
  - Stopwatch → count-up chronometer from `effectiveStart`.
- Action buttons: **Pause/Resume**, **Stop**. Taps are delivered to the main
  isolate → call `activeSessionProvider.notifier` pause/resume/stop and update
  the notification.
- Manifest: add the foreground service, `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_SPECIAL_USE` (Android 14), `POST_NOTIFICATIONS` (Android 13,
  request at runtime), `WAKE_LOCK`.
- Reconcile on resume: when the app returns to foreground, re-read service state
  so in-app UI and notification agree.

**Testing**: needs a real Android device / emulator. Cannot be verified purely by
`flutter analyze` — flagged for manual device test.

### Phase 2b — iOS Live Activity (PLAN ONLY — blocked on Windows)

Live Activities require a **SwiftUI Widget Extension built in Xcode on macOS**.
The current dev machine is Windows 11, so the native half cannot be built or
tested here. Dart-side scaffolding can be written; the Swift widget is deferred.

Steps for when Mac/Xcode is available:
1. Add `live_activities` (Dart wrapper for ActivityKit).
2. In Xcode: add a Widget Extension target; set
   `NSSupportsLiveActivities=YES` in `Runner/Info.plist`; add an **App Group**
   shared between Runner and the extension.
3. Build the SwiftUI `ActivityConfiguration`:
   - Lock screen view + Dynamic Island (compact / expanded / minimal).
   - Use native `Text(timerInterval:countsDown:)` so iOS ticks the timer with no
     app runtime — count down to `countdownEnd` (timer) or up from
     `effectiveStart` (stopwatch).
4. Interactive controls (pause/resume/stop) need **App Intents (iOS 17+)**:
   the intent writes the action into the App Group; the Flutter app reconciles
   when it next resumes (it may be suspended when the button is tapped).
5. Dart: start the activity on session start, push updates on pause/resume,
   end it on stop/cancel/complete.

**Requirements**: iOS 16.1+ (Live Activities), 16.1+ (Dynamic Island),
17+ (interactive buttons), a paid-ish Apple dev setup, and macOS.

---

## Sequencing

1. Phase 1 (dim) — implement + `flutter analyze`/`flutter test` now.
2. Model change (effective-start helpers).
3. Phase 2a (Android) — implement; verify on a device.
4. Phase 2b (iOS) — scaffold Dart; native work deferred to macOS.

## Eval

- `flutter analyze` zero warnings after each phase.
- `flutter test` green.
- Manual device test for Phase 2a (foreground notification + actions).
