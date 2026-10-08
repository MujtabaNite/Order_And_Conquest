# 07 · Responsive and Accessibility

The acceptance checklist for the pack. Every number here was computed from the tokens in
[01](01-design-system.md) and the anchors in `../shared/maps/world_classic.json` — none is an
estimate, and two of them changed the design system rather than the other way round.

---

## 7.1 Breakpoints

**Mobile is landscape-only (UX-05).** Breakpoints are therefore keyed to the **landscape** viewport,
and portrait on a phone or tablet renders a rotate prompt rather than a layout.

| Name | Landscape viewport | Typical | Input | Board | Panels |
|---|---|---|---|---|---|
| `phone` | 640 × 360 – 932 × 430 | phone, landscape | touch | full-bleed, zoom + pan | right-edge `Drawer`, overlay |
| `tablet` | 1024 × 768 – 1366 × 1024 | tablet, landscape | touch | full-bleed, zoom + pan | right-edge `Drawer`, overlay |
| `desktop` | 1280 × 800 – 1439 | laptop | pointer | fit, panels over the ocean margin | persistent side panels |
| `desktop-wide` | 1440 + | desktop | pointer | fit, centred, max 1600 | persistent side panels, widened |

**Minimum supported viewport: 640 × 360 CSS px (UX-05).** A design target, deliberately not an NFR —
no NFR in `../docs/03-requirements.md` fixes a viewport and this pack does not get to add one.

### The dividing line is input, not width

`phone` and `tablet` differ only in how much board is visible at a playable zoom; they share one
layout. The real break is between **touch** and **pointer**, and it changes two things: the target
minimum (§7.2) and whether a panel may be persistent (UX-14).

---

## 7.2 Touch targets, and the zoom model that satisfies them

Two minimums apply, and conflating them is what produced the error corrected below:

| Input | Minimum | Source | Required board scale |
|---|---|---|---|
| **Touch** | **48 px** | Material 48 dp · Apple HIG 44 pt · WCAG 2.1 SC 2.5.5 | **≥ 0.537** |
| **Pointer** | **24 px** | WCAG 2.1 SC 2.5.8 Target Size (Minimum), AA | ≥ 0.268 |

`control-h-lg` is 48 px and every panel, drawer, button, stepper and list row meets it trivially on
every platform. The board is the only surface where the geometry has to be checked.

### The measurement

The 42 territory anchors on the 1600 × 900 canvas:

| | Distance | Pair |
|---|---|---|
| **Closest two anchors** | **89.4 px** | `irkutsk`↔`mongolia`, and `mongolia`↔`china` |
| 2nd | 92.2 px | `northwest_territory`↔`alberta` |
| 3rd | 94.9 px | `east_africa`↔`congo`, `northern_europe`↔`southern_europe`, `yakutsk`↔`irkutsk` |
| Median nearest-neighbour | 110.0 px | |
| **Loosest** nearest-neighbour | **145.6 px** | `japan` |

Every territory has a neighbour within 145.6 px, so the board is uniformly dense: a target that fails
in Asia fails everywhere. A 48 px target therefore needs **scale ≥ 0.537** — the **tactical scale**.

### The board zooms, so 0.537 is a threshold the player crosses, not a device test

| Device, landscape | Overview (fit) | At tactical zoom, board visible | Pinch needed |
|---|---|---|---|
| Small Android 640 × 360 | 0.356 → 31.8 px | 75 % × 66 % | 1.51 × |
| iPhone SE 667 × 375 | 0.372 → 33.3 px | 78 % × 69 % | 1.44 × |
| iPhone 15 844 × 390 | 0.389 → 34.8 px | **98 % × 72 %** | 1.38 × |
| Pixel 8 892 × 412 | 0.413 → 37.0 px | **100 % × 77 %** | 1.30 × |
| iPhone 15 Pro Max 932 × 430 | 0.433 → 38.8 px | **100 % × 81 %** | 1.24 × |
| iPad mini 1024 × 768 | 0.640 → **57.2 px** | 100 % × 100 % | **none** |
| iPad Pro 11 1194 × 834 | 0.746 → **66.7 px** | 100 % × 100 % | **none** |

