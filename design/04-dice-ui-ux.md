# 04 · Dice UI/UX

**Binding filename.** Cited from `../appendices/E-pseudocode.md` §E.6,
`../docs/00-decisions-and-assumptions.md` (D-29) and `../docs/07-game-design.md`. Do not rename
without updating those citations.

This document exists because of one supervisory question: *can the die have a face count other
than 6 — say 7?* The engine answer is **yes**, landed as **D-29 / FR-84**: `combat.diceSides`
defaults to 6, is settable from **2 to 20**, and is frozen into the match at creation. This file is
the interface half of that answer, and it is written so a d7 can be **demonstrated working** rather
than asserted.

---

## 4.1 The renderer contract

> **The dice renderer is handed a face count and a list of values. It has no opinion about either.**

That one sentence is the whole design. Expanded:

```
RenderRoll(
    faces:          int,        // state.options.diceSides — 6 by default, 2…20
    attackerValues: int[],      // from the DiceRolled event, in draw order
    defenderValues: int[]       // from the DiceRolled event, in draw order
)
```

| The renderer is given | The renderer never |
|---|---|
| How many faces a die has | Decides how many faces a die has |
| Which value each die shows | Generates, draws, re-rolls or adjusts a value |
| Which side won each pair | Compares values to decide who won |
| How many armies each side lost | Computes a loss |

The second column is **FR-69** (*animate dice from the `DiceRolled` event rather than computing an
outcome*) and **FR-67** (*no client shall implement combat … logic*). A client that honours it needs
**no change whatsoever** to support a d7, a d2 or a d20 — which is exactly why this was cheap enough
to accept after the rules were locked.

### What arrives

`DiceRolled`, pushed over `/hubs/match` to every seat (`../appendices/A-api-contract.md` §A.9):

```jsonc
{ "type": "DiceRolled", "from": "kamchatka", "to": "alaska",
  "attacker": [6, 4, 3], "defender": [6, 2],
  "attackerLosses": 1, "defenderLosses": 1 }
```

Face count is **not** in the event — it is in `state.options.diceSides`, frozen at match creation
and constant for the match's life. The renderer reads it once when it joins and caches it.

### Draw order is specification, not presentation

The event lists **all attacker dice first in index order, then all defender dice**. That is the
order the seeded random source produced them, and the replay viewer (S-19) steps through the log
expecting it. So the settle animation (§4.5) reveals dice in exactly that order and may not reorder
them for visual balance — even though the *comparison* in §4.4 sorts descending.

Two orders, both visible, doing different jobs: **draw order** is the audit trail, **sorted order**
is the rule.

---

## 4.2 The die token

One geometry for every face count.

| Property | Value |
|---|---|
| Shape | Rounded square, `radius-md` |
| Size | **44 × 44** px desktop, **48 × 48** px mobile |
| Fill | `bg-surface-raised`, 1 px `border-strong` |
| Elevation | `elev-1` idle, `elev-2` rolling |
| Attacker tint | 2 px top border in the attacking seat's `seat-n` |
| Defender tint | 2 px top border in the defending seat's `seat-n` |
| Gap | `space-2` within a row, `space-5` between the two rows |

### Why not a polyhedron

A cube face is a square, so a d6 drawn as a square is honest. There is no regular polyhedron with 7
faces, and building a credible 3D die for each of 19 possible face counts is an unbounded art task
that would make a d7 look like a different *kind* of object from a d6. It is not — it is the same
object with a different `N`.

So: one token shape, always. The face count is communicated by the **values that appear on it** and
by the match-setup summary, never by the silhouette.

---

## 4.3 Pips or numerals (UX-06)

> **Presentation mode is a property of the match, not of the die.**

```
mode = (state.options.diceSides <= 6) ? Pips : Numerals
```

| `diceSides` | Mode | Every die in the match shows |
|---|---|---|
| 2, 3, 4, 5, **6** | **Pips** | A pip pattern |
| **7**, 8 … 20 | **Numerals** | A numeral in `type-num-lg`, tabular |

The alternative — pips for 1–6 and a numeral only for 7 — was rejected deliberately. It would make
the seventh face look like a critical hit, a jackpot, *something*. It is none of those things; it is
one face of a seven-faced die, exactly as likely as the other six. Encoding it differently would
teach the player a rule that does not exist.

So at `diceSides = 7` all seven faces are numerals, including the 1 through 6. Consistency inside a
match beats familiarity across matches.

### Pip layouts

A 3 × 3 grid inside the token, pip Ø 7 px desktop / 8 px mobile, `text-primary`:

```
      1            2            3            4            5            6
   ·  ·  ·      ●  ·  ·      ●  ·  ·      ●  ·  ●      ●  ·  ●      ●  ·  ●
   ·  ●  ·      ·  ·  ·      ·  ●  ·      ·  ·  ·      ·  ●  ·      ●  ·  ●
   ·  ·  ·      ·  ·  ●      ·  ·  ●      ●  ·  ●      ●  ·  ●      ●  ·  ●
```

