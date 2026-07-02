# App icon assets

Drop the exported PNGs here, then run:

```
dart run flutter_launcher_icons
```

## Required files

| File | Size | Alpha | Notes |
|------|------|-------|-------|
| `icon_1024.png` | 1024×1024 | **No alpha** | Master icon (iOS + Android legacy). Full-bleed background; glyph within central ~66%. |
| `icon_foreground.png` | 1024×1024 | **Transparent** | Android adaptive foreground — glyph only, centered within ~66% (outer ~33% may be masked). |

Adaptive background color is set in `pubspec.yaml` (`adaptive_icon_background: "#0E0E10"`).
Swap it for an image path if you want a gradient background layer instead.

## Design constraints (see docs/plans if expanded)
- Background fills 100% of the square — do NOT pre-round corners (iOS/Android mask their own).
- Glyph ≈ 60–66% of canvas, optically centered.
- 2–3 colors max; brand accent `#6C63FF`.
- Flat glyph on a softly-lit gradient — no glossy 3D.
- Validate at 48 px and in grayscale.
