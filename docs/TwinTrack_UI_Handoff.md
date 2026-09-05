# TwinTrack AI - Final UI Audit and SwiftUI Handoff

**UI status:** READY TO LOCK FOR SWIFTUI IMPLEMENTATION  
**Implementation status:** EXTERNAL AI DRAFT - REQUIRES XCODE VALIDATION  
**Audit date:** 2026-09-05  
**Owner:** A  
**Implementation recipient:** B

## Source authority

This final audit uses the following source priority:

1. `Screenshot 2026-09-05 042526.png` - latest corrected Home visual reference; it overrides older Home captures.
2. `final ui design.zip` - visual reference for all non-Home screens and states. Duplicate captures are counted once.
3. `FInal TwinTrack AI UI.zip` - final primary source for exact HTML/CSS values, assets, component structure, shared wording, appearance parity, and prototype behavior.
4. Current TwinTrack requirements - authority for model, data, HealthKit, Foundation Models, testing, and scope rules.

For Home appearance, the latest Home image wins. For non-Home measurements or content that is cropped or not separately captured, the active top-level HTML/CSS source wins. Historical duplicate files inside the archive's `uploads/` folders are not active implementation sources.

## 1. Final verdict

**UI STATUS: READY TO LOCK**

The approved visual system is consistent and requires no redesign. All previously identified UI-lock corrections are present and independently verified in the final archive.

## 2. A. MUST FIX BEFORE UI LOCK - NONE

Resolved and verified:

- `assets/twintrack-mark-light-2x.png` is now a genuine transparent 408 x 206 PNG. Independent pixel inspection found 77.058% fully transparent pixels, no visible pale-neutral/near-white plate pixels, and alpha 0 at all four corners. It displays only the emblem over white, `#F1F4F8`, and `#070B12`.
- The active Home and TwinTrack AI files contain no hard-coded `largest positive`, `strongest positive`, `negative weight`, or `driven mostly` feature-ranking claims. The replacement wording is predictive and non-causal.

## 3. Known-correction verification

| Correction | Source result | Classification |
| --- | --- | --- |
| A. HealthKit wording | Uses `Apple Health`, `Recent data available`, `No accessible recent value`, and `Included in access request`; old status claims are absent from active UI copy | **NO ACTION NEEDED** |
| B. Methodology | Uses the approved learned-coefficients/regularization wording | **NO ACTION NEEDED** |
| C. Main Profile model summary | Reads `Ridge · On-device` | **NO ACTION NEEDED** |
| D. Model Information wording | Shows Model, Frozen status, On-device execution, 7 inputs, and Ridge as numerical source | **NO ACTION NEEDED** |
| E. About wording | Uses the approved student-friendly paragraph exactly | **NO ACTION NEEDED** |
| F. Light-mode logo | Active 1x, 2x, and 3x emblem files are genuinely transparent and use no crop/blend workaround | **NO ACTION NEEDED** |
| G. AI opening copy | Uses the approved broad general-conversation and What-If wording | **NO ACTION NEEDED** |
| H. Contrast tokens | Corrected semantic values are byte-identical across Home, AI, and Profile; audited normal-text pairs meet 4.5:1 | **NO ACTION NEEDED** |
| I. Clear Prediction History | Renders using the destructive red role; native SwiftUI must add confirmation | **NO ACTION NEEDED for UI; IMPLEMENTATION REQUIRED** |
| J. Manual Inputs | Study Time and Screen Time use Hours/Minutes wheel structures and save total minutes; Previous Score remains numeric | **NO ACTION NEEDED for UI; IMPLEMENTATION REQUIRED** |
| K. Shared TabBar | One `TabBar.dc.html` is imported by Home, AI, and Profile; every state uses the same 23 x 23 path geometry | **NO ACTION NEEDED** |

Locked shared copy:

- Health Permissions: `TwinTrack requests read access to these Apple Health data types. Nothing is written back to Health.`
- Prediction Methodology: `Ridge Regression combines the seven model inputs using learned coefficients. Its regularization discourages overly large coefficients and helps reduce overfitting.`
- TwinTrack AI opening: `Ask me about your habits, studying, wellbeing, or general questions. I can also run TwinTrack What-If scenarios using your current data.`
- About: `The aim is to help students understand how their logged habits relate to predicted performance, while keeping predictions consistent and explainable.`
- Home Model Insight: `TwinTrack combines all seven inputs to produce the current prediction. Model relationships are predictive, not causal.`
- TwinTrack AI general explanation: `Your TwinTrack prediction is produced from all seven inputs by the on-device Ridge model. Ask me to change a value and I can run a deterministic What-If comparison. Model relationships are predictive, not causal.`
- TwinTrack AI What-If explanation structure: `Changing [variable] moved the Ridge result [delta] points [higher/lower]. This is a model prediction and does not prove that the change causes an academic outcome.`

## 4. B. IMPLEMENTATION ISSUE — FIX IN SWIFTUI

These do not require another visual redesign.

