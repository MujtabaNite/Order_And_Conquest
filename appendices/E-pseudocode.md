# Appendix E — Pseudocode

> **Deliverable P.** The algorithms that carry the rules, in implementation-independent form.
>
> Pseudocode conventions follow the 2022 source report (§2.4). This appendix is derived from
> [§5.2](../docs/05-system-design.md), [§5.4](../docs/05-system-design.md), [§5.6](../docs/05-system-design.md),
> [§5.7](../docs/05-system-design.md) and [§7](../docs/07-game-design.md); where this file and §7 could
> disagree about a rule, **§7 is authoritative and this file is the defect**.

---

## E.1 Conventions

| Notation | Meaning |
|---|---|
| `←` | Assignment |
| `∪`, `∈`, `∅` | Set union, membership, empty set |
| `⌊x⌋` | Floor |
| `\|S\|` | Cardinality |
| `rules.*` | A value read from [`shared/rules.json`](../shared/rules.json) — never a literal in code |
| `map.*` | A value read from the frozen `matches.effective_map` — never re-read from disk |
| `opt.*` | A value read from the frozen `matches.options` — **`opt.diceSides` and `opt.attackRange` are read only from here**, never from `rules.*` (FR-84, FR-85, D-29, D-30) |
| `rng` | The injected `IRandomSource`. **The only source of randomness in the engine** |
| `fail X` | Raise a named, typed failure. Never return a partially-applied state |
| `assert` | A condition a test pins. Each one names its test case |

Three standing rules govern every routine below:

1. **`Apply` never mutates its input.** It returns a new state (NFR-03, TC-ARC-02). Pseudocode written as
   `state′ ← state with (…)` denotes construction, not assignment into the original.
2. **Only `Apply` draws from `rng`.** `Legal` and every agent are side-effect free with respect to the
   random source (FR-76, TC-AI-02).
3. **Dice draw order is part of the specification.** All attacker dice first, in index order, then all
   defender dice, in index order. Any other order produces a different match from the same seed.
4. **Configured combat parameters are frozen at `Start`, not read live.** `opt.diceSides` and
   `opt.attackRange` are copied into `matches.options` by `Start` and read from there for the rest of the
   match (FR-84, FR-85). `rules.combat.diceSides` and `rules.combat.attackRange` are *defaults for
   creating a match*, nothing more. The reason is specific to `diceSides`: a live read would leave
   `rng_position` advancing identically while producing different faces, so a replay would diverge with
   every determinism test still passing. **TC-PER-07** is the guard.

---

## E.2 The engine surface

Three entry points. Everything else in this appendix is reached through one of them.

```
function Start(map, options, rng) → GameState
function Legal(state)             → list of GameAction
function Apply(state, action)     → (GameState, list of GameEvent)
```

`Legal` is total: for any reachable state it returns a non-empty list, because `EndPhase` is always
available (§E.5). That is what guarantees an agent can never be stuck, and it is why `IAgent` receives
the legal list rather than computing one (§5.2).

---

## E.3 Start

```
function Start(map, options, rng):
    ValidateMap(map)                                   // E.16 — V-01…V-12, throws on failure
    opt ← FreezeOptions(options)                       // E.3.3 — resolve and range-check, then freeze

    seats ← BuildSeats(opt)                            // E.3.1
    state ← new GameState with
        seats        ← seats
        phase        ← Claim
        round        ← 0
        currentSeat  ← 0
        tradeIndex   ← 0
        map          ← map
        options      ← opt                             // frozen alongside the map (FR-10, FR-84, FR-85)
        territories  ← { t.key ↦ (owner: none, armies: 0) for t ∈ map.territories }
        cards        ← ShuffleDeck(map, rng)           // E.3.2
        armiesToPlace ← { s ↦ rules.setup.startingArmies[|seats|] for s ∈ seats }

    assert |state.territories| = |map.territories|     // TC-PER-02 — never 42 by assumption
    assert state.options.diceSides   ≥ 2               // TC-CMB-10
    assert state.options.attackRange ≥ 1               // TC-CMB-09
    return state
```

### E.3.1 BuildSeats — the two-player variant

```
function BuildSeats(options):
    seats ← [ new Seat(index: i, kind: options.seatKinds[i], …)
              for i ← 0 to options.playerCount - 1 ]

    if options.playerCount = 2 and rules.setup.twoPlayerVariant = "neutral":
        seats.append(new Seat(index: 2, kind: Neutral, userId: none, agent: none))

    return seats
```

A two-player match therefore has **three** seats and draws the 3-seat starting-army count of 35 (D-07,
§7.4). The `Neutral` seat never takes a turn, holds no cards and is skipped by the turn loop — but it
owns territories, can be attacked, and can be eliminated like any other seat.

### E.3.2 ShuffleDeck

```
function ShuffleDeck(map, rng):
    deck ← [ Card(key: t.key, symbol: t.cardSymbol) for t ∈ map.territories ]
    for i ← 1 to rules.cards.wildCount:
        deck.append(Card(key: "wild_" + i, symbol: Wild))

    // Fisher-Yates, drawing from the match source in index order
    for i ← |deck| - 1 down to 1:
        j ← rng.NextInt(0, i + 1)
        swap deck[i], deck[j]

    for i ← 0 to |deck| - 1:
        deck[i].deckOrder ← i
        deck[i].location  ← Deck

    assert |deck| = |map.territories| + rules.cards.wildCount     // 44 on the classic board
    return deck
```

`deckOrder` is **written once and stored** rather than re-derived from the seed on resume. Storing it
means a resumed match cannot possibly deal a different card, and it keeps dealing independent of
`rngPosition` (Appendix B, TC-PER-01).

### E.3.3 FreezeOptions — the configured combat parameters

```
function FreezeOptions(options):
    opt ← Clone(options)

    // Two parameters the creator may set; both default to the classic rule (D-29, D-30)
    opt.diceSides   ← options.diceSides   ?? rules.combat.diceSides        // default 6
    opt.attackRange ← options.attackRange ?? rules.combat.attackRange      // default 1

    if opt.diceSides   ∉ [ rules.combat.diceSidesMin   … rules.combat.diceSidesMax   ]:
        fail InvalidOptions("diceSides")                                   // 2 … 20
    if opt.attackRange ∉ [ rules.combat.attackRangeMin … rules.combat.attackRangeMax ]:
        fail InvalidOptions("attackRange")                                 // 1 … 10

    return Immutable(opt)
```

Validation happens **once, here**, so no routine downstream of `Start` ever range-checks either value
again. Rejection is at match creation, where it costs the creator a corrected form; acceptance of a bad
value would cost a mid-match failure in `ApplyAttack`, which has no legal way to report one.

`Immutable` is the load-bearing word. These two values are persisted in `matches.options` and read from
the match for the rest of its life. The failure mode this prevents is narrow and nasty, and is worth
stating in full because no determinism test catches it:

> `diceSides` is read live from `shared/rules.json`. The match was created at 6; the file is later edited
> to 7. On resume, every call to `rng.NextInt` consumes **exactly one draw** as before, so
> `rng_position` tracks the log perfectly and TC-DET-01…04 all pass — while every face, every combat
> outcome and therefore the whole match diverges from the recorded log. **TC-PER-07** asserts the values
> come from the match row.

---

