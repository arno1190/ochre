# 08 — Design system: "Primaries on paper"

## Inspiration, and what we take from it

In 2024 Pigment, the business-planning company, rebranded with the agency Fiasco. Its identity rests on three ideas:
- **Three primaries** (red, yellow, blue) drawn as painterly brush strokes that form a cycle, a nod to colour theory and to the craft of painting.
- An **extended palette** in which each core use case gets its own colour, and **gradients** for "bright, varied compositions".
- A **geometric sans** for everything, plus a **serif accent** for section headers and quotes (DM Sans + Crimson Pro).

Ochre takes the *method*, not the assets. It uses its own three primaries on a warm paper ground, one pigment per Stage kind, painterly washes for the few expressive surfaces, and its own type pairing. No Pigment colour value, font, logo or illustration is reused.

The concept: **a recruiter's desk**. The background is warm paper and the text is near-black ink. Three primaries mark the things that matter (action, attention, celebration), and a band of secondary pigments colours the Pipeline. The interface itself stays quiet: colour is spent on the candidate's journey, not on chrome.

## 1. Colour

### 1.1 Base (neutrals)

| Token | Light | Dark | Use |
|---|---|---|---|
| `paper` | `#F6F1E8` | `#14131F` | app background |
| `surface` | `#FFFDF8` | `#1D1C2B` | cards, dialogs, board columns |
| `surface-sunk` | `#EFE8DB` | `#100F19` | input fields, column bodies, code |
| `line` | `#E2D9C8` | `#2E2C40` | borders, dividers |
| `line-strong` | `#CFC3AE` | `#45425C` | input borders, focus off |
| `ink` | `#1C1B2E` | `#F1EBDF` | primary text, primary button fill (light) |
| `ink-muted` | `#655F72` | `#A9A2B4` | secondary text, meta |
| `ink-faint` | `#958E9E` | `#6F6980` | placeholders, disabled (never for essential text) |

Measured contrast: `ink` on `paper` is 14.99:1 and `ink-muted` on `paper` is 5.44:1. In dark mode, `ink` on `paper` is 15.48:1 and `ink-muted` is 7.45:1.

### 1.2 The three primaries (brand)

| Token | Light | Dark | Role | Text rule |
|---|---|---|---|---|
| `ultramarine` | `#2D47D0` | `#8C9DFF` | **Action**: links, focus ring, selected state, primary buttons in dark mode, the ⌘K highlight | White on it is 7.18:1; it reads as text on paper at 6.38:1 |
| `vermilion` | `#E0482C` | `#FF8A6E` | **Attention**: the brand mark, the Needs Triage dot, the "new" badge, the urgent days-in-stage chip | **Fill and graphics only.** It is 3.64:1 on paper, so never use it for text below 18 px bold. Ink on it is 4.12:1 (large text only) |
| `cadmium` | `#F2B42C` | `#FFCB5C` | **Celebration and warmth**: the hire moment, star ratings, the Notes callout border | Fill only. Ink on it is 9.10:1 |

### 1.3 Pipeline pigments (one per Stage kind, plus extras)

Like Pigment's colour per use case, each Stage kind owns a pigment. The board, timeline, funnel and dashboard all use the same mapping, so colour *means* the step.

| Token | Light | Dark (text/dot) | Default for | Contrast on paper (light) |
|---|---|---|---|---|
| `slate` | `#5C6477` | `#A3ABBE` | `applied` | 5.27 |
| `cobalt` | `#137C8F` | `#5CC3D6` | `screening` | 4.33 |
| `violet` | `#6A4CD6` | `#AE9BFF` | `interview` | 5.16 |
| `madder` | `#C93F72` | `#FF8DB5` | `interview` (2nd), `custom` | 4.21 |
| `ochre` | `#B57A12` | `#E8B04D` | `offer` | 3.24 (dot and fill only; use `ochre-ink` `#7E540B` for text) |
| `viridian` | `#1D8257` | `#5CCB97` | Outcome `hired` | 4.26 |
| `carmine` | `#B42342` | `#FF7A93` | Outcome `rejected` | 5.73 |
| `umber` | `#7A5236` | `#C79B7B` | Outcome `withdrawn`, archived | 6.05 |

Rules:
- Pigments render as a **dot**, a **2 px left rule** on a column header, or a **tint**: the pigment at 10% alpha on `surface`, with text in the pigment's *ink* variant at 70% mix with `ink`. They never fill large areas behind body text.
- Text in a pigment colour is allowed only at ≥ 14 px with weight ≥ 500, and only where the measured contrast is ≥ 4.5:1. `ochre` and `vermilion` are never text.
- The **tag palette** is the 8 pipeline pigments plus the 3 primaries, plus `ink-muted` (12 options, matching the 12-colour tag picker).

### 1.4 Semantic aliases