| Area | Required native behavior |
| --- | --- |
| Navigation | Use one root `TabView` with exactly Home, TwinTrack AI, and Profile. The HTML TabBar has no navigation handlers and must not be copied literally. |
| Profile navigation | Use `NavigationStack` for detail pages. Every visible chevron must open its destination. |
| Sheets | Use native `.sheet` for Edit Profile and Manual Inputs. Preserve Cancel/Save behavior and draft values until Save. |
| Existing no-op controls | Wire Open TwinTrack AI, Manage in Settings, View Stored Data, Clear Prediction History, and all tab items. |
| Destructive action | Clear Prediction History uses `role: .destructive`, asks for confirmation, clears only real local history, and displays the honest empty state. |
| Shared state | Home, Profile manual inputs, What-If baseline, HealthKit results, current prediction, and history must read from one shared `TwinData`/app state. |
| Missing inputs | All seven values are required. Never substitute zero. Identify missing inputs, hide/disable the current prediction, and disable What-If until a valid baseline exists. |
| Manual Inputs | Use native wheel-style pickers with separate Hours and Minutes columns for Study Time and Screen Time; no seconds. Store `study_minutes` and `screen_time_minutes` as total minutes and format only for display (`2h 45m`). Keep missing (`nil`) distinct from an explicitly entered zero. Previous Score remains a validated numeric 0-100 input. |
| Mock prediction code | Do not port `BASE`, `SPEC`, handwritten coefficients, or the HTML `simulate()` equation. Use only the frozen Swift Ridge engine. |
| Model insight | Use the locked non-ranking predictive wording. Do not derive feature-importance claims from the HTML mock coefficients. |
| Trends | The `SERIES` arrays are preview data. Store and show only real prediction snapshots; omit unavailable days and support empty/partial history. |
| Foundation Models | Support normal conversation, but route TwinTrack numerical requests through the deterministic tool. Provide unavailable, generating, failure, and retry states. Ridge remains usable without Foundation Models. |
| HealthKit | Query real HealthKit data. Show availability of recent values, not a claimed read-authorization result. Never fabricate or replace missing values with zero. |
| Touch targets | Preserve visual sizes but make Refresh, prompt chips, Edit Profile, Back, send, and 26 x 26 What-If controls at least 44 x 44 points in effective hit area. |
| Dynamic Type | Use semantic fonts, allow cards/rows to grow vertically, and avoid fixed text clipping. At accessibility sizes, permit the metric grid to adapt rather than truncate. |
| Safe areas | Do not copy the HTML's hard-coded 58/64-point status-bar offsets. Use SwiftUI safe areas, navigation bars, keyboard avoidance, and scroll content insets. |
| Appearance | Persist System/Light/Dark with `@AppStorage`. Apply one app-level appearance decision and automatically select the correct logo asset. |
| Accessibility | Add VoiceOver labels/values, button traits, chart summaries, and non-color state cues. Decorative source dots should be hidden from VoiceOver. |

## 5. D. NO ACTION NEEDED

- The three main screens use one coherent visual language.
- Dark and light token strings are byte-identical across Home, TwinTrack AI, and Profile.
- The shared TabBar uses a 23 x 23 icon frame, identical geometry in every state, and color/label weight only for selection.
- The Home hero, metric cards, trend card, AI result card, Profile groups, detail cards, and sheets use consistent spacing and radii.
- Cyan is reserved for prediction/product actions; violet is restrained and identifies Foundation Models explanations.
- Ridge and Apple Foundation Models are clearly separated visually.
- Non-causal language appears in the AI explanation, Methodology, and Disclaimer.
- There are no confidence percentages or claims of proven real-world academic accuracy.
- Privacy Policy, Terms of Use, and Prediction Disclaimer are visibly marked Draft.
- The approved About, main Profile summary, and Model Information corrections are present.
- The latest Home reference is visually consistent with the shared typography, card, color, spacing, logo-frame, and TabBar system.
- No gradients are used in the app UI.
- All approved layouts can be implemented with standard SwiftUI views.

## 6. Screenshot ZIP coverage

`final ui design.zip` contains 33 PNG files. Duplicate or equivalent captures were evaluated once. The unique UI coverage includes:

- Home light top/lower and dark top/lower; `Screenshot 2026-09-05 042526.png` is the authoritative latest Home reference.
- TwinTrack AI light/dark conversation, Ridge What-If results, AI explanations, and collapsed/expanded manual What-If controls.
- Profile light/dark upper and lower content.
- Edit Profile and Manual Inputs sheets.
- Health Permissions, Data & Privacy, Prediction Methodology, Model Information, About TwinTrack AI, Privacy Policy, and Prediction Disclaimer.

Equivalent Methodology, Model Information, and Privacy Policy captures are duplicates, not additional states. The export-dialog capture is not an app screen. The standalone logo capture is asset evidence, not a page.

The ZIP does not independently show every source-defined page/state, including Terms of Use, Appearance, the open Hours/Minutes wheel, all missing-data states, and Foundation Models unavailable/loading/error states. This is not a UI-lock blocker because the active HTML/source defines the shared pages and controls, and the unavailable/error states are native implementation requirements. Therefore, the screenshot ZIP is sufficient only when paired with the active source archive, as specified in the source priority.

## 7. Exact color system from source

The values below are the final corrected source tokens. CSS pixels are design coordinates; treat them as points only at the base content size.