So:

- **Tablets are compliant at rest.** Overview already exceeds 48 px; zoom is a convenience.
- **Phones are compliant one small pinch away**, and at that pinch an iPhone 15 still holds 98 % of
  the board width on screen. Auto-framing on selection ([03 §3.11](03-map-ui-ux.md)) performs that
  pinch for the player, so compliance is the default state during an action, not an opt-in.
- Overview on a phone gives 32–39 px, below the minimum — which is exactly why overview is for
  *reading* and tapping there goes through a disambiguation popover rather than a guess.

> **Correction of record.** An earlier revision of this section concluded that *"the whole board
> cannot offer compliant touch targets on any phone"* and made a territory list the primary mobile
> selection path. That assumed a board fitted to the viewport. The board zooms and pans, as the genre
> does, so the conclusion does not follow. The measurements were correct; the inference was wrong, and
> both it and the design that followed from it have been withdrawn. The list remains, as a
> convenience and an accessibility path (§7.7), not as the primary one.

### A panel may never resize the board (UX-14)

Because compliance is a function of scale, anything that shrinks the board can break it. Measured
with a persistent 280 px side rail:

| Device, landscape | Full-bleed | With a 280 px rail | |
|---|---|---|---|
| iPhone 15 844 × 390 | 34.8 px | 31.5 px | worse |
| iPhone 15 Pro Max 932 × 430 | 38.8 px | 36.4 px | worse |
| **iPad mini 1024 × 768** | **57.2 px — compliant** | **41.6 px — 16 of 42 under** | **breaks compliance** |
| iPad Pro 11 1194 × 834 | 66.7 px | 51.1 px | still compliant |

A rail turns a compliant iPad mini into a non-compliant one. So on touch, **panels overlay a
full-bleed board** and the board's scale and centre are never touched. Desktop keeps persistent
panels because the pointer minimum is 24 px: at 1366 × 768 with the full 540 px of side chrome the
board still yields 46.2 px, nearly twice what a pointer needs.

Bottom sheets are rejected for a second, independent reason: in landscape the board has only
**320–390 px of height** on a phone, and a half-height sheet would leave under 200 px.

---

## 7.3 Contrast, measured

WCAG 2.1 thresholds: **4.5 : 1** body text, **3 : 1** large text and non-text UI boundaries.

| Pair | Ratio | Verdict |
|---|---|---|
| `text-primary` on `bg-surface` (L) | 16.91 | AAA |
| `text-primary` on `bg-canvas` (L) | 15.26 | AAA |
| `text-primary` on `bg-surface` (D) | 14.81 | AAA |
| `text-secondary` on `bg-surface` (L) | 6.00 | AA |
| `text-secondary` on `bg-surface` (D) | 7.10 | AAA |
| `accent` (L) | 5.43 | AA |
| `accent` (D) | 5.85 | AA |
| `danger` (L) | 5.46 | AA |
| `danger` (D) | 5.88 | AA |
| **`warning` (L), corrected to `#9c5700`** | **5.56** | AA |
| `legal` (L) | 3.45 | **UI / large only — never text** |
| `legal-fill` (L), white text on it | 5.40 | AA — the filled-control token |
| `legal` (D) | 8.13 | AAA |
| **`border-strong` (L), corrected to `#7d8896`** | **3.60** | non-text AA |
| `focus-ring` on `bg-canvas` | 4.90 | AA |
| `text-disabled` (L) | 2.56 | **exempt** — inactive control |
| `text-disabled` (D) | 2.81 | **exempt** |

Two tokens were changed because of this table, not because of taste: `warning` was 2.44 : 1 and the
forced-trade banner is body text; `border-strong` was 1.92 : 1 and a territory boundary must be
identifiable. Both are recorded in [01 §1.4](01-design-system.md).

