# Doro — UI Style Guide

> Canonical reference for visual consistency. Consult this before adding any new UI. All values come from `lib/core/theme/`.

## Design Principles
- **Minimal** — every element earns its place; no decorative clutter
- **Glass** — surfaces feel translucent and layered, not flat or skeuomorphic
- **Focus** — typography and spacing guide the eye; the timer is always the hero

---

## Color Tokens (`lib/core/theme/app_colors.dart`)

### Dark Mode
| Token | Hex | Usage |
|-------|-----|-------|
| `darkBackground` | `#0A0A0A` | Scaffold background |
| `darkSurface` | `#141414` | Bottom sheets, drawers |
| `darkCard` | `#1C1C1E` | Material cards |
| `darkAccent` | `#FFFFFF` | Primary actions, active state |
| `darkAccentCyan` | `#AAAAAA` | Secondary actions |
| `darkText` | `#FFFFFF` | Primary text |
| `darkTextSecondary` | `#8E8E93` | Labels, captions, placeholders |
| `darkBorder` | `#FFFFFF 19%` | Dividers, input borders |

### Light Mode
| Token | Hex | Usage |
|-------|-----|-------|
| `lightBackground` | `#F2F2F7` | Scaffold background |
| `lightSurface` | `#FFFFFF` | Bottom sheets, drawers |
| `lightCard` | `#FFFFFF` | Material cards |
| `lightAccent` | `#0A0A0A` | Primary actions |
| `lightText` | `#0A0A0A` | Primary text |
| `lightTextSecondary` | `#6B6B6B` | Labels, captions |
| `lightBorder` | `#000000 19%` | Dividers |

### Semantic / Shared
| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#EF5350` | Destructive actions, error states |
| `success` | `#43B89C` | Completion, positive feedback |
| `warning` | `#F9A825` | Caution states |

### Glass Overlays
| Token | Value | Usage |
|-------|-------|-------|
| `glassDark` | `#FFFFFF 10%` | Glass surface background (dark) |
| `glassLight` | `#FFFFFF 70%` | Glass surface background (light) |
| `glassBorderDark` | `#FFFFFF 19%` | Glass border (dark) |
| `glassBorderLight` | `#FFFFFF 25%` | Glass border (light) |

---

## Typography

Font family: **Inter** (via `google_fonts`) — wired in `AppTheme._buildTextTheme()`.  
Use `Theme.of(context).textTheme` — never call `GoogleFonts.inter()` directly in widgets.

| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| `displayLarge` | 57 | 700 | primary | Hero numbers (timer display) |
| `displayMedium` | 45 | 700 | primary | Large stats |
| `displaySmall` | 36 | 600 | primary | Section headers |
| `headlineLarge` | 32 | 600 | primary | Page titles |
| `headlineMedium` | 28 | 600 | primary | Card headers |
| `headlineSmall` | 24 | 600 | primary | Sub-section titles |
| `titleLarge` | 22 | 600 | primary | Dialog titles |
| `titleMedium` | 16 | 500 | primary | List item titles |
| `titleSmall` | 14 | 500 | primary | Compact list titles |
| `bodyLarge` | 16 | 400 | primary | Body copy |
| `bodyMedium` | 14 | 400 | primary | Secondary body |
| `bodySmall` | 12 | 400 | secondary | Captions, hints |
| `labelLarge` | 14 | 600 | primary | Button labels |
| `labelMedium` | 12 | 500 | secondary | Tags, badges |
| `labelSmall` | 11 | 400 | secondary | Timestamps, metadata |

---

## Spacing

Base unit: **4px**. All spacing is a multiple of 4.

| Name | Value | Usage |
|------|-------|-------|
| xs | 4px | Icon-text gap, tight internal padding |
| sm | 8px | List item gap, compact padding |
| md | 12px | Button vertical padding |
| base | 16px | Standard content padding |
| lg | 24px | Section gap, card internal padding |
| xl | 32px | Between major sections |
| xxl | 48px+ | Top of page hero areas |

---

## Border Radius

| Context | Radius |
|---------|--------|
| Cards, bottom sheets, modals | 16px |
| Buttons, text fields, dropdowns | 12px |
| Chips, tags, small badges | 8px |
| Avatar, circular icons | 50% |

---

## Glass Surfaces

### When to Use Which Primitive

| Use Case | Widget | File |
|----------|--------|------|
| Content card (tappable or not) | `GlassCard` | `lib/widgets/glass_card.dart` |
| Container needing blur (non-card) | `GlassWidget` | `lib/core/theme/glass_decoration.dart` |
| Container without blur (BoxDecoration only) | `GlassDecoration.themed(context)` | `lib/core/theme/glass_decoration.dart` |

### GlassCard Defaults
- `borderRadius`: 16
- `blur (sigmaX/Y)`: 8
- `padding`: `EdgeInsets.all(16)`
- `border width`: 1.5px

### GlassWidget Defaults
- `borderRadius`: 16
- `blur (sigmaX/Y)`: 6
- `border width`: 1px

---

## App Bar
- Transparent background, no elevation
- `centerTitle: false` — title left-aligned
- Title uses `titleLarge` style (22px, w600)

---

## Buttons
- Primary: `GlassButton` from `lib/widgets/glass_button.dart`
- Destructive: red tint using `AppColors.error`
- Disabled: 40% opacity of normal state
- Min tap target: 44×44px

---

## Elevation & Shadows
Avoid Material elevation. Use subtle shadows on glass cards only:
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.1),
  blurRadius: 12,
  offset: Offset(0, 4),
)
```

---

## Icons
- Style: outlined (Material Symbols or similar)
- Size: 20px (compact), 24px (standard), 28px (prominent)
- Color: inherits from `iconTheme` — use `AppColors.darkText` / `lightText`

---

## Animation Guidelines
- Entrance: fade + slide up, 300ms, `Curves.easeOut`
- Exit: fade out, 200ms
- Micro-interactions (tap feedback, toggle): 150–200ms
- Page transitions: 400ms max
- Avoid bouncy/spring physics — keep it calm and focused