| Value | Grid cells |
|---|---|
| 1 | centre |
| 2 | top-left, bottom-right |
| 3 | top-left, centre, bottom-right |
| 4 | four corners |
| 5 | four corners + centre |
| 6 | both outer columns, all three rows |

Standard western die faces, so a d6 looks like a d6. At `diceSides` 2 through 5 the same layouts are
used for the values that occur — a d4 shows only 1, 2, 3 and 4, and nothing about the token says the
missing patterns exist.

### Numeral mode

| Property | Value |
|---|---|
| Type | `type-num-lg`, 700, **tabular** |
| Range | up to `20` — two digits must fit; at two digits the size steps down to 24 / 28 |
| Alignment | optically centred, which for tabular figures means true centre |
| Face-count badge | A small `d7` / `d20` chip on the dice tray header, `type-label`, so a screenshot is self-describing |

The badge is the one concession to the unfamiliar. A reviewer looking at a screenshot of a 7 next to
a 4 should not have to wonder whether the 7 is a bug.

---

## 4.4 The dice tray

Where a roll is read. Up to **3 + 2 = 5** tokens, which is the maximum at any face count.

```
┌──────────────────────────────────────────────┐
│  KAMCHATKA  →  ALASKA                   d7   │   header, face-count badge
├──────────────────────────────────────────────┤
│  Attacker   ⟦6⟧ ⟦4⟧ ⟦3⟧                      │   draw order, attacker first
│  Defender   ⟦6⟧ ⟦2⟧                          │   draw order
├──────────────────────────────────────────────┤
│   6  ──┬──  6      TIE  →  defender holds    │   sorted descending, pairwise
│   4  ──┴──  2      attacker wins             │
│   3            unpaired, discarded           │
├──────────────────────────────────────────────┤
│  Attacker −1 army      Defender −1 army      │
└──────────────────────────────────────────────┘
```

Four regions, in this order, because it is the order the rule is applied:

| Region | Content | Source |
|---|---|---|
| Header | origin → target, face-count badge | the event + `options.diceSides` |
| Rolled | both rows in **draw order** | the event |
| Compared | both rows re-sorted **descending**, paired highest-with-highest; unpaired dice shown greyed and labelled *discarded* | the event, re-sorted locally — sorting is not a rule computation |
| Outcome | losses per side | the event's `attackerLosses` / `defenderLosses` |

### The tie row carries the game's most-misremembered rule

`defenderWinsTies: true` is described in `../shared/rules.json` as *"the single highest-risk flag in
this file"*. Players arrive believing otherwise. So a tie is never rendered as a quiet non-event:

- the pair's connector turns `danger`;
- the row is labelled **"TIE → defender holds"** in words, not a symbol;
- the defender's die keeps its full-strength border and the attacker's dims to `text-disabled`.

A comparison is strict `>`. Equal values are a defender win, every time, at every face count —
`diceSides` does not interact with the tie rule at all, because the rule compares two drawn values
and says nothing about their range.

### Unpaired dice

Attacker 3 vs defender 1 produces two unpaired attacker dice. They are shown — not hidden — greyed
and labelled *discarded*, because a player who rolled a 6 and lost needs to see that the 6 was never
in the comparison. Hiding them produces the single most common "this game is rigged" complaint.

---

## 4.5 Choreography

Total ≈ **1.1 s**, fully skippable by the next tap, and scaled by the S-20 animation-speed control.

| Window | What happens |
|---|---|
| 0 – 120 ms | Tray slides up to `elev-2`; both rows render as blank tokens |
| 120 – 520 ms | **Tumble.** Each token cycles through faces `1 … diceSides` at 60 ms per face |
| 520 – 640 ms | **Settle.** Tokens ease to their final values, staggered 40 ms apart, **in draw order** — all attacker dice in index order, then all defender dice |
| 640 – 900 ms | **Compare.** The sorted rows animate into alignment; connectors draw; winners glow `legal`, losers `danger`; the tie label appears |
| 900 – 1100 ms | **Resolve.** Loss floaters rise from the affected territories on the board's L11; army badges pulse |

### The tumble contains no random numbers

The cycle is a **deterministic sweep** of `1 … diceSides`, offset per die by its index. It is not a
local random draw.

This is a deliberate, slightly fussy choice, and the reason is worth keeping: it means **no client
contains a random source at all.** Not one that is unused, not one that is only decorative, not one
behind a flag. There is nothing for a later refactor to accidentally promote into a game outcome,
and nothing a reviewer has to read carefully to be sure of. FR-69 becomes verifiable by the absence
of an import rather than by reading an animation.