## E.4 Legal — the legal-action builder

One function per phase. The union is what the client renders and what every agent receives (FR-21, FR-66).

```
function Legal(state):
    if state.phase = GameOver: return []

    seat ← state.currentSeat
    switch state.phase:
        case Claim:    return LegalClaim(state, seat)
        case Draft:    return LegalDraft(state, seat)
        case Attack:   return LegalAttack(state, seat)   ∪ [EndPhase]
        case Occupy:   return LegalOccupy(state, seat)
        case Fortify:  return LegalFortify(state, seat)  ∪ [EndPhase]
        case EndTurn:  return [EndPhase]
```

`Occupy` returns **only** occupation actions and no `EndPhase`: a pending occupation must be resolved,
because the defending territory is momentarily empty and DR-04 forbids leaving it so.

### E.4.1 Claim

```
function LegalClaim(state, seat):
    unowned ← [ t ∈ state.territories where t.owner = none ]
    if unowned ≠ ∅:
        return [ ClaimTerritory(t.key) for t ∈ unowned ]
    else:
        return [ PlaceArmies(t.key, 1) for t ∈ state.territories where t.owner = seat ]
```

Unowned territories first, then reinforcement of owned ones, one army at a time, until every starting
army is placed (§7.4).

### E.4.2 Draft

```
function LegalDraft(state, seat):
    hand ← HandOf(state, seat)
    actions ← []

    // Forced trade takes precedence over everything else (FR-35)
    if |hand| ≥ rules.cards.maxCardsBeforeForcedTrade:
        return [ TradeSet(c) for c ∈ Combinations(hand, rules.cards.setSize) where IsSet(c) ]

    if |hand| ≥ rules.cards.setSize:
        actions ∪← [ TradeSet(c) for c ∈ Combinations(hand, rules.cards.setSize) where IsSet(c) ]

    if state.armiesToPlace[seat] > 0:
        actions ∪← [ PlaceArmies(t.key, n)
                     for t ∈ state.territories where t.owner = seat
                     for n ∈ 1 … state.armiesToPlace[seat] ]
    else:
        actions ∪← [ EndPhase ]

    return actions
```

A forced trade returns **only** trade actions, so the phase cannot be advanced and no army can be placed
until the hand is below the cap. If a seat holds 5+ cards and no subset of three forms a set, the returned
list is empty — which is unreachable under a 3-alike/3-distinct/joker set rule, and is asserted so by
**TC-CRD-09**.

### E.4.3 Attack

Three attack families, one after another, all optional.

```
function LegalAttack(state, seat):
    actions ← []
    caps    ← SeatCapabilities(state, seat)            // E.9
    opt     ← state.options                            // frozen at Start (E.3.3)

    for each o ∈ state.territories where o.owner = seat and o.armies ≥ rules.combat.minArmiesToAttack:
        maxDice ← min(rules.combat.attackerMaxDice, o.armies - rules.combat.mustLeaveBehind)

        // 1 · land — within the configured range over land edges. At range 1 this set is
        //            exactly map.landNeighbours(o.key), which is the classic rule (FR-85, D-30)
        for each (n, dist) ∈ WithinRange(map, o.key, opt.attackRange):
            if state.territories[n].owner ≠ seat:
                actions ∪← [ Attack(o.key, n, d) for d ∈ 1 … maxDice ]

        // 2 · air — capability-gated, once per turn
        if AirForce ∈ caps and not state.airAttackUsed[seat]:
            for each (target, dist) ∈ WithinRange(map, o.key, rules.airForce.maxRange):
                if dist ≥ rules.airForce.minRange and state.territories[target].owner ≠ seat:
                    actions ∪← [ AirAttack(o.key, target, d) for d ∈ 1 … maxDice ]

        // 3 · naval — capability-gated, over sea routes only
        if rules.navalForce.enabled and NavalForce ∈ caps:
            for each r ∈ map.seaRoutesTouching(o.key):
                other ← r.otherEnd(o.key)
                if state.territories[other].owner ≠ seat:
                    actions ∪← [ NavalAttack(o.key, other, r.id, d) for d ∈ 1 … maxDice ]

    return actions
```

Four notes, each of which is a rule that would otherwise be lost:

- `maxDice` encodes rule 1 of §7.5 — the attacker needs **more armies than dice rolled**. With 3 armies
  and `mustLeaveBehind = 1`, `maxDice = 2`, not 3.
- The land branch now shares `WithinRange` with the Air Force branch, at a different range. **Only the
  range argument differs.** Intervening ownership is deliberately not consulted: the path is measured over
  the land graph, not over owned territory, so a range-3 attack may cross two enemy territories. The two
  surviving distinctions of an Air Force attack are therefore `airForce.attacksPerTurn = 1` and the
  capability requirement — not the existence of range itself (§7.8).
- The Air Force branch calls `WithinRange`, which is handed **`map.landNeighbours`** and has no access to
  `map.seaRoutes` at all. C-08 is enforced by construction, not by a condition (§5.4). The land branch
  inherits that exclusion rather than re-stating it, so a configured range never opens a sea crossing.
- Capability appears here as a **gate only**. Holding `NavalForce` while no sea route touches an owned
  territory yields no naval action, which is the case Appendix D §D.5 records and TC-NAV-03 asserts.

### E.4.4 Fortify

```
function LegalFortify(state, seat):
    if state.fortifyUsed[seat]: return []
    caps    ← SeatCapabilities(state, seat)
    actions ← []

    for each o ∈ state.territories where o.owner = seat and o.armies > rules.combat.mustLeaveBehind:
        movable ← o.armies - rules.combat.mustLeaveBehind
        reach   ← FortifyReach(state, seat, o.key, caps)
        for each d ∈ reach:
            actions ∪← [ Fortify(o.key, d, n) for n ∈ 1 … movable ]

    return actions

function FortifyReach(state, seat, origin, caps):
    switch rules.fortify.mode:
        case single_pair, one_step_all:
            reach ← [ n ∈ map.landNeighbours(origin) where state.territories[n].owner = seat ]
            if rules.navalForce.enabled and NavalForce ∈ caps:
                reach ∪← [ r.otherEnd(origin) for r ∈ map.seaRoutesTouching(origin)
                           where state.territories[r.otherEnd(origin)].owner = seat ]
            return reach

        case connected_path:
            // BFS over owned territories only, land edges plus naval edges if capable
            return OwnedComponent(state, seat, origin, caps) \ {origin}
```

A naval fortification consumes the same single fortification as a land one (D-19, FR-49) — which is why
`state.fortifyUsed[seat]` is checked once, before the mode switch, and not per edge type.

A naval fortification is **not a distinct action type**. It is `Fortify(origin, destination, n)` where the
destination happens to be the far end of a sea route rather than a land neighbour. Nothing in the *action*
distinguishes the two, and nothing needs to: the engine re-derives reach from the map when it re-checks
legality (§E.5). The resulting `ArmiesFortified` event does carry `viaSeaRoute`, so a client can label the
move "by sea" after the fact from the event, or before the fact from the **map** — never from the action.

### E.4.5 Occupy

```
function LegalOccupy(state, seat):
    p       ← state.pendingOccupy
    assert p ≠ none                                     // Occupy is only reachable with one pending
    available ← state.territories[p.origin].armies - rules.combat.mustLeaveBehind

    return [ Occupy(n) for n ∈ p.minArmies … available ]
```

