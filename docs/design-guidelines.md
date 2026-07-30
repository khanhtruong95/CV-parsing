# DentaMatch — Design Guidelines (Candidate Onboarding)

PRD mandate: **keep the interface simple, do not overbuild.** Clean, trustworthy healthcare/professional feel. Desktop-first, fully usable on mobile. 2026 form UX basics applied: single-column flow, one topic per section, inline validation, visible progress (2 steps), progressive disclosure for conditional fields.

## Brand
- Wordmark: text "DentaMatch" in Bricolage Grotesque 700 + minimal teal tooth glyph (inline SVG). No logo images.
- Voice: calm, reassuring, plain language. Dutch market — copy in English for wireframes, NL-ready.

## Typography (Google Fonts)
- **Headings: Bricolage Grotesque** — weights 600, 700. Distinctive warm grotesque; professional without being generic.
- **Body / UI / forms: Public Sans** — weights 400, 500, 600. Built for gov/form accessibility; excellent at small sizes.
- Both support Latin Extended (Dutch diacritics) + Vietnamese subset.
- Scale: h1 28/34 (mobile 24), h2 20/28 (section titles), body 15/24 (1.6), label 13/18 (600), hint & badge 12/16.
- Load: `https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@600;700&family=Public+Sans:wght@400;500;600&display=swap`

## Color Tokens (hex, WCAG AA on white unless noted)
| Token | Hex | Use / contrast |
|---|---|---|
| `--primary` | `#0F766E` | Buttons, links, focus, active step (5.9:1) |
| `--primary-hover` | `#0C5F58` | Hover state |
| `--primary-soft` | `#E7F4F2` | "Extracted from CV" badge bg, selected chip bg |
| `--accent` | `#E2725B` | Warm coral. **Decorative only** (wordmark glyph, ≥24px graphics) — never small text |
| `--success` | `#15803D` | Success text/icons (4.9:1); bg `#EAF6EE` |
| `--warning` | `#92400E` | "Please check" text (8.4:1); bg `#FEF3DC`, border `#F0D9A6` |
| `--danger` | `#B42318` | "Missing" text, errors (6.6:1); bg `#FDECEA`, border `#F2B8B0` |
| `--bg` | `#F5F8F7` | Page background (teal-tinted) |
| `--surface` | `#FFFFFF` | Cards, inputs |
| `--border` | `#DCE5E3` | Card/divider borders |
| `--border-input` | `#B9C9C6` | Input borders (3.1:1 vs surface — AA non-text) |
| `--text` | `#1C2B29` | Primary text (14.5:1) |
| `--text-secondary` | `#52625E` | Secondary text, filled labels (6.5:1) |
| `--text-hint` | `#6B7B77` | Hints/placeholders (4.6:1) |

## Spacing & Shape
- Base 4px scale: **4, 8, 12, 16, 24, 32, 48, 64**. Card padding 24 (mobile 16); gap between fields 16; between sections 24.
- Radius: inputs/buttons 8px, cards 12px, chips/badges 999px. Shadow: cards `0 1px 2px rgba(28,43,41,.06)` max — borders do the work.
- Content max-width: 720px single column (forms), centered.

## Components
- **Buttons** — h 44px (touch min), radius 8, weight 600, 15px. Primary: `--primary` bg / white. Secondary: white bg, `--border-input` border, `--text`. Tertiary/link: `--primary` text, underline on hover. Disabled: 45% opacity, no pointer.
- **Inputs / selects / textarea** — h 44px (textarea auto), white bg, 1px `--border-input`, radius 8, padding 12x14, 15px text. Label above (13px/600) + optional hint below (12px `--text-hint`). Select uses chevron SVG.
- **Checkbox chips** (multi-select: regions, transport, skills, working days) — pill, 1px `--border-input`, padding 8x14, min-h 36px. Selected: `--primary-soft` bg, `--primary` border+text, leading ✓. Real `<input type="checkbox">` visually hidden for a11y.
- **Provenance badges** — pill, 12px/600, padding 2x8, icon 12px:
  - *Extracted from CV*: `--primary-soft` bg, `#0E6B63` text — subtle, no border.
  - *Please check*: `#FEF3DC` bg, `--warning` text, `#F0D9A6` border, ⚠ icon. Field also gets amber border.
  - *Missing*: `#FDECEA` bg, `--danger` text, `#F2B8B0` border. Field gets `--danger` border.
- **Section cards** — white, `--border`, radius 12; header: numbered circle (28px, `--primary-soft` bg, `--primary` text) + h2 + optional badge count.
- **Repeaters** (education, experience) — inner bordered sub-cards; "Remove" tertiary-danger text button top-right; "+ Add education/experience" dashed full-width button.
- **Upload dropzone** — 2px dashed `--border-input`, radius 12, `--surface` bg, centered icon+copy, padding 40. Hover/dragover: `--primary` border + `--primary-soft` bg. Shows accepted types + max size (PDF/DOC/DOCX · 25MB).
- **Progress indicator** — 2 steps, numbered circles + labels, connector line. Active: `--primary` filled; upcoming: white + border; done: ✓.

## States
- **Focus (all interactive)**: `outline: 2px solid #0F766E; outline-offset: 2px` — always visible, never removed.
- **Error**: 1px→2px `--danger` border + 13px `--danger` message below field with icon. Inline validation on blur.
- **Processing (CV analyze)**: spinner (2px ring, `--primary`, 0.8s spin, respects `prefers-reduced-motion`), reassuring copy + time expectation ("usually under 30 seconds").
- **Parse failed**: danger banner (icon, title, plain-language explanation), retry secondary button + "Continue manually" primary — never a dead end.

## Accessibility (WCAG 2.1 AA)
- All text tokens ≥4.5:1; UI borders/icons ≥3:1. Touch targets ≥44×44. Labels always visible (no placeholder-as-label).
- `aria-describedby` links hints/errors/badges to inputs; badge meaning conveyed in text, not color alone.
- Logical heading order (h1 page, h2 sections). `prefers-reduced-motion`: disable spinner/transition animations.
- Responsive: single column ≤640px; two-column field rows only ≥768px where pairs are related (first/last name).
