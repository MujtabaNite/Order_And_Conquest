# 03 · Map UI/UX

**Binding filename.** Cited from `../docs/00-decisions-and-assumptions.md` (D-30) and
`../docs/07-game-design.md`. Do not rename without updating those citations.

The board is the only screen a player looks at for the whole match. Everything else is a panel that
opens over it. This document fixes what is drawn, what is **not** drawn, how ownership and reach are
read at a glance, and how all of that survives a 360 px phone.

---

## 3.1 What ships, and when

| Phase | Board | Why |
|---|---|---|
| 1 – 11 | **Debug renderer** — labelled circles at each territory's `label` anchor, real edges, real interaction, real army badges | `shape` is deliberately absent from the map file: *"adjacency ships first, artwork in Phase 12"* |
| 12 | **Artwork renderer** — the same layer stack with `TerritoryShape` swapped from a circle to a polygon | Nothing else changes. Interaction, hit-testing, highlighting and badges are identical |

This is UX-09, and it is the single most useful thing in this document for a team with little time.
The board is **not** blocked on an illustrator. The debug renderer is a complete, playable,
screenshot-able board, and the Phase 12 upgrade is a swap of one component's geometry. Every number
in §3.3 onward applies to both renderers.

---

## 3.2 Coordinate system

| | |
|---|---|
| Design canvas | **1600 × 900** (`canvas` in `../shared/maps/world_classic.json`), aspect **16 : 9** |
| Anchor range | x ∈ [110, 1420], y ∈ [90, 740] |
| Implied margin | 110 px left, 180 px right, 90 px top, 160 px bottom |
| Transform | Uniform scale + letterbox. **Never** non-uniform, **never** crop below the anchor range |

Clients hold one `Viewport { scale, panX, panY }` and derive everything from it. A territory's screen
position is `anchor × scale + pan`. The margins exist so the right-hand side can carry a desktop
panel over the ocean without covering `eastern_australia` at x = 1420.

### Measured anchor density — the fact that decides the mobile design

| Statistic | Value |
|---|---|
| Closest two anchors | **89.4 px** — `irkutsk ↔ mongolia`, and `mongolia ↔ china` |
| Next closest | 92.2 `northwest_territory ↔ alberta`, 94.9 `east_africa ↔ congo`, 94.9 `northern_europe ↔ southern_europe`, 94.9 `yakutsk ↔ irkutsk` |
| Median anchor separation | 497.3 px |
| **Loosest** nearest-neighbour gap | **145.6 px** (`japan`) |

The last row is the important one. *Every* territory has a neighbour within 145.6 px, so there is no
loosely-packed region to fall back on — the board is uniformly dense, and a touch target that fails
in Asia fails everywhere.

| Viewport width | Scale | Closest anchor gap becomes |
|---|---|---|
| 360 px | 0.225 | **20.1 px** |
| 414 px | 0.259 | 23.1 px |
| 768 px | 0.480 | 42.9 px |
| 1024 px | 0.640 | 57.2 px |
| 1600 px | 1.000 | 89.4 px |

A 48 px touch target (`control-h-lg`) needs a 48 px gap, which needs **scale ≥ 0.537**, which needs
a **viewport ≥ 859 px**. For a 44 px target the threshold is 787 px.

**So the whole board cannot offer compliant touch targets on any phone, at any fit-to-width zoom.**
That is not a layout problem to be solved by nudging anchors; it is arithmetic. §3.11 handles it
with two selection modes rather than by pretending otherwise.

---

## 3.3 The landmass rule (UX-01) — *only mainlands, no extra islands*

> **One territory is exactly one closed polygon. Every drawn landmass is a territory, and every
> territory is a drawn landmass.**

A bijection, in both directions. Stated as three instructions to whoever draws the map:

1. **Draw 42 shapes. Not 41, not 43, and not 60.**
2. **Draw no island that is not a territory** — at any zoom, in any decoration layer, at any opacity.
3. **Draw no territory as more than one shape.** An archipelago territory is simplified into a
   single silhouette.

### Why this is a correctness rule and not an aesthetic one