### Seat fills against the ocean

This is where the palette has a real, bounded limitation. Seat fill vs `bg-ocean`:

| Seat | vs ocean (light) | vs ocean (dark) | White text on fill |
|---|---|---|---|
| `seat-0` Crimson | 4.01 | 3.18 | 5.44 |
| `seat-1` Cobalt | 3.18 | 4.02 | 4.30 |
| `seat-2` Jade | **2.12** | 6.02 | **2.87** |
| `seat-3` Amber | **1.38** | 9.28 | **1.86** |
| `seat-4` Violet | 4.33 | **2.95** | 5.87 |
| `seat-5` Teal | **2.42** | 5.27 | 3.28 |
| `seat-neutral` Slate | **2.57** | 4.98 | 3.48 |

Four light-mode fills fall below 3 : 1 against the ocean, `seat-3` Amber worst at 1.38. Two
mitigations, both now mandatory:

1. **Every territory shape carries a 1.5 px `border-strong` stroke** (2 px in the debug renderer).
   The land/sea boundary is carried by the stroke, which is 3.60 : 1, so it never depends on fill
   contrast. This is why `border-strong` was darkened.
2. **The army badge never uses white text on the seat fill.** It sits on its own `bg-surface` pill
   with `text-primary` — 16.91 : 1 regardless of owner. White-on-Amber would have been 1.86 : 1,
   i.e. illegible, on the single most common number on the board.

The seat colours themselves are **not** changed: `seat-3` is the best-separated entry in the palette
(ΔE 62.8 from its nearest neighbour, and the clearest in greyscale), and degrading it to win an
ocean-contrast ratio that the stroke already provides would be the wrong trade.

---

## 7.4 Colour vision

Simulated with the Machado (2009) matrices at full severity, compared as CIE76 ΔE in CIELAB.
ΔE < 10 is treated as indistinguishable at a glance.

| Deficiency | Closest pairs | ΔE | |
|---|---|---|---|
| **Deuteranopia** | `seat-5` Teal / `seat-neutral` Slate | **3.75** | collapsed |
| | `seat-1` Cobalt / `seat-4` Violet | **5.42** | collapsed |
| | `seat-0` Crimson / `seat-2` Jade | 21.43 | ok |
| **Protanopia** | `seat-5` Teal / `seat-neutral` Slate | 11.92 | marginal |
| | `seat-1` Cobalt / `seat-4` Violet | 19.91 | marginal |
| **Tritanopia** | `seat-2` Jade / `seat-5` Teal | **5.36** | collapsed |
| | `seat-1` Cobalt / `seat-5` Teal | 12.77 | marginal |
| **Normal** | `seat-2` Jade / `seat-5` Teal | 28.72 | well separated |

So the palette is good for normal vision and **fails for three specific pairs** under two specific
deficiencies. Reshuffling hues does not fix it — a seven-way categorical palette has no arrangement
that survives all three deficiencies at once. Hence **UX-03**: the pattern channel is the fix.

### Greyscale does not rescue it either

Relative luminance, sorted:

| Seat | Luminance (×100) |
|---|---|
| `seat-4` Violet | 12.90 |
| `seat-0` Crimson | 14.31 |
| `seat-1` Cobalt | 19.41 |
| `seat-neutral` Slate | 25.19 |
| `seat-5` Teal | 27.01 |
| `seat-2` Jade | 31.55 |
| `seat-3` Amber | 51.33 |

Closest adjacent pair: **`seat-4` and `seat-0`, 1.40 apart** — invisible in greyscale.

This corrects a plausible misreading of [01 §1.10](01-design-system.md)'s check 4. "Distinguishable
with hue removed" is satisfied by the **pattern**, not by luminance, and the check is that the
patterns differ — which they do by construction, since each seat owns a distinct one.

### The three channels, and what each one is for