It also happens to look better: a sweep reads as a spinning die, whereas random flicker reads as a
loading state.

### Reduced motion

`prefers-reduced-motion`, or S-20's fastest animation setting, collapses the sequence to:

1. tray appears — cut, no slide;
2. final faces appear — **cut, no tumble**;
3. comparison and losses appear after 150 ms.

The faces are identical. They come from the event (FR-69), so no accessibility setting can change
what the dice show — only how long it takes to show it.

---

## 4.6 The odds readout

`OddsReadout` shows **`winChance` from the server**. The client computes nothing.

`GET /api/matches/{id}/legal?seat=n` returns it on every attack action
(`../appendices/A-api-contract.md` §A.7):

```jsonc
{ "type": "Attack",     "from": "kamchatka", "to": "alaska",  "maxDice": 3, "winChance": 0.662 },
{ "type": "AirAttack",  "from": "peru",      "to": "egypt",   "maxDice": 3, "winChance": 0.470, "range": 4 }
```

| Property | Value |
|---|---|
| Primary | Percentage, no decimal — **66 %** |
| Secondary | A horizontal bar, `legal` fill, `border-subtle` track |
| Detail | Long-press / hover reveals the full value — `0.662` — and the dice counts it assumes |
| Updates | Live, as the attacker's dice stepper moves — each dice count is a separate legal action with its own `winChance` |
| Empty | While `GET /legal` is in flight: `Skeleton`, never a stale or placeholder number |

### Why this single field is the whole d7 story on the client side

At `diceSides = 6` a 3 vs 1 attack has `winChance` 0.6597. At `diceSides = 7` the same attack has
0.6735. **The server sends a different number and the client renders it.** No table is shipped, no
formula is embedded, no branch on face count exists anywhere in the UI.

That is the practical demonstration the supervisor's question deserves: changing the dice changes
the odds the player sees, through a field that was already there.

---

## 4.7 Reference odds — documentation, not implementation

For the setup screen's help panel and for the report. **Nothing in a client may compute these.**

| Matchup | d6 | d6 decimal | d7 | d7 decimal | Change |
|---|---|---|---|---|---|
| 1 vs 1 | 15/36 | 0.4167 | 21/49 | 0.4286 | **+1.19 pp** |
| 2 vs 1 | 125/216 | 0.5787 | 203/343 | 0.5918 | **+1.31 pp** |
| 3 vs 1 | 855/1296 | 0.6597 | 1617/2401 | 0.6735 | **+1.37 pp** |
| 1 vs 2 | 55/216 | 0.2546 | 91/343 | 0.2653 | **+1.07 pp** |
| 3 vs 2 | 2890/7776 | 0.3717 | 6559/16807 | 0.3903 | **+1.86 pp** |

Every denominator is `N^(a+d)` — 36 is 6², 216 is 6³, 1296 is 6⁴, 7776 is 6⁵. The five published
d6 fractions are simply the `N = 6` instance of exhaustive enumeration, which is why no new oracle
machinery was needed to support any other face count.

### The 1 vs 1 closed form

$$P(\text{attacker wins, 1v1}) = \frac{N-1}{2N}$$

| N | 2 | 4 | **6** | **7** | 10 | 20 | → ∞ |
|---|---|---|---|---|---|---|---|
| P | 0.2500 | 0.3750 | **0.4167** | **0.4286** | 0.4500 | 0.4750 | → 0.5 |

### Every figure moves in the attacker's favour, and that is derivable

The defender's advantage **is** the tie. `P(tie) = 1/N`, so as `N` rises ties become rarer and the
defender's edge shrinks — monotonically, approaching a coin flip from below but never reaching it.

Which means the direction of the effect needed no playtesting to discover:

- **more faces → weaker defender**;
- a d2 is the most defensive die possible (the attacker wins just 1 in 4 at 1 vs 1);
- a d20 is nearly fair;
- 6 is already close enough to the limit that the d6 → d7 change is about **one percentage point**
  per matchup — a real effect, and a small one.

Worth saying plainly in the help panel: raising the face count does **not** make combat swingier. It
makes it very slightly less defensive. Players assume the opposite.

---

## 4.8 Choosing the face count — match setup (S-04)

| Control | `Stepper` |
|---|---|
| Label | **Dice faces** |
| Range | 2 … 20, from `rules.combat.diceSidesMin` / `diceSidesMax` |
| Default | **6**, marked on the track as *"classic"* |
| Display | `d6`, `d7`, `d20` — plus a live preview of one token in the resulting mode |
| Helper text | *"More faces make ties rarer, which very slightly favours the attacker. 6 is the classic rule."* |
| Learn more | Opens §4.7's table as static copy |
| Frozen | Once the match is created this is immutable; S-04 says so, and every in-match surface shows it read-only |

### The setup screen must not compute odds

