# 05 · Card UI/UX

Screen **S-10** — the hand, the sets, the escalating trade value, the forced trade. Plus the card's
second job, which is easy to miss: a card in hand **grants a capability**, so the hand is not only
an economy, it is part of what a seat can do.

---

## 5.1 The deck

| | |
|---|---|
| Size | **44** cards — 42 territory cards + 2 Wild |
| Territory card | names one territory and carries that territory's `cardSymbol` |
| Wild | carries the symbol `Wild`, names no territory |
| A set | **exactly three cards** (`cards.setSize: 3`) — locked; five-card sets are not introduced |

| Symbol | Count | Icon | Unlocks an action? |
|---|---|---|---|
| Infantry | **12** | helmet | no |
| Cavalry | **10** | horse | no |
| Artillery | **8** | cannon | no |
| **AirForce** | **7** | aircraft | **yes** — the Air Force attack |
| **NavalForce** | **5** | ship | **yes** — naval attack and naval fortification |
| Wild | **2** | star burst | no — a Wild has **no** capability profile (D-20) |

The counts are not decoration. They are the distribution of `cardSymbol` across the 42 territories
plus the two Wilds, so the hand's rarest card is also the rarest capability. A designer should let
that show: AirForce and NavalForce card faces carry the accent treatment in §5.2, because drawing
one is the interesting event.

---

## 5.2 The card face

```
┌───────────────────┐      ┌───────────────────┐      ┌───────────────────┐
│ ✈                 │      │ 🛡                 │      │        ✦          │
│                   │      │                   │      │                   │
│    [ aircraft ]   │      │    [ helmet ]     │      │   [ starburst ]   │
│                   │      │                   │      │                   │
│  NORTH AFRICA     │      │  ALASKA           │      │  WILD             │
│  Africa · AirForce│      │  N. America · Inf │      │  any symbol       │
└───────────────────┘      └───────────────────┘      └───────────────────┘
   action symbol              plain symbol               wild
```

| Region | Content | Token |
|---|---|---|
| Corner glyph | the symbol icon, 16 px | `text-secondary`, or `accent` for AirForce / NavalForce |
| Centre | the symbol icon, 40 px | same |
| Name | the territory name, or **WILD** | `type-h3` |
| Footer | continent name · symbol name | `type-body-sm`, `text-secondary`; the continent name carries a `Chip` in the continent colour (UX-04) |
| Size | 132 × 184 desktop · 112 × 156 mobile | `radius-md`, `elev-1` |
| Owned-territory marker | a small seat dot when the named territory is currently mine | drives the territory bonus, §5.5 |

| State | Rendering |
|---|---|
| Face-up | as above |
| **Face-down** | a uniform back — hatched in `border-subtle`, no symbol, no hint (§5.6) |
| Selected | 3 px `accent` outline, lifted 8 px, `elev-2` |
| **In a valid set** | 2 px `legal` outline + `legal-dim` wash |
| Disabled | 40 % opacity, pointer-events off |

The Wild's footer reads *"any symbol"* and the card appears in the hand, in sets, and in the trade
preview — but it **never** appears in the capability panel (S-16). A Wild has no profile, so a hand
of two Wilds grants nothing. An interface that listed a capability under a star burst would be
asserting a rule that does not exist (D-20).

---

## 5.3 Set highlighting comes from the server — this is the load-bearing decision

`GET /api/matches/{id}/legal?seat=n` returns **one `TradeSet` action per valid combination** of the
seat's hand. So:

> **The client never implements `IsSet`. It highlights whichever combinations the server offered.**

The implementation is a lookup, not a rule:

```
validSets   = legal.filter(a => a.type == "TradeSet")          // each carries its 3 card keys
isInAnySet  = card => validSets.some(s => s.cards.includes(card.key))
```

### Why this matters more here than anywhere else

Two card rules are **recorded but not yet confirmed** — they await a reviewer's sign-off before
Phase 4 (`../shared/rules.json` → `cards._note`):

| | Decision | Configured value | Alternative |
|---|---|---|---|
| **D-27** | `distinctSetRule` | `any_distinct` — any three distinct non-Wild symbols | `classic_triple` — specifically Infantry + Cavalry + Artillery |
| **D-28** | `wildSubstitution` | `joker` — a Wild stands for any symbol, so any two cards plus a Wild form a set | `pair_only` — a Wild only completes a pair |

With classic RISK's three symbols these alternatives coincide. With **five** non-Wild symbols they do
not, and they change which hands are tradeable at all.

Because set validity is read from the legal list, **flipping either decision needs zero client
changes.** The server offers a different set of `TradeSet` actions and the highlighting follows. That
is the entire reason this document refuses to let the client know what a set is: a UI that
implemented `any_distinct` would have to be found and rewritten the day the reviewer says
`classic_triple`, and S-10 is not a screen anyone would think to re-check.

