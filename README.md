# Doro

A focused work tracking app that helps you understand how you spend your time.

## What It Does

Doro lets you log work sessions against tasks and see how long you stayed focused. After each session you get a summary with a trend chart. Over time, the analytics dashboard shows your activity patterns — a weekly bar chart and task breakdown — so you can spot when you're most productive and where your hours actually go.

## Features

- **Session timer** — start a session under a task, stop when done
- **Session summary** — per-session review with trend chart and comment
- **Analytics dashboard** — weekly bar chart + activity pie chart by task
- **Task management** — create and organize tasks; recent tasks surfaced for quick access
- **Lock mode** — prevent accidental stops during a session
- **Data export** — export session history
- **Premium** — subscription tier with additional benefits
- **Push notifications** — powered by Firebase FCM

## Stack

| Layer | Tech |
|---|---|
| Frontend | Flutter (iOS & Android) |
| Backend / DB | Supabase (Postgres + Auth + RLS) |
| Notifications | Firebase FCM |
| State | Riverpod providers |
| Purchases | In-app purchases via `purchase_service` |

## Project Structure

```
lib/
  core/          # Theme, constants, config, utilities
  models/        # Session, Task, User
  pages/         # Screen-level widgets (timer, summary, home, settings, …)
  providers/     # Riverpod state providers
  services/      # Supabase, session, task, export, sync, purchase logic
  widgets/       # Shared UI components (glass cards, buttons, dropdowns)
supabase/        # Numbered SQL migrations
```

## Development Notes

- No web target — mobile only
- SQL migrations are numbered sequentially under `supabase/`
- RLS policies use `(SELECT auth.uid())` pattern throughout
- `debugPrint` only — no `print()`