Tempting, and wrong. A live *"attacker wins 42.9 %"* readout under the stepper would be combat logic
in a client — exactly what FR-67 forbids — and it would be the only such computation in the entire
codebase, sitting in the one screen nobody re-reads.

The resolution: the helper text is **qualitative** (*"very slightly favours the attacker"*), and the
*quantitative* answer is the static reference table, which is documentation shipped as copy. Both are
accurate; neither is a calculation.

### It is frozen, and the UI must say so

`diceSides` is copied into `matches.options` at creation and read **only** from there. Editing
`shared/rules.json` mid-match must not change a match in progress, because the number of random
draws per roll is unchanged — so the random-source position would track the log perfectly while
every face differed, and a replay would diverge silently with every determinism test still passing.
**TC-PER-07** is the guard.

The interface consequence is small but mandatory: anywhere the face count appears in a running
match — dice tray badge, settings screen, replay viewer header — it is **read-only**, and the
settings screen explains why in one line: *"Fixed when the match was created."* No control anywhere
offers to change it, so no player can be led to expect that it would take effect.

---

## 4.9 Attacker and defender dice counts

| | |
|---|---|
| **Attacker** | Chosen by the player, 1 … 3, as a `Stepper` in the attack panel. Each count is a **separate legal action** with its own `winChance`, so the stepper's range comes from the legal list, not from a rule |
| **Defender** | **Derived by the engine.** The submitted action is `Attack(from, to, dice)` and carries only the attacker's count. The tray shows the defender's dice read-only, as the event reports them |

Constraints that limit the attacker's stepper — at least 2 armies in the origin, and strictly more
armies than dice rolled — are enforced server-side and surface simply as a shorter legal list. The
UI never re-derives them; a count that is not offered is a count that is not legal.

---

## 4.10 Accessibility

| Concern | Measure |
|---|---|
| Colour vision | Win / loss is **never** colour alone: the winner's connector is solid and labelled, the loser's dashed and dimmed, and the outcome is written in words |
| Pip legibility | Pip Ø 7 px at 44 px token; at 200 % text scaling the token grows to 64 px rather than the pips shrinking |
| Numeral legibility | `type-num-lg` tabular; two digits step the size down, never the token |
| Screen reader | The tray announces: *"Attacker rolled 6, 4, 3. Defender rolled 6, 2. Six against six, tie, defender holds. Four against two, attacker wins. Attacker loses 1 army, defender loses 1 army."* |
| Reduced motion | §4.5 — a cut to final faces, identical values |
| Non-visual play | Everything the tray shows is in the event, so the announcement is complete; nothing is conveyed by motion alone |

---

## 4.11 What a client must never do

| Never | Because |
|---|---|
| Generate a die face — including for the tumble | FR-69, §4.5. No client holds a random source |
| Compare two faces to decide a winner | FR-67. The event carries the losses |
| Compute `winChance` | FR-67, §4.6. `GET /legal` carries it |
| Hard-code `6` | FR-84, D-29. Read `state.options.diceSides` |
| Read `diceSides` from `shared/rules.json` during a match | §4.8, TC-PER-07. It is frozen in `matches.options` |
| Treat a face above 6 as special | UX-06, §4.3 |
| Reorder the rolled rows away from draw order | §4.1. S-19 replays in that order |
| Hide unpaired dice | §4.4 |
| Offer a control that changes the face count mid-match | §4.8 |

---

## 4.12 Design acceptance checks

Verified by inspection in Phase 8. Not additions to the 119-case catalogue — **TC-CMB-10** pins the
engine side of every face count, **TC-PER-07** pins the frozen-parameter rule, and **TC-UI-02**
already requires that dice animate from the event.

| # | Check | Rule |
|---|---|---|
| DA-15 | A match at `diceSides = 7` renders sevens, and a 7 is visually indistinguishable in kind from a 4 | UX-06 |
| DA-16 | A match at `diceSides = 20` renders two-digit numerals without clipping | §4.3 |
| DA-17 | A match at `diceSides = 2` renders pips and never a numeral | §4.3 |
| DA-18 | No client source file contains a random-number call on the dice path | §4.5, FR-69 |
| DA-19 | No client source file contains the literal `6` as a face count | §4.11, FR-84 |
| DA-20 | Every tie is labelled in words and visibly resolved to the defender | §4.4 |
| DA-21 | Unpaired attacker dice are visible and labelled *discarded* | §4.4 |
| DA-22 | Settle order matches the event's array order exactly | §4.1 |
| DA-23 | `winChance` is rendered, never computed — grep the client for an odds formula | §4.6, FR-67 |
| DA-24 | No in-match surface offers to change the face count | §4.8 |
| DA-25 | With reduced motion, the faces shown are identical to the animated path | §4.5 |

---

[← 03 Map UI/UX](03-map-ui-ux.md) · [05 Card UI/UX →](05-card-ui-ux.md)