| Semantic role / source token | Dark value | Light value | Use |
| --- | --- | --- | --- |
| Preview canvas `pageBg` | `#0A0E15` - rgb(10,14,21) | `#E7EBF1` - rgb(231,235,241) | Outside the simulated device only; not an app color |
| Primary background `bg` | `#070B12` - rgb(7,11,18) | `#F1F4F8` - rgb(241,244,248) | Screen background |
| Card background `card` | `rgba(255,255,255,.028)` | `#FFFFFF` - rgb(255,255,255) | Standard cards and grouped rows |
| Elevated surface `card2` | `rgba(255,255,255,.045)` | `#FFFFFF` - rgb(255,255,255) | Assistant bubble, input field, changed-value chips |
| Border/divider `bd` | `rgba(255,255,255,.055)` | `#DDE3EC` - rgb(221,227,236) | Standard 1-point borders/dividers |
| Strong border `bd2` | `rgba(255,255,255,.07)` | `#D3DAE6` - rgb(211,218,230) | Stronger borders, disabled/background controls |
| Hover `hover` | `rgba(255,255,255,.03)` | `#F5F7FA` - rgb(245,247,250) | Web prototype hover only |
| Primary text `tx` | `#F2F4F7` - rgb(242,244,247) | `#0F1B2D` - rgb(15,27,45) | Main text |
| Secondary text `tx2` | `rgba(226,235,250,.50)` | `#5A6B82` - rgb(90,107,130) | Supporting copy and inactive tabs |
| Tertiary text `tx3` | `rgba(226,235,250,.50)` | `#607087` - rgb(96,112,135) | Meaningful muted captions and chevrons; corrected for contrast |
| Decorative text `tx4` | `rgba(226,235,250,.30)` | `#93A1B5` - rgb(147,161,181) | Decorative/inactive marks only |
| Hero text `hero` | `#EAF6FD` - rgb(234,246,253) | `#0B2033` - rgb(11,32,51) | Score and simulated result |
| Cyan accent `acc` | `#5AC8F0` - rgb(90,200,240) | `#0E7FB8` - rgb(14,127,184) | Selected icons, links, chart bar |
| Cyan text `accTx` | `#9BD6F3` - rgb(155,214,243) | `#0B6E9E` - rgb(11,110,158) | Accent labels on pale/tinted surfaces |
| Selected-tab label `accLabel` | `#5AC8F0` - rgb(90,200,240) | `#0B6E9E` - rgb(11,110,158) | Selected TabBar label |
| Cyan surface `accBg` | `rgba(90,200,240,.06)` | `#E9F4FB` - rgb(233,244,251) | Prediction/result cards and chips |
| Cyan border `accBd` | `rgba(122,197,240,.20)` | `#C3DEEF` - rgb(195,222,239) | Accent-card borders |
| Strong cyan/blue `accStrong` | `#1976B8` - rgb(25,118,184) | `#0B6E9E` - rgb(11,110,158) | Primary CTA and active send/user surfaces; corrected for on-accent contrast |
| On-accent text `onAcc` | `#F4FBFF` - rgb(244,251,255) | `#FFFFFF` - rgb(255,255,255) | Filled-button text |
| Dim on-accent `onAccDim` | `rgba(244,251,255,.70)` | `rgba(255,255,255,.85)` | Filled-button chevron |
| Trend bars `bar` | `rgba(90,200,240,.26)` | `#BEDDF0` - rgb(190,221,240) | Historical bars |
| Violet accent `vio` | `#9A8FF0` - rgb(154,143,240) | `#5B4BC4` - rgb(91,75,196) | AI marker dot/icon |
| Violet text `vioTx` | `rgba(178,168,245,.85)` | `#5044B0` - rgb(80,68,176) | Foundation Models labels |
| Violet surface `vioBg` | `rgba(139,127,232,.06)` | `#F2F0FD` - rgb(242,240,253) | AI explanation cards |
| Violet border `vioBd` | `rgba(139,127,232,.16)` | `#DAD4F6` - rgb(218,212,246) | AI-card borders |
| Positive green `grn` | `#34C77B` - rgb(52,199,123) | `#187A46` - rgb(24,122,70) | Positive delta and recent Health-data availability |
| Positive surface `grnBg` | `rgba(52,199,123,.12)` | `#E4F5EB` - rgb(228,245,235) | Positive/status pills |
| Warning amber `amb` | `#E3A23C` - rgb(227,162,60) | `#9A6608` - rgb(154,102,8) | Warning marker and Draft badge |
| Warning text `ambTx` | `rgba(235,203,146,.90)` | `#7A5205` - rgb(122,82,5) | Warning copy |
| Warning surface `ambBg` | `rgba(227,162,60,.07)` | `#FCF3E4` - rgb(252,243,228) | Warning/Draft background |
| Warning border `ambBd` | `rgba(227,162,60,.20)` | `#EDD8AE` - rgb(237,216,174) | Warning/Draft border |
| On-warning text `onWarn` | `#0B2033` - rgb(11,32,51) | `#FFFFFF` - rgb(255,255,255) | Draft badge foreground |
| Error/destructive `red` | `#D9736E` - rgb(217,115,110) | `#B3423C` - rgb(179,66,60) | Negative deltas and destructive actions |
| Tab/nav background `navBg` | `rgba(7,11,18,.82)` | `rgba(241,244,248,.88)` | Tab bar and detail navigation background |
| User bubble `userBub` | `#1F4E72` - rgb(31,78,114) | `#0B6E9E` - rgb(11,110,158) | User chat bubble |
| User bubble text `userTx` | `#EAF6FD` - rgb(234,246,253) | `#FFFFFF` - rgb(255,255,255) | User message text |
| Sheet surface `sheet` | `#141A24` - rgb(20,26,36) | `#FFFFFF` - rgb(255,255,255) | Modal sheets |
| Modal scrim `scrim` | `rgba(0,0,0,.55)` | `rgba(15,27,45,.30)` | Background dimming behind sheets |
| Tab selected | Icon `acc`; label `accLabel` | Icon `acc`; label `accLabel` | Same icon geometry; color and label weight change only |
| Tab unselected | `tx2` | `tx2` | Inactive icon and label |
| Disabled background | **NOT EXPLICITLY DEFINED**; current send uses `bd2` | **NOT EXPLICITLY DEFINED**; current send uses `bd2` | Define a semantic disabled role in SwiftUI |
| Disabled foreground `disFg` | `rgba(226,235,250,.45)` | `#8794A6` - rgb(135,148,166) | Disabled send/control foreground; native controls also expose disabled state non-visually |