---

## 5.4 Trade value and escalation

| | |
|---|---|
| Schedule | **4, 6, 8, 10, 12, 15, 20, 25**, then **+5** for every set after |
| Position | `state.tradeIndex` — **match-wide**, monotonic, and **public** (DR-13) |
| Provenance | 4, 6, 8, 20 and 25 are sourced; 10, 12 and 15 are inferred, and stay as data for exactly that reason |

Match-wide and public is the interesting part, and it must be *visible* or the escalation is
invisible strategy. The trade value does not belong to a seat — any seat's trade raises it for
everyone. So S-10's header carries the whole ladder, not just the next rung:

```
┌──────────────────────────────────────────────────────────────┐
│  TRADE VALUE                                                 │
│   4    6    8   10   ▸12◂  15   20   25   +5 …               │
│   ✓    ✓    ✓    ✓     ↑                                     │
│                   next set is worth  12 armies               │
└──────────────────────────────────────────────────────────────┘
```

| Element | Meaning |
|---|---|
| Ticked rungs | already consumed, by any seat |
| `▸ ◂` marker | the next value |
| `+5 …` | the open-ended tail past 25 |
| Caption | *"next set is worth **12** armies"* — `type-num-lg` for the number |

The ladder is also shown on S-09 (draft) as a one-line summary, because the decision *"trade now or
hold"* is made while looking at the army pool, not while looking at the hand.

---

## 5.5 Trading — the preview

Selecting three cards opens a preview that states the full consequence **before** the action is
submitted. Every number in it comes from the server's `TradeSet` action and the resulting
`StateChanged`; none is computed.

```
┌──────────────────────────────────────────────────────────────┐
│  TRADE SET                                                   │
│   [N.AFRICA ✈]   [ALASKA 🛡]   [WILD ✦]                      │
│                                                              │
│   Set value                              +12 armies          │
│   Territory bonus · North Africa          +2 armies  ▸ there │
│                                          ───────────         │
│   To your draft pool                      12 armies          │
│   Placed directly on North Africa          2 armies          │
│                                                              │
│   After this trade the next set is worth 15                  │
│   ⚠ You will lose the AirForce capability from this hand      │
│                                                              │
│                        [ Cancel ]   [ Trade ]                │
└──────────────────────────────────────────────────────────────┘
```

Four things the preview must separate, because they behave differently:

| Line | Behaviour |
|---|---|
| Set value | goes into the draft pool, placed wherever the player likes |
| **Territory bonus** | **+2 armies placed directly on that territory** — *not* added to the pool, so it cannot be placed elsewhere |
| Escalation | the next value rises, for every seat |
| **Capability loss** | see below |

### The capability warning

A seat holds a capability if it owns a territory whose profile contains it **or holds a card whose
profile contains it** (CAP-2, `seatHoldsCapabilityFromCards: true`). So trading away your only
AirForce card can **remove the AirForce capability** — and with it the Air Force attack — in the
same action that hands you twelve armies.

That is a genuine trap, and it is invisible unless the interface says so. The preview checks the
seat's post-trade capability set against `state.seats[me].capabilities` and warns when one is about
to be lost. The capability set is in the state response, so this is a comparison of two
server-supplied lists, not a derivation of CAP-1.

### The territory bonus cap

`../docs/07-game-design.md` §7 states *"+2 armies placed directly on that territory, capped at 2 per
turn (FR-37)"*. The pseudocode in `../appendices/E-pseudocode.md` §E.8 implements the cap by
counting **armies**:

```
if granted ≥ rules.cards.territoryBonusMaxPerTurn: break
...
granted ← granted + rules.cards.territoryBonusArmies
```

With `territoryBonusArmies: 2` and `territoryBonusMaxPerTurn: 2`, the first bonus sets
`granted = 2`, which satisfies the break condition. **So as specified, a turn yields at most one
+2 bonus, not two.**

The prose wording *"capped at 2 per turn"* reads either way; the pseudocode does not. The UI
therefore follows the pseudocode and labels the counter in armies, which is unambiguous under both
readings:

> `Territory bonus this turn: 2 of 2 armies`

and greys any further bonus row with *"cap reached this turn"*. **Flagged for the reviewer**: if the
intent was two separate bonuses, `territoryBonusMaxPerTurn` should read `4`, and this label needs no
change — which is the point of counting armies rather than bonuses.

---

## 5.6 Hidden hands and redaction (UX-12)

Card **identities** are redacted server-side; card **counts** are not.

| Field | Own seat | Other seats |
|---|---|---|
| `cards` | the three card objects | **`null`** |
| `cardCount` | the number | **the number** — public information in RISK |