A landmass drawn on the board looks tappable. If it is not a territory it can never be tapped, never
be owned, never be attacked and never appear in a legal-action list — so every one of them is a
promise the interface cannot keep. The player's model of the board must be exactly the engine's
model of the board, and the engine's model has 42 entries.

It is also the cheapest thing on the board to verify: **count the shapes**.

### The seven island territories are kept

They are islands, and they are also territories, so rule 1 keeps them and rule 2 does not touch them:

| Territory | Continent | Anchor | Drawn as |
|---|---|---|---|
| `greenland` | NA | 430, 90 | one landmass |
| `iceland` | EU | 560, 150 | one landmass |
| `great_britain` | EU | 570, 250 | **one** landmass — the British Isles simplified into a single mass, Ireland folded in |
| `madagascar` | AF | 870, 690 | one landmass |
| `japan` | AS | 1330, 280 | **one** landmass — the four main islands simplified into a single elongated mass |
| `indonesia` | AU | 1230, 570 | **one** landmass — Sumatra / Java / Borneo simplified into a single mass |
| `new_guinea` | AU | 1370, 560 | one landmass |

The three bolded rows are where rule 3 does real work. Japan drawn faithfully is four shapes;
Indonesia is dozens. Each must become one, because a player who taps Honshu and gets nothing has
found a bug in the artwork.

### The do-not-draw list

Non-territory islands that a cartographer will add by habit. None of these is a territory, so none
of them appears:

| Region | Omitted |
|---|---|
| Caribbean | Cuba, Hispaniola, Jamaica, Puerto Rico, Bahamas, Trinidad, the Lesser Antilles |
| Atlantic | Azores, Madeira, Canary Islands, Cape Verde, Bermuda, Falklands, South Georgia, Faroes |
| Arctic | Svalbard, Novaya Zemlya, Franz Josef Land, Severnaya Zemlya, New Siberian Islands, Wrangel, Baffin, Ellesmere, Victoria Island, the Aleutians |
| Mediterranean | Sicily, Sardinia, Corsica, Crete, Cyprus, Malta, the Balearics |
| Indian Ocean | Sri Lanka, Maldives, Andaman & Nicobar, Socotra, Seychelles, Mauritius, Réunion, Comoros |
| East Asia | Taiwan, Hainan, the Philippines, Sakhalin, the Kurils, the Ryukyus |
| Oceania | New Zealand, Tasmania, Fiji, New Caledonia, Vanuatu, the Solomons, the Bismarcks, Hawaii, every Pacific atoll |
| Polar | Antarctica |

### Offshore fragments of a territory

Some omitted islands are *geographically part of* a territory — Baffin Island belongs to the land
area of `northwest_territory`, Tasmania to `eastern_australia`, Sri Lanka to `india`. Rule 3 forbids
drawing them as separate shapes, so each is handled one of two ways:

- **folded in**, if it can join the silhouette without a visible isthmus at board scale; or
- **dropped**.

Never drawn detached. A detached fragment in a seat's colour implies a second clickable region that
does not exist, which is the same lie as rule 2 forbids, wearing a legitimate owner's colour.

---

## 3.4 Layer stack

Bottom to top. A client that builds these eleven layers in this order gets both renderers.

| # | Layer | Content | Notes |
|---|---|---|---|
| L0 | Backdrop | `bg-canvas` | Fills the letterbox outside 16 : 9 |
| L1 | Ocean | `bg-ocean` | Flat. Not a continent colour, not animated |
| L2 | Continent grouping | Continent outline, 3 px, continent colour @ 70 % | **The only place a continent colour touches the board** (UX-04) |
| L3 | Territory bodies | `TerritoryShape` — fill = owner's `seat-n` + that seat's pattern @ 18 % | Circle in debug mode (Ø 44 canvas px), polygon in artwork mode |
| L4 | Territory borders | 1.5 px `border-strong`; 3 px continent colour where the border is a continent boundary | |
| L5 | Land adjacency | The 83 land edges, 1.5 px `border-strong` @ 45 % | **Debug renderer: always. Artwork renderer: off** — shared borders imply adjacency once shapes exist. An "adjacency overlay" toggle turns it back on, and S-20 remembers the setting |
| L6 | Land-across-water | The **10** `crossesWater` edges, **dashed** 2 px | Drawn in **both** renderers, always, never toggled off — see §3.6 |
| L7 | Sea routes | Per-match, from `state.seaRoutes[]`, 2.5 px dotted wave in `info` | 2–10 of them; frozen at match creation |
| L8 | Highlight | Legal-target wash, selected origin, in-range rings, distance badges | Entirely driven by the legal list — §3.7 |
| L9 | Army badges | `ArmyBadge` pinned to `label` | UX-10 — §3.5 |
| L10 | Labels | Territory name | Visibility rules in §3.11 |
| L11 | Transient | Dice tray tether, loss floaters, conquest flash, arrows | Never blocks input |