### Gradients

**None are defined in the application UI source.** Do not add gradients during implementation.

## 8. Typography

The source family is `-apple-system, SF Pro Text, system-ui, sans-serif`. Use native San Francisco through `Font.system`; do not bundle a font file.

| Role | Source value | Recommended SwiftUI implementation |
| --- | --- | --- |
| Profile large title | 28 px, weight 700, line-height 1.1, tracking -0.7 px | `.title.bold()`; allow Dynamic Type |
| Home/AI brand or screen title | 21 px, weight 600, line-height 1, tracking -0.4 px | `.title3.weight(.semibold)` |
| Home logo subtitle / screen subtitle | 11.5 px, regular | `.footnote` with `secondaryText` |
| Section heading | 10.5 px, weight 600, tracking 1.1 px, uppercase | `.caption2.weight(.semibold).tracking(1.1)` |
| Profile row/card title | 13.5 px, weight 500 or 600 | `.subheadline.weight(.medium/.semibold)` |
| Detail card title | 12.5 px, weight 600 | `.subheadline.weight(.semibold)` |
| Body/chat text | 13-13.5 px, line-height 1.45-1.55 | `.subheadline`; use `.lineSpacing()` only after device comparison |
| Secondary body | 11.5-12.5 px, regular | `.footnote` |
| Captions/source labels | 9-11 px, weight 500/600, tracking 0.3-0.6 px | `.caption2`; do not force below Dynamic Type's readable size |
| Button text | 13-15 px, weight 600 | `.subheadline.weight(.semibold)` |
| Main score | 62 px, weight 600, line-height 0.9, tracking -2.4 px | Deliberate custom display font: `.system(size: 62, weight: .semibold).monospacedDigit()` at base size; scale with `@ScaledMetric` |
| Metric values | 19 px, weight 600, line-height 1.25, tracking -0.5 px | `.title3.weight(.semibold).monospacedDigit()` |
| What-If current score | 24 px, weight 600, tracking -0.8 px | `.title2.weight(.semibold).monospacedDigit()` |
| What-If simulated score | 34 px, weight 600, line-height 0.95, tracking -1.2 px | `.largeTitle.weight(.semibold).monospacedDigit()` |
| Detail navigation title | 14.5 px, weight 600, tracking -0.2 px | Native `NavigationStack` toolbar principal `.headline` |
| Tab label | 10 px, line-height 12 px, weight 600 selected / 400 inactive | Native `Label` in `TabView`; `.caption2` if a custom label is required |

Literal CSS line heights should not be locked in SwiftUI. Prefer semantic fonts and natural wrapping. Keep fixed custom sizes only for the score/result display hierarchy.

## 9. Spacing and layout

### Source-based spacing scale

| Token | Points | Repeated source use |
| --- | ---: | --- |
| `micro` | 3 | Text stacks and compact Profile labels |
| `xxs` | 4 | Icon-to-label gap, compact stacks |
| `xs` | 6 | AI labels, card inner stacks |
| `sm` | 7 | Header/status/source gaps |
| `md` | 8 | Button/icon gaps and compact controls |
| `cardGap` | 9 | Metric grid, Profile feature cards, sheet fields |
| `control` | 12 | Row/icon gaps and standard vertical separation |
| `cardInset` | 14 | Common card/field inset |
| `screen` | 16 | Primary screen horizontal inset |
| `large` | 20 | Header and hero horizontal inset |
| `section` | 24 | Standard section separation |
| `sectionLarge` | 26 | Home/Profile major heading separation |

### Layout measurements