Three notes:

- The lower bound is `p.minArmies`, which `ApplyAttack` set to the **attacker's dice count** (§E.6, line
  `minArmies: aDice`). Moving in at least as many armies as dice rolled is DR-06; leaving at least
  `mustLeaveBehind` behind is DR-04. Both bounds are therefore data already in the state, not a
  recomputation.
- **The list is never empty, and that is not obvious.** `Legal` is total (§E.1) and the `Occupy` branch of
  §E.4 deliberately offers no `EndPhase`, so an empty list here would be a dead state with no exit. It
  cannot arise: a capture requires `dLoss = defender.armies`, and `dLoss ≤ min(aDice, dDice)` with
  `dDice = min(2, defender.armies)`. At `defender.armies ≥ 3` that bound is 2 and no capture is possible;
  at 2 or 1 every compared pair must have gone to the attacker, so `aLoss = 0`. **An attacker never loses
  an army in the exchange that captures.** `origin.armies` is therefore unchanged from the moment the
  attack was ruled legal, where `aDice ≤ origin.armies - mustLeaveBehind` already held — so
  `available ≥ p.minArmies` and at least one `Occupy` is always offered.
- `p.kind` is not consulted. Occupation is identical for land, Air Force and naval captures (D-18, §E.12).

---

## E.5 Apply

```
function Apply(state, action):
    if action ∉ Legal(state):
        fail IllegalAction(action)                     // FR-22. No state change, no draw from rng

    events ← []
    state′ ← state

    switch action.type:
        case ClaimTerritory: (state′, events) ← ApplyClaim(state, action)
        case PlaceArmies:    (state′, events) ← ApplyPlace(state, action)
        case TradeSet:       (state′, events) ← ApplyTrade(state, action)
        case Attack:         (state′, events) ← ApplyAttack(state, action, Land)
        case AirAttack:      (state′, events) ← ApplyAttack(state, action, Air)
        case NavalAttack:    (state′, events) ← ApplyAttack(state, action, Naval)
        case Occupy:         (state′, events) ← ApplyOccupy(state, action)
        case Fortify:        (state′, events) ← ApplyFortify(state, action)
        case EndPhase:       (state′, events) ← AdvancePhase(state)

    (state′, victoryEvents) ← CheckVictory(state′)     // E.14
    state′.version ← state.version + 1
    return (state′, events ∪ victoryEvents)
```

### The legality re-check is not redundant

`Legal` is called by the client, then the action travels over the network, then `Apply` calls `Legal`
again. The second call is the authoritative one: a modified client can submit anything, and this line is
where it is refused (FR-22, §5.9). The cost is one legal-list construction per action, which a turn-based
game can afford without measurement.

### E.5.1 AdvancePhase

```
function AdvancePhase(state):
    switch state.phase:
        case Claim:
            if AllStartingArmiesPlaced(state):
                return (state with phase ← Draft, round ← 1, currentSeat ← 0, …), [PhaseChanged]
            else:
                return (state with currentSeat ← NextSeat(state), …), [PhaseChanged]

        case Draft:   return (state with phase ← Attack),  [PhaseChanged]
        case Attack:  return (state with phase ← Fortify), [PhaseChanged]
        case Occupy:  fail InvalidTransition                // resolved by ApplyOccupy only
        case Fortify: return (state with phase ← EndTurn),  [PhaseChanged]

        case EndTurn:
            next ← NextSeat(state)                          // skips eliminated and Neutral seats
            r    ← state.round + (1 if next ≤ state.currentSeat else 0)
            if r > rules.match.roundCap:
                return EndByRoundCap(state)                 // E.14
            state′ ← state with
                currentSeat    ← next
                round          ← r
                phase          ← Draft
                airAttackUsed  ← { next ↦ false }           // per-turn counters reset HERE
                fortifyUsed    ← { next ↦ false }
                armiesToPlace  ← { next ↦ DraftArmies(state, next) }    // E.7
            return (state′, [PhaseChanged, TurnStarted, ArmiesGranted])
```

Per-turn counters reset on **turn start**, not on phase entry. Resetting `airAttackUsed` when the Attack
phase begins would be identical today and wrong the moment a rule allows re-entering Attack, so the reset
lives where the concept does.

---

## E.6 Combat — the one resolver

Every attack in the game reaches this function. Land, Air and Naval differ only in which targets were
legal (FR-31, §7.5).

```
function ApplyAttack(state, action, kind):
    o ← action.origin;  t ← action.target
    aDice ← action.dice
    dDice ← min(rules.combat.defenderMaxDice, state.territories[t].armies)
    N     ← state.options.diceSides                   // frozen at Start; 6 by default (FR-84)

    // Draw order is specification: all attacker dice, then all defender dice
    aRolls ← [ rng.NextInt(1, N + 1) for 1 … aDice ]
    dRolls ← [ rng.NextInt(1, N + 1) for 1 … dDice ]

    aSorted ← SortDescending(aRolls)
    dSorted ← SortDescending(dRolls)

    aLoss ← 0;  dLoss ← 0
    for i ← 0 to min(aDice, dDice) - 1:
        if aSorted[i] > dSorted[i] then dLoss ← dLoss + 1
                                   else aLoss ← aLoss + 1      // ← DEFENDER WINS TIES

    state′ ← state with
        territories[o].armies ← state.territories[o].armies - aLoss
        territories[t].armies ← state.territories[t].armies - dLoss

    events ← [ DiceRolled(aRolls, dRolls, kind), ArmiesLost(o, aLoss), ArmiesLost(t, dLoss) ]

    if kind = Air: state′.airAttackUsed[state.currentSeat] ← true      // AIR-1, one per turn

    if state′.territories[t].armies = 0:
        state′.phase           ← Occupy
        state′.pendingOccupy   ← (origin: o, target: t, minArmies: aDice, kind: kind)
        events ∪← [ TerritoryEmptied(t) ]
        // Ownership does NOT change here — see E.13

    return (state′, events)
```

### The one comparison that matters

```
if aSorted[i] > dSorted[i]
```

Strict `>` is rule 4 of §7.5 — the defender wins ties. Writing `≥` shifts every combat probability by
several percent, is invisible during play, passes every smoke test, and silently corrupts every agent
trained against it. **TC-CMB-02…06** assert the exact fractions below against large seeded samples — and
**TC-CMB-03** is the defender-wins-ties case specifically (§9.2) — which is why that defect cannot
survive a test run:

| Attacker : defender dice | Attacker wins, at `diceSides = 6` |
|---|---|
| 1 : 1 | 15 / 36 |
| 2 : 1 | 125 / 216 |
| 3 : 1 | 855 / 1296 |
| 1 : 2 | 55 / 216 |
| 3 : 2, attacker takes both | 2890 / 7776 |

### The table is one row of a family

Those five fractions are the `diceSides = 6` instance of exhaustive enumeration over `N^(a+d)` equally
likely outcomes — which is exactly the shape of every denominator above: 36, 216, 1296, 216, 7776. Once
`diceSides` is configurable (FR-84) the oracle does not change kind; it takes a parameter. **The resolver
above is already correct at every `N`** — nothing in it mentions 6 — which is the whole point of reading
`N` from the match rather than writing a literal.