| Channel | Carries | Survives |
|---|---|---|
| Seat **colour** | fast identification at a glance | normal vision |
| Seat **pattern** | identity when hue fails | all three deficiencies, and greyscale |
| Seat **glyph** (● ◆ ▲ ■ ★ ✚ ○) | identity in lists, chips, standings, screen readers | everything, including text-only output |

Every place a seat is named uses at least **two** of the three. The board uses colour + pattern; the
standings table uses colour + glyph + name; a screen reader gets the name.

---

## 7.5 Text scaling

| Requirement | Treatment |
|---|---|
| Up to **200 %** | All panel text reflows. No clipping, no truncation of a number, no horizontal scroll |
| Minimum rendered size | **12 px** ([01 §1.5](01-design-system.md)); at 200 % that is 24 px |
| Reserved expansion | **30 %** on every string in [08](08-wireframes.md), for localisation and scaling together |
| Numbers | Tabular figures at every size, so a scaled army badge does not re-centre as it ticks 9 → 10 |
| **Army badges** | Grow with text scale. Because the board is dense (§7.2), at 200 % the badges of adjacent territories can overlap — resolved by the declutter table in [03 §3.11](03-map-ui-ux.md), in which the **badge is never the element dropped**; the continent label and the edge lines go first |
| Dice | Token grows to 64 px rather than the pips shrinking ([04 §4.10](04-dice-ui-ux.md)) |

The badge rule is the one that needed a decision. At 200 % scaling on a 640 × 360 landscape board
something has to give, and the choice is explicit: lose geography before losing the number, because
the number is the game state and the geography is already visible as shape.

---

## 7.6 Reduced motion

`prefers-reduced-motion`, or S-20's fastest animation setting:

| Normally | Reduced |
|---|---|
| Panel slide, sheet, screen transition | Cross-fade at `motion-fast` |
| Dice tumble | **Cut to the final faces** |
| Army march | Instant count change with a single pulse |
| Loss floaters | Static for 600 ms, then gone |
| `Skeleton` shimmer | Static block |
| **Hand-over clear** | Already `motion-instant` — unchanged |

**No accessibility setting changes what the dice show.** The faces come from the `DiceRolled` event
(FR-69), so reduced motion changes only how long it takes to see them — and the hand-over path is
already instant, so there is nothing to reduce (§01.8).

---

## 7.7 Non-visual play

The board is spatial, so this is the hardest area and the one with the clearest answer: **everything
the board shows is also a list**, because §7.2 already required that for touch.

| Surface | Announcement |
|---|---|
| Territory (focused) | *"Ukraine. Europe. Yours, 12 armies. Legal target: Afghanistan, Ural, Southern Europe."* |
| Army badge change | *"Ukraine now 14 armies."* |
| Dice tray | the full §04.10 sentence, including the tie resolution in words |
| Phase change | *"Attack phase. Your turn, round 7."* |
| Card hand | *"3 cards. North Africa, Air Force. Alaska, Infantry. Wild. One valid set."* |
| Opponent hand | *"Mars, 2 cards, hidden."* — count announced, identities not (UX-12) |
| Forced trade | *"You must trade a set before placing armies."* |
| Hand-over | *"Pass the device to Mars. Tap to continue."* |
| Capability | *"Air Force: held, from North Africa card. Naval Force: not held."* |

Two rules make this complete rather than aspirational:

- **Nothing is conveyed by motion or colour alone.** Every state in [03 §3.7](03-map-ui-ux.md) has a
  text equivalent, and every outcome in [04 §4.4](04-dice-ui-ux.md) is written in words.
- **The legal list is the announcement source.** A focused territory announces its legal targets by
  reading `legal`, so the screen-reader path and the visual path cannot disagree — the same FR-66
  predicate drives both.

---

## 7.8 Motor and input