| Alias | Maps to |
|---|---|
| `accent` | `ultramarine` |
| `focus` | `ultramarine` (2 px ring, 2 px offset `paper`) |
| `success` | `viridian` |
| `warning` | `ochre` (fills) / `ochre-ink` (text) |
| `danger` | `carmine`. Destructive buttons are a `carmine` fill with white text (6.44:1) |
| `info` | `cobalt` |
| `ai` | `violet`. The only colour used to mark AI-derived content ("Read from CV", First Read), always with the ✦ glyph |

### 1.5 Washes (gradients)

Washes are used **only** on:
- the careers hero;
- the login and setup screens;
- empty states;
- the hire celebration.
Each is a soft two-stop radial or linear blend, with an SVG turbulence grain at 4% opacity so it reads as paint, not a CSS gradient.

| Wash | Stops | Where |
|---|---|---|
| `wash-dawn` | `vermilion` → `cadmium` (radial from the bottom-left, 40% → 0%) over `paper` | login, careers hero (default) |
| `wash-deep` | `ultramarine` → `violet` | setup wizard, dark-mode careers hero |
| `wash-meadow` | `cadmium` → `viridian` | the hire celebration, the "Nothing to triage" empty state |

The **brush mark**: the logo is three overlapping brush strokes in the three primaries, forming an open loop. It is drawn as three SVG paths with rough, tapered ends. The same stroke shape, at 8% opacity, underlines page titles (a single `ink` stroke under the H1 on the careers pages, never in the app).

### 1.6 Careers-site theming
The careers site reads `settings.careers.theme`:
```yaml
accent: ultramarine | "#RRGGBB"     # buttons/links; contrast-checked on save (≥ 4.5:1 vs white and paper), else rejected
wash: dawn | deep | meadow | none | image
hero_image_file_id: null
logo_file_id: …                     # SVG or PNG
font_pairing: default | system      # system = no web fonts (privacy-strict orgs)
corner_style: soft | square         # v0's careers site was square to match the company site
```
The app UI is **not** themeable in v1: one design keeps the code lean. Only the logo in the sidebar changes.

## 2. Type

| Role | Family | Weights | Notes |
|---|---|---|---|
| UI and body | **Instrument Sans** (Google Fonts, OFL) | 400, 500, 600 | Its grotesque, slightly condensed width packs more onto a board. `font-feature-settings: "ss01"`, tabular numbers on counts |
| Display and accent | **Instrument Serif** (Google Fonts, OFL), regular and italic | 400 | Page titles on the careers site, H1 on empty states, the quote style for rationale and evidence, and the "Read from CV" summaries in italic. **Never** used for UI controls or tables |
| Mono | **JetBrains Mono** (OFL) | 400 | Template editor, ids, PAT prefixes |

The fonts are self-hosted (`@fontsource`), with no Google Fonts call at runtime. The `system` pairing falls back to `ui-sans-serif` and `ui-serif`.

Scale (rem, 16 px root):
- App: `12 / 13 / 14 (body) / 16 / 20 / 24`.
- Careers: `16 (body) / 18 / 24 / 36 / 56 / 72 (hero, serif)`.
- Line heights: 1.5 body, 1.2 headings.
- App headings use Instrument Sans 600, with tracking −0.01em at 20 px and above.

## 3. Shape, space, elevation
- **Radius**: `sm` 6 px (inputs, chips), `md` 10 px (cards, buttons), `lg` 16 px (dialogs, sheets). Pills use `full`.
- **Spacing**: a 4 px base, using only 4, 8, 12, 16, 24, 32 and 48.
- **Page grid**: content max width 1280 px; the board is full width.
- **Gutters**: 24 px desktop, 16 px mobile.
- **Elevation**: flat by default, with borders doing the work.
  - `shadow-1` (`0 1px 2px rgb(28 27 46 / 6%)`) for a card being dragged or a popover.
  - `shadow-2` for dialogs.
  - Dark mode uses lighter `surface` steps instead of shadows.
- **Density**: board cards are 72 px tall at minimum. A **compact** toggle saves 25% vertical space and is stored per user.

## 4. Components (shadcn/ui on Radix, restyled with these tokens)