For one die against one die the result has a closed form:

```
P(attacker wins) = (N - 1) / (2N)
```

Of the `N²` outcomes, `N` are ties (all lost by the attacker) and the remaining `N² - N` split evenly, so
the attacker takes `(N² - N)/2`. At `N = 6` that is 15/36, the first row above. This was checked against
enumeration for every `N` from 2 to 20.

The supervisor's example, `diceSides = 7`, computed by the same enumerator that reproduces the d6 column:

| Attacker : defender | d6 | d7 | Change |
|---|---|---|---|
| 1 : 1 | 15/36 = 0.4167 | 21/49 = 0.4286 | +1.19 pp |
| 2 : 1 | 125/216 = 0.5787 | 203/343 = 0.5918 | +1.31 pp |
| 3 : 1 | 855/1296 = 0.6597 | 1617/2401 = 0.6735 | +1.38 pp |
| 1 : 2 | 55/216 = 0.2546 | 91/343 = 0.2653 | +1.07 pp |
| 3 : 2, both | 2890/7776 = 0.3717 | 6559/16807 = 0.3903 | +1.86 pp |

Every figure moves in the **attacker's** favour, and that is not an accident of the arithmetic. The
defender's whole structural advantage is the tie, and `P(tie) = 1/N` on any compared pair. Raising the
face count makes ties rarer, so a larger die weakens the defender and pushes 1:1 combat toward a coin flip
from below — `(N-1)/(2N) → ½` as `N → ∞`, never reaching it. Lowering it to 2 gives the defender 1/4.
That relationship is the answer to the supervisor's question: the parameter is not cosmetic, and the
direction of its effect is derivable rather than something to be discovered by playtesting.

### Dice are events, not return values

`DiceRolled` carries **every face**, in roll order (FR-29). Clients animate the faces they are given and
never generate one (FR-69). That is what makes a replay visually identical rather than merely
outcome-identical, and it is the property that makes client-side cheating uninteresting (§5.9).

This is also why a configurable face count costs the client nothing: the renderer is handed a face count
and a list of values and has no opinion about either, so a d7 needs no new event, no new endpoint and no
new engine path — only a die face that can draw a 7 ([`design/04-dice-ui-ux.md`](../design/04-dice-ui-ux.md)).

---

## E.7 Draft calculation

```
function DraftArmies(state, seat):
    owned ← [ t ∈ state.territories where t.owner = seat ]

    territoryTerm ← max(rules.draft.minimumArmies, ⌊ |owned| / rules.draft.territoryDivisor ⌋)

    continentTerm ← 0
    for each c ∈ map.continents:
        members ← [ t ∈ map.territories where t.continent = c.key ]
        if every m ∈ members has state.territories[m].owner = seat:
            continentTerm ← continentTerm + c.bonus

    return territoryTerm + continentTerm
```

The card-trade term is **not** added here: a trade is a separate action inside the Draft phase, and it
adds to `armiesToPlace` when it is applied (§E.8.3). Folding it in would require knowing at turn start
whether the seat will trade.

The floor of 3 (DR-08) is what keeps a seat reduced to one or two territories able to act at all. It
dominates further than it looks: `max(3, ⌊t/3⌋)` equals 3 for **every count from 1 to 11**, so the
**twelfth** territory is the first that increases income. Asserted by **TC-DRF-01** (the whole 1…42
curve) and **TC-DRF-02** (the 1–11 plateau specifically).

---

## E.8 Cards

### E.8.1 IsSet — and a genuine ambiguity

A set is exactly `rules.cards.setSize` = **3** cards (DR-12, C-05). Six symbols do not change the set
size; five-card sets are an explicit §40 prohibition.

With six symbols rather than classic RISK's four, two questions arise that §7.6's phrasing — *"three of
the same symbol, three different symbols, or two of one symbol plus a Wild"* — does not settle. Both are
recorded as new decisions and both are **data**, not code:

| ID | Question | Decision | Key |
|---|---|---|---|
| **D-27** | "Three different symbols" — any three distinct, or specifically one each of Infantry/Cavalry/Artillery? | **Any three distinct non-Wild symbols** | `cards.distinctSetRule: "any_distinct"` |
| **D-28** | Does a Wild substitute for *any* symbol, or only complete a pair? | **Any symbol** — the classic-RISK reading | `cards.wildSubstitution: "joker"` |

```
function IsSet(hand):
    if |hand| ≠ rules.cards.setSize: return false

    wilds ← count of c ∈ hand where c.symbol = Wild
    reals ← [ c.symbol for c ∈ hand where c.symbol ≠ Wild ]

    if wilds = 0:
        return AllEqual(reals) or DistinctOk(reals)

    if rules.cards.wildSubstitution = "joker":
        // A Wild takes any symbol. Reachable hands with ≥1 Wild are always sets:
        //   wilds = 1, reals equal    → assign reals[0]   → three alike
        //   wilds = 1, reals differ   → assign a third    → three distinct
        //   wilds = 2                 → assign reals[0]   → three alike
        return true

    else:   // "pair_only" — the narrow reading of §7.6
        return wilds = 1 and reals[0] = reals[1]

function DistinctOk(symbols):
    if rules.cards.distinctSetRule = "any_distinct":
        return AllDistinct(symbols)
    else:   // "classic_triple"
        return SetOf(symbols) = {Infantry, Cavalry, Artillery}
```

> **Why this is flagged rather than quietly chosen.** Under `joker`, *any* two cards plus a Wild form a
> set — which is the official classic-RISK rule, and broader than §7.6's literal wording. Under
> `pair_only`, a hand of Infantry + Cavalry + Wild is **not** a set, and a hand of one card plus both
> Wilds is not a set either. The two readings change how often a forced trade is satisfiable, and
> therefore change agent behaviour and every card-family test oracle. `joker` is the default because it
> reproduces classic RISK, which the whole design takes as its foundation. **TC-CRD-06** must assert the
> configured branch explicitly, and a reviewer should confirm the intended reading before Phase 4 begins.

Three Wilds is unreachable: `rules.cards.wildCount` = 2.

### E.8.2 Trade value

```
function TradeValue(state):
    i     ← state.tradeIndex                           // 0-based, match-wide, monotonic
    table ← rules.cards.tradeValues                    // [4, 6, 8, 10, 12, 15, 20, 25]
    if i < |table|:
        return table[i]
    else:
        return table[|table| - 1] + (i - |table| + 1) × rules.cards.tradeIncrementAfterTable
```

`tradeIndex` is a property of the **match**, not of the seat. It advances once per trade regardless of who
traded and never resets (DR-13). The ninth trade in a match is worth 30 armies whether one seat made all
nine or nine seats made one each — asserted by **TC-CRD-07**.

### E.8.3 ApplyTrade

