# Appendix G — Configuration Tables

> **Deliverable T.** Every tunable value in [`shared/rules.json`](../shared/rules.json), with its
> default, its permitted range, its provenance and the test that pins it.
>
> The design rule this appendix documents is stated in the rules file itself: *"all tunable numbers
> live here as DATA, not in code"* and *"changing a value here must never require an engine
> rebuild."* **TC-ARC-03** enforces it by asserting that no tunable number appears as a literal in
> the engine.

**Coverage: 112 leaf keys across 13 sections.** Every one appears below.

---

## G.1 How to read these tables

| Column | Meaning |
|---|---|
| **Key** | Dotted path from the root of `rules.json` |
| **Default** | The value as shipped |
| **Permitted** | The range or enumeration the engine accepts |
| **Status** | See below |
| **Pinned by** | The test that fails if the value and the behaviour disagree |

### Status vocabulary

| Status | Meaning |
|---|---|
| **SOURCED** | Supported by a citation in [`12-references.md`](../docs/12-references.md). Changing it departs from published RISK |
| **ASSUMPTION** | A design decision recorded in [`00-decisions-and-assumptions.md`](../docs/00-decisions-and-assumptions.md) with a `D-nn` or family ID |
| **LOCKED** | Settled and not revisitable in v1 — changing it is a redesign, not a configuration change |
| **DERIVED** | A bound computed from the map or the rules, not chosen freely |
| **UNCONFIRMED** | Recorded, implemented, and **awaiting a reviewer's sign-off before Phase 4** |

### Three kinds of "changing this"

Not every key is equally safe to edit, and the difference matters more than the values:

| Class | What happens | Keys |
|---|---|---|
| **Free** | Change it, restart, play. No test oracle moves | `match.roundCap`, `ai.*`, `seaRoutes.default`, `airForce.attacksPerTurn` |
| **Oracle-moving** | The value is baked into a test's expected result. Change it and that test must be re-derived | `combat.defenderWinsTies`, `cards.tradeValues`, `draft.territoryDivisor`, `setup.startingArmies` |
| **Frozen per match** | Copied into `matches.options` at creation and read **only** from there. Editing it here must not affect a running match | `combat.diceSides`, `combat.attackRange`, the resolved sea-route count |

§G.14 lists the frozen set in full, because it is the one class that can corrupt a match silently.

---

## G.2 `setup` — 8 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `minSeats` | `2` | 2 | LOCKED | TC-API-01 |
| `maxSeats` | `6` | 6 | LOCKED | TC-API-01 |
| `startingArmies.3` | `35` | int ≥ 1 | **SOURCED** | TC-DRF family |
| `startingArmies.4` | `30` | int ≥ 1 | **SOURCED** | TC-DRF family |
| `startingArmies.5` | `25` | int ≥ 1 | **SOURCED** | TC-DRF family |
| `startingArmies.6` | `20` | int ≥ 1 | **SOURCED** | TC-DRF family |
| `twoPlayerVariant` | `"neutral"` | `"neutral"` | ASSUMPTION **D-07** | TC-SYS family |
| `territoryAllocation` | `"claim"` | `"claim"` \| `"random"` | ASSUMPTION (FR-16) | TC-MAP-06, TC-DET-02 |

> **There is no `startingArmies.2` and that is deliberate.** A 2-player match runs as **three
> seats** — two players plus `Neutral` (D-07) — so it uses the `3` row, 35 armies. A reader who
> adds a `2` key will have added a value nothing reads.

---

## G.3 `draft` — 3 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `territoryDivisor` | `3` | int ≥ 1 | **SOURCED** | TC-DRF-01 |
| `minimumArmies` | `3` | int ≥ 0 | **SOURCED** | TC-DRF-01 |
| `continentBonusEnabled` | `true` | bool | **SOURCED** | TC-DRF family |

Reinforcement is `max(minimumArmies, ⌊t / territoryDivisor⌋) + Σ continent bonuses + card trade
value`. Continent bonus values live in the **map**, not here — a generated map may ship different
ones, which is why `continentBonusEnabled` is a switch and not a table.

---

