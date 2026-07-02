# Plan — Editable Tasks (rename / recolor / delete + Manage Tasks)

## Goal
Let the user manage the tasks that identify sessions:
- Edit a task's **name** and **color**, and **delete** a task.
- Reach a **"View all Tasks"** management screen from the task pull-down.
- Edit the task's **name + color** directly from the **Session Detail** page.

## Decisions (confirmed)
- **Manage UI:** dedicated full page.
- **Delete:** cascade-delete the task *and* its sessions, behind a strong warning that shows how many sessions / how much tracked time will be lost.
- **Session Detail edit:** name **and** color (same editor as Manage Tasks).

## Identity note (task_id / task_name / owner_id)
Already satisfied — no model/migration change needed:
- Sessions reference tasks via `task_id`; `Task` carries `id` + `name`.
- Ownership exists as `user_id` on the Supabase `tasks`/`sessions` tables, attached at sync time (`sync_service.dart:38`). Local SQLite is single-user, so no local `owner_id` column is required.

## Existing building blocks (reuse, don't recreate)
- `DatabaseService.updateTask` ✅ and `TaskService.updateTask` ✅ already exist.
- Delete already cascades in SQLite (`database_service.dart:59`, `ON DELETE CASCADE`).
- `_showAddTaskDialog` in `start_task_panel.dart:344` is the name+color editor to extract & reuse.

---

## Work items

### 1. Provider: wire up update (and fix remote delete)
`lib/providers/task_provider.dart` — `TasksNotifier`:
- Add `Future<Task> updateTask(Task task)`: call `service.updateTask`, replace the task in `state` list by id, `_syncInBackground()` (upsert already propagates rename/recolor since it keys on `id`).
- Keep `deleteTask` but make the delete actually propagate remotely (see item 5).

### 2. Reusable task editor dialog
New `lib/widgets/task_editor_dialog.dart`:
- `TaskEditorDialog` supporting **create** and **edit** modes (prefill name + selected color; title "New Task" / "Edit Task"; button "Create" / "Save").
- Name + `AppConstants.defaultColors` swatch picker (lifted from `start_task_panel.dart:344-414`).
- Returns the entered `(name, colorHex)` (or null on cancel); caller decides create vs update.
- Refactor `start_task_panel._showAddTaskDialog` to use it (no behavior change).

### 3. Manage Tasks page
New `lib/pages/tasks/manage_tasks_page.dart` (`ConsumerWidget`/`ConsumerStatefulWidget`):
- `SafeArea` + `CustomScrollView`/`SliverAppBar` titled "All Tasks", matching Session Detail styling.
- Watches `tasksProvider`; renders each task as a `GlassCard` row: color dot, name, a subtitle with session count + total tracked time, plus **edit** and **delete** actions.
- Session count/time per task: add `sessionCountByTaskProvider`/reuse `sessionsByTaskProvider(taskId)` (already exists at `session_provider.dart:152`) to compute count + summed `durationSeconds`.
- **Edit** → `TaskEditorDialog` (edit mode) → `tasksProvider.notifier.updateTask(...)`.
- **Delete** → confirm dialog: *"Delete '<name>'? This will permanently remove N sessions (Xh Ym tracked). This cannot be undone."* → `deleteTask(id)`; then `ref.invalidate(sessionsProvider)`.
- Empty state when no tasks.
- Follow `.claude/rules/flutter_ui.md`: `AppColors`, `Theme...textTheme`, `GlassCard`, 16px padding, 4px spacing, `mounted` guards after awaits.

### 4. Entry point from the pull-down
`lib/widgets/task_dropdown.dart`:
- Add a pinned "View all Tasks" row (list/settings icon) below the task list (next to / near "Add new task").
- New `VoidCallback? onViewAll` prop; `start_task_panel.dart` passes a callback that `Navigator.push`es `ManageTasksPage` and closes the dropdown.

### 5. Make delete propagate to Supabase (bug fix)
`sync_service.dart` only upserts, so deletes resurrect on next `syncFromSupabase()`.
- Add `Future<void> deleteTaskRemote(String id)` (deletes the task row; sessions cascade via FK if configured, otherwise also delete `sessions` where `task_id = id`) and call it from `TasksNotifier.deleteTask` (guard: only when configured + premium + signed in; ignore/log failures like other background sync).
- Verify Supabase `sessions.task_id` FK/cascade; if absent, delete sessions rows explicitly in the same call. (Parameterized `.eq('id', id)` / `.eq('task_id', id)` — no string interpolation.)

### 6. Session Detail: edit name + color
`lib/pages/session/session_detail_page.dart`:
- Convert `task` from `widget.task` getter to mutable state `Task? _task = widget.task`.
- Make the task header row (`:107-130`) tappable (or add an edit affordance) → `TaskEditorDialog` (edit mode).
- On save: `tasksProvider.notifier.updateTask(...)`, update local `_task`, `ref.invalidate(sessionsProvider)` + `sessionsByTaskProvider(_session.taskId)`; `mounted` guard.
- Note in UI is unchanged.

### 7. Stale selected-task cleanup
- `start_task_panel` holds a local `_selectedTask` copy and `selectedTaskProvider` may hold a stale `Task` after a rename/recolor. After returning from Manage Tasks, re-resolve the selected task from `tasksProvider` by id (or invalidate) so the picker shows fresh name/color.

---

## Files touched
- `lib/providers/task_provider.dart` — add `updateTask`; call remote delete.
- `lib/widgets/task_editor_dialog.dart` — **new** reusable editor.
- `lib/pages/tasks/manage_tasks_page.dart` — **new** page.
- `lib/widgets/task_dropdown.dart` — "View all Tasks" entry + `onViewAll`.
- `lib/pages/home/widgets/start_task_panel.dart` — use editor dialog; wire `onViewAll`; refresh selected task.
- `lib/pages/session/session_detail_page.dart` — editable task header.
- `lib/services/sync_service.dart` — `deleteTaskRemote`.
- (No migration; no `Task`/`Session` model change.)

## Eval checklist (from CLAUDE.md)
```
flutter analyze          # zero warnings
flutter test
flutter test integration_test/
```
- Add/extend a `TaskService`/provider test for `updateTask`.
- Manually verify: rename/recolor reflects in dropdown, timer header, session detail, and manage list; delete removes task + sessions and shows the warning count; changes survive a sync round-trip.

## Open risks
- Cascade delete is destructive (session history lost) — mitigated only by the warning dialog, per decision.
- Editing a task's name/color affects **all** sessions under it (shared entity) — expected, but worth a one-line hint in the Session Detail editor.
