# 01 · Design System

Tokens. Everything in this file is a named constant that appears in [08 wireframes](08-wireframes.md)
and nowhere is a raw hex or pixel value used in a later document without a token name beside it.

Token names are given in `kebab-case` so they transliterate directly into CSS custom properties,
Unity `ScriptableObject` fields, Godot theme overrides and Flutter `ThemeExtension` members without
renaming.

---

## 1.1 Base grid and spacing

4 px base unit. Every margin, padding, gap and component height is a multiple of it.

| Token | Value | Used for |
|---|---|---|
| `space-0` | 0 | — |
| `space-1` | 4 px | Icon-to-label gap, badge inset |
| `space-2` | 8 px | Inside a chip, between dice |
| `space-3` | 12 px | Inside a card, list-row padding |
| `space-4` | 16 px | Panel padding, the **mobile side gutter** |
| `space-5` | 24 px | Between panel sections |
| `space-6` | 32 px | Desktop panel gutter |
| `space-8` | 48 px | Screen-level top/bottom margin |
| `space-10` | 64 px | Dialogue inset on desktop |

| Token | Value | Used for |
|---|---|---|
| `radius-sm` | 4 px | Chips, badges, dice pips container |
| `radius-md` | 8 px | Buttons, cards, dice token |
| `radius-lg` | 16 px | Panels, drawers |
| `radius-full` | 9999 px | Army badge, seat dot, avatar |

| Token | Value | Used for |
|---|---|---|
| `control-h-sm` | 32 px | Dense list row, stepper button on desktop |
| `control-h-md` | 40 px | Standard button, text field |
| `control-h-lg` | 48 px | **Every primary touch target** (see [07 §7.2](07-responsive-and-accessibility.md)) |

---

## 1.2 Ownership palette (UX-02, UX-03)

Seven entries: six playable seats and `Neutral`. The seat index *is* the palette index — seat 3
always gets `seat-3`, in every client, in every match, so a screenshot is readable without a key.

**Values are sampled from the reference frames — see [09 §9.3](09-art-direction.md) for each one's
source file and pixel region.** Three of the six are measured; three are derived to extend the same
language, and each is marked.

### Two tiers per seat: a muted fill and a bright accent

This is the reference's key structural decision and it is not a shading relationship — the two values
are chosen independently.

| Token | Fill | Accent | Name | Source |
|---|---|---|---|---|
| `seat-0` | `#FF0103` | `#FF2E30` | Red | **sampled** |
| `seat-1` | `#96843C` | `#FBBA2D` | Gold | **sampled** |
| `seat-2` | `#2F6E92` | `#45A4EE` | Blue | **sampled** |
| `seat-3` | `#6D9423` | `#8FD13A` | Green | derived |
| `seat-4` | `#8A3FA8` | `#B97BE8` | Violet | derived |
| `seat-5` | `#B4532A` | `#F2863A` | Orange | derived |
| `seat-neutral` | `#4E5765` | `#8A94A2` | Slate | derived |

| Tier | Used for |
|---|---|
| **Fill** | the territory body, the continent grouping band, the seat chip background |
| **Accent** | the army badge disc, the seat ring, the territory-pulse on change, any UI element naming the seat |

> **Never interchange them.** A territory in accent red would glare; a badge in fill gold would
> disappear against the landmass. §9.9 check DA-78 asserts it.

The accented `seat-0` differs from the sampled pure red `#FF0103` only by a lift for white-numeral
legibility on the badge; the fill keeps the exact sampled value.


### The pattern channel (UX-03)

Each seat also owns a **fill pattern**, applied at 18 % opacity over the seat colour inside a
territory polygon and shown at full strength in the seat chip. This is not decoration. A
seven-colour categorical palette has no arrangement that survives every form of colour vision. Under
simulation (Machado 2009 matrices, CIE76 ΔE between simulated pairs — see
[07 §7.4](07-responsive-and-accessibility.md) for the full table) three pairs collapse:

| Deficiency | Pair | ΔE | |
|---|---|---|---|
| Deuteranopia | `seat-5` Teal / `seat-neutral` Slate | **3.75** | indistinguishable |
| Deuteranopia | `seat-1` Cobalt / `seat-4` Violet | **5.42** | indistinguishable |
| Tritanopia | `seat-2` Jade / `seat-5` Teal | **5.36** | indistinguishable |

Under normal vision the closest pair is Jade / Teal at ΔE 28.7, which is comfortably separated — so
this is specifically a colour-vision problem, not a palette-quality one, and no reshuffling of hues
fixes it. The pattern is the channel that still works when the hue does not.

| Seat | Pattern | Glyph (for the seat chip and the standings table) |
|---|---|---|
| `seat-0` | solid | ● |
| `seat-1` | diagonal hatch ↗ 45°, 3 px | ◆ |
| `seat-2` | horizontal rule, 4 px pitch | ▲ |
| `seat-3` | dotted grid, 5 px pitch | ■ |
| `seat-4` | diagonal hatch ↘ 135°, 3 px | ★ |
| `seat-5` | cross-hatch, 4 px pitch | ✚ |
| `seat-neutral` | 30 % dot stipple, desaturated | ○ |

`Neutral` must read as *inert*, not as a seventh competitor — it is the only seat that is never
offered a turn (D-07). It is the one entry that is both desaturated and stippled.

---

## 1.3 Continent palette (UX-04)

Copied verbatim from `../shared/maps/world_classic.json` → `continents`. These are **map data**, not
design tokens — a generated map may ship different ones, so a client reads them from the map and
never hard-codes them.

| Continent | Hex | Bonus | Territories |
|---|---|---|---|
| North America `NA` | `#d4a05a` | **5** | 9 |
| South America `SA` | `#7fa650` | **2** | 4 |
| Europe `EU` | `#5b8fb9` | **5** | 7 |
| Africa `AF` | `#c97f4e` | **3** | 6 |
| Asia `AS` | `#a4695f` | **7** | 12 |
| Australia `AU` | `#9b7fb0` | **2** | 4 |

**A continent colour never fills a territory (UX-04).** It is permitted in exactly three places:

1. the continent **outline** on the board — 3 px, at 70 % opacity;
2. the continent **bonus chip** in the draft breakdown (S-09) and the capability panel (S-16);
3. the continent **grouping band** in any territory list.

The reason is a collision, not a preference: Europe's `#5b8fb9` and `seat-2`'s fill `#2F6E92` are
both mid-blue. If both could appear as a territory fill, a glance could not separate *who owns this*
from *where this is*. Keeping fill exclusively for ownership resolves it permanently, and also means
the six continent colours never need to be checked against the seven seat colours again.

Note too that the map's continent colours are **desaturated** while the seat accents are
**saturated**. That is the secondary cue: anything vivid is a player, anything muted is geography.

---

## 1.4 Semantic colour — one committed theme

**There is no light mode.** The reference is a single committed visual world: a bright cyan board
inside deep teal-navy chrome. A "light theme" for a cyan ocean and near-black territory outlines
would be a second art direction, not a palette swap, and no reference frame shows one. S-20 therefore
carries no theme control.

Values marked **sampled** come from a reference frame — see [09 §9.2](09-art-direction.md).