L5 and L6 is the pairing that is easy to get wrong. Land adjacency is implied by shared borders once
real shapes exist, so L5 can be hidden. The ten `crossesWater` adjacencies are **not** implied by
anything — `alaska` and `kamchatka` do not share a border — so L6 must always be visible or the
player cannot see a third of the board's strategic structure.

---

## 3.5 Army badges (UX-10)

Pinned to the territory's `label` anchor. Not centred in the polygon, not free text.

| Property | Value |
|---|---|
| Shape | `radius-full` pill, min 24 × 24 px, grows with digit count |
| Fill | owner's `seat-n` at full strength |
| Text | `type-num`, white or `#1a1d21` by contrast, **tabular** |
| Border | 2 px `bg-surface` — keeps it legible against any seat colour and over any edge |
| Position | anchored at `label`, with collision avoidance (§3.11) |
| `changed` state | one 200 ms pulse after `StateChanged` alters the count, with a `+n` / `−n` floater on L11 |

The map file documents `label` as *"an approximate anchor for the debug board view and for the
army-count badge"*. Honouring that is what lets Phase 12 replace every shape without moving a
single number — the badge is positioned by data, not by artwork.

The badge is also the only place an army count appears on the board. Armies are **identical and
anonymous** — capability is a property of the seat, not of the armies — so there is nothing to draw
per-army and no unit icon to design. A territory holding 41 armies and one holding 1 differ by a
numeral.

---

## 3.6 The ten `crossesWater` edges (UX-08)

```
alaska ↔ kamchatka            greenland ↔ iceland
central_america ↔ venezuela   brazil ↔ north_africa
western_europe ↔ north_africa southern_europe ↔ egypt
east_africa ↔ middle_east     siam ↔ indonesia
kamchatka ↔ japan             mongolia ↔ japan
```

| What it is | What it is **not** |
|---|---|
| A **render hint**: this adjacency crosses water, so draw it so a player can see it | A sea route |
| A **subset of `neighbours`** — every one is an ordinary land edge | A separate edge type |
| **Mechanically meaningless** — the engine never reads it | Naval-only, capability-gated, or in any way restricted |

So: dashed line, and a legend entry reading **"land border across water"**. Never the words
"sea route", never the ship icon, never `info` blue — all three belong to L7.

This matters because the error is one-directional and expensive. A player who believes
`brazil ↔ north_africa` needs Naval Force will never attack across it, will mis-read Africa as safe,
and will conclude the game is broken when an opponent walks through. The two must be
*unmistakably* different: **dashed grey line** (land, across water) versus **dotted blue wave with
a ship badge** (sea route, needs Naval capability).

| | L6 land-across-water | L7 sea route |
|---|---|---|
| Count | Exactly 10, fixed | 2–10, chosen at setup, endpoints generated |
| Source | `map.crossesWater` | `state.seaRoutes[]` |
| Style | dashed, 2 px, `border-strong` | dotted wave, 2.5 px, `info` |
| Badge | none | ship glyph at midpoint |
| Needs a capability | **No** | **Yes** — NavalForce |
| Counts as an attack range step | **Yes** — it is a land edge | **No** — excluded structurally (C-08) |

---

## 3.7 Territory states

Every state below is derived from the server. None is computed from a rule.