| Item | Exact source measurement | SwiftUI instruction |
| --- | --- | --- |
| Preview canvas | 402 x 874 | Reference size only; do not constrain the app to this device |
| Standard card horizontal margin | 16 | Use `screen` |
| Header horizontal padding | 20 | Keep the approved header alignment |
| Section-heading horizontal padding | 22 | Preserve unless native layout rounding requires 1 point adjustment |
| Home hero | Margin top 14, horizontal 16; padding 20 top/side, 18 bottom; gap 14 | Dedicated `PredictionHeroView` |
| Metric grid | Two equal columns; 9-point gap; horizontal 16 | Keep two columns at normal sizes; adapt for accessibility sizes |
| Metric card | 13 horizontal/top, 11 bottom; minimum height 78 | Allow vertical growth; no fixed maximum height |
| Previous Score row | Top margin 9; padding 13 vertical, 15 horizontal | Full-width card |
| Trend card | Top margin 24; padding 17 top, 18 horizontal, 15 bottom | Scrolls with Home |
| Insight card | Top margin 12; padding 16 vertical, 18 horizontal; 9-point stack gap | Scrolls with Home |
| Primary CTA | 50 high; horizontal container 16; bottom 22 | Use a native `Button` with a 50-point visual height |
| AI page title | 64 top, 20 horizontal, 12 bottom in HTML | Replace hard-coded top with safe-area-aware layout |
| AI prompt strip | 7 gap; 16 horizontal; 12 bottom | Horizontal `ScrollView`, no indicator |
| AI message list | 16 horizontal/bottom; 12 between messages | `ScrollViewReader` + `LazyVStack` |
| AI composer | 16 horizontal, 10 bottom; 9 gap | Keep above keyboard and tab bar |
| Profile title | HTML top 58 + 6; 20 horizontal | Use safe area; match visible baseline |
| Profile identity card | Top 18, horizontal 16; 16 padding; 14 gap | Allow name/grade to wrap before clipping |
| Profile section heading | 24-26 top, 22 horizontal, 9 bottom | Reuse `SectionHeader` |
| Detail content | 16 horizontal/top, 34 bottom; 11 block gap | `ScrollView` inside `NavigationStack` |
| Detail navigation | 52 top, 16 horizontal, 10 bottom, 18-point blur | Use native navigation bar/material |
| Sheet | Maximum 76% preview height; 10 top, 24 bottom; content 16 horizontal | Use native sheet detents and safe-area padding |
| Sheet grabber | 38 x 4 | Prefer native sheet grabber |
| TabBar | Source content is about 75 high; component hint is 80; 9 top and 26 bottom | Use one native `TabView`; let iOS own safe-area height |

Other exact local values in the source include 5, 10, 11, 13, 15, 18, and 22 points. Keep these inside the dedicated component where they occur instead of adding global tokens for one-off values.

## 10. Corner radii

| Element | Source radius |
| --- | ---: |
| Main prediction hero | 24 |
| Trend, insight, What-If result, Profile identity | 20 |
| Chat bubbles and Profile grouped/feature cards | 18 |
| Metric cards, Previous Score, primary CTA, AI explanation, detail cards/groups | 16 |
| What-If rows, Run Simulation, detail action button, sheet fields | 14 |
| Draft banner | 12 |
| Profile icon tiles | 9 |
| Changed-variable chip and What-If +/- visual buttons | 8 |
| AI composer and circular send button | 21 |
| Bottom sheet top corners | 26 |
| Pills, badges, circular avatar/source dots | 99 (use `.capsule` or `.circle`) |
| Trend bars | 5 |
| Draft badge | 5 |

## 11. Borders, shadows, and materials

- Standard cards: 1-point `bd` border.
- Accent cards: 1-point `accBd` border.
- AI cards: 1-point `vioBd` border.
- Warning/Draft cards: 1-point `ambBd` border.
- Dividers: 1 point in `bd`.
- App UI shadows: **none explicitly defined**.
- Tab bar and detail navigation: `navBg` plus 18 px backdrop blur in HTML. In SwiftUI, use a native material such as `.ultraThinMaterial` with the semantic tint rather than reproducing CSS blur.
- Sheets: use native sheet material, system scrim, corner handling, and grabber. The exact prototype scrim tokens are retained only as visual references.
- The 40/80 px device-frame shadow and simulated Dynamic Island in `ios-frame.jsx` are presentation scaffolding, not app UI. Do not implement them.
- Gradients: none.

## 12. Icon inventory

Use one icon geometry for selected and inactive tab states. Selection changes color and label weight only.

