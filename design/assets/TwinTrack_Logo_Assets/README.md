# TwinTrack locked header-emblem assets

These files are copied byte-for-byte from the locked final UI project. They have not been redrawn, cropped, filtered, or regenerated.

## Recommended source files

| Appearance | File | Pixels | Alpha | SHA-256 |
|---|---|---:|---|---|
| Dark | `Dark/twintrack-mark.png` | 716 × 360 | RGBA; transparent background confirmed | `8bfdcef67df80dc8ab34464650c5c3ae1cf99e79ead55b3d8dd8bb0243784bd6` |
| Light | `Light/twintrack-mark-light-3x.png` | 612 × 309 | RGBA; transparent background confirmed | `d2385d95a129f43eadb2e855d7316859ea7511eed93f54356c9d9d2d741c1e84` |

## Existing variants

| Appearance | File | Pixels | Intended scale/reference |
|---|---|---:|---|
| Dark | `Dark/twintrack-mark-sm.png` | 204 × 103 | Small / approximately 1× |
| Dark | `Dark/twintrack-mark.png` | 716 × 360 | Highest-resolution clean source |
| Light | `Light/twintrack-mark-sm-light.png` | 204 × 103 | 1× |
| Light | `Light/twintrack-mark-light-2x.png` | 408 × 206 | 2× |
| Light | `Light/twintrack-mark-light-3x.png` | 612 × 309 | 3× / highest-resolution clean source |

The final project does not contain separate, exact 2× and 3× dark files. Do not relabel the 716 × 360 source as a scale-specific export.

## SwiftUI / Xcode mapping

Create one appearance-aware Image Set, for example `TwinTrackHeaderMark`:

- **Any Appearance / Light:** use the light emblem.
- **Dark Appearance:** use the dark emblem.
- Display it aspect-fit in the approved approximately 68 × 34 pt header frame.

Do not use the legacy opaque uploads or `twintrack-logo-full.png` for the header emblem. The latter is the full logo lockup rather than the emblem-only header asset.

## Verification

All included PNGs use RGBA pixels, contain fully transparent pixels, and have alpha-zero corners. The corrected light assets contain no visible pale-neutral checkerboard or plate pixels. Visual composites on white, `#F1F4F8`, and `#070B12` backgrounds show only the emblem.