| Token | Value | Meaning | Source |
|---|---|---|---|
| `bg-chrome-deep` | `#081A24` | Behind everything; menu gradient base | **sampled** |
| `bg-chrome` | `#0A2433` | Screen background, menus | **sampled** |
| `bg-panel` | `#123A50` | Panels, drawers, cards | **sampled** |
| `bg-panel-raised` | `#20658A` | Dialogues, popovers, the active row | **sampled** |
| `bg-ocean` | **`#1897C8`** | The sea on the board | **sampled** |
| `bg-ocean-hi` | `#53B7E5` | Wave highlight | **sampled** |
| `bg-land` | **`#383E48`** | Unowned landmass | **sampled** |
| `board-outline` | **`#120400`** | 3 px territory outline (§09.4) | **sampled** |
| `banner-panel` | `#D3E9F3` | Top instruction banner | **sampled** |
| `text-primary` | `#FFFFFF` | Board type, panel headings |  |
| `text-on-panel` | `#E8F2F7` | Body text on a panel |  |
| `text-secondary` | `#9FC0D2` | Labels, captions |  |
| `text-disabled` | `#5E7788` | Inert control text |  |
| `text-ink` | `#000000` | Text on `banner-panel` only | **sampled** |
| `accent-gold` | **`#FBBA2D`** | The non-seat interactive accent; currency, emphasis | **sampled** |
| `legal` | `#5FD13A` | **A legal target** (see below) |  |
| `legal-dim` | `#5FD13A33` | Legal fill wash, 20 % |  |
| `danger` | `#FF5457` | Destructive, elimination, loss |  |
| `warning` | `#FBBA2D` | Forced trade, round cap approaching |  |
| `info` | `#45A4EE` | Neutral notice |  |
| `focus-ring` | `#8FD13A` | 2 px outline + 2 px offset, always visible |  |

### The dark text outline is load-bearing, and that is measured

White on `bg-ocean` is only **3.33 : 1** — enough for large UI, **not** for body text. White on
`bg-land` is 10.76 : 1. Board type crosses both surfaces constantly as the player pans, so it cannot
be tuned for either.

> **Every piece of white type on the board carries a dark outline.** That is not a stylistic echo of
> the reference; it is the only way one type colour stays legible over a 3.33 : 1 surface and a
> 10.76 : 1 surface at the same time. Army numerals, territory names and phase labels all take it.

The light `banner-panel` exists for the same reason in reverse: when a long instruction must be read
rather than glanced at, it gets a plate, and black on `#D3E9F3` measures **16.72 : 1**.

### `legal` is a reserved colour

`legal` / `legal-dim` mean one thing and may not be reused for emphasis, hover, selection or
branding: **this element appears in the server's current legal-action list.** That is the
whole FR-66 affordance vocabulary ([06 §6.1](06-interaction-and-affordances.md)). If `legal` green
also meant "nice", a player would learn to distrust it, and the one visual promise the interface
makes would be broken.

`accent-gold` exists so that ordinary interactive chrome — a link, a stepper, a tab — has somewhere
to live that is neither a seat colour nor the legal colour.

### Measured contrast

| Foreground | on `bg-chrome` | on `bg-panel` | on `bg-land` | on `bg-ocean` |
|---|---|---|---|---|
| `text-primary` white | **15.99** | **12.02** | **10.76** | 3.33 — outline required |
| `text-on-panel` | 14.07 | 10.58 | 9.47 | — |
| `text-secondary` | 8.34 | 6.27 | 5.61 | — |
| `accent-gold` | 9.26 | 6.96 | 6.24 | — |
| `legal` | 8.12 | 6.11 | 5.47 | — |
| `danger` | 5.07 | 3.81 — large/UI | 3.41 — large/UI | — |
| `text-ink` on `banner-panel` | — | — | — | **16.72** |

`text-disabled` measures 3.40 : 1 on `bg-chrome` and stays that way: WCAG exempts inactive
controls, and raising it would make a disabled control look available. That is a deliberate
exemption, recorded here so it is not re-"fixed" later.

---

## 1.5 Type

| Token | Size / line | Weight | Used for |
|---|---|---|---|
| `type-display` | 32 / 40 | 700 | Game-over winner, splash title |
| `type-h1` | 24 / 32 | 700 | Screen title |
| `type-h2` | 20 / 28 | 600 | Panel title |
| `type-h3` | 16 / 24 | 600 | Section label, seat name |
| `type-body` | 15 / 22 | 400 | Prose, list rows |
| `type-body-sm` | 13 / 18 | 400 | Captions, help text |
| `type-label` | 12 / 16 | 600, +0.04 em | Chip text, table headers, all-caps labels |
| `type-num-lg` | 28 / 32 | 700, **tabular** | Army pool, trade value, dice numeral |
| `type-num` | 15 / 20 | 600, **tabular** | Army badge, territory count, odds |

Two hard rules:

- **Every number uses tabular figures.** An army badge that re-centres as it ticks 9 → 10 reads as
  the territory moving. Dice values, army counts, odds percentages, trade values and round numbers
  are all numbers.
- **Minimum rendered size is 12 px.** Below that the army badge on a dense board becomes a smudge,
  and [07 §7.5](07-responsive-and-accessibility.md) requires 200 % text scaling to remain legible.

Stack: `Inter`, then `Segoe UI Variable`, `SF Pro Text`, `Roboto`, `system-ui`, `sans-serif`.
Numerals must come from a face with true tabular figures; if the licensed face lacks them,
`JetBrains Mono` is the numeric fallback for `type-num*` only.

---

## 1.6 Elevation

| Token | Shadow | Used for |
|---|---|---|
| `elev-0` | none | Flush panels, board |
| `elev-1` | `0 1px 2px rgb(0 0 0 / .08)` | Cards, chips |
| `elev-2` | `0 4px 12px rgb(0 0 0 / .12)` | Dropdowns, tooltips, the dice tray |
| `elev-3` | `0 12px 32px rgb(0 0 0 / .20)` | Dialogues, drawers, the hand-over screen |

In dark mode shadows carry almost nothing, so each level also raises the surface token one step
(`bg-surface` → `bg-surface-raised`) and adds a 1 px `border-subtle` hairline.

---

## 1.7 Iconography

16 / 20 / 24 px, 1.5 px stroke, square cap. One icon per concept, no synonyms.

| Concept | Icon | Appears in |
|---|---|---|
| Infantry | helmet | Card face, capability panel |
| Cavalry | horse | same |
| Artillery | cannon | same |
| **AirForce** | aircraft silhouette | Card face, capability panel, **S-12**, air-attack affordance |
| **NavalForce** | ship silhouette | Card face, capability panel, **S-13**, sea-route edge badge |
| Wild | star burst | Card face only — a Wild has **no** capability (D-20), so it never appears in S-16 |
| Attack | crossed swords | S-11, action bar |
| Fortify | shield with arrow | S-15, action bar |
| Occupy | arrow into box | S-14 |
| Draft / reinforce | stacked chevrons | S-09 |
| Trade cards | two-way arrows | S-10 |
| Sea route | dotted wave | Board legend, S-13 |
| Land border across water | dashed line | Board legend **only** (UX-08) |
| Range | concentric arcs | S-11 range chip, S-12 (**one component** — UX-07) |
| End phase | forward chevron | Action bar |

The Wild row is a correctness constraint, not a style note. Capability derives from
`profile(t) = {Infantry} ∪ ({NavalForce} if coastal) ∪ {cardSymbol}`, and a Wild has no profile
(D-20). An interface that showed a star in the capability panel would be asserting a rule that
does not exist.

---

## 1.8 Motion

| Token | Duration | Curve | Used for |
|---|---|---|---|
| `motion-instant` | 0 ms | — | Anything revealing or hiding hidden information |
| `motion-fast` | 120 ms | `cubic-bezier(.2,0,.4,1)` | Hover, focus, chip toggle |
| `motion-base` | 200 ms | `cubic-bezier(.2,0,.2,1)` | Panel open, sheet slide, selection |
| `motion-slow` | 320 ms | `cubic-bezier(.3,0,.2,1)` | Screen transition, army march |
| `motion-dice` | **see [04 §4.5](04-dice-ui-ux.md)** | | The roll sequence, which is choreographed rather than tweened |

Three constraints:

- **`motion-instant` for the hand-over path.** Clearing the outgoing seat's hand on
  `HandOverDevice` is not animated and is not deferred by a frame. TC-UI-03 checks that the hand is
  cleared *before* any incoming state is requested, including across a background-and-restart.
  A 200 ms cross-fade of a card hand is an information leak with an easing curve on it.
- **Animation never gates input.** Every animation is skippable by the next tap. S-20 exposes an
  animation-speed control, and at its fastest setting every duration above collapses toward 0.
- **`prefers-reduced-motion` replaces movement with a cross-fade** at `motion-fast`, and replaces
  the dice tumble with a direct cut to the final faces — the faces themselves are never changed,
  because they come from the `DiceRolled` event (FR-69).