| State | Source | Rendering |
|---|---|---|
| **Inert** | not in the legal list | normal fill, no outline, pointer-events off |
| **Owned by me** | `territories[k].ownerSeat == seat` | `seat-n` fill + pattern |
| **Legal target** | appears as a `to` in `GET /legal` | `legal-dim` wash + 2 px `legal` outline |
| **Legal origin** | appears as a `from` in `GET /legal` | 2 px `legal` outline, no wash |
| **Selected origin** | local UI state | 3 px `accent` outline + `elev-2` lift |
| **In range, not legal** | reachable, but not a legal target (e.g. my own territory inside the range) | 1 px `accent` dashed outline, distance badge, **still inert** |
| **Hover / focus** | local | `focus-ring` |
| **Just conquered** | `StateChanged` after an `Occupy` | 320 ms flash to the new owner's colour |
| **Contested** | a `DiceRolled` event names it | pulsing `danger` outline for the duration of the roll |

"In range, not legal" is the state that keeps the board honest once `attackRange > 1`. A territory
can be within reach and still not be attackable — because you own it, or because the origin has too
few armies. Showing reach and legality as **different outlines** means the player can see the
geometry of their range without the board claiming they may act on all of it. FR-66 governs the
second channel: inert is inert, whatever outline it wears.

---

## 3.8 Range display (UX-07)

One component, `RangeReadout`, used by both callers. It answers *"which territories are reachable
from here, and how far is each"* and is parameterised only by the bound it is handed.

| Caller | Bound | Screen |
|---|---|---|
| Land attack | `state.options.attackRange` — **1 by default** | S-11 |
| Air Force attack | `rules.airForce.maxRange` = 5 | S-12 |

Both search the **land graph only**; a sea route is never a range step at any range (C-08). Both get
their reachable set from the server's legal list, not from a local search — the client has no graph
search in it at all (FR-67).

### At the default, there is nothing to draw

`attackRange = 1` is exactly adjacency. The legal list contains neighbours, the board highlights
neighbours, and no ring, arc or distance badge appears. **The default board is the classic RISK
board.** The range affordances below switch on only when a match was created with a larger range,
which is how a feature added after the rules were locked stays invisible until asked for.

### Above the default

| Affordance | Rendering |
|---|---|
| Reach rings | Concentric arcs from the selected origin, one per distance step, `accent` @ 25 %, dashed |
| Distance badge | Small numeral at each reachable territory's anchor — `2`, `3`, … — offset from the army badge, `type-label` |
| Range chip | In the action bar: *"Attack range 3"*, with the concentric-arcs icon |
| Path | **None.** No route is drawn, because no route is chosen — see below |

### Two things the board must not imply

**No path is traversed.** A range-3 attack is not a march through two intermediate territories. It
is one attack, resolved by one combat, between an origin and a target that happen to be three land
edges apart. Intervening ownership is **not consulted** — an enemy wall does not block it, and a
friendly corridor is not required. Drawing a route would assert a rule the engine does not have.

**Reach is not legality.** See the "in range, not legal" row in §3.7.

### What distinguishes the Air Force once range is configurable

Worth stating on the board's legend, because players will ask. With `attackRange` tunable, the Air
Force is set apart by exactly **two** things:

1. `airForce.attacksPerTurn: 1` — a separate, once-per-turn attack budget;
2. it requires the AirForce capability.

At `attackRange ≥ 5` it confers **no extra reach whatsoever** — the land attack already reaches
everything range 5 reaches. So S-12's value at high ranges is the second attack, not the distance,
and its copy says so: *"A second attack this turn, ignoring your land-attack budget."*

### Reach on the classic board, for sizing the affordance

Ordered pairs reachable out of 1722, measured on the 42-territory land graph (diameter 10):

| Range | Pairs | % |
|---|---|---|
| 1 | 166 | 9.6 % |
| 2 | 394 | 22.9 % |
| 3 | 676 | 39.3 % |
| 4 | 996 | 57.8 % |
| **5** | **1330** | **77.2 %** |
| 6 | 1554 | 90.2 % |
| 7 | 1650 | 95.8 % |
| 8 | 1692 | 98.3 % |
| 9 | 1716 | 99.7 % |
| 10 | 1722 | 100 % |

Design consequence: at range 5 a single origin can reach up to **40** of the other 41 territories
(`ukraine`); the worst origin reaches 11 (`eastern_australia`); the mean is 31.7. So the distance-badge
layer must stay readable with **40 badges on screen at once**. That is why the badge is a bare
numeral in `type-label` and not a pill, and why §3.11's declutter rules apply to it before they
apply to names.