## G.4 `combat` — 13 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `attackerMaxDice` | `3` | 1 – 3 | **SOURCED** | TC-CMB family |
| `defenderMaxDice` | `2` | 1 – 2 | **SOURCED** | TC-CMB family |
| `minArmiesToAttack` | `2` | int ≥ 2 | **SOURCED** | TC-CMB family |
| `attackerNeedsOneMoreArmyThanDice` | `true` | bool | **SOURCED** | TC-CMB family |
| **`defenderWinsTies`** | **`true`** | bool | **SOURCED** | **TC-CMB-02…06** |
| `occupyMinimumEqualsDiceRolled` | `true` | bool | **SOURCED** (DR-06) | TC-CMB-07, TC-CMB-08 |
| `mustLeaveBehind` | `1` | int ≥ 1 | **SOURCED** (DR-04) | TC-CMB-07, TC-FRT family |
| **`diceSides`** | **`6`** | **2 – 20** | ASSUMPTION **D-29** / FR-84 | **TC-CMB-10**, TC-PER-07 |
| `diceSidesMin` | `2` | 2 | DERIVED | TC-API-01 |
| `diceSidesMax` | `20` | 20 | ASSUMPTION D-29 | TC-API-01 |
| **`attackRange`** | **`1`** | **1 – 10** | ASSUMPTION **D-30** / FR-85 | TC-AIR family, TC-PER-07 |
| `attackRangeMin` | `1` | 1 | DERIVED — range 1 **is** adjacency | TC-API-01 |
| `attackRangeMax` | `10` | 10 | **DERIVED** — the measured diameter of the classic land graph | TC-MAP-02 |

### `defenderWinsTies` is the highest-risk flag in the file

The rules file says so itself. It is a single boolean that inverts the outcome of every tied pair,
and five published odds fractions are asserted against it. It is also the rule players most often
misremember, which is why [04 §4.4](../design/04-dice-ui-ux.md) requires every tie to be labelled
**in words** on screen.

### `attackRangeMax = 10` is measured, not chosen

The classic land graph has diameter **10**: at range 10 every ordered pair of the 1 722 is
reachable. A larger value is not dangerous, merely meaningless — it cannot reach an eleventh step
that does not exist, and it can never open a sea crossing, because the range function is handed
`map.landNeighbours` and has no access to `map.seaRoutes` at all (C-08, enforced by construction).

### What `diceSides` does and does not change

| Changes | Does not change |
|---|---|
| Every drawn face, and therefore every outcome | The **number** of random draws per roll |
| Every `winChance` the server computes | `defenderWinsTies` — strict `>` on two drawn values |
| Pip vs numeral presentation (UX-06, `≤ 6` vs `> 6`) | Any client code at all |

Reference odds at the two interesting values, verified by exhaustive enumeration:

| Matchup | d6 | d7 | Change |
|---|---|---|---|
| 1 v 1 | 15/36 = 0.4167 | 21/49 = 0.4286 | +1.19 pp |
| 2 v 1 | 125/216 = 0.5787 | 203/343 = 0.5918 | +1.31 pp |
| 3 v 1 | 855/1296 = 0.6597 | 1617/2401 = 0.6735 | +1.37 pp |
| 1 v 2 | 55/216 = 0.2546 | 91/343 = 0.2653 | +1.07 pp |
| 3 v 2 | 2890/7776 = 0.3717 | 6559/16807 = 0.3903 | +1.86 pp |

Every denominator is `N^(a+d)`, so the five published d6 fractions are the `N = 6` instance of the
same enumeration — no new oracle machinery was needed for any other face count. The 1 v 1 case has
a closed form:

$$P(\text{attacker wins, 1v1}) = \frac{N-1}{2N}$$

verified against enumeration for **every N from 2 to 20**. The defender's advantage *is* the tie,
and `P(tie) = 1/N` falls as `N` rises — so **more faces means a slightly weaker defender**,
monotonically approaching a coin flip from below. Raising the face count does not make combat
swingier; players assume it does.

---

