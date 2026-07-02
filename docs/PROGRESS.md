# Doro — Progress Log

Running status of milestones. Newest entry first.

---

## 2026-07-01 — Closed testing live on both stores

### Distribution
- ✅ **iOS**: First build uploaded to App Store Connect, installed on device via TestFlight, added to closed testing group. See `TESTFLIGHT_DEPLOY.md`.
- ✅ **Android**: Signed AAB on a closed testing track in Play Console; testers installed via opt-in link. See `ANDROID_CHECKLIST.md`.
- ✅ **Google Sign-In** verified working on device (both platforms).
- ⏳ Remaining store work: subscriptions (both stores), Sign In with Apple, Supabase Apple OAuth, license testers + purchase test pass.

### Feature 1 — Dim / power-saver (Phase 1) — ✅ DONE
Plan: `docs/plans/session-power-and-live-activity.md`
- `wakelock_plus` + `screen_brightness` in `pubspec.yaml`.
- `lib/services/screen_power_service.dart`: wakelock on engage, 30s idle timer → dim to 10%, restore on interaction, suspend on pause/background, full release on dispose. All platform calls guarded with try/catch + `debugPrint`.
- Wired in `lib/pages/timer/timer_page.dart`: `Listener.onPointerDown` resets idle timer; lifecycle + session-state listeners suspend/resume correctly.
- Code-reviewed against the plan's edge cases — all covered. Manual device testing in progress (user testing dim behavior now).

### ▶ NEXT: Phase 2a — Android lock-screen live timer
**This is where we left off.** Plan section: `docs/plans/session-power-and-live-activity.md` → "Phase 2a".
Not started — no `flutter_foreground_task` in the project yet.

Order of work:
1. Model change first: `effectiveStart` / `countdownEnd` helpers on `ActiveSessionState` (prerequisite for 2a and 2b).
2. Add `flutter_foreground_task`; foreground service starts/stops with session.
3. Notification with chronometer (count-down to `countdownEnd` for timer, count-up from `effectiveStart` for stopwatch) + Pause/Resume + Stop action buttons.
4. Manifest: foreground service, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS` (runtime request), `WAKE_LOCK`.
5. Reconcile service ↔ app state on resume.
6. Verify on real Android device (analyze/test alone can't validate this).

Phase 2b (iOS Live Activity) remains blocked on macOS/Xcode — Dart scaffolding only until then.