---

## 1.9 Component inventory

The complete set. Anything in [08](08-wireframes.md) is one of these, so a client builds this list
once and then assembles screens.

| Component | Key states | Notes |
|---|---|---|
| `Button` | default · hover · active · focus · **legal** · disabled · loading | `legal` variant only for action-bar commitment, and it fills with **`legal-fill`**, never `legal` (§1.4) |
| `Stepper` | value, min, max, default marker, at-bound | Used for dice, armies, seats, sea routes, **face count**, **attack range** |
| `Chip` | neutral · seat · continent · capability · selected | The continent variant is the only place a continent colour appears in a list (UX-04) |
| `SeatChip` | colour + pattern + glyph + name + kind + territory/army counts | Carries all three ownership channels (UX-03) |
| `ArmyBadge` | count, owner, selected, **changed** | Pinned to `label` (UX-10). Sits on its own `bg-surface` pill with `text-primary` — **never white text on the seat fill**, which measures 1.86 : 1 on `seat-3`. `changed` pulses once after `StateChanged` |
| `TerritoryShape` | owned · legal-target · selected-origin · in-range · inert · contested | See [03 §3.7](03-map-ui-ux.md) |
| `EdgeLine` | land · **land-across-water (dashed, UX-08)** · sea route · highlighted | |
| `Die` | idle · rolling · settled · winning · losing | Face count agnostic (UX-06) |
| `DiceTray` | attacker row, defender row, pairwise comparison, losses | [04 §4.4](04-dice-ui-ux.md) |
| `GameCard` | face-up · face-down · selected · in-valid-set · disabled | [05](05-card-ui-ux.md) |
| `CardHand` | 0…n cards, forced-trade warning, set highlighting | |
| `PhaseBar` | Claim · Draft · Attack · Occupy · Fortify · EndTurn | Current phase, whose turn, round |
| `OddsReadout` | `winChance` from the server, as a percentage and a bar | Never computed client-side (FR-67) |
| `RangeReadout` | reachable targets + distance to each | One component for land and air (UX-07) |
| `CapabilityPanel` | per-capability: held / not held, and the source | S-16. No Wild row (D-20) |
| `Drawer` | closed · open (touch only) | **Right-edge overlay.** Floats above a full-bleed board and never resizes it (UX-14). Width `min(320 px, 45 vw)`. Replaces the desktop side panel on phone and tablet |
| `ZoomControl` | overview · tactical | Snaps to the two named states; shows which is active (UX-13) |
| `RotatePrompt` | — | The entire portrait layout on touch. One instruction, nothing else (UX-05) |
| `Dialogue` | confirm · error · blocking | `elev-3` |
| `Toast` | info · warning · danger | Never used for anything requiring an action |
| `EmptyState` | icon + line + optional action | [06 §6.7](06-interaction-and-affordances.md) |
| `Skeleton` | shimmer, reduced-motion safe | [06 §6.6](06-interaction-and-affordances.md) |

---

## 1.10 Acceptance checks for this file

| # | Check |
|---|---|
| 1 | No hex literal appears in [08](08-wireframes.md); every colour is a token from §1.2–§1.4 |
| 2 | No continent colour is used as a territory fill anywhere (UX-04) |
| 3 | `legal` / `legal-dim` appear **only** where the server's legal list is the source (§1.4) |
| 4 | Every seat is distinguishable with hue removed — by **pattern**, since luminance alone does not separate them (`seat-4` and `seat-0` are 1.4 apart; [07 §7.4](07-responsive-and-accessibility.md)) |
| 5 | Every number uses a tabular face (§1.5) |
| 6 | No animation sits on the `HandOverDevice` path (§1.8, TC-UI-03) |
| 7 | The capability panel has no Wild row (§1.7, D-20) |
| 8 | Every primary touch target is ≥ `control-h-lg` (§1.1, [07 §7.2](07-responsive-and-accessibility.md)) |

---

[← 00 Index](00-index.md) · [02 Screen inventory and flows →](02-screen-inventory-and-flows.md)