| Component | Spec |
|---|---|
| **Button** | `primary` = `ink` fill with `paper` text in light mode (14.99:1), `ultramarine` fill with `paper` text in dark mode (7.34:1); `secondary` = `surface` + `line-strong` border; `ghost`; `danger` = `carmine`. Heights 32 and 36. The label is always a verb ("Reject 4 candidates", not "Confirm") |
| **Stage pill** | a dot plus the name. The `tint` background appears only when selected |
| **Days-in-stage chip** | `<7d`: `ink-muted` text, no fill. `7–13d`: `ochre` dot and `ochre-ink` text. `≥14d`: `vermilion` dot, `carmine` text and a 1 px `carmine` 30% card border |
| **Rating** | 5 stars, `cadmium` fill and `line-strong` outline. Keyboard: ←/→ and 1–5 |
| **Notes callout** | `surface`, a 3 px `cadmium` left rule, the author and time, and the first 3 lines of the latest Note |
| **AI block** | a 1 px `violet` 30% border, the ✦ label "Read from CV" or "First read", and the content in Instrument Serif italic. Every quoted piece of evidence is shown with a "found in CV" tick |
| **Verdict chip** | `standout` = `cadmium` fill with ink text "★ Standout"; `worth_a_look` = `cobalt` tint; `pass` = `umber` tint. Shown only to Rc |
| **Toast** | bottom-left, maximum 3, 5 s, pausable on hover, with an *Undo* when the action allows it (move, tag, library remove) |
| **Empty state** | a wash blob, an Instrument Serif headline, one sentence, one action |
| **Dialog** | `lg` radius. A destructive dialog lists exactly what will happen and offers the safer alternative ("To turn them down, reject instead.") |
| **Command palette (⌘K)** | `cmdk`, 640 px wide, results grouped (Candidates, Positions, Go to), with an `ultramarine` left rule on the active row |

## 5. Motion
- Durations: 120 ms for micro interactions (hover, press), 200 ms for overlays, 280 ms for layout moves. Easing `cubic-bezier(.2,.8,.2,1)`.
- **Drag**: the lifted card tilts 1.5° and gains `shadow-1`. On drop it settles with a 200 ms spring.
- **Hire celebration**: a single brush-stroke swipe across the card in `wash-meadow`, 600 ms. There is no confetti.
- `prefers-reduced-motion`: all transforms are removed, opacity fades are kept, and the careers hero video is replaced by its poster.

## 6. Iconography and illustration
- **Icons**: Lucide, 1.5 px stroke, 16 px in UI and 20 px in navigation.
- **Illustrations**: none, apart from the brush mark and the washes. Empty states use colour, not drawings.

## 7. Tailwind v4 tokens (reference implementation)

```css
@import "tailwindcss";
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

@theme {
  --font-sans: "Instrument Sans", ui-sans-serif, system-ui, sans-serif;
  --font-serif: "Instrument Serif", ui-serif, Georgia, serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --color-paper: #F6F1E8;  --color-surface: #FFFDF8;  --color-surface-sunk: #EFE8DB;
  --color-line: #E2D9C8;   --color-line-strong: #CFC3AE;
  --color-ink: #1C1B2E;    --color-ink-muted: #655F72; --color-ink-faint: #958E9E;

  --color-ultramarine: #2D47D0; --color-vermilion: #E0482C; --color-cadmium: #F2B42C;

  --color-slate: #5C6477; --color-cobalt: #137C8F; --color-violet: #6A4CD6; --color-madder: #C93F72;
  --color-ochre: #B57A12; --color-ochre-ink: #7E540B; --color-viridian: #1D8257;
  --color-carmine: #B42342; --color-umber: #7A5236;

  --radius-sm: 6px; --radius-md: 10px; --radius-lg: 16px;
  --ease-paint: cubic-bezier(.2,.8,.2,1);
}

[data-theme=dark] {
  --color-paper: #14131F;  --color-surface: #1D1C2B;  --color-surface-sunk: #100F19;
  --color-line: #2E2C40;   --color-line-strong: #45425C;
  --color-ink: #F1EBDF;    --color-ink-muted: #A9A2B4; --color-ink-faint: #6F6980;
  --color-ultramarine: #8C9DFF; --color-vermilion: #FF8A6E; --color-cadmium: #FFCB5C;
  --color-slate: #A3ABBE; --color-cobalt: #5CC3D6; --color-violet: #AE9BFF; --color-madder: #FF8DB5;
  --color-ochre: #E8B04D; --color-ochre-ink: #E8B04D; --color-viridian: #5CCB97;
  --color-carmine: #FF7A93; --color-umber: #C79B7B;
}
```
- The theme follows the system by default, with a manual override (`light`, `dark`, `system`) stored per user. The pre-paint script sets `data-theme` before first render, so there is no flash.
- **Every component is reviewed in both themes** (09 §Testing: visual snapshots in light and dark).
- v0's light-only `bg-*-50` classes are banned by a lint rule that forbids raw Tailwind palette colours (`bg-red-50`, `text-slate-700`, …) in components.

## 8. Voice and copy
- Plain, warm and short. Address the user as "you". Sentence case everywhere.
- Name the outcome on buttons: "Send 4 invitations", "Move to Screening".
- Say what happened and what to do next: "Not sent: Ada has no screener. Assign one".
- Never blame the candidate in copy shown to them. Rejection copy is kind and final.
- No "AI-powered" marketing in the product. AI content is labelled with what it is: "Read from CV", "First read".