## G.5 `cards` — 13 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `wildCount` | `2` | int ≥ 0 | **SOURCED** | TC-CRD family |
| `maxCardsBeforeForcedTrade` | `5` | int ≥ `setSize` | **SOURCED** | TC-CRD family (FR-35) |
| `maxCardsAfterElimination` | `6` | int ≥ `setSize` | **SOURCED** | TC-ELM family (FR-36) |
| `setSize` | `3` | 3 | **LOCKED** | TC-CRD family |
| `awardPerTurn` | `1` | int ≥ 0 | **SOURCED** | TC-CRD family |
| `awardRequiresConquest` | `true` | bool | **SOURCED** | TC-CRD family |
| `territoryBonusArmies` | `2` | int ≥ 0 | **SOURCED** (FR-37) | TC-CRD family |
| `territoryBonusMaxPerTurn` | `2` | int ≥ 0 | ASSUMPTION | TC-CRD family |
| `tradeValues` | `[4,6,8,10,12,15,20,25]` | ascending ints | **mixed** — 4, 6, 8, 20, 25 SOURCED; 10, 12, 15 inferred | TC-CRD family |
| `tradeIncrementAfterTable` | `5` | int ≥ 0 | **SOURCED** | TC-CRD family |
| `symbols` | 6 entries | fixed set | ASSUMPTION | TC-MAP-04, TC-CAP family |
| **`distinctSetRule`** | `"any_distinct"` | `"any_distinct"` \| `"classic_triple"` | **UNCONFIRMED D-27** | **TC-CRD-06** |
| **`wildSubstitution`** | `"joker"` | `"joker"` \| `"pair_only"` | **UNCONFIRMED D-28** | **TC-CRD-06** |

### `territoryBonusMaxPerTurn` counts armies, not bonuses

The prose in [`07-game-design.md`](../docs/07-game-design.md) reads *"capped at 2 per turn"*, which
is ambiguous. The pseudocode in [`E-pseudocode.md`](E-pseudocode.md) §E.8 is not — it breaks on
`granted ≥ territoryBonusMaxPerTurn` where `granted` accumulates **armies**:

```
if granted ≥ rules.cards.territoryBonusMaxPerTurn: break
granted ← granted + rules.cards.territoryBonusArmies
```

At `2 / 2` the first bonus sets `granted = 2` and the break fires, so **a turn yields at most one
+2 bonus.** If the intent was two separate bonuses, this key should read **`4`**. Flagged for the
reviewer; the interface labels the counter in armies so that either reading renders correctly
([05 §5.5](../design/05-card-ui-ux.md)).

### D-27 and D-28 change whether a forced trade is always satisfiable

Both are implemented and both await sign-off. They are not cosmetic: they decide whether `mustTrade`
can be true while **no** legal `TradeSet` exists. Exhaustively enumerating every 5-card hand over
the six symbols (at most 2 Wilds):

| `distinctSetRule` | `wildSubstitution` | 5-card hands with **no** valid set |
|---|---|---|
| **`any_distinct`** | **`joker`** | **0** ← the configured default |
| `any_distinct` | `pair_only` | **0** |
| `classic_triple` | `joker` | **39** |
| `classic_triple` | `pair_only` | **51** |

Smallest counterexample under `classic_triple`: `{Infantry, Infantry, Cavalry, Cavalry, AirForce}`.

**At the configured values the unsatisfiable state is unreachable** — five cards cannot show fewer
than three distinct symbols without containing three alike. Selecting `classic_triple` makes it
reachable, and therefore requires an engine change as well as a rules edit: `LegalDraft` must fall
through to offering `PlaceArmies` and `EndPhase` rather than returning an empty list, or `Legal`
stops being total. The UI side is specified at [05 §5.7](../design/05-card-ui-ux.md).

> This is the concrete content of the rules file's own warning that D-27 and D-28 *"change how often
> a forced trade (FR-35) is satisfiable"*. The answer is: from **never unsatisfiable** to
> **unsatisfiable in 39 or 51 hands**.

---

## G.6 `capability` — 5 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `rule` | `"CAP-1"` | `"CAP-1"` | LOCKED | TC-MAP-05 |
| `seatHoldsCapabilityFromTerritories` | `true` | bool | ASSUMPTION **CAP-2** | TC-CAP family |
| `seatHoldsCapabilityFromCards` | `true` | bool | ASSUMPTION **CAP-2** | TC-CAP family |
| `nonActionSymbols` | Infantry, Cavalry, Artillery | subset of `cards.symbols` | ASSUMPTION **D-09** | TC-CAP family |
| `actionSymbols` | AirForce, NavalForce | subset of `cards.symbols` | ASSUMPTION **D-09** | TC-CAP family, TC-AIR, TC-NAV |

`profile(t) = {Infantry} ∪ ({NavalForce} if t.coastal) ∪ {t.cardSymbol}` — **derived, never
stored** (FR-41, D-10). TC-MAP-05 re-derives all 42 profiles and fails if an authored one has
drifted.

**A Wild has no profile (D-20).** It is in `cards.symbols` and in neither `nonActionSymbols` nor
`actionSymbols`, which is why the capability panel has no Wild row.

---

