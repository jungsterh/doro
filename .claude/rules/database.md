---
name: database
description: Supabase, RLS, and local SQLite rules for Doro
paths: ["lib/services/**/*.dart", "lib/core/config/**/*.dart", "supabase/**/*"]
---

# Database Rules

## Supabase Queries
Always use parameterized/prepared queries — never interpolate user data into query strings:
```dart
// correct
await supabase.from('tasks').select().eq('user_id', userId);

// correct — rpc with named params
await supabase.rpc('get_summary', params: {'p_user_id': userId});

// wrong — never do this
await supabase.rpc('SELECT * FROM tasks WHERE id = $taskId');
```

## RLS Policies
Always use `(SELECT auth.uid())`, never bare `auth.uid()`:
```sql
-- correct
CREATE POLICY "users see own rows" ON tasks
  FOR SELECT USING (user_id = (SELECT auth.uid()));

-- wrong
CREATE POLICY "users see own rows" ON tasks
  FOR SELECT USING (user_id = auth.uid());
```

## Migrations
- File: `supabase/migrations/NNN_description.sql`
- **Next number: 015**
- Every migration must be idempotent (`IF NOT EXISTS`, `IF EXISTS`) where possible
- Never modify existing migration files — always add a new one
- Test locally with `supabase db reset` before shipping

## Local SQLite (sqflite)
Used for offline session buffering and cache. Service: `lib/services/database_service.dart`
- Always use `db.rawQuery(sql, [params])` or `db.query(table, where: '...', whereArgs: [])` — never string interpolation
- Schema changes require a `db.execute('ALTER TABLE ...')` in `onUpgrade` with version bump

## Service Layer Pattern
Supabase calls live exclusively in `lib/services/`. Pages/providers call services, not Supabase directly:
```
Page → Provider → Service → Supabase/SQLite
```
Sync between local and remote is handled in `sync_service.dart`.