| Concern | Measure |
|---|---|
| Target size | `control-h-lg` 48 px everywhere outside the board; §7.2 for the board |
| Spacing | ≥ `space-2` (8 px) between adjacent targets |
| **No timed input** | Nothing in the product expires. No turn timer, no reaction window, no auto-dismiss on anything requiring an action (`Toast` is never used for something actionable — §01.9) |
| Drag-free | Every action is reachable by tap or key alone; drag only pans (§06.4) |
| Double-tap unbound | §06.5 — a tremor cannot double-commit |
| Keyboard parity | Full, including board traversal (§06.4) |
| One-handed reach | Mobile commit controls pinned to the sheet bottom, never inside a scrolling area ([05 §5.9](05-card-ui-ux.md)) |
| Focus always visible | `focus-ring` 2 px + 2 px offset, 4.90 : 1, never suppressed |

"No timed input" is worth stating as a property of the whole product: a turn-based game has no
reason to impose a clock, and the AI think-time delay is applied **server-side** (D-22) so it is not
a window the player must act within.

---

## 7.9 What this pack does not claim

Stated plainly, because an overclaim in a report is worse than a gap:

| Not claimed | Why |
|---|---|
| **WCAG 2.1 AA conformance** | No NFR in `../docs/03-requirements.md` requires it. AA is the *target* used to pick values in §7.3 and §7.5, and `legal`-as-text and `text-disabled` are documented exceptions. A conformance claim needs an audit this pack has not run |
| A fixed minimum viewport as a requirement | UX-05 is a design target. Promoting it would be adding an NFR, which is out of scope (§00.2) |
| Compliant board touch targets in **Overview** on a phone | §7.2 — Overview yields 32–39 px, under the 48 px minimum. Compliance is a property of **Tactical**, which auto-framing enters on selection. Tapping in Overview goes through the disambiguation popover rather than guessing |
| Portrait support on touch | UX-05 — the app locks to landscape. Portrait is a rotate prompt, not a degraded layout |
| Tested screen-reader support | §7.7 specifies the announcements; verifying them is Phase 8 inspection (DA-67, DA-68) |
| Localisation | Deferred (§00.6); 30 % expansion is reserved so it stays a translation job |

---

## 7.10 Acceptance checklist

Run against every screen before it is called finished. Not additions to the 119-case catalogue —
**TC-UI-01** and **TC-UI-02** pin reachability and interactivity.

| # | Check | Source |
|---|---|---|
| DA-57 | Every target outside the board is ≥ 48 px | §7.2 |
| DA-58 | Selecting an origin auto-frames to Tactical, so every target of that action is ≥ 48 px without a deliberate pinch | §7.2, UX-13 |
| DA-58b | No panel resizes the board on any platform; a drawer or strip overlays it | §7.2, UX-14 |
| DA-58c | Portrait on touch renders only the rotate prompt | §7.1, UX-05 |
| DA-59 | The zoom control snaps to the 0.537 tactical threshold | §7.2 |
| DA-60 | Every text pair in §7.3 measures at or above its stated ratio in the built UI | §7.3 |
| DA-61 | Every territory carries a `border-strong` stroke; no fill-only land/sea boundary | §7.3 |
| DA-62 | No army badge renders white text on a seat fill | §7.3 |
| DA-63 | Each of the 7 seats is identifiable with hue removed, by pattern | §7.4 |
| DA-64 | Every seat reference carries at least two of colour / pattern / glyph | §7.4 |
| DA-65 | 200 % text scaling clips nothing and never drops an army badge | §7.5 |
| DA-66 | Reduced motion shows identical dice faces to the animated path | §7.6 |
| DA-67 | Every board state and dice outcome has a text equivalent | §7.7 |
| DA-68 | Screen-reader announcements are generated from `legal`, not a parallel list | §7.7 |
| DA-69 | Nothing in the product expires on a timer | §7.8 |
| DA-70 | Focus is visible on every focusable element, in both themes | §7.8 |

---

[← 06 Interaction and affordances](06-interaction-and-affordances.md) · [08 Wireframes →](08-wireframes.md)