## G.7 `airForce` — 7 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `enabled` | `true` | bool | ASSUMPTION | TC-AIR family |
| `maxRange` | `5` | 1 – 10 | **LOCKED** | TC-AIR family |
| `rangeGraph` | `"land"` | `"land"` | **LOCKED** (C-08) | TC-AIR family |
| `minRange` | `1` | int ≥ 1 | ASSUMPTION | TC-AIR family |
| `attacksPerTurn` | `1` | int ≥ 0 | ASSUMPTION **AIR-1** | TC-AIR family |
| `requiresCapability` | `true` | bool | ASSUMPTION | TC-CAP family |
| `usesStandardCombat` | `true` | bool | **LOCKED** (FR-31) | **TC-ARC-05** |

Measured reach at range 5 on the classic board: **1 330 of 1 722 ordered pairs = 77.2 %**. Graph
diameter 10. Worst origin `eastern_australia` (11 of 41), best `ukraine` (40 of 41), mean 31.7.

### The Air Force's distinctiveness depends on `combat.attackRange`

Post-D-30 both land attack and the Air Force call the **same** range function over the **same**
land graph, differing only in the range argument. So:

| `combat.attackRange` | What the Air Force still adds |
|---|---|
| `1` (default) | Reach up to 5 steps, plus the capability gate and the one-per-turn limit |
| `2` – `4` | Progressively less extra reach |
| **`≥ 5`** | **No extra reach at all.** Only `attacksPerTurn: 1` and the capability requirement remain |

That is not a defect, but it is a consequence a reviewer should see stated: raising `attackRange` to
5 or above makes the Air Force a strictly worse land attack. `usesStandardCombat: true` is what
keeps this safe — there is exactly one combat implementation (TC-ARC-05), so the two paths cannot
drift even as their ranges converge.

---

## G.8 `navalForce` — 7 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `enabled` | `true` | bool | ASSUMPTION | TC-NAV family |
| `requiresCapability` | `true` | bool | ASSUMPTION | TC-CAP family |
| `allowsAttack` | `true` | bool | ASSUMPTION | TC-NAV family |
| `allowsFortify` | `true` | bool | ASSUMPTION **D-19** | TC-FRT family |
| `allowsOccupy` | `true` | bool | ASSUMPTION **D-18** | TC-CMB-07 |
| `usesStandardCombat` | `true` | bool | **LOCKED** (FR-31) | **TC-ARC-05** |
| `unitsRequiredPerRoute` | `0` | int ≥ 0 | ASSUMPTION **NAV-1** | TC-NAV family |

Setting `enabled: false` requires `seaRoutes` count `0` (D-13, `400` otherwise) — that is the
classic-only configuration.

A naval fortification **consumes the same single fortification** as a land one (D-19, FR-49), and
is not a distinct action type: it is `Fortify(from, to, n)` whose destination happens to be across a
sea route (§E.4.4).

**TC-NAV-03** covers the case Appendix D §D.5 records: capability held, but no sea route touches an
owned territory, so no naval action is offered. Capability is a gate, not a guarantee.

---

## G.9 `seaRoutes` — 8 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `min` | `2` | int ≥ 0 | ASSUMPTION **SEA-1** | TC-SEA family |
| `max` | `10` | int ≥ `min` | ASSUMPTION **SEA-1** | TC-SEA family |
| `default` | `4` | within `[min, max]` | ASSUMPTION **SEA-1** | TC-SEA family |
| `endpointsMustBeCoastal` | `true` | bool | **LOCKED** | TC-MAP-04, TC-SEA family |
| `forbidExistingLandAdjacency` | `true` | bool | **LOCKED** | TC-SEA family |
| `forbidDuplicate` | `true` | bool | **LOCKED** | TC-SEA family |
| `preferDifferentContinents` | `true` | bool | ASSUMPTION | TC-SEA family |
| `maxGenerationAttempts` | `500` | int ≥ 1 | ASSUMPTION | TC-SEA family |

The seat chooses the **count** at setup (S-05); the system chooses the **endpoints**. Generated
routes are frozen into `matches.effective_map`, so they are reproducible from the match row alone
and a later edit to this section cannot move a running match's routes.

`422` on failure, **creating nothing** — if the requested count cannot be placed within
`maxGenerationAttempts`, the response states how many were placeable and no match is created.