| Purpose | Prototype source | Closest SF Symbol | Source size/state | SwiftUI note |
| --- | --- | --- | --- | --- |
| Home tab | Custom filled SVG path | `house.fill` | 23 x 23; `acc` selected, `tx2` inactive | Use the same `house.fill` in both states |
| TwinTrack AI tab | Custom three-sparkle SVG | `sparkles` | 23 x 23; color-only state | Same symbol in both states |
| Profile tab | Custom filled circular-person SVG | `person.crop.circle.fill` | 23 x 23; color-only state | Same symbol in both states |
| Apple Health row | Custom filled heart SVG | `heart.fill` | 15 x 15 inside 30 x 30 tile | Green role; accessibility label `Apple Health` |
| Manual Inputs | Custom pencil SVG | `pencil` | 15 x 15 inside 30 x 30 tile | Secondary color |
| Ridge/model | Custom rising-line SVG | `chart.line.uptrend.xyaxis` | 15 x 15 in Profile; 12 x 12 in What-If | Cyan role |
| Foundation Models | Custom sparkle SVG | `sparkles` | 15 x 15 in Profile; 12 x 12 in chat label | Violet role |
| Privacy/on-device | Custom shield outline | `shield` | 13 x 13 | Cyan text role |
| Back | Custom left-chevron SVG | `chevron.left` | 17 x 17 | Use native navigation back behavior |
| Row chevron | Text glyph `›` | `chevron.right` | 15 | Decorative; hide from VoiceOver |
| Edit | Pencil SVG on Manual row; Edit Profile is text only | `pencil` | 15 where present | Do not add an icon to Edit Profile button |
| Refresh | Unicode `↻` | `arrow.clockwise` | 12.5 | Effective 44-point hit target |
| Send | Custom up-arrow SVG | `arrow.up` | 18 inside 42 circle | Use a 44-point button; disabled semantic state |
| What-If decrease/increase | Text `-` / `+` | `minus` / `plus` | 14 inside 26 x 26 visual tile | Expand hit target to 44 x 44 without enlarging tile |
| Appearance selected | Text checkmark | `checkmark` | 15 | Cyan, trailing |
| CTA chevron | Text `›` | `chevron.right` | 14 | Decorative inside button label |
| Sleep metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Steps metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Exercise metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Resting Heart Rate metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Study metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Screen Time metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Previous Score metric | No icon in approved design | N/A | Source dot only | Do not add an icon |
| Info | No visible icon in approved design | N/A | N/A | Do not add one |

The logo is a **CUSTOM ASSET**, not an SF Symbol.

## 13. Reusable SwiftUI component inventory

| Component | Appears in | Important specification and states |
| --- | --- | --- |
| `TwinTrackTabView` | Entire app | Exactly three tabs; single persistent native `TabView`; shared symbols and semantic selected/inactive colors |
| `SectionHeader` | Home and Profile | 10.5 source size, semibold, uppercase, 1.1 tracking; optional trailing caption |
| `SurfaceCardStyle` | All screens | Reusable background/border/radius modifier; variants standard, cyan, violet, warning |
| `PredictionHeroView` | Home | Radius 24, 20/20/18 padding, score/delta/progress/method line; ready and unavailable states |
| `MetricCardView` | Home | Two-column grid, radius 16, minimum 78 at base size, source label, value/missing state, selected trend state |
| `SourceLabel` | Home metrics | 5-point source dot + 9.5 source label; Health vs Manual; hidden decorative dot for VoiceOver |
| `TrendCardView` | Home | Seven date slots based only on real history; selected metric, partial/empty state, accessible summary |
| `InsightCardView` | Home | Violet surface; verified model wording only; predictive/non-causal sentence |
| `PromptChip` | TwinTrack AI | Capsule, cyan surface/border, horizontal scrolling, 44-point hit target |
| `AIMessageBubble` | TwinTrack AI | User and assistant variants; 18 radius with one 6-point lower corner; Dynamic Type wrapping |
| `WhatIfResultCard` | TwinTrack AI | Radius 20; current/simulated/delta; changed-variable chips; optional range warning; numbers supplied by Ridge only |
| `WhatIfStepperRow` | TwinTrack AI | Radius 14; label/value/+/-; valid range warning; 44-point hit targets |
| `PrimaryActionButton` | Home and detail actions | 50-point Home CTA / 46-point detail visual height; semantic filled or tinted variant; enabled/disabled/loading states |
| `ProfileRow` | Profile groups and Data & Privacy actions | Full-row button, optional 30-point icon tile, title/detail/value/chevron, normal/destructive state |
| `DetailCard` | Methodology, About, legal pages, Data & Privacy | Radius 16; 14 x 15 padding; title/body stack; semantic text |
| `DraftBanner` | Privacy Policy, Terms, Disclaimer | Radius 12; amber surface/border; DRAFT capsule and message |
| `ProfileFormSheet` | Edit Profile and Manual Inputs | Native sheet; draft state, Cancel/Save, fields, keyboard handling, validation |
| `AppearanceSelector` | Appearance | System/Light/Dark rows; one checkmark; `@AppStorage` binding |

Avoid a separate component for every one-off text block. `DetailCard`, `ProfileRow`, and shared styles cover the repeated Profile structures.

## 14. Screen-by-screen implementation notes

Dark and light appearances must be two palettes applied to the same SwiftUI view hierarchy, not duplicate screen files.

