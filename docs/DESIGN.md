# ReLearn — Brand and Logo

## 1. Name

**ReLearn** — a portmanteau of *recycle* and *learn*.

- **Display name:** ReLearn (capital R, capital L, no space).
- **Tagline:** *Recycle to Learn.*
- **Android package / bundle ID:** `com.relearn.app`
- **Web domain suggestion:** `relearn.app` (fallbacks: `relearn.ng`, `getrelearn.com`)
- **Short description (store listing):** Turn recyclable waste into school
  supplies. Scan a card, record materials, earn points, collect pencils and books.

### Why this name

| Candidate | Verdict |
|---|---|
| **ReLearn** | Clear double meaning, short, easy to say in English and Nigerian Pidgin context, works as a verb ("I ReLearn") |
| Recycle2Learn | Descriptive but long and clumsy on a card |
| GreenBook | Collides with finance brands, loses the recycling idea |
| EcoPoint | Generic, sounds like a loyalty startup |
| WasteWise | Good but negative ("waste"), no education signal |

The name is already used consistently across the source PRD, so keep it. Avoid
variants like "Re-Learn", "Relearn" or "Re Learn".

### Voice

Warm, plain, practical. Short sentences. Never guilt-based climate language.
Say "bring bottles, earn a book", not "combat the planetary crisis". Use "pts"
for points and "collector" for field agents.

---

## 2. Logo idea — "The Learning Loop"

```
        ╭──────────────╮
     ╭──╯   (amber     ╰──╮
    ╱       leaf)         ╲
   │    ╭─────────────╮    │
   │   ╱  open book    ╲   │
   ╰──▶  (cream pages)  ◀──╯
        ╰─────────────╯
```

### Concept

A single **circular arrow** loops over an **open book**. The arrow is the
recycling cycle; the book is learning. The loop returns *into* the book, which is
exactly the product promise: what goes around (waste and points) comes back as
school supplies. A small **amber leaf** sprouts from the book's spine — the
environmental result — and doubles as the "spark" of new knowledge.

### Construction

- **Container:** rounded square (radius 24%) in Leaf Green `#2E9E5B`, safe for
  app icons and favicons.
- **Book:** two cream `#FBF7EC` pages meeting at a visible spine; slightly open
  (12°), bottom edge straight so it sits optically centred.
- **Loop arrow:** cream stroke, 13 units on a 240 unit grid, round caps, opens
  at the bottom with a triangular arrowhead pointing down into the spine.
- **Leaf:** Sun Amber `#F2B441`, simple two-arc leaf, tilted 30°.
- **Grid:** draw on a 240 × 240 grid; keep all strokes ≥ 12 units for
  legibility at 16 px.

### Files

| File | Use |
|---|---|
| `assets/brand/logo_mark.svg` | App icon, favicon, avatar, tile |
| `assets/brand/logo_horizontal.svg` | Light backgrounds, web header, documents |
| `assets/brand/logo_horizontal_dark.svg` | Dark/photo backgrounds |
| `assets/brand/logo_mark_1024.png` | Store icon, social avatar |

### Clear space and minimum size

- Clear space: at least the width of the arrow stroke (≈ 12% of the mark) on all
  sides.
- Minimum mark size: 24 px digital, 10 mm print.
- Minimum horizontal lockup width: 120 px digital, 35 mm print.
- Below 32 px, use the mark only — never the horizontal lockup.

### Do / don't

| Do | Don't |
|---|---|
| Use the green tile for app icons | Recolour the book or leaf |
| Pair the wordmark with the mark in one lockup | Add shadows, gradients or outlines |
| Keep the tagline in one line under the wordmark | Set the wordmark in all caps or italics |
| Use the cream mark on photography | Place the full-colour lockup on busy images |
| Allow the arrow to break the tile edge? **No** — keep inside | Rotate, stretch or add extra arrows |

---

## 3. Colour system

| Token | Hex | Usage |
|---|---|---|
| `leaf` | `#2E9E5B` | Primary actions, brand tile, success |
| `forest` | `#14532D` | Headings, dark surfaces, pressed states |
| `cream` | `#FBF7EC` | Page background, card faces, logo pages |
| `sun` | `#F2B441` | Highlights, points, low-stock warning, leaf |
| `ink` | `#1F2937` | Body text |
| `muted` | `#6B7280` | Secondary text |
| `line` | `#E5E7EB` | Borders, dividers |
| `danger` | `#DC2626` | Errors, blocked cards, voids |
| `sky` | `#0EA5E9` | Informational states, sync |

Contrast: `ink` on `cream` = 13.8:1; white on `leaf` = 3.6:1 (use for large text
and buttons only, minimum 18 px bold or 24 px regular); `forest` on `cream` =
9.6:1. Do not use `sun` for text on cream; use it as a fill or with ink text.

---

## 4. Typography

- **UI / body:** Inter or system sans (Roboto on Android, Segoe UI on Windows).
- **Headings:** Inter SemiBold, tight tracking (−0.02 em), sentence case.
- **Numbers:** tabular figures for balances and IDs (`fontFeatures:
  [FontFeature.tabularFigures()]`).
- **Scale:** 12 / 14 / 16 / 20 / 24 / 32 / 48.
- **Weights:** 400 body, 500 labels, 600 headings, 700 KPI numbers.

No custom display font for MVP: it keeps the web bundle small and avoids font
licensing costs.

---

## 5. Iconography and illustration

- Material Symbols Rounded, 24 px, 1.75 stroke feel.
- Custom icons only where Material fails: QR card, points ledger, sachet.
- Illustration style: flat two-colour (leaf + sun) with cream negative space;
  show bottles, books, a phone scanning a card. Never photoreal children's faces.
- Photography: hands, materials and cards, not identifiable pupils without
  written consent.

---

## 6. UI tokens

- Radius: 12 px inputs, 16 px cards, 24 px sheets, 999 px pills.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48.
- Elevation: 0 for flat tables, 1 for cards, 3 for sheets and dialogs.
- Motion: 150 ms standard, 220 ms page transitions; no bouncing.
- Collector buttons: 56 px height, 18 px semibold label.
- Admin content max width: 1280 px, 24 px gutters.