```
function ApplyTrade(state, action):
    seat  ← state.currentSeat
    cards ← action.cards
    assert IsSet(cards)                                // re-checked; Legal already filtered

    value  ← TradeValue(state)
    state′ ← state with
        tradeIndex           ← state.tradeIndex + 1
        armiesToPlace[seat]  ← state.armiesToPlace[seat] + value
        cards[c].location    ← Discard  for c ∈ cards
        cards[c].holderSeat  ← none     for c ∈ cards

    events ← [ SetTraded(cards, value), ArmiesGranted(seat, value) ]

    // Territory bonus — capped per turn (FR-37)
    granted ← 0
    for each c ∈ cards where c.key names a territory
                          and state.territories[c.key].owner = seat:
        if granted ≥ rules.cards.territoryBonusMaxPerTurn: break
        state′.territories[c.key].armies ← state′.territories[c.key].armies
                                         + rules.cards.territoryBonusArmies
        granted ← granted + rules.cards.territoryBonusArmies
        events ∪← [ TerritoryBonus(c.key, rules.cards.territoryBonusArmies) ]

    return (state′, events)
```

The territory bonus is placed **directly on that territory**, not added to `armiesToPlace` — it is not a
free-placement army (§7.4). The cap is on armies granted, not on cards matched, so trading three owned
territories yields 2 armies on one territory and nothing further. **TC-CRD-10** pins the cap.

Trading can **remove a capability the same turn** it grants armies: the traded cards leave the hand, and
CAP-2 is re-derived on the next query (§E.9). That interaction is intended (§7.6).

### E.8.4 Award and forced trade-down

```
function AwardCardIfEarned(state, seat):
    if state.conqueredThisTurn[seat] and not state.cardAwardedThisTurn[seat]:
        c ← the Deck card with the lowest deckOrder
        if c = none: c ← ReshuffleDiscard(state)        // deck exhausted
        return (state with cards[c] ← (location: Hand, holderSeat: seat),
                           cardAwardedThisTurn[seat] ← true,
                [CardAwarded(seat, c.key)])
    return (state, [])
```

At most one card per turn, and only on a turn with at least one conquest (DR-11). Ten conquests award one
card, not ten — **TC-CRD-02**.

```
function TransferCardsOnElimination(state, victim, eliminator):
    state′ ← state with cards[c].holderSeat ← eliminator
                        for c ∈ HandOf(state, victim)

    if |HandOf(state′, eliminator)| ≥ rules.cards.maxCardsAfterElimination:
        state′.phase             ← Draft
        state′.mustTradeDownSeat ← eliminator           // FR-36: trade below 5 immediately
    return state′
```

---

## E.9 Capability — CAP-1 and CAP-2

```
function TerritoryProfile(map, key):                   // CAP-1
    t ← map.territories[key]
    p ← { Infantry }
    if t.coastal: p ← p ∪ { NavalForce }
    p ← p ∪ { t.cardSymbol }
    return p

function SeatCapabilities(state, seat):                // CAP-2
    caps ← ∅
    for each t ∈ state.territories where t.owner = seat:
        caps ← caps ∪ TerritoryProfile(map, t.key)
    for each c ∈ state.cards where c.location = Hand and c.holderSeat = seat:
        if c.key names a territory:
            caps ← caps ∪ TerritoryProfile(map, c.key)
        // a Wild names no territory, so its profile is ∅ (D-20)
    return caps
```

**Derived on demand, never stored** (FR-41, D-10). There is no capability column, no counter and no
cache, so capability cannot desynchronise from ownership. Losing the last coastal territory removes Naval
capability at the instant the territory changes hands — **TC-CAP-04** and **TC-CAP-05** assert the *loss*,
because a cache added later for performance would break exactly that and nothing else.

Only `AirForce` and `NavalForce` gate an action (D-09). `Infantry`, `Cavalry` and `Artillery` are
set-matching symbols and are computed only so the profile is complete. The full 42-row mapping is
[Appendix D](D-capability-mapping-decision-table.md).

---

## E.10 WithinRange — the shared range search

Two callers, one function: land attacks at `opt.attackRange` (FR-85) and Air Force attacks at
`rules.airForce.maxRange` (FR-45). There is **one** BFS in the engine, not two.

```
function WithinRange(map, origin, maxRange):
    dist  ← { origin ↦ 0 }
    queue ← Queue([origin])

    while queue not empty:
        t ← queue.dequeue()
        if dist[t] = maxRange: continue                // frontier reached; do not expand
        for each n ∈ map.landNeighbours(t):             // ← LAND EDGES ONLY
            if n ∉ dist:
                dist[n] ← dist[t] + 1
                queue.enqueue(n)

    return dist \ { origin }
```