| Screen/state | Short implementation note |
| --- | --- |
| App root | One `TabView`; inject one shared `TwinData`; apply System/Light/Dark at app level; exactly three tabs |
| Home | `NavigationStack` is optional at root; vertical `ScrollView`; safe-area header; real seven inputs; prediction unavailable if any input is missing; persistent TabView below content |
| Home lower content | Trend, insight, and CTA remain in the same Home scroll view; use stored real history only; CTA selects AI tab |
| TwinTrack AI | Fixed header/prompt strip/composer around a scrollable message list; `ScrollViewReader`; keyboard-safe composer; Ridge numbers and AI language kept separate |
| TwinTrack AI manual What-If | Collapsible section; all seven controls and Run button reachable; validate ranges; disable without a complete baseline; same Ridge engine as Home |
| Foundation Models unavailable | Reuse the AI content area for a clear unavailable explanation and retry/status action; keep deterministic Ridge/What-If usable where the baseline exists |
| Profile | `NavigationStack` within the Profile tab; vertical `ScrollView`; use shared grouped rows; no account/cloud additions |
| Edit Profile sheet | Native `.sheet`; maintain draft name/grade; Cancel discards; Save commits; keyboard-safe and validated |
| Manual Inputs sheet | Native `.sheet`; Study Time and Screen Time use separate Hours/Minutes wheel columns with no seconds; save total minutes and display `xh ym`; Previous Score remains numeric 0-100; Save updates shared state and prediction |
| Health Permissions | Pushed detail page; neutral request/data-availability language; Manage in Settings behavior must be tested on device |
| Data & Privacy | Pushed detail page; existing actions only; View Stored Data presents real local data/empty state; Clear History is destructive and confirmed |
| Prediction Methodology | Pushed, scrollable detail; use corrected Ridge sentence; retain deterministic and predictive-not-causal content |
| Model Information | Pushed detail; show Model, Status, Execution, Inputs, Numerical source, then approved paragraph |
| About TwinTrack AI | Pushed detail; retain approved simplified wording; do not add technical coefficient language |
| Privacy Policy | Pushed, scrollable detail; visible Draft banner; keep prototype wording until formally replaced |
| Terms of Use | Pushed, scrollable detail; visible Draft banner; source contains the complete page even though PDF capture is clipped |
| Prediction Disclaimer | Pushed, scrollable detail; visible Draft banner; preserve educational/non-causal/no-guarantee language |
| Appearance | Pushed detail; System/Light/Dark selector; persist selection and update all three tabs immediately |

## 15. SwiftUI semantic token mapping

Use named color assets with default/light and Dark variants. The source already contains the final contrast-corrected values.

```swift
import SwiftUI

enum TwinTrackColors {
    static let background = Color("TTBackground")          // CSS --bg
    static let card = Color("TTCard")                      // CSS --card
    static let elevatedCard = Color("TTElevatedCard")     // CSS --card2
    static let border = Color("TTBorder")                  // CSS --bd
    static let strongBorder = Color("TTStrongBorder")      // CSS --bd2

    static let primaryText = Color("TTPrimaryText")        // CSS --tx
    static let secondaryText = Color("TTSecondaryText")    // CSS --tx2
    static let tertiaryText = Color("TTTertiaryText")      // corrected CSS --tx3
    static let decorativeText = Color("TTDecorativeText")  // CSS --tx4
    static let heroText = Color("TTHeroText")              // CSS --hero

    static let accent = Color("TTAccent")                  // CSS --acc
    static let accentText = Color("TTAccentText")          // CSS --accTx
    static let selectedTabText = Color("TTSelectedTabText")// CSS --accLabel
    static let accentSurface = Color("TTAccentSurface")    // CSS --accBg
    static let accentBorder = Color("TTAccentBorder")      // CSS --accBd
    static let accentStrong = Color("TTAccentStrong")      // corrected CSS --accStrong
    static let onAccent = Color("TTOnAccent")              // CSS --onAcc

    static let aiAccent = Color("TTAIAccent")              // CSS --vio
    static let aiText = Color("TTAIText")                  // CSS --vioTx
    static let aiSurface = Color("TTAISurface")            // CSS --vioBg
    static let aiBorder = Color("TTAIBorder")              // CSS --vioBd

    static let positive = Color("TTPositive")              // corrected CSS --grn
    static let positiveSurface = Color("TTPositiveSurface")
    static let warning = Color("TTWarning")
    static let warningText = Color("TTWarningText")
    static let warningSurface = Color("TTWarningSurface")
    static let warningBorder = Color("TTWarningBorder")
    static let onWarning = Color("TTOnWarning")
    static let destructive = Color("TTDestructive")

    static let tabBarBackground = Color("TTTabBarBackground")
    static let disabledBackground = Color("TTDisabledBackground")
    static let disabledForeground = Color("TTDisabledForeground")
}

enum TwinTrackSpacing {
    static let micro: CGFloat = 3
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 7
    static let md: CGFloat = 8
    static let cardGap: CGFloat = 9
    static let control: CGFloat = 12
    static let cardInset: CGFloat = 14
    static let screen: CGFloat = 16
    static let large: CGFloat = 20
    static let section: CGFloat = 24
    static let sectionLarge: CGFloat = 26
}

enum TwinTrackRadius {
    static let chip: CGFloat = 8
    static let iconTile: CGFloat = 9
    static let banner: CGFloat = 12
    static let control: CGFloat = 14
    static let card: CGFloat = 16
    static let group: CGFloat = 18
    static let feature: CGFloat = 20
    static let hero: CGFloat = 24
    static let sheet: CGFloat = 26
}

enum TwinTrackTypography {
    static let screenTitle = Font.title3.weight(.semibold)
    static let profileTitle = Font.title.bold()
    static let section = Font.caption2.weight(.semibold)
    static let cardTitle = Font.subheadline.weight(.semibold)
    static let body = Font.subheadline
    static let secondary = Font.footnote
    static let caption = Font.caption2
    static let button = Font.subheadline.weight(.semibold)
    static let score = Font.system(size: 62, weight: .semibold).monospacedDigit()
    static let result = Font.largeTitle.weight(.semibold).monospacedDigit()
}
```