So an opponent's hand renders as **face-down cards, counted**:

```
   Mars  ◆  14 territories · 33 armies
   ▨ ▨          2 cards
```

Not a blank space, not an estimate, not a question mark. Both halves of the truth at once: the count
is known, the identities are not. A player who cannot see an opponent's card count is missing public
information and will mis-time their own trade.

### The hand-over path is the one place this becomes a correctness requirement

In pass-and-play, one device holds several `LocalHuman` seats. On `HandOverDevice`:

1. the outgoing seat's hand is cleared **immediately** — `motion-instant`, no fade, no deferral;
2. the blocking hand-over screen (S-17) appears;
3. **only then** is the incoming seat's state requested.

That order is the requirement, not the implementation detail. **TC-UI-03** checks it survives a
background-and-restart: relaunching mid-hand-over must resume at the blocking screen, never at a
revealed hand. A 200 ms cross-fade of a card hand is an information leak with an easing curve on it,
which is why §01.8 puts `motion-instant` on this path and nothing else.

The event itself names only the incoming seat and carries no card data, so a client that clears
first cannot leak even if it renders early.

---

## 5.7 Forced trades

Two triggers, both surfaced by the state, never computed:

| Trigger | Threshold | State field | Rule |
|---|---|---|---|
| Draft phase begins with a full hand | **5 or more** cards | `mustTrade: true` | FR-35 |
| A seat was eliminated by this seat | **6 or more** cards, trade down immediately | `mustTradeDownSeat` | FR-36 |

When `mustTrade` is true the Draft legal list contains **only** `TradeSet` actions — no
`PlaceArmies`, no `EndPhase`. So the interface presents it as the phase itself, not as a modal:

| Surface | Treatment |
|---|---|
| S-09 draft panel | Replaced by the trade panel. No army pool, no placement targets |
| Banner | `warning`: *"You hold 5 cards. You must trade a set before placing armies."* |
| Dismissal | **None.** No close button, no back navigation, no escape. The phase bar shows Draft and cannot advance |
| Valid sets | pre-highlighted, and if exactly one exists it is pre-selected |

A dismissible dialogue would be a lie: there is nothing else legal to do, so offering a way out
would offer a way to an empty legal list.

### The unsatisfiable forced trade — specified because a pending decision can reach it

If `mustTrade` is true and **no** set is satisfiable, the legal list is empty and the player is
stuck. Whether that is reachable depends entirely on D-27 and D-28. Enumerating every 5-card hand
over the six symbols:

| `distinctSetRule` | `wildSubstitution` | 5-card hands with no valid set |
|---|---|---|
| **`any_distinct`** | **`joker`** | **0** — the configured default |
| `any_distinct` | `pair_only` | 0 |
| `classic_triple` | `joker` | **39** |
| `classic_triple` | `pair_only` | **51** |

Smallest counterexample under `classic_triple`: **{Infantry, Infantry, Cavalry, Cavalry, AirForce}**
— no three alike, no Infantry + Cavalry + Artillery, no Wild.

At the configured values the state is **unreachable**: `any_distinct` means three distinct symbols
suffice, and five cards cannot show fewer than three distinct symbols without containing three
alike. So S-10 need never show it today.

It is specified anyway, because D-27 is explicitly *unconfirmed* and flipping it to `classic_triple`
makes the state reachable in 39 of the possible hands:

> **EmptyState** — *"No set can be formed from your hand."*
> Body: *"You hold 5 cards but no valid set. Your draft continues without a trade."*
> Action: **Continue** → submits `EndPhase`.

Which is a UI requirement **and** an engine one: if `classic_triple` is ever selected, `LegalDraft`
must fall through to offering `PlaceArmies` and `EndPhase` rather than returning an empty list.
Recorded here as the design-side half of a decision that is still open, so that confirming D-27 as
`classic_triple` is known to carry an engine change and not only a rules-file edit.

---

## 5.8 Desktop layout (S-10)

On desktop the hand is the persistent right panel from [03 §3.10](03-map-ui-ux.md), expanded.

```
┌───────────────────────────────────────┐
│ YOUR HAND                   3 cards   │
│ ───────────────────────────────────── │
│  TRADE VALUE                          │
│   4  6  8  10 ▸12◂ 15  20  25  +5…    │
│  next set is worth 12 armies          │
│ ───────────────────────────────────── │
│                                       │
│  ┌────┐  ┌────┐  ┌────┐               │
│  │ ✈  │  │ 🛡  │  │ ✦  │   ← legal    │
│  │N.AF│  │ALSK│  │WILD│      outline  │
│  └────┘  └────┘  └────┘               │
│                                       │
│  1 valid set            [ Trade ▸ ]   │
│ ───────────────────────────────────── │
│  OPPONENTS                            │
│   ◆ Mars      ▨▨        2 cards       │
│   ▲ Chaos     ▨▨▨▨      4 cards  ⚠    │
│   ■ Vega      —         0 cards       │
└───────────────────────────────────────┘
```