Breadth-first over the land adjacency graph. `map.seaRoutes` is a **separate structure that this function
cannot reach** — it is not a parameter and not a field of the graph it is handed. C-08 ("sea routes are
excluded from Air Force range entirely") is therefore a structural property rather than a conditional that
a later edit could remove (§5.4). Because the land branch of `LegalAttack` goes through the same function,
a configured attack range inherits that exclusion for free: no range value can produce a sea crossing.

At `maxRange = 1` the returned set is exactly `map.landNeighbours(origin)` with distance 1, which is why
the default configuration reproduces classic adjacency without a special case. **TC-CMB-09** pins the
range-dependent legality and **TC-AIR-02** asserts that no attack of any kind is legal beyond
`max(opt.attackRange, rules.airForce.maxRange)` — which evaluates to 5 at the defaults.

Complexity is O(V + E) per call, bounded by the frontier check: 42 vertices and 83 edges on the classic
board, so an exhaustive legal-list build over all owned origins is trivially affordable.

| Measured on the classic board | Value |
|---|---|
| Land-graph diameter | 10 |
| Reachable pairs at range 5 | 1330 of 1722 = **77.2 %** |
| Worst origin | Eastern Australia — 11 of 41 |
| Best origin | Ukraine — 40 of 41 |
| Mean | 31.7 |

The same reach table now serves both callers, so it is also the table that says what a configured attack
range *means* on this board — range 1 reaches 9.6 % of ordered pairs, range 3 reaches 39.3 %, range 5
reaches 77.2 % and range 10 reaches all of them (§7.8).

A range-5 capture may be adjacent to nothing else the attacker owns. The attacker then holds an isolated
pocket it cannot reinforce by land fortification. **This is a direct consequence of the locked rule, not a
defect** — TC-AIR-04 asserts it so nobody "fixes" it (§7.8). Raising `attackRange` above 1 makes that
situation ordinary rather than exceptional, which is worth knowing before a reviewer reads the pocket as a
bug.

---

## E.11 Naval legality

```
function LegalNavalTargets(state, seat, origin):
    if not rules.navalForce.enabled:                 return ∅
    if NavalForce ∉ SeatCapabilities(state, seat):   return ∅

    out ← ∅
    for each r ∈ map.seaRoutesTouching(origin):
        other ← r.otherEnd(origin)
        if state.territories[other].owner ≠ seat:
            out ← out ∪ { (target: other, routeId: r.id) }
    return out
```

`rules.navalForce.unitsRequiredPerRoute` = **0** (NAV-1, D-12): crossing a route consumes nothing, so a
sea route behaves exactly like a land edge *for a seat holding Naval capability*. There is no naval unit
type, no transport capacity, no loading step and no second combat system.

A landlocked territory is never a route endpoint (DR-17, FR-51), enforced at generation (§E.15) and
asserted by V-11 at load, so this function needs no landlocked check.

---

## E.12 Occupy

```
function ApplyOccupy(state, action):
    p ← state.pendingOccupy
    assert p ≠ none
    assert action.armies ≥ p.minArmies                                  // ≥ dice rolled (DR-06)
    assert action.armies ≤ state.territories[p.origin].armies - rules.combat.mustLeaveBehind

    seat   ← state.currentSeat
    victim ← state.territories[p.target].owner

    state′ ← state with
        territories[p.origin].armies ← state.territories[p.origin].armies - action.armies
        territories[p.target].owner  ← seat
        territories[p.target].armies ← action.armies
        conqueredThisTurn[seat]      ← true
        pendingOccupy                ← none
        phase                        ← Attack

    events ← [ TerritoryCaptured(p.target, from: victim, to: seat, armies: action.armies) ]

    if NoTerritoriesLeft(state′, victim):
        state′ ← EliminateSeat(state′, victim, by: seat)                // E.14
        events ∪← [ SeatEliminated(victim, by: seat) ]

    assert state′.territories[p.origin].armies ≥ rules.combat.mustLeaveBehind      // DR-04
    assert state′.territories[p.target].armies ≥ 1                                 // DR-04
    return (state′, events)
```

**Occupation is identical for land, Air Force and Naval captures** (D-18). `p.kind` is carried in the
pending record for the event log and for nothing else: there is no separate landing rule, no reduced
garrison and no beachhead penalty. The capture mechanism differs only in which target was legal.

The card award is evaluated at end of turn, not here, because at most one card is awarded per turn
regardless of how many territories were taken (§E.8.4).

---

## E.13 Why ownership changes in Occupy, not in Attack

`ApplyAttack` reduces the defender to zero armies and sets `phase ← Occupy`. It does **not** change
`owner`. Ownership transfers only in `ApplyOccupy`, together with the armies that will garrison it.

If `ApplyAttack` transferred ownership, the state between the two actions would hold a territory owned by
the attacker with **zero armies** — which violates CK-11 (`armies ≥ 1`) and DR-04. That state is
persistable: it is exactly what a client crash between the two requests would leave in the database. The
intermediate state must therefore be one the schema permits, which it is: the target is still owned by the
defender, at zero armies, with a `pendingOccupy` record naming it.

> **This is the reason `Occupy` is a phase and not a parameter of `Attack`.** Folding the army count into
> the attack action would remove the intermediate state, but it would also require the attacker to commit
> the garrison **before** seeing the dice — which changes the game.

`armies ≥ 1` is enforced by CK-11 only for rows that exist; the zero-army defending territory is legal
transiently because it still belongs to the defender and the engine's own assertion covers the window.
**TC-CMB-08** pins the sequence.

---

## E.14 Elimination and victory

```
function EliminateSeat(state, victim, by):
    state′ ← TransferCardsOnElimination(state, victim, by)              // E.8.4, FR-38
    state′ ← state′ with
        seats[victim].status          ← Eliminated
        seats[victim].eliminatedBy    ← by
        seats[victim].eliminatedRound ← state.round
    return state′

function CheckVictory(state):
    active ← [ s ∈ state.seats where s.status = Active ]

    // World domination — the only victory condition (D-26: no secret missions)
    for each s ∈ state.seats:
        if every t ∈ state.territories has t.owner = s.index:
            return (state with phase ← GameOver, winnerSeat ← s.index,
                    [MatchFinished(winner: s.index, by: Domination)])

    if |active| = 1:
        return (state with phase ← GameOver, winnerSeat ← active[0].index,
                [MatchFinished(winner: active[0].index, by: LastSeatStanding)])

    return (state, [])

function EndByRoundCap(state):
    ranked ← state.seats sorted by TerritoryCount(state, s) descending
    return (state with phase ← GameOver, winnerSeat ← ranked[0].index,
            [MatchFinished(winner: ranked[0].index, by: RoundCap, ranking: ranked)])
```

A seat is **exactly the territories it holds**, so holding none is being out of the game — elimination is
a consequence of the territory rule (§7.3), not a separate mechanic. A `Neutral` seat is eliminated the
same way.

The round cap (100) is not decoration: two cautious agents can fail to terminate, and a training run that
never ends produces nothing (FR-55). **TC-VIC-04** asserts that a capped match finishes with a ranking.

Domination and last-seat-standing are checked separately because a `Neutral` seat can hold territory while
being the only non-active seat left; the two conditions coincide on the classic board but not in the
two-player variant.

---

## E.15 Sea-route generation

The host chooses **how many**; the system chooses **where every one of them goes** (FR-15, FR-16). There
is no interface anywhere for naming endpoints — an explicit §40 prohibition (Appendix C §C.4).

```
function GenerateSeaRoutes(map, count, rng):
    if count = 0:
        assert not rules.navalForce.enabled            // 0 is legal only with Naval disabled (D-13)
        return []

    if count < rules.seaRoutes.min or count > rules.seaRoutes.max:
        fail SeaRouteCountOutOfRange(count, rules.seaRoutes.min, rules.seaRoutes.max)

    coastal ← [ t ∈ map.territories where t.coastal ]
    budget  ← rules.seaRoutes.maxGenerationAttempts     // 500

    // Pass 1 honours the soft preference; pass 2 drops it. Two passes make "soft" deterministic.
    routes ← TryPlace(map, coastal, count, rng, requireDifferentContinents: true,  budget: ⌊budget/2⌋)
    if |routes| < count:
        routes ← routes ∪ TryPlace(map, coastal, count - |routes|, rng,
                                   requireDifferentContinents: false, budget: ⌈budget/2⌉,
                                   existing: routes)

    if |routes| < count:
        fail SeaRouteGenerationFailed(requested: count, placed: |routes|)

    for i ← 0 to |routes| - 1: routes[i].id ← i
    return routes

function TryPlace(map, coastal, need, rng, requireDifferentContinents, budget, existing):
    placed   ← []
    attempts ← 0
    while |placed| < need and attempts < budget:
        attempts ← attempts + 1
        a ← coastal[ rng.NextInt(0, |coastal|) ]
        b ← coastal[ rng.NextInt(0, |coastal|) ]

        if a = b:                                        continue   // hard
        if b ∈ map.landNeighbours(a.key):                continue   // hard — adds nothing
        if {a, b} ∈ existing ∪ placed:                   continue   // hard — no duplicates
        if requireDifferentContinents
           and a.continent = b.continent:                continue   // soft

        placed.append((a: a.key, b: b.key))
    return placed
```

### Failure is specific and total

If the requested count cannot be placed within the attempt bound, match creation returns `422` stating
**how many were placeable**, and **no match row exists** (UC-04 alternative path 9a, Appendix A). A match
with three of four requested routes would be a match the host did not configure.

### Frozen at creation

Routes are generated **once** and written into `matches.effective_map`, never regenerated, so a resumed
match has exactly the routes it started with (FR-10, **TC-PER-06**). `id` is stable for the life of the
match and is what `NavalAttack` carries on the wire.

---

## E.16 ValidateMap — the V-01…V-12 gate

Every map — authored, generated or hand-edited — passes the **same** twelve rules (FR-08). One validator
in the Engine, so the API, the simulator and the offline clients cannot apply different standards.

```
function ValidateMap(map):
    errors ← []

    // V-01 symmetry
    for each t ∈ map.territories, for each n ∈ t.neighbours:
        if t.key ∉ map.territories[n].neighbours: errors.append(V01, t.key, n)

    // V-02 no self-loops
    for each t ∈ map.territories:
        if t.key ∈ t.neighbours: errors.append(V02, t.key)

    // V-03 no duplicate edges
    for each t ∈ map.territories:
        if HasDuplicates(t.neighbours): errors.append(V03, t.key)

    // V-04 no dangling neighbour keys
    for each t ∈ map.territories, for each n ∈ t.neighbours:
        if n ∉ map.territories: errors.append(V04, t.key, n)

    // V-05 continent keys resolve
    for each t ∈ map.territories:
        if t.continent ∉ map.continents: errors.append(V05, t.key)

    // V-06 continents partition the territories exactly
    if MultiSet(t.continent for t ∈ map.territories) does not cover map.continents exactly once each
        per territory: errors.append(V06)

    // V-07 the land graph is connected
    if |ReachableFrom(map, any territory)| ≠ |map.territories|: errors.append(V07)

    // V-08 board large enough to deal
    if |map.territories| < 2 × rules.setup.maxPlayers: errors.append(V08)

    // V-09 every continent has a border territory
    for each c ∈ map.continents:
        if no t ∈ c has a neighbour outside c: errors.append(V09, c.key)

    // V-10 stored capabilities equal their CAP-1 derivation
    for each t ∈ map.territories:
        if SetOf(t.capabilities) ≠ TerritoryProfile(map, t.key): errors.append(V10, t.key)

    // V-11 no NavalForce symbol on a landlocked territory
    for each t ∈ map.territories:
        if t.cardSymbol = NavalForce and not t.coastal: errors.append(V11, t.key)

    // V-12 crossesWater ⊆ adjacency edges
    for each (a, b) ∈ map.crossesWater:
        if b ∉ map.territories[a].neighbours: errors.append(V12, a, b)

    if errors ≠ ∅:
        fail MapValidationFailed(errors)               // named rules and offending keys
```

### A failing map is rejected, never repaired

A repaired map is a map nobody specified. The validator names the failed rule and the offending keys, and
the map does not load. For **generated** maps the response is different but equally strict: discard the
result and reseed (§E.17 step 9). Neither path patches a bad graph.

The gate is only real if it has been shown to reject something: `tests/fixtures/invalid_*.json` holds
**one deliberately broken map per rule**, and TC-MAP-01…05 plus that fixture set are what verify it.

---

## E.17 Procedural map generation

Seeded and deterministic: the same seed and parameters produce a byte-identical map (NFR-02, TC-MAP-06).

```
function GenerateMap(seed, params):
    rng ← new SeededRandomSource(seed)
    attempts ← 0

    while attempts < params.maxAttempts:
        attempts ← attempts + 1

        points  ← PoissonDisc(params.territories, params.radius, rng)      // 1 · Bridson
        points  ← Lloyd(points, params.lloydIterations)                    // 2 · relaxation
        tri     ← Delaunay(points)                                         // 3 · DelaunatorSharp

        // 4 · adjacency from half-edges — ONE pass, exactly correct
        adj ← { p ↦ ∅ for p ∈ points }
        for each halfEdge e ∈ tri.halfedges:
            (u, v) ← tri.endpointsOf(e)
            adj[u] ← adj[u] ∪ { v };  adj[v] ← adj[v] ∪ { u }

        polys      ← VoronoiCells(tri)                                     // 5 · rendering only
        continents ← MultiSourceBFS(adj, params.continents, rng)           // 6 · contiguous
        bonuses    ← { c ↦ clamp(round(target × size(c) × borders(c)), 1, 10)
                       for c ∈ continents }                                // 7 · MARS static value
        coastal    ← HullTouching(polys) ∪ ContinentBoundary(continents, adj)   // 8
        symbols    ← DealSymbols(points, rules.cards.symbols, 12:10:8:7:5, rng)

        map ← AssembleMap(seed, points, adj, polys, continents, bonuses, coastal, symbols)

        if TryValidate(map) succeeds:                                      // 9 · same gate
            return map
        // else: discard and reseed — no repair pass
        rng ← new SeededRandomSource(seed + attempts)

    fail MapGenerationFailed(seed, attempts)
```

### Step 4 matters more than it looks

Adjacency from a proximity threshold produces *almost* the right graph — and an almost-right adjacency
graph is an unplayable board with a plausible-looking picture. The triangulation already knows exactly
which cells share an edge, so the half-edge pass is both cheaper and exactly correct.

### Step 9's discard-and-reseed

This is what lets steps 1–8 stay simple. Generation is allowed to fail, and the cheapest correct response
is another seed rather than a repair pass on a bad graph. `coastal` from step 8 feeds CAP-1 unchanged, so
**V-10 asserts the capability derivation on generated maps exactly as on the authored one** — there is no
separate capability path for generated maps, which is what keeps a procedural board compatible with the
same engine (§42).

---

## E.18 MarsBot — expected-value scoring

Position value, from the MARS paper (§2.5); coefficients live in `rules.json → ai.mars`, so tuning is a
data edit:

```
V(state, seat) = P_sv + P_fn + P_fnu + P_en + P_enu + P_cb
               + V_bonus × (V_cp + P_oc + P_eoc)
```

```
function ChooseAction(state, legal):
    positionBefore ← rng.Position                      // for the assertion below

    best ← legal[0];  bestScore ← -∞
    for each a ∈ legal:
        s ← ScoreAction(state, a)
        if s > bestScore: best ← a;  bestScore ← s

    assert rng.Position = positionBefore               // TC-AI-04
    return best

function ScoreAction(state, action):
    if action is an attack of any kind:
        seat  ← state.currentSeat
        dDice ← min(rules.combat.defenderMaxDice, state.territories[action.target].armies)
        p     ← WinProbability(action.dice, dDice)      // CLOSED FORM — no dice rolled

        won   ← HypotheticalCapture(state, action)      // constructed directly
        lost  ← HypotheticalRepulse(state, action)      // constructed directly

        return p × V(won, seat) + (1 - p) × V(lost, seat)
    else:
        return V(HypotheticalApply(state, action), state.currentSeat)
```

### The speculative-apply trap

The obvious implementation — call `Apply` and evaluate the result — is wrong in a way that does not
announce itself:

> Calling `Apply` **rolls dice**. Rolling dice advances `rng.Position`. The match's random stream would
> then depend on **how many options the bot considered**, and the dice the player actually sees would not
> be the dice the seed implies. Determinism (NFR-02) breaks silently and the match becomes
> non-reproducible.

The failure is invisible: the bot plays well, every unit test passes, and only a replay of a real match
diverges. That is why the correct implementation scores by expected value from the closed-form dice table
(§7.5) and constructs the two hypothetical states directly, and why the assertion `rng.Position` is
unchanged across a full decision is a **test case with a number** (FR-76, **TC-AI-04**) rather than a code
comment.

`HypotheticalCapture` and `HypotheticalRepulse` construct the most likely outcome states without drawing —
attacker loses none / defender loses all, and attacker loses the comparison count / defender loses none.
They are approximations of a distribution, which is appropriate for a heuristic evaluator and is exactly
what keeps them pure.

### The other agents

```
PassiveBot     : attack only where WinProbability ≥ 0.80; never leave a territory below 3
AggressiveBot  : attack wherever WinProbability ≥ 0.45
ChaoticBot     : legal[ rng_agent.NextInt(0, |legal|) ]        // its OWN source, never the match's
OnnxPolicyAgent: argmax over the policy head, masked to `legal`; falls back to MarsBot with no file
```

`ChaoticBot` draws from an agent-owned random source, never the match source — the same trap as §E.18 in
its simplest form. And it is not filler: it is the baseline every stronger agent must beat, it reaches
code paths scripted agents never visit, and it is the fastest opponent for a large smoke test (§5.6).

Every agent returns a **member of the supplied legal list**. `IAgent` takes that list as a parameter
rather than computing it, which is what makes NFR-20 — an invalid-action rate of exactly zero — a
structural property rather than a target.

---

## E.19 The API action pipeline

The engine is pure; this is the orchestration around it (§5.5, §6.7).

```
function PostAction(matchId, seatToken, body):
    match ← Load(matchId)                                      // snapshot + effective_map
    seat  ← AuthoriseSeat(seatToken, match)                    // 401 / 403; Neutral always 403

    if body.expectedVersion ≠ match.version:
        return 409 Conflict with CurrentState(match, seat)     // never auto-retried by a client

    if seat.index ≠ match.currentSeat:
        return 409 Conflict with reason NotYourTurn

    state  ← Rehydrate(match)                                  // snapshot → GameState
    rng    ← new SeededRandomSource(match.rngSeed, match.rngPosition)   // POSITION RESTORED
    action ← Deserialise(body.action)                          // 422 on a malformed body

    if action ∉ Engine.Legal(state):
        return 422 Unprocessable with legal action list

    (state′, events) ← Engine.Apply(state, action)

    BEGIN TRANSACTION
        rows ← UPDATE matches SET version = version + 1, rngPosition = rng.Position, …
                WHERE id = matchId AND version = body.expectedVersion
        if rows = 0:
            ROLLBACK;  return 409 Conflict with CurrentState(match, seat)

        UpdateSnapshot(state′)                                 // territory_state, cards, seats
        INSERT INTO moves (matchId, seq, seatIndex, round, phase,
                           action, events, versionAfter, rngPositionAfter)
    COMMIT

    Broadcast(events, redactedPerSeat: true)                   // SignalR
    return 200 with Redact(state′, seat)
```

### Two properties worth naming

**The version predicate is the entire concurrency design.** If it matches no row, the transaction affects
nothing, the client receives `409` with the current state, and no partial write ever existed (FR-61,
NFR-13, TC-API-03, TC-PER-05). There are no row locks, no `SELECT … FOR UPDATE`, and no lock held across a
client round trip. A turn-based game has one writer at a time; the only real contention is a double-tap,
and a version check is the cheapest correct answer to it. On localhost a double-tap is genuinely faster
than a round trip, so this is not deferred to Phase 6.

**The RNG stream is state.** `rngSeed` alone cannot resume a match — `rngPosition` must be restored into
the source, or the next die differs from the one the seed implies. **TC-DET-03** asserts that
`matches.rng_position` equals `rng_position_after` of the highest `seq` in `moves`, which detects the
defect without replaying the match.

### Redaction

```
function Redact(state, viewerSeat):
    out ← state
    for each s ∈ out.seats where s.index ≠ viewerSeat:
        out.cards[s] ← { count: |HandOf(state, s)| }            // count only, never the symbols
    out.deckOrder ← omitted                                     // would reveal every future draw
    out.rngSeed   ← omitted
    return out
```

Redaction happens at the **API layer**, not in the engine, because the engine has no concept of a viewer.
An un-redacted state reaching a client would leak both opponents' hands and every future card — **TC-SEC-02**
asserts that neither appears in any response for a non-owning seat.

---

## E.20 Traceability

| Algorithm | Section | Implementation | Tests |
|---|---|---|---|
| `Start`, deck shuffle | E.3 | `Engine/GameEngine`, `Engine/Rules/SetupRules` | TC-PER-02, TC-PER-01, TC-CRD-01 |
| `FreezeOptions` | E.3.3 | `Engine/Rules/OptionsResolver` | **TC-PER-07**, TC-CMB-09, TC-CMB-10 |
| `Legal` | E.4 | `Engine/Actions/LegalActionBuilder` | TC-AI-01, TC-ARC-05 |
| `Apply` | E.5 | `Engine/GameEngine` | TC-ARC-02, TC-ARC-03 |
| Combat | E.6 | `Engine/Rules/CombatRules` | **TC-CMB-01…10**, esp. TC-CMB-03 |
| Draft | E.7 | `Engine/Rules/DraftRules` | TC-DRF-01…06 |
| Cards | E.8 | `Engine/Rules/CardRules` | TC-CRD-01…10 |
| CAP-1 / CAP-2 | E.9 | `Engine/Rules/CapabilityRules` | TC-CAP-01…06, TC-MAP-05 |
| `WithinRange` | E.10 | `Engine/Map/RangeSearch` | TC-AIR-01…06, **TC-CMB-09** |
| Naval | E.11 | `Engine/Rules/NavalRules` | TC-NAV-01…06 |
| Occupy | E.12–E.13 | `Engine/Rules/CombatRules` | TC-CMB-07, TC-CMB-08 |
| Elimination, victory | E.14 | `Engine/Rules/VictoryRules` | TC-ELM-01…03, TC-VIC-01…04 |
| Sea routes | E.15 | `Engine/Map/SeaRouteGenerator` | TC-SEA-01…06 |
| `ValidateMap` | E.16 | `Engine/Validation/MapValidator` | TC-MAP-01…05 |
| Map generation | E.17 | `Engine/Generation/MapGenerator` | TC-MAP-06…10 |
| MarsBot | E.18 | `Ai/MarsBot` | TC-AI-02 (ordering), **TC-AI-04** (consumes no dice), TC-AI-01, TC-AI-03 |
| Action pipeline | E.19 | `Api/Controllers/ActionsController` | TC-API-01…08, TC-DET-03, TC-PER-05 |
| Redaction | E.19 | `Api/StateRedactor` | TC-SEC-01…04 |

### New decisions raised by this appendix

| ID | Question | Decision | Status |
|---|---|---|---|
| D-27 | "Three different symbols" with six symbols | Any three distinct non-Wild symbols | Data — `cards.distinctSetRule` |
| D-28 | Whether a Wild substitutes for any symbol | Yes — the classic-RISK reading | Data — `cards.wildSubstitution` |

Both are recorded in [`00-decisions-and-assumptions.md`](../docs/00-decisions-and-assumptions.md) Part C
and both need a reviewer's confirmation before Phase 4, because they change how often a forced trade is
satisfiable and therefore every card-family test oracle.

Two further decisions, **D-29** (`combat.diceSides`) and **D-30** (`combat.attackRange`), arrived from
supervisory review after the rule lock and are recorded in Part C.2 of the same file. They are reflected
here in E.1 rule 4, E.3, E.3.3, E.4.3, E.6 and E.10. At their defaults — 6 and 1 — every routine in this
appendix behaves exactly as it did before they existed, which is the property that let them land without
reopening a single locked decision.

---

**Appendix index:** [A](A-api-contract.md) · [B](B-database-schema.sql) · [C](C-map-specification.md) ·
[D](D-capability-mapping-decision-table.md) · E · [F](F-test-cases.md) ·
[G](G-configuration-tables.md) · [H](H-additional-diagrams-and-screenshots.md)