> A sea route is **not** a `crossesWater` edge. The map's 10 `crossesWater` entries are a render
> hint with no mechanical meaning and are a subset of `neighbours`; sea routes are generated,
> counted, and require the Naval capability. [03 §3.6](../design/03-map-ui-ux.md) tables the
> difference, because conflating them mis-plans every turn.

---

## G.10 `fortify` — 2 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `mode` | `"single_pair"` | `"single_pair"` \| `"one_step_all"` \| `"connected_path"` | ASSUMPTION **D-16** | TC-FRT family |
| `mustLeaveBehind` | `1` | int ≥ 1 | **SOURCED** (DR-04) | TC-FRT family |

Published RISK rules **disagree** with one another here, which is exactly why this is data: a
trained RL checkpoint can assert which variant it learned rather than silently assuming one.

---

## G.11 `match` — 4 keys

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `roundCap` | `100` | int ≥ 1 | **SOURCED** (MARS) | TC-VIC family |
| `capTiebreak` | `"territoryCount"` | `"territoryCount"` | ASSUMPTION | TC-VIC family |
| `turnTimerSeconds` | `0` | int ≥ 0 | ASSUMPTION — `0` = unenforced | — |
| `aiMinimumThinkTimeMs` | `400` | int ≥ 0 | ASSUMPTION **D-22** | TC-API-07 |

`turnTimerSeconds: 0` is deliberately unenforced in v1. The field exists now so that online play in
Phase 6 is a **configuration** change rather than a schema change. [07 §7.8](../design/07-responsive-and-accessibility.md)
records the consequence: nothing in the product expires on a timer.

`aiMinimumThinkTimeMs` is applied **at the API layer, not in the agent** (D-22) — so RL training and
`Sim` runs execute at full speed while a human-facing match still gets a readable pause.

---

## G.12 `ai` — 29 keys

### MARS heuristic coefficients — 13 keys, all SOURCED

| Key | Default | | Key | Default |
|---|---|---|---|---|
| `ai.mars.C_sv` | `70.0` | | `ai.mars.C_eoc` | `4.0` |
| `ai.mars.C_fn` | `1.2` | | `ai.mars.P_db` | `3.5` |
| `ai.mars.C_en` | `-0.3` | | `ai.mars.P_ob` | `170.0` |
| `ai.mars.C_fnu` | `0.05` | | **`ai.mars.W_p`** | **`0.7375`** |
| `ai.mars.C_enu` | `-0.03` | | `ai.mars.W_p1` | `0.25` |
| `ai.mars.C_cb` | `0.5` | | `ai.mars.G_l` | `5` |
| `ai.mars.C_oc` | `20.0` | | | |

`W_p` is the difficulty dial. Pinned by **TC-AI** family; **TC-AI-01** asserts a **zero
invalid-action rate** (NFR-20) across every agent, which is the property that matters most here —
coefficients change how well an agent plays, never whether its moves are legal.

### Difficulty table — 12 keys, ASSUMPTION AI-1

| Difficulty | `agent` | Overrides |
|---|---|---|
| `Easy` | `PassiveBot` | — |
| `Normal` | `MarsBot` | `W_p: 0.85`, `G_l: 0`, `temperature: 1.0` |
| `Hard` | `MarsBot` | `W_p: 0.7375`, `G_l: 5`, `temperature: 0.5` |
| `Brutal` | `OnnxPolicyAgent` | `temperature: 0.0`, **`fallback: "MarsBot"`** |

`Brutal`'s `fallback` is what keeps the optional RL work optional: with no ONNX checkpoint present
the difficulty still resolves, to `MarsBot`. Nothing in the shipped product depends on Phase 13.

### Bot thresholds — 4 keys

| Key | Default |
|---|---|
| `ai.bots.PassiveBot.minWinChance` | `0.80` |
| `ai.bots.PassiveBot.neverLeaveBelow` | `3` |
| `ai.bots.ChaoticBot.minWinChance` | `0.00` |
| `ai.bots.AggressiveBot.minWinChance` | `0.45` |

---

## G.13 `rl` — 12 keys, all OPTIONAL

| Key | Default | | Key | Default |
|---|---|---|---|---|
| `rl.gamma` | `0.995` | | `rl.gnn.layers` | `3` |
| `rl.reward.win` | `1.0` | | `rl.gnn.hidden` | `128` |
| `rl.reward.loss` | `-1.0` | | `rl.opponentPool.current` | `0.40` |
| `rl.reward.drawAtCap` | `0.0` | | `rl.opponentPool.frozenCheckpoints` | `0.30` |
| `rl.reward.perStep` | `-0.0005` | | `rl.opponentPool.mars` | `0.20` |
| `rl.shipGate` | beat MarsBot over ≥ 1000 seeded matches | | `rl.opponentPool.chaotic` | `0.10` |

