---
name: flutter-ui
description: Flutter UI patterns, widget conventions, and theming rules for Doro
paths: ["lib/**/*.dart"]
---

# Flutter UI Rules

## Theming — Always Use Theme Tokens
- Colors → `AppColors.<constant>` from `lib/core/theme/app_colors.dart`
- Text styles → `Theme.of(context).textTheme.<style>`
- Never inline `GoogleFonts.inter(...)` in widgets — the theme already wires this
- Never use raw hex literals (e.g. `Color(0xFF...)`) outside of `app_colors.dart`

## Glass Surfaces
Use the existing primitives — don't recreate `BackdropFilter` manually:
- `GlassCard` (`lib/widgets/glass_card.dart`) — tappable content cards
- `GlassWidget` (`lib/core/theme/glass_decoration.dart`) — non-tappable containers
- `GlassDecoration.themed(context)` — when you only need a `BoxDecoration`

Default blur: `sigmaX/Y = 15` (GlassCard), `10` (GlassWidget)

## Spacing & Layout
- Base unit: 4px — all spacing must be multiples of 4
- Content padding: 16px (`EdgeInsets.all(16)`)
- Section gap: 24px
- List item gap: 8–12px
- Safe area: always wrap scrollable screens in `SafeArea`

## Border Radius
| Context | Radius |
|---------|--------|
| Cards, sheets | 16px |
| Buttons, inputs | 12px |
| Chips, badges | 8px |
| Icons | circular |

## Async & State
- All Supabase/service calls go in `lib/services/`, never directly in widgets or pages
- Pages use `ConsumerWidget` / `ConsumerStatefulWidget` and read Riverpod providers
- Guard every `BuildContext` use after an `await` with a `mounted` check:
  ```dart
  await someAsyncCall();
  if (!mounted) return;
  // safe to use context here
  ```

## Animation
- Use `flutter_animate` package for entrance/exit animations
- Keep durations: 200–300ms for micro-interactions, 400–600ms for page transitions
- Prefer fade + slide combinations; avoid bouncy physics in a productivity app

## Widget Patterns
- Extract widgets when a subtree exceeds ~50 lines or is reused
- Prefer `const` constructors everywhere possible
- Name widgets descriptively: `TaskListItem`, not `ListTile1`