---

## 3.9 The debug renderer, specified (UX-09)

Not a placeholder — the board for Phases 1 through 11, and therefore specified rather than improvised.

| Element | Spec |
|---|---|
| Territory | Circle, Ø **44** canvas px, centred on `label` |
| Fill | owner's `seat-n` + pattern @ 18 %; unowned during Claim = `bg-surface` with `border-strong` |
| Border | 2 px; continent colour where it is a continent boundary |
| Label | 3-letter key abbreviation inside the circle at `type-label`; full name on hover / long-press |
| Army badge | `ArmyBadge` at the lower-right of the circle, overlapping by 25 % |
| Land edge | all 83, straight, 1.5 px `border-strong` @ 45 % |
| Across-water edge | the 10, dashed, 2 px, drawn over land edges |
| Sea route | from `state.seaRoutes[]`, dotted wave, `info`, ship badge at midpoint |
| Continent | convex hull of the continent's anchors, 3 px continent outline @ 70 %, inflated by 32 px, plus a name + bonus chip |
| Ocean | `bg-ocean` fill of the whole canvas |

A circle of Ø 44 against a closest-anchor gap of 89.4 px leaves a 45 px channel between the two
tightest neighbours at full scale — tight but non-overlapping, which is why 44 is the number.

Every interaction in §3.7, §3.8 and §3.11 works identically here. Phase 12 changes one line: the
geometry `TerritoryShape` draws.

---

## 3.10 Desktop layout (≥ 1024 px)

```
┌───────────────────────────────────────────────────────────────────────────────┐
│ PhaseBar   Round 12 · ATTACK · Seat 0 Commander          [⚙]  [Capability ▸]  │  56 px
├──────────────┬────────────────────────────────────────────┬───────────────────┤
│              │                                            │                   │
│  SEAT LIST   │                  B O A R D                 │   CARD HAND       │
│              │                                            │                   │
│  SeatChip ×n │   16:9, fit-to-region, pan + zoom          │   GameCard ×n     │
│  territory   │   L0…L11                                    │   set highlight   │
│  + army      │                                            │   next value: 12  │
│  counts      │   legend, bottom-left, collapsible          │                   │
│              │                                            │  ─────────────    │
│  ─────────   │                                            │   EVENT LOG       │
│  CONTINENT   │                                            │   newest first    │
│  BONUSES     │                                            │                   │
│              │                                            │                   │
│   240 px     │                  flexible                  │      300 px       │
├──────────────┴────────────────────────────────────────────┴───────────────────┤
│ ACTION BAR   origin → target · dice ▣▣▣ · odds 66 % · [Attack]  [End phase ▸] │  72 px
└───────────────────────────────────────────────────────────────────────────────┘
```

- Side panels sit **over the ocean margins** — that is what the 110 px / 180 px anchor margins buy.
- The board region keeps 16 : 9 and letterboxes; it never stretches.
- At ≥ 1440 px the panels widen to 280 / 340 px; the board grows with the window.
- The legend is collapsible but **defaults to open**, because §3.6's dashed-versus-dotted
  distinction is learned from it.

---

## 3.11 Mobile layout (< 768 px, down to 360 px)

The board is full-bleed; every panel is a `BottomSheet`.

```
┌─────────────────────────┐   ┌─────────────────────────┐
│ R12 · ATTACK · Seat 0 ⚙ │   │ R12 · ATTACK · Seat 0 ⚙ │  44 px
├─────────────────────────┤   ├─────────────────────────┤
│                         │   │                         │
│                         │   │        B O A R D        │
│       B O A R D         │   │       (compressed)      │
│      full-bleed         │   │                         │
│      pan + zoom         │   ├─────────────────────────┤
│                         │   │ ═══ grab ═══            │
│                         │   │ KAMCHATKA → ALASKA      │
│                         │   │ 5 armies  vs  1         │
│                         │   │ Dice  ① ② ③   odds 66 % │
│                         │   │ [ ATTACK ]              │
├─────────────────────────┤   │ ▸ Other targets (4)     │
│ ═══ peek ═══  ATTACK    │   └─────────────────────────┘
│ [Cards 3] [Seats] [▸]   │        sheet at HALF
└─────────────────────────┘
      sheet at PEEK
```