Pinned by **TC-RL-01…04**, all marked **(OPT)** and skipped entirely if Phase 13 is not reached.

> **Nothing in the engine, API, database or clients depends on `rl.*`.** The game is complete and
> shippable at Phase 7 with heuristic AI (NFR-24). The opponent pool weights sum to 1.00.

---

## G.14 `formatVersion` — 1 key

| Key | Default | Permitted | Status | Pinned by |
|---|---|---|---|---|
| `formatVersion` | `1` | int ≥ 1 | LOCKED for v1 | TC-ARC-03 |

---

## G.15 The frozen-per-match set

These values are **copied into `matches.options` at match creation and read only from there.**
Editing them in `rules.json` affects **new** matches only.

| Key | Where it lives during a match | Surfaced as |
|---|---|---|
| `combat.diceSides` | `matches.options.diceSides` | read-only on S-20, the dice-tray badge, the replay header |
| `combat.attackRange` | `matches.options.attackRange` | read-only on S-20 |
| resolved sea-route count and endpoints | `matches.effective_map` | read-only on S-20 |

### Why this is the most dangerous class of key in the file

Suppose `diceSides` were read **live** instead. A resumed match would consume **exactly one random
draw per roll**, exactly as before — the draw *count* is unchanged. So `rng_position` would track
the log perfectly, every determinism test would pass, and **every face and every outcome would
differ.**

| Test | Detects a live `diceSides` read? |
|---|---|
| TC-DET-01 … TC-DET-04 | **No.** The draw count is unchanged, so `Position` tracks the log |
| TC-ARC-03 | Partially — covers the no-hidden-state side |
| **TC-PER-07** | **Yes.** It asserts the *source* of the value, not the value |

**TC-PER-07 is the only guard**, and it is the only test in the suite that asserts where a number
came from rather than what it equals. That is why it exists and why it must not be "simplified"
into an equality check.

The interface consequence is in [04 §4.8](../design/04-dice-ui-ux.md): no control anywhere offers
to change a face count mid-match, and every in-match surface showing one is labelled *"fixed when
the match was created."*

---

## G.16 Open items for the reviewer

| # | Key | Question | Consequence if changed |
|---|---|---|---|
| 1 | `cards.distinctSetRule` (**D-27**) | `any_distinct` or `classic_triple`? | `classic_triple` makes a forced trade unsatisfiable in **39** of the 5-card hands, which needs a `LegalDraft` fall-through **and** a UI empty state (§G.5) |
| 2 | `cards.wildSubstitution` (**D-28**) | `joker` or `pair_only`? | Under `classic_triple`, `pair_only` raises 39 bad hands to **51** |
| 3 | `cards.territoryBonusMaxPerTurn` | Is "capped at 2 per turn" two **armies** or two **bonuses**? | As written the cap is two armies, i.e. one bonus. Two bonuses needs the value **`4`** (§G.5) |
| 4 | `combat.attackRange` ≥ 5 | Acceptable that the Air Force then confers no extra reach? | Not a defect; the capability gate and `attacksPerTurn: 1` remain (§G.7) |

Items 1 – 3 should be settled **before Phase 4**. Item 4 is informational: it needs an
acknowledgement, not a change.

---

## G.17 Reconciliation

| Section | Keys | Section | Keys |
|---|---|---|---|
| `formatVersion` | 1 | `airForce` | 7 |
| `setup` | 8 | `navalForce` | 7 |
| `draft` | 3 | `seaRoutes` | 8 |
| `combat` | 13 | `fortify` | 2 |
| `cards` | 13 | `match` | 4 |
| `capability` | 5 | `ai` | 29 |
| | | `rl` | 12 |
| | | **Total** | **112** |

13 sections, 112 leaf keys, every one tabled above. `_comment`, `_note`, `_note_*` and `_rule_text`
members are documentation inside the data file and carry no behaviour.

---

**Appendix index:** [A](A-api-contract.md) · [B](B-database-schema.sql) · [C](C-map-specification.md) ·
[D](D-capability-mapping-decision-table.md) · [E](E-pseudocode.md) · [F](F-test-cases.md) · G ·
[H](H-additional-diagrams-and-screenshots.md)