Use `@ScaledMetric` for deliberate custom sizes such as the 62-point hero score and enforce layout tests at larger content sizes. Do not create separate `DarkHomeView` and `LightHomeView` implementations.

## 16. Asset inventory

| File | Dimensions/type | Current purpose | Handoff decision |
| --- | --- | --- | --- |
| `assets/twintrack-mark-sm.png` | 204 x 103, PNG with alpha | Dark-mode header emblem | Approved dark header asset; import to asset catalog |
| `assets/twintrack-mark.png` | 716 x 360, PNG with alpha | Larger dark emblem source | Retain as higher-resolution source; verify which scale produces the cleanest asset catalog result |
| `assets/twintrack-mark-sm-light.png` | 204 x 103, PNG with genuine alpha | Active light-mode header emblem | Approved clean 1x light asset; current Home header uses this file |
| `assets/twintrack-mark-light-2x.png` | 408 x 206, PNG with genuine alpha | 2x light header emblem | Approved clean 2x light asset; independently verified over light and dark surfaces |
| `assets/twintrack-mark-light-3x.png` | 612 x 309, PNG with genuine alpha | 3x light header emblem | Approved clean 3x light asset; its trimmed geometry scales exactly with the clean 1x file |
| `assets/twintrack-logo-full.png` | 1024 x 1024, PNG with alpha | Full dark logo/lockup source | Not used by the Home header; retain for branding only |
| `uploads/TwinTrack AI home screen/assets/twintrack-logo-light.png` and `-87027b92.png` | 1254 x 1254, opaque PNG | Historical interim light files | Legacy only; do not import into Xcode |
| `uploads/twintrack white logo.png` and nested copies | 1254 x 1254, opaque PNG | Historical source with baked background | Legacy only; do not import into Xcode |
| Inline SVG paths | HTML source | Tab and small functional icons | Replace with the shared SF Symbols listed above, unless exact custom-path fidelity is required |

### Logo implementation contract

- Asset catalog image set: `TwinTrackHeaderMark`.
- Xcode Any/default slot: the final transparent light emblem at clean 1x/2x/3x scales.
- Xcode Dark appearance slot: the approved dark emblem at corresponding scales.
- Render frame: 68 x 34 points.
- Content mode: `.fit`.
- Preserve aspect ratio and placement.
- No blend mode, CSS-style crop, filter, background box, border, shadow, or glow.
- Mark the image decorative if the adjacent `TwinTrack AI` text supplies the accessible name.

## 17. Data and model implementation boundary

The HTML is a design prototype, not an implementation source for numerical behavior.

Do not port:

- `BASE = 84.6`
- the HTML `SPEC` coefficients or observed ranges
- the HTML `simulate()` calculation
- hard-coded mock explanations about feature weights
- Home `SERIES` history arrays
- mock names, timestamps, Health status, scores, or previous score

The frozen model remains authoritative. Preserve this exact feature order using Swift `Double`:

1. `sleep_hours`
2. `steps`
3. `exercise_minutes`
4. `resting_heart_rate`
5. `study_minutes`
6. `screen_time_minutes`
7. `previous_score`

Every prediction and What-If result follows the frozen Swift Ridge engine and must pass all 21 golden profiles before verification. Apple Foundation Models may interpret requests and explain results, but it must never calculate or invent scores, deltas, coefficients, HealthKit values, or history.

## 18. What B needs before Sunday implementation

- This `TwinTrack_UI_Handoff.md`.
- Latest Home image, `final ui design.zip`, and the active top-level source files in `FInal TwinTrack AI UI.zip`.
- Approved dark header emblem and the verified transparent light 1x/2x/3x asset set.
- Private GitHub repository access and a successful pull/clone.
- Native SwiftUI Xcode project and working physical-device signing.
- `TwinTrackModel.swift`, `twintrack_model_params.json`, `golden_profiles.json`, 21 golden test profiles, and `AUDIT.md`.
- Do not use `feature_coefficients.csv`; it is not stored in model feature order.
- Evidence log template and understanding of: build/test -> inspect -> commit -> push -> evidence.

For UI reproduction, MEDIUM reasoning is sufficient. Switch to MAX before the Ridge port, 21/21 parity, and final Ridge review.

## 19. C. OPTIONAL POST-CORE ENHANCEMENT

These are not UI-lock blockers and must not delay the graduation-critical implementation order:

- Subject/recent-grades entry: allow multiple 0-100 grades, calculate one equal-weight average, and pass that single result into the existing `previous_score`. It is not an eighth Ridge input and must not retrain or alter the model.
- Profile picture selection: use the native iOS photo picker and local app storage. Do not add login, accounts, Firebase, cloud storage, or Profile redesign for this feature.

## 20. UI lock decision

The UI is ready to lock. Begin native SwiftUI implementation from the locked references without redesigning the approved screens. All generated/native code remains unverified until it is compiled and tested in Xcode.

---

**EXTERNAL AI DRAFT - REQUIRES XCODE VALIDATION**