| Sheet state | Height | Holds |
|---|---|---|
| **Peek** | 96 px | Phase, the primary action, three tabs. Board fully visible |
| **Half** | 50 % | Active action panel — attack, draft, fortify, occupy |
| **Full** | 92 % | Card hand, seat list, capability panel, settings, event log |

### Selection below 859 px — the two modes

§3.2 established that compliant touch targets need a viewport ≥ 859 px. Below that the board offers
**two** ways to select, and both are always available:

**1 · Direct touch, with an anchor hit radius.** Hit-testing is point-in-polygon (point-in-circle in
debug mode) **unioned with a 22 px radius around the anchor**, so a near-miss still lands. When two
candidates are both within the radius — which at fit-to-width zoom is routine in Asia, North America
and Europe — no guess is made: a **disambiguation popover** opens listing the candidates by name,
each row `control-h-lg` tall. Two taps, never a wrong one.

**2 · The territory list.** The bottom sheet's active panel always carries the same choice as a
list — *"Other targets (4)"* in the sketch above — grouped by continent, each row showing name,
owner chip, army count and, when `attackRange > 1`, distance. Every row is `control-h-lg`.

The list is not a fallback for an awkward board; it is the **primary** path on a phone, and the
board is primarily a display. That inversion is deliberate: a player who prefers tapping the map can
pinch in and do so, and a player who does not never has to fight a 20 px gap.

### Zoom

| | |
|---|---|
| Fit-to-width | the default; the whole 16 : 9 board visible |
| Min scale | fit-to-width (never smaller — there is nothing outside the board to see) |
| Max scale | 3.5 × fit |
| **Tactical threshold** | **0.537 of design scale.** At or above it, direct touch meets 48 px and the disambiguation popover stops appearing. A small chip reads *"tap-to-select"* when crossed |
| Gestures | one-finger pan, two-finger pinch, double-tap to zoom to the tapped territory, two-finger double-tap to fit |
| Auto-frame | on `TurnChanged` to my seat, and on entering Occupy, the board eases to frame the relevant territories — skippable by any touch |

### Declutter, in order

Applied in this order as scale falls, so the information that survives longest is the information
the player needs:

| Scale | Territory names | Distance badges | Army badges | Edge lines |
|---|---|---|---|---|
| ≥ 0.80 | all | all | all | all |
| 0.54 – 0.80 | on tap / selection only | all | all | all |
| 0.34 – 0.54 | hidden | selected origin's only | all | all |
| < 0.34 | hidden | selected origin's only | **all — never dropped** | across-water + sea routes only |

**The army badge is never decluttered.** It is the board's only quantitative content, and a board
without it answers no question a player has. Names are recoverable by tapping; a missing army count
is not.

---

## 3.12 Interaction by phase

| Phase | Legal origins | Legal targets | Board affordance |
|---|---|---|---|
| **Claim** | — | every unowned territory | Unowned = `legal` wash. One tap claims. Seat order chip shows who is next |
| **Draft** | — | my territories | `legal` outline on mine. Tap adds one army; long-press / stepper adds many. Army pool in the action bar, continent-bonus breakdown in the sheet |
| **Attack** | mine with ≥ 2 armies **and** a reachable enemy | enemy territories within `options.attackRange`, plus air and naval targets | Tap origin → origin selects, targets light up, reach rings appear if range > 1. Tap target → the attack panel opens with the dice stepper and the server's `winChance` |
| **Occupy** | fixed — the attack's origin | fixed — the captured territory | Both highlighted, everything else inert. A stepper chooses the move-in count between `minArmies` (= dice rolled) and `maxArmies`. **This phase cannot be skipped** |
| **Fortify** | mine with ≥ 2 armies | per `fortify.mode` — `single_pair` by default | One fortification per turn (naval fortification consumes the same one). After it, the action bar offers only End turn |
| **EndTurn / hand-over** | — | — | Board **blanked** behind the hand-over screen before any incoming state is requested (FR-64, TC-UI-03) |
| **GameOver** | — | — | Final ownership, no interaction, standings sheet over it |

