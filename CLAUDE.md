# Doro — Focus Timer App

## Stack
Flutter + Supabase + Firebase FCM. Mobile only (iOS + Android). No web target.

## Context Workflow
For any non-trivial task, follow this pattern to avoid context rot:
1. **Explore** — read files, understand the area, ask questions
2. **Plan** — use `/plan` mode to draft approach, save to `docs/plans/<feature>.md`
3. **Clear** — run `/clear` or start fresh session with the plan file as input
4. **Execute** — implement against the plan

At ~50% context usage, run `/compact` to prune history while keeping the goal.

## Eval Checklist (run after changes)
```
flutter analyze          # zero warnings policy
flutter test             # all tests green
flutter test integration_test/  # integration suite
```
Flag any new analyzer warnings before marking a task done. If a test must be skipped, leave a `// TODO: re-enable after X` comment.

## Rules
- Never auto-commit
- SQL migrations: `supabase/migrations/` numbered sequentially — **next: 006_**
- Always use `(SELECT auth.uid())` in RLS policies, never bare `auth.uid()`
- Null safety strict; `debugPrint` not `print()`
- Never use `BuildContext` across async gaps — guard with `mounted` check
- Prepared statements / parameterized queries only; no string interpolation in SQL
- Log meaningful events with `debugPrint`; no sensitive data in logs

## UI & Styling
The app uses a glass-morphism aesthetic with Inter font. See `docs/style_guide.md` for the full token reference before touching any UI. Key constraints:
- Colors: only `AppColors` constants — no raw hex literals in widgets
- Typography: only `Theme.of(context).textTheme` — no inline `GoogleFonts` calls in widgets
- Glass surfaces: use `GlassCard` or `GlassWidget` from `lib/widgets/` — don't recreate BackdropFilter ad hoc
- Border radius default: 16px (cards), 12px (buttons/inputs), 8px (chips/tags)
- Spacing: multiples of 4px; standard content padding 16px

## Architecture
- State: Riverpod providers in `lib/providers/`
- Business logic: `lib/services/` — keep pages/widgets free of direct Supabase calls
- Models: `lib/models/` — pure data, no side effects
- Shared widgets: `lib/widgets/` and `lib/core/theme/`

## Preferences
- Minimal, clean, sleek UI — no decorative elements without purpose
- Concise responses, no filler
- Ask before touching files outside the current task scope