| Detail | |
|---|---|
| Max hand | the forced-trade threshold is 5, so 5 face-up cards is the widest case; they wrap to two rows |
| Opponent rows | face-down backs + count (UX-12). The `⚠` marks a seat at 4+, one card from a forced trade — public information, worth surfacing |
| `1 valid set` | a count, from the legal list. Tapping it cycles the highlighted set when several exist |
| Trade button | `legal` variant, enabled only when the current selection is one of the offered `TradeSet` actions |

---

## 5.9 Mobile layout

The hand is a `BottomSheet` at **full** height, reached from the peek bar's `[Cards n]` tab.

```
┌─────────────────────────┐
│ ═══ grab ═══            │
│ YOUR HAND      3 cards  │
│ next set worth 12       │
│  4 6 8 10 ▸12◂ 15 20 25 │
├─────────────────────────┤
│  ┌─────┐ ┌─────┐        │
│  │  ✈  │ │  🛡  │        │
│  │N.AFR│ │ALASKA│       │
│  └─────┘ └─────┘        │
│  ┌─────┐                │
│  │  ✦  │   ← tap to     │
│  │WILD │     select     │
│  └─────┘                │
├─────────────────────────┤
│  1 valid set            │
│  [      TRADE      ]    │
├─────────────────────────┤
│  OPPONENTS              │
│  ◆ Mars   ▨▨      2     │
│  ▲ Chaos  ▨▨▨▨    4  ⚠  │
└─────────────────────────┘
```

| Rule | Value |
|---|---|
| Card size | 112 × 156, two per row at 360 px — a 5-card hand is three rows, scrolling inside the sheet |
| Tap target | the whole card, well over `control-h-lg` |
| Selection | tap to select, tap again to deselect; three selected enables Trade |
| **One-handed reach** | the Trade button is pinned to the sheet's bottom, never inside the scrolling card area |
| Peek badge | the `[Cards n]` tab turns `warning` when `mustTrade` is true, so the forced trade is visible without opening the sheet |

---

## 5.10 Cards elsewhere in the interface

| Screen | What cards contribute |
|---|---|
| **S-09 Draft** | One-line trade summary; the forced-trade takeover of the whole panel (§5.7); the territory-bonus armies shown as placed, not pooled |
| **S-16 Capability panel** | Each held capability traced to its source — a territory row from [03 §3.14](03-map-ui-ux.md)'s table, or a card in hand. **No Wild row** (D-20) |
| **S-11 Attack** | Air Force and naval attacks are offered only when the capability is held; when the only source is a card, the attack affordance carries a card glyph so the player knows it is contingent on the hand |
| **S-18 Game over** | Final hands revealed for every seat — the first and only point at which redaction ends |
| **S-19 Replay** | `CardAwarded`, `SetTraded` and `TerritoryBonusAwarded` log entries; **the deck order is never shown**, at any point, to any seat (NFR-11) |

The S-11 row is a small thing that prevents a real surprise: a seat whose only AirForce source is a
card can lose the Air Force attack by trading. The glyph is the warning, and §5.5's preview is the
confirmation.

---

## 5.11 Design acceptance checks

Verified by inspection in Phase 8. Not additions to the 119-case catalogue — **TC-CRD-01…10** pin
the engine's card rules and **TC-UI-03** pins the hand-over path.

| # | Check | Rule |
|---|---|---|
| DA-26 | No client source file implements `IsSet`, set validity, or an escalation table | §5.3, FR-67 |
| DA-27 | Set highlighting changes correctly when `distinctSetRule` is flipped, **with no client rebuild** | §5.3, D-27 |
| DA-28 | Every opponent renders face-down backs **and** a numeric count | UX-12, §5.6 |
| DA-29 | No capability is ever attributed to a Wild, on any screen | D-20, §5.2 |
| DA-30 | The trade preview separates pool armies from territory-bonus armies | §5.5, FR-37 |
| DA-31 | The trade preview warns before a capability is traded away | §5.5, CAP-2 |
| DA-32 | The forced-trade panel has no dismissal affordance by any route | §5.7, FR-35 |
| DA-33 | The outgoing hand is cleared before any incoming state is requested, including across a restart | §5.6, TC-UI-03 |
| DA-34 | The deck order appears nowhere, including the replay viewer | NFR-11 |
| DA-35 | The territory-bonus counter is labelled in **armies** | §5.5 |

---

[← 04 Dice UI/UX](04-dice-ui-ux.md) · [06 Interaction and affordances →](06-interaction-and-affordances.md)