---

## 3.13 Accessibility on the board

| Concern | Measure |
|---|---|
| Colour vision | Ownership is colour **and** pattern **and**, in every list, a glyph (UX-03). The board is verified in greyscale |
| Edge types | Dashed vs dotted-wave differ in **dash pattern, weight, colour and badge** — four channels, so none of them is load-bearing alone |
| Legend | Always reachable; defaults open on desktop, one tap on mobile |
| Focus | Full keyboard traversal: `Tab` cycles legal origins, arrows cycle that origin's legal targets, `Enter` commits, `Esc` deselects. `focus-ring` always visible |
| Screen reader | Each territory announces *"{name}, {continent}, {owner}, {armies} armies"*, then *"legal target, distance 3"* when applicable |
| Reduced motion | Auto-frame, conquest flash and army march become cuts or cross-fades. Dice faces never change (§04.5) |
| Text scaling | At 200 % the army badge grows and names declutter one step earlier; no number is ever clipped |

---

## 3.14 The 42 anchors

`label` is the badge anchor and the debug-renderer centre (UX-10). `Across water` lists that
territory's `crossesWater` neighbours — ordinary land edges drawn dashed (UX-08).

| Key | Name | Cont. | `label` x, y | Coastal | Card symbol | Nbrs | Across water |
|---|---|---|---|---|---|---|---|
| `alaska` | Alaska | NA | 110, 130 | yes | Cavalry | 3 | `kamchatka` |
| `northwest_territory` | Northwest Territory | NA | 250, 130 | yes | Infantry | 4 | – |
| `greenland` | Greenland | NA | 430, 90 | yes | Artillery | 4 | `iceland` |
| `alberta` | Alberta | NA | 230, 220 | **no** | Infantry | 4 | – |
| `ontario` | Ontario | NA | 330, 220 | **no** | Cavalry | 6 | – |
| `quebec` | Quebec | NA | 430, 220 | yes | Artillery | 3 | – |
| `western_united_states` | Western United States | NA | 230, 320 | yes | AirForce | 4 | – |
| `eastern_united_states` | Eastern United States | NA | 350, 330 | yes | Infantry | 4 | – |
| `central_america` | Central America | NA | 260, 420 | yes | NavalForce | 3 | `venezuela` |
| `venezuela` | Venezuela | SA | 330, 510 | yes | Infantry | 3 | `central_america` |
| `peru` | Peru | SA | 330, 620 | yes | AirForce | 3 | – |
| `brazil` | Brazil | SA | 440, 600 | yes | NavalForce | 4 | `north_africa` |
| `argentina` | Argentina | SA | 360, 740 | yes | Cavalry | 2 | – |
| `iceland` | Iceland | EU | 560, 150 | yes | Infantry | 3 | `greenland` |
| `great_britain` | Great Britain | EU | 570, 250 | yes | NavalForce | 4 | – |
| `scandinavia` | Scandinavia | EU | 690, 130 | yes | Cavalry | 4 | – |
| `northern_europe` | Northern Europe | EU | 700, 240 | **no** | Artillery | 5 | – |
| `western_europe` | Western Europe | EU | 620, 340 | yes | Infantry | 4 | `north_africa` |
| `southern_europe` | Southern Europe | EU | 730, 330 | yes | AirForce | 6 | `egypt` |
| `ukraine` | Ukraine | EU | 830, 200 | **no** | Cavalry | 6 | – |
| `north_africa` | North Africa | AF | 650, 470 | yes | AirForce | 6 | `brazil`, `western_europe` |
| `egypt` | Egypt | AF | 760, 470 | yes | Infantry | 4 | `southern_europe` |
| `east_africa` | East Africa | AF | 820, 560 | yes | NavalForce | 6 | `middle_east` |
| `congo` | Congo | AF | 730, 590 | yes | Cavalry | 3 | – |
| `south_africa` | South Africa | AF | 750, 700 | yes | Artillery | 3 | – |
| `madagascar` | Madagascar | AF | 870, 690 | yes | Infantry | 2 | – |
| `ural` | Ural | AS | 930, 150 | yes | Cavalry | 4 | – |
| `siberia` | Siberia | AS | 1030, 120 | yes | Infantry | 5 | – |
| `yakutsk` | Yakutsk | AS | 1150, 110 | yes | Artillery | 3 | – |
| `kamchatka` | Kamchatka | AS | 1290, 140 | yes | Cavalry | 5 | `japan`, `alaska` |
| `irkutsk` | Irkutsk | AS | 1120, 200 | **no** | Infantry | 4 | – |
| `mongolia` | Mongolia | AS | 1160, 280 | yes | Artillery | 5 | `japan` |
| `japan` | Japan | AS | 1330, 280 | yes | NavalForce | 2 | `kamchatka`, `mongolia` |
| `afghanistan` | Afghanistan | AS | 960, 270 | **no** | Cavalry | 5 | – |
| `china` | China | AS | 1120, 360 | yes | AirForce | 6 | – |
| `middle_east` | Middle East | AS | 900, 400 | yes | AirForce | 6 | `east_africa` |
| `india` | India | AS | 1020, 430 | yes | Infantry | 4 | – |
| `siam` | Siam | AS | 1180, 450 | yes | Artillery | 3 | `indonesia` |
| `indonesia` | Indonesia | AU | 1230, 570 | yes | Cavalry | 3 | `siam` |
| `new_guinea` | New Guinea | AU | 1370, 560 | yes | Infantry | 3 | – |
| `western_australia` | Western Australia | AU | 1290, 700 | yes | Artillery | 3 | – |
| `eastern_australia` | Eastern Australia | AU | 1420, 690 | yes | AirForce | 2 | – |

