# Fonts

**Vazirmatn** (SIL OFL) is bundled here and used app-wide for Persian and Latin
text — the app never falls back to the system font when it's present.

## Using IRANSans / IRANYekan instead

The font engine (`AppFont` in `Typography.swift`) auto-detects and **prefers**
IRANSans / IRANYekan if you add them. To switch:

1. Drop the TTFs into this folder, e.g.:
   - `IRANSansX-Regular.ttf`, `IRANSansX-Medium.ttf`, `IRANSansX-Bold.ttf`
2. Add their filenames to `UIAppFonts` in `project.yml`.
3. `xcodegen generate` and rebuild.

`AppFont.candidates` lists the PostScript names it looks for (IRANSansX,
IRANYekanX, …) in priority order, falling back to Vazirmatn. IRANSans is a
commercial font, so it is intentionally **not** committed to this repo — add
your own licensed copy.