The six **no** rows are the landlocked territories. They can never be a sea-route endpoint, never
hold NavalForce from geography, and never show the ship badge. They are a legitimate place for an
interface to go wrong, which is why they are called out rather than left to be inferred from a
boolean.

The `cardSymbol` column is on the board's side because of CAP-1:
`profile(t) = {Infantry} ∪ ({NavalForce} if coastal) ∪ {cardSymbol}`. A territory's own symbol is
what grants its owner a capability, so the capability panel (S-16) traces every held capability back
to a row in this table or to a card in hand.

---

## 3.15 Design acceptance checks

Verified by inspection during Phase 8 (debug renderer) and Phase 12 (artwork). These are **not**
additions to the 119-case catalogue in `../appendices/F-test-cases.md` — TC-UI-01 already covers
screen presence and reachability, and TC-UI-02 covers the FR-66 affordance rule. They are an asset
review checklist.

| # | Check | Rule |
|---|---|---|
| DA-01 | The artwork contains **exactly 42** closed territory shapes | UX-01 |
| DA-02 | Every shape maps to a `key` in `world_classic.json`, and every `key` has a shape | UX-01 |
| DA-03 | No territory is drawn as two or more shapes — Japan, Indonesia and Great Britain especially | UX-01 rule 3 |
| DA-04 | No island from §3.3's do-not-draw list appears at any zoom or opacity | UX-01 rule 2 |
| DA-05 | No continent colour appears as a territory fill | UX-04 |
| DA-06 | All ten `crossesWater` edges are drawn dashed, in both renderers, and are not toggleable | UX-08 |
| DA-07 | No `crossesWater` edge carries the ship badge, `info` blue, or the words "sea route" | UX-08 |
| DA-08 | The board is readable in greyscale: every seat remains distinguishable | UX-03 |
| DA-09 | Army badges sit at `label` and survive every declutter level | UX-10, §3.11 |
| DA-10 | At `attackRange = 1` no ring, arc or distance badge is rendered | §3.8 |
| DA-11 | 40 distance badges render simultaneously without overlap at ≥ 0.80 scale | §3.8 |
| DA-12 | At < 859 px viewport, the disambiguation popover appears for every ambiguous tap, and the territory list offers every choice the board does | §3.11 |
| DA-13 | The six landlocked territories never show a ship badge or a sea-route endpoint | §3.14 |
| DA-14 | The board is blank behind the hand-over screen before any incoming state is requested | §3.12, TC-UI-03 |

---

[← 02 Screen inventory and flows](02-screen-inventory-and-flows.md) · [04 Dice UI/UX →](04-dice-ui-ux.md)
