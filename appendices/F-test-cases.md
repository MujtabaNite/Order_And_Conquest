# Appendix F — Test Cases

> **Deliverable S (part).** The 119 enumerated test cases of §9, each with its level, precondition, steps,
> expected result and oracle.
>
> [§9 Testing](../docs/09-testing.md) states the strategy, the four oracles and what is tested at which
> level. This appendix is the catalogue that chapter refers to. Every identifier here is one cited in the
> **Test** column of [`13-traceability-matrix.md`](../docs/13-traceability-matrix.md), and the counts
> reconcile against §9.1 in [§F.23](#f23-count-reconciliation).

> **No case in this appendix has been executed.** This is a specification of tests, not a report of
> results. Outcomes belong in §9.6, which is deliberately empty until the suite is run (§39). A case here
> describes what *will* be asserted; it makes no claim that the assertion currently holds.

---

## F.1 How to read a case

Each family is a table. The columns are the same throughout:

| Column | Content |
|---|---|
| **ID** | The identifier used in §9, §13 and the source `[Fact]` / `[Theory]` name |
| **Precondition** | The state the case arranges before acting. `—` means none beyond a constructed engine |
| **Steps** | What the case does |
| **Expected result** | The assertion. This is the pass condition, stated so a reader can check it without the code |
| **Oracle** | Which of the four oracles of §9.1 supplies the expected value |
| **Verifies** | The FR, DR or NFR this case is the evidence for, per §13 |

**Level is stated once per family**, in the family heading, because no family mixes levels. The one
apparent exception is TC-UI-04, which crosses an integration boundary but is counted at the Client level;
§9.3 records that deliberately and so does the case.

### Oracle abbreviations

| Short | Oracle | What it means |
|---|---|---|
| **CF** | Closed form | A value computed independently of the implementation — the combat fractions, the reinforcement formula, the escalation table |
| **IC** | Independent computation | A property recomputed by different means *inside the test* — a naive BFS compared against `Legal` |
| **INV** | Invariant | A property that must hold after *any* action, asserted after every applied action |
| **GF** | Golden file | A recorded expected output, reviewed once by a human. Used only for determinism, never for rules |

A golden file records what the code *did*, not what it *should* do. Where a closed form exists — which,
for a dice game with a published rule set, is nearly everywhere — it is used instead.

### Priority

Cases are mandatory unless marked **(OPT)**. Five are optional: TC-RL-01…04 and TC-AI-05. They are gated
on the optional RL component and none of the other 111 depends on them (NFR-24).

## F.2 Fixtures

Every case draws from this set and no other. A case that needs a state not reachable from these fixtures
constructs it directly in the test body and says so.

| Fixture | Contents | Used by |
|---|---|---|
| `shared/maps/world_classic.json` | The authored 42-territory board. The same file the product ships | Most families |
| `tests/fixtures/tiny_12.json` | A 12-territory hand-authored map, 3 continents, 2 coastal pairs. Fast rule tests and curriculum stage 1 | TC-CMB, TC-CRD, TC-CAP, TC-AIR, TC-NAV |
| `tests/fixtures/invalid_V01.json` … `invalid_V12.json` | One deliberately broken map per validation rule | TC-MAP-08, 09, 10 |
| `tests/fixtures/seeds.json` | Named seeds with recorded outcomes — `seedAlpha`, `seedBravo`, `seedCharlie` | TC-DET, TC-AI-06 |
| `ThrowingRandomSource` | An `IRandomSource` that throws on any draw | TC-AI-04 |
| `CountingRandomSource` | An `IRandomSource` that records `Position` without altering behaviour | TC-CMB-06, TC-AI-04 |

`tiny_12.json` exists because a 42-territory board makes a card-escalation test slow and a hand-checked
capability table unreadable. It is validated by the same twelve rules as the shipping board, so using it
is not a weaker test — TC-MAP-10 asserts that.

---

## F.3 TC-ARC — Architecture and structure

**Level: Architecture · 5 cases.** These assert facts about the build, not about behaviour. They run
first in CI because they fail at the only moment the failure is cheap to fix.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-ARC-01** | The solution compiles | Reflect over `OrderAndConquest.Engine`'s referenced assemblies, transitively | The closure contains no web framework, no ORM, no database driver and no file-system API. The assertion names the offending reference on failure | INV | NFR-01 |
| **TC-ARC-02** | A `GameState` built from `world_classic.json` at any phase | Deep-clone the state, call `Apply(state, action)`, deep-compare the original against the clone | The input state is byte-identical before and after. Asserted for one action of every action kind | INV | NFR-03, FR-22 |
| **TC-ARC-03** | Source of `Engine/Rules/` | Parse every rules module for numeric literals, excluding `0`, `1`, `-1` and array indices | No tunable number appears as a literal. Every dice bound, army minimum, range, cap and trade value resolves through the bound `RuleSet` | INV | NFR-16 |
| **TC-ARC-04** | The three client projects | Search each client for combat resolution, adjacency computation, range computation, reinforcement arithmetic, set recognition and victory detection | None is present in any client. A client computes no rule outcome | INV | NFR-17, FR-67 |
| **TC-ARC-05** | `ChaoticBot` at every seat, both map kinds, a seeded range of seeds | Play matches to conclusion. After **every** applied action, assert the full invariant set | Zero violations across the whole run. Exactly one combat implementation is reached, asserted by instrumenting the resolver entry point | INV | NFR-01, FR-21, FR-31, DR-04, DR-05, DR-19 |

### The invariant set asserted by TC-ARC-05

This list is the definition referred to by every other case that says "the invariant set". It is asserted
after each applied action, not at the end of a match, so the failing action is the one reported.

| # | Invariant | Source |
|---|---|---|
| 1 | Every territory has exactly one owner and at least 1 army | DR-04 |
| 2 | Army totals change only by combat losses — no action creates or destroys armies except draft placement and combat | DR-05 |
| 3 | The sum of seat army pools plus armies on the board equals the issued total minus combat losses | DR-05 |
| 4 | No eliminated seat is the current seat, and no eliminated seat appears in a legal action | DR-14 |
| 5 | A `Neutral` seat is never offered a turn | DR-15 |
| 6 | Card count per seat never exceeds the configured post-elimination cap | FR-36 |
| 7 | The escalation table position never decreases | DR-13 |
| 8 | `rng_position` is non-decreasing and advances only through combat and seeded allocation | NFR-02 |
| 9 | Every action applied was a member of the `Legal` list computed immediately before it | FR-21, NFR-20 |
| 10 | Capability is recomputed, never read from a field | FR-41 |

**TC-ARC-05 is the case that finds the rule interaction nobody wrote a case for** — a card trade during a
forced trade after an elimination that crossed a continent boundary. It is also the slowest case in the
suite, which is why it is a nightly gate for long runs and a short seeded run on merge.

---

## F.4 TC-DET — Determinism and replay

**Level: Unit · 4 cases.** The family NFR-02 rests on.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-DET-01** | `seedAlpha`, `world_classic.json`, a recorded 200-action sequence | Run the sequence twice in separate processes | Identical dice faces in identical order, identical final state hash, identical `Position` | GF | NFR-02, FR-29 |
| **TC-DET-02** | `territoryAllocation = "random"`, `seedBravo`, 6 seats | Allocate twice | Identical territory-to-seat assignment and identical starting army placement | GF | NFR-02, FR-17 |
| **TC-DET-03** | A match played 120 actions deep, its snapshot and its `moves` log | Replay the log from the initial state into a fresh engine | The replayed state hash equals the stored snapshot hash, and the replayed `Position` equals `matches.rng_position` | GF | NFR-02, FR-22, FR-58 |
| **TC-DET-04** | The same seed and action sequence as TC-DET-01 | Execute on two CI runner images with different operating systems | Identical state hash on both. The case fails if any state serialisation depends on dictionary enumeration order | GF | NFR-02 |

### Why TC-DET-04 runs on a second runner image

The trap is §8.3's: a state hash built by enumerating a dictionary is stable within one runtime and
unstable across two. It passes on the developer's machine and fails in the marker's, and the symptom —
"replay sometimes disagrees" — is the most expensive class of defect in this codebase to diagnose.

One extra CI job on a different image converts that into a red build on the commit that introduced it.

---

## F.5 TC-MAP — Map validation and generation

**Level: Unit · 10 cases.** The validation gate is `Engine/Validation/MapValidator`, and the twelve rules
V-01…V-12 are defined in [Appendix C §C.4](C-map-specification.md).

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-MAP-01** | `world_classic.json` | Run the full twelve-rule gate | Passes all twelve. Territories 42, continents 6, land edges 83, continent sizes 9/4/7/6/12/4, bonuses 5/2/5/3/7/2 — each asserted against the file, not against a hand-typed constant | CF | FR-09, FR-08 |
| **TC-MAP-02** | `world_classic.json` | Recompute symmetry (V-01) and connectivity (V-07) by an independent BFS written in the test | Adjacency is symmetric in both directions for all 83 edges; the land graph is a single connected component | IC | DR-01, DR-02, FR-26 |
| **TC-MAP-03** | `world_classic.json` | Recompute the continent partition (V-06) and the `crossesWater` subset check (V-12) | Every territory is in exactly one continent; the union of continents is the territory set; every `crossesWater` pair is an existing adjacency edge | IC | DR-03, FR-47 |
| **TC-MAP-04** | `world_classic.json` | For every territory, test V-11 | No landlocked territory carries a `NavalForce` card symbol. Violation count is 0 | INV | FR-11, DR-17 |
| **TC-MAP-05** | `world_classic.json` | For every territory, derive its profile by CAP-1 in the test and compare against the stored `capabilities` array (V-10) | All 42 derivations agree. A drifted authored profile fails and names the territory | IC | FR-11 |
| **TC-MAP-06** | `MapGenerator`, a fixed seed and parameter set | Generate twice, in separate processes | Byte-identical map output, including territory ordering, adjacency ordering and continent assignment | GF | FR-07, NFR-02 |
| **TC-MAP-07** | `MapGenerator`, 200 distinct seeds | Generate and run the full gate on each | Every generated map passes all twelve rules. Generation never returns an invalid map; on internal failure it reseeds within the attempt bound | INV | FR-07, FR-08 |
| **TC-MAP-08** | `invalid_V01…V05.json` | Load each | Each is rejected naming exactly its own rule — asymmetric adjacency, self-loop, duplicate edge, dangling neighbour key, orphan continent key. No map is silently repaired | INV | FR-08 |
| **TC-MAP-09** | `invalid_V06…V09.json` | Load each | Each is rejected naming its rule — split continent, disconnected island group, `territories < 2 × maxPlayers`, a continent with no border territory | INV | FR-08 |
| **TC-MAP-10** | The full `invalid_*.json` set, all twelve | Load every fixture; also run the gate over `tiny_12.json` | Twelve fixtures, twelve rejections, twelve distinct machine-readable reasons. `tiny_12.json` passes all twelve, so the fast fixture is held to the shipping standard | INV | FR-08 |

### A failing map is rejected, never repaired

TC-MAP-08, 09 and 10 assert the rejection *and* the reason code. A validator that rejects everything
passes a test that only checks for failure, which is why each case pins the specific rule named.

This is the negative-testing obligation of §9.1: *a validator with no negative tests is a validator that
has never been shown to reject anything.*

---

## F.6 TC-DRF — Setup, reinforcement and draft

**Level: Unit · 6 cases.**

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-DRF-01** | A seat holding *t* territories, no full continent, no trade, for *t* = 12, 14, 21, 30, 42 | Compute reinforcements | `⌊t / 3⌋` exactly: 4, 4, 7, 10, 14 | CF | FR-23 |
| **TC-DRF-02** | A seat holding *t* territories for *t* = 1…11 | Compute reinforcements | `3` for every *t* from 1 to 11 — the floor holds across the whole range, not only at *t* = 1 | CF | FR-23, DR-08 |
| **TC-DRF-03** | A seat holding every territory of one continent, for each of the 6 continents in turn | Compute reinforcements | The continent's configured bonus is added: 5, 2, 5, 3, 7, 2 respectively | CF | FR-24 |
| **TC-DRF-04** | A seat holding every territory of a continent **except one** | Compute reinforcements | **No bonus at all.** Asserted for each of the 6 continents, and for each of several distinct missing territories | CF | FR-24, DR-09 |
| **TC-DRF-05** | A seat at `Draft` with a computed pool, holding a mix of owned and unowned territories | Enumerate `Legal`; attempt a placement on an unowned territory | Placement targets are exactly the owned set. The unowned placement is absent from `Legal`, and applying it directly changes nothing and consumes no randomness | IC | FR-23, FR-22 |
| **TC-DRF-06** | Match creation at 3, 4, 5 and 6 seats, both allocation modes | Create and inspect the initial state | Starting armies are 35 / 30 / 25 / 20 by seat count. Every territory is allocated exactly once; every army issued is placed; no territory holds 0 | CF, INV | FR-17, FR-18 |

### The 2-seat row

A 2-seat match is created as **three** seats with a `Neutral` (FR-14, D-07) and therefore takes the
3-seat army count of 35. TC-DRF-06 asserts the arithmetic; the behavioural half — that the `Neutral` is
never offered a turn — is TC-SYS-02, because it needs a match to play out rather than a state to inspect.

---

## F.7 TC-CMB — Dice combat and occupation

**Level: Unit · 10 cases.** The family with the project's only statistical assertion, and the one
load-bearing case the whole rule set hangs on.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-CMB-01** | `world_classic.json`, a seat owning a known territory set, `attackRange = 1` (the default) | Enumerate legal attack targets; recompute the expected set from the map file's neighbour lists in the test | The two sets are equal. No non-adjacent target appears; no adjacent enemy target is missing; no owned territory is a target | IC | FR-26 |
| **TC-CMB-02** | An origin holding *n* armies, *n* = 1…6 | Enumerate legal dice counts | Attacker dice 1–3, defender dice 1–2. An origin with 1 army offers no attack. Dice requested must be strictly fewer than armies in the origin | CF | FR-26, FR-27 |
| **TC-CMB-03** | Pinned dice: attacker `[6, 5]`, defender `[6, 5]`; and attacker `[6]`, defender `[6]` | Resolve | **The defender wins both comparisons.** The attacker loses 2 armies in the first case and 1 in the second; the defender loses none | CF | FR-27, DR-07 |
| **TC-CMB-04** | Pinned dice: attacker `[3, 6, 2]`, defender `[5, 4]` | Resolve | Comparison is by descending order after sorting — 6 v 5 (attacker wins), 3 v 4 (defender wins) — **not** by the order the dice were drawn. One loss each | CF | FR-27 |
| **TC-CMB-05** | Pinned dice across all 1–3 × 1–2 shapes | Resolve each | Exactly one army is lost per comparison made, by the loser of that comparison. The number of comparisons is `min(attackerDice, defenderDice)` | CF | FR-27 |
| **TC-CMB-06** | `CountingRandomSource`, a large seeded sample per dice shape | Resolve repeatedly and tally outcomes | The observed frequencies match the five exact fractions within a tolerance derived from the sample size: 1:1 → 15/36 (0.4167); 2:1 → 125/216 (0.5787); 3:1 → 855/1296 (0.6597); 1:2 → 55/216 (0.2546); 3:2 attacker takes both → 2890/7776 (0.3717). The test is seeded and cannot flake | CF | FR-27, DR-07 |
| **TC-CMB-07** | A capture with *d* dice rolled, origin holding *a* armies | Occupy | At least *d* armies move in; at least 1 remains behind; the mover may choose any count in `[d, a − 1]`; a count outside that range is not legal | CF, INV | FR-28, DR-06 |
| **TC-CMB-08** | Three attack kinds arranged to reach the same dice shape: `Attack`, `AirAttack`, `NavalAttack` | Instrument the combat resolver; execute one of each | All three enter the **same** resolver with the same arguments and produce the same outcome for the same pinned dice. Exactly one combat implementation exists | IC, INV | FR-31, DR-19 |
| **TC-CMB-09** | `world_classic.json`; matches created with `attackRange` = 1, 2, 3 and 5 | Enumerate legal land-attack targets per origin; recompute by a **naive BFS written in the test**, over land adjacency only, bounded at the configured range | The engine's target set equals the BFS result at every range. At range 1 it is exactly the adjacency list, so the default reproduces classic RISK. At range > 1 intervening ownership is **irrelevant** — a path through enemy territory counts. No sea route is ever traversed at any range | IC | FR-26, FR-85 |
| **TC-CMB-10** | Matches created with `diceSides` = 2, 6, 7 and 20 | For each, enumerate the observed face values over a large seeded sample, then tally outcome frequencies per dice shape | Every face drawn lies in `1 … diceSides` and every face in that range occurs. The 1:1 attacker win rate equals `(N − 1) / 2N` — 1/4 at N = 2, 15/36 at N = 6, 21/49 at N = 7, 19/40 at N = 20 — and the d7 column matches 203/343, 1617/2401, 91/343 and 6559/16807 for the other four shapes. `diceSides` outside `[2, 20]` is rejected at match creation, not mid-match | CF, IC | FR-84 |

### TC-CMB-03 is the case this project cannot afford to lose

Inverting one comparison shifts every figure in TC-CMB-06 by several percent. The game still plays. Every
smoke test still passes. Every agent trained against it learns a different game, and every evaluation
number in §10.3 becomes a measurement of the wrong rule set.

`combat.defenderWinsTies` in `shared/rules.json` carries the same warning in its own `_note`. TC-CMB-03
pins the flag and TC-CMB-06 pins its consequences, which is why both exist rather than one.

### Why TC-CMB-06 is statistical rather than exhaustive

The 3:2 shape has 7776 outcomes. Enumerating them is possible and would be a closed-form test; sampling
them is faster and, seeded, equally deterministic. The case asserts against the *exact fractions*, so the
oracle is still closed form — the sample only decides the tolerance.

### TC-CMB-10 needs no new oracle machinery

The five fractions TC-CMB-06 asserts are the `diceSides = 6` instance of exhaustive enumeration over
`N^(a+d)` equally likely outcomes — which is visible in the denominators themselves: 36, 216, 1296, 216,
7776. Changing the face count changes `N`, not the method. So TC-CMB-10 reuses the independent-computation
oracle §9.1 already defines, with one parameter supplied, and the d7 figures it asserts were produced by
the same enumerator that reproduces the d6 column exactly.

One property is worth asserting as well as computing: **every figure moves in the attacker's favour as
`N` rises.** The defender's structural advantage is the tie, `P(tie) = 1/N` on any compared pair, so
rarer ties mean a weaker defender and 1:1 combat approaching a coin flip from below. A test that merely
checked "the faces are in range" would pass against an implementation that had quietly inverted the tie
rule at N ≠ 6; asserting the closed form `(N − 1)/2N` across four face counts will not.

### Why TC-CMB-09 recomputes rather than reads a fixture

The range search is one BFS shared by land attacks and Air Force attacks (Appendix E §E.10), so a fixture
of expected target sets would be derived from the same traversal it is meant to check. The test writes its
own BFS instead — the same reason TC-AIR-02 does, and the same reason both cases bound it explicitly
rather than trusting the engine's frontier check.

---

## F.8 TC-CRD — Cards, sets, escalation and forced trades

**Level: Unit · 10 cases.**

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-CRD-01** | A deck built from `world_classic.json` | Inspect the deck | Exactly one card per territory (42) plus the configured wilds (2) = 44. Every territory appears exactly once. Every non-Wild card carries one of the five symbols | CF | FR-19, DR-10 |
| **TC-CRD-02** | A turn in which the seat captured at least one territory; and a turn in which it captured none | End each turn | One card awarded in the first case, **none** in the second. Never more than one card per turn regardless of how many territories were captured | INV | FR-32, FR-30, DR-11 |
| **TC-CRD-03** | Hands of three identical symbols, for each of the five non-Wild symbols | Test set recognition | Each is a valid set | CF | FR-33 |
| **TC-CRD-04** | Hands of three distinct non-Wild symbols, enumerated over all such combinations | Test set recognition | Each is a valid set under `distinctSetRule = "any_distinct"`. Under `"classic_triple"` only Infantry + Cavalry + Artillery is. **The case asserts whichever branch is configured**, and names the setting in its failure message | CF | FR-33 |
| **TC-CRD-05** | Hands of 2, 4 and 5 cards, including otherwise-valid symbol combinations | Test set recognition | None is a set. A set is **exactly** three cards; four- and five-card sets are rejected | CF | FR-33, DR-12 |
| **TC-CRD-06** | Hands containing one and two Wilds, in every combination with non-Wild symbols | Test set recognition | Under `wildSubstitution = "joker"`, any two cards plus a Wild form a set. Under `"pair_only"`, `{Infantry, Cavalry, Wild}` and `{X, Wild, Wild}` are **not** sets. The case asserts the configured branch | CF | FR-33, DR-12 |
| **TC-CRD-07** | A match with the escalation table `[4, 6, 8, 10, 12, 15, 20, 25]`, increment 5 after the table | Trade sets repeatedly across several seats and several turns | Values are awarded in table order, then `+5` per trade beyond the table: 30, 35, 40… The position advances **once per trade for the whole match**, never per seat, and **never resets** | CF, INV | FR-34, DR-13 |
| **TC-CRD-08** | A seat entering `Draft` holding exactly 5 cards | Enumerate `Legal` | The list contains **only** trade actions. No placement, no attack, no end-turn is legal until a set is traded | INV | FR-35 |
| **TC-CRD-09** | A seat holding 4 cards that eliminates an opponent holding 3 | Apply the elimination | The seat now holds 7, which exceeds the post-elimination cap of 6; it must trade down to fewer than 5 immediately, and only trade actions are legal until it does | INV | FR-36 |
| **TC-CRD-10** | A seat trading a set in which one card names a territory it owns; and a set naming two such territories | Trade | +2 armies placed **directly on that territory**, not into the pool. With two matching territories the bonus is capped at 2 armies for the turn | CF | FR-37 |

### Two settings this family cannot resolve on its own

`distinctSetRule` (D-27) and `wildSubstitution` (D-28) both change how often a forced trade (FR-35) is
satisfiable, and therefore change the oracle of TC-CRD-04, TC-CRD-06 and TC-CRD-08. `shared/rules.json`
records that both need a reviewer's confirmation before Phase 4.

The cases are written to assert **whichever branch is configured** and to name the setting when they
fail. That is the honest form: the test encodes the rule the project chose, not a rule the test author
preferred.

---

## F.9 TC-CAP — Capability derivation

**Level: Unit · 6 cases.** Capability is derived on demand and never stored (FR-41), which is exactly
what makes TC-CAP-04 and 05 load-bearing.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-CAP-01** | `world_classic.json` and `tiny_12.json` | For every territory, derive the profile by CAP-1 in the test: `{Infantry} ∪ ({NavalForce} if coastal) ∪ {cardSymbol}` | Derivation matches the engine for all 42 and all 12. No landlocked territory yields `NavalForce` | IC | FR-11, FR-51, DR-17 |
| **TC-CAP-02** | A seat owning one territory whose profile contains `AirForce`, and owning no such territory | Query capability | Holds `AirForce` in the first case, not in the second. CAP-2 from **territory ownership** | IC | FR-39 |
| **TC-CAP-03** | A seat owning no qualifying territory but **holding a card** whose profile contains `NavalForce` | Query capability | Holds `NavalForce`. CAP-2 from **cards in hand** is sufficient on its own | IC | FR-39 |
| **TC-CAP-04** | A seat holding `NavalForce` from its only coastal territory | Take that territory away by combat | Capability is **lost immediately**. Naval actions vanish from `Legal` on the same state transition, with no intervening turn boundary | INV | FR-41 |
| **TC-CAP-05** | A seat holding `AirForce` solely from a card in hand | Trade that card away in a set | Capability is **lost immediately**. Air Force actions vanish from `Legal` at once | INV | FR-41 |
| **TC-CAP-06** | Seats holding only Infantry, only Cavalry, only Artillery territories and cards | Enumerate `Legal` | No action is unlocked by any of the three. They are set-matching symbols only, exactly as in classic RISK | INV | FR-40 |

### Why 04 and 05 are the cases that catch a cache

The obvious optimisation — compute capability once per turn and store it — passes TC-CAP-01, 02, 03 and
06 and fails only 04 and 05. Losing the last coastal territory mid-turn must remove Naval actions on that
same transition, and a cache refreshed at the turn boundary will not.

FR-41 states the rule as *derive on demand, do not store*, and these two cases are what make that
statement enforceable rather than advisory.

---

## F.10 TC-AIR — Air Force

**Level: Unit · 6 cases.** Range is `maxRange = 5`, measured over land edges only.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-AIR-01** | A seat holding `AirForce`, owning a known origin on `world_classic.json` | Enumerate legal Air Force targets | Exactly the territories within 5 land edges that the seat does not own. Owned territories are never targets | IC | FR-42 |
| **TC-AIR-02** | Several origins spanning the board, including one at each graph extreme | Recompute reach by a **naive BFS written in the test**, bounded at `max(options.attackRange, airForce.maxRange)`, over land adjacency only | The engine's target set equals the BFS result for every origin, and **no attack of any kind is legal beyond that bound** — which evaluates to 5 at the defaults. Distance 1 through the bound inclusive; beyond it, empty | IC | FR-43, FR-85 |
| **TC-AIR-03** | A map state where the **only** path from origin to target of length ≤ 5 crosses a sea route | Enumerate legal Air Force targets | **The target is absent.** Sea routes are excluded from the range graph entirely; adding one to the edge set makes this case fail and nothing else | IC | FR-43, DR-18 |
| **TC-AIR-04** | A seat that has not yet used its Air Force attack this turn | Launch one air attack that captures a territory adjacent to none the seat owns; then attempt a second air attack | The first is legal and the captured **disconnected pocket is permitted and retained** (D-11). The second is absent from `Legal` — `attacksPerTurn` is 1, and the allowance resets only at the seat's next turn | INV | FR-45 |
| **TC-AIR-05** | Origins holding 1, 2 and 3 armies; dice counts 1–3 | Enumerate legal Air Force attacks | The same minimum-army and dice constraints as a land attack: origin needs ≥ 2 armies and strictly more armies than dice. No relaxation for being airborne | CF | FR-46 |
| **TC-AIR-06** | An Air Force attack and a land attack arranged to the same dice shape, same pinned dice | Resolve both | Identical outcome. Both enter the same resolver; occupation follows the ordinary rules including the leave-1-behind constraint | IC | FR-44, FR-31 |

### TC-AIR-03, stated plainly

The land-adjacency list and the sea-route list are one field apart in the map model. Including sea routes
in the range BFS is a two-character mistake that leaves the feature *apparently working* — Air Force
attacks still happen, targets still appear, combat still resolves — while making the locked rule false.

The independent BFS in TC-AIR-02 and the negative construction in TC-AIR-03 are what separate "the
feature works" from "the feature follows the rule".

---

## F.11 TC-NAV — Naval Force

**Level: Unit · 6 cases.** A sea route is an edge, never a territory (DR-16), and crossing costs nothing
(NAV-1).

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-NAV-01** | A seat holding `NavalForce`, owning one endpoint of a sea route whose other endpoint it does not own | Enumerate legal naval attacks | The route is offered as an attack. Routes to territories the seat already owns are not offered as attacks | IC | FR-48 |
| **TC-NAV-02** | A naval attack that reduces the defender to 0 | Occupy | Armies move **across the sea route** into the captured territory under the ordinary occupation rules. The route itself is unchanged, unowned and uncaptured | INV | FR-50, DR-16 |
| **TC-NAV-03** | A seat owning both endpoints of a sea route, having not yet fortified this turn | Fortify across the route; then attempt a land fortification in the same turn | The naval fortification is legal and **consumes the turn's single fortification**. The subsequent land fortification is absent from `Legal` | INV | FR-49 |
| **TC-NAV-04** | A naval attack and a land attack at the same dice shape, same pinned dice | Resolve both | Identical outcome through the same resolver. No separate naval combat path exists | IC | FR-50, FR-31 |
| **TC-NAV-05** | A seat **without** `NavalForce` capability owning a route endpoint; and a seat with capability owning no route endpoint | Enumerate `Legal` | No naval action in either case. Capability and an owned endpoint are both required | INV | FR-48 |
| **TC-NAV-06** | A landlocked territory; a match created with `navalForce.enabled = false` | Derive capability and enumerate `Legal` | A landlocked territory never grants Naval capability automatically. With naval disabled, the capability system reports no naval actions at all and the match is classic-only | INV | FR-51, DR-17 |

---

## F.12 TC-SEA — Sea routes

**Level: Unit · 6 cases.** The host chooses a **count**; the system chooses the endpoints. No interface
anywhere accepts a named pair (C-07).

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-SEA-01** | Configured range `[2, 10]`, default 4 | Request counts of 1, 2, 4, 10 and 11 | 2, 4 and 10 accepted. 1 and 11 rejected with the permitted range reported, and **no match created** | CF | FR-15 |
| **TC-SEA-02** | A generated route set on `world_classic.json` | Inspect every route | Both endpoints are coastal. A route is an edge in its own list, never an entry in the territory list and never an entry in land adjacency | INV | FR-16, FR-47, DR-16 |
| **TC-SEA-03** | A generated route set | For every route, test whether its endpoints are already land-adjacent | No route duplicates an existing land border. A sea route connects places the land graph does not | INV | FR-16 |
| **TC-SEA-04** | A generated route set | Compare every unordered endpoint pair | No duplicates. Requesting *n* routes yields *n* **distinct** connections, not *n* entries | INV | FR-16 |
| **TC-SEA-05** | A match created with 4 routes, then saved and resumed; and the source map file edited after creation | Resume and re-read the effective map | The same 4 routes, byte-identical. Routes are **frozen into `matches.effective_map`** at creation and never regenerated. Editing the map file does not alter the match | GF, INV | FR-10 |
| **TC-SEA-06** | A map and count for which the generator cannot place the requested number within `maxGenerationAttempts` | Attempt creation | Rejected, stating **how many were placeable**. **No match row exists** — no partial match is created (D-13) | INV | FR-16 |

### TC-SEA-06 and the partial-match rule

A partially created match is worse than a refused one: it occupies a room code, it appears in a resume
list, and it cannot be played. D-13 makes refusal the rule, and this case asserts the absence of the
match row rather than merely the presence of the error.

---

## F.13 TC-FRT — Fortification

**Level: Unit · 4 cases.** `fortify.mode` is data, and all three modes are asserted because a trained RL
checkpoint records which one it learned under (FR-83).

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-FRT-01** | `mode = "single_pair"`, a seat owning an adjacent pair | Fortify | One move between one pair per turn, leaving ≥ 1 behind. A second fortification is absent from `Legal` | CF, INV | FR-52, DR-06 |
| **TC-FRT-02** | `mode = "one_step_all"` | Enumerate legal fortifications | Armies may move one step from any owned territory to any adjacent owned territory, under the same leave-1-behind rule and the same one-per-turn allowance | INV | FR-52 |
| **TC-FRT-03** | `mode = "connected_path"`, a seat owning a chain of territories connected only through a third | Enumerate legal fortifications | Movement is legal between any two owned territories joined by a path of owned territories. A destination reachable only through an enemy territory is not legal | IC | FR-52 |
| **TC-FRT-04** | A seat owning both endpoints of a sea route, in each of the three modes | Fortify across the route, then attempt any second fortification | Legal in all three modes and **shares the single per-turn allowance** with land fortification. The second attempt is absent from `Legal` | INV | FR-49, FR-52 |

---

## F.14 TC-ELM — Elimination

**Level: Unit · 3 cases.**

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-ELM-01** | Seat A reduces seat B to its last territory and captures it; B holds 3 cards | Apply the capture | B is eliminated; **B's 3 cards transfer to A**; the eliminating seat is recorded on B's row | INV | FR-38, FR-53 |
| **TC-ELM-02** | A seat losing its last territory | Apply the capture | The seat is marked eliminated on the same state transition — not at the next turn boundary. `SeatEliminated` is emitted once | INV | FR-53 |
| **TC-ELM-03** | A match containing an eliminated seat | Advance turns around the table several full rounds | The eliminated seat is **never** the current seat, never appears in any legal action, and is skipped permanently. Turn order over the remaining seats is stable | INV | FR-25, DR-14 |

---

## F.15 TC-VIC — Victory and match end

**Level: Unit · 4 cases.**

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-VIC-01** | A seat owning every territory but one | Capture the last territory | Victory is declared **on that action**, not at the next phase or turn boundary | INV | FR-54 |
| **TC-VIC-02** | A finished match | Enumerate `Legal`; attempt any action | `Legal` is empty. `GameOver` was emitted exactly once. Any submitted action is rejected with no state change | INV | FR-54 |
| **TC-VIC-03** | `roundCap = 100`, a match reaching round 100 with no domination | Advance past the cap | The match ends at the cap. No 101st round begins | CF | FR-55, DR-20 |
| **TC-VIC-04** | A match ended at the cap with seats holding distinct territory counts, and a case with a tie | Rank the seats | Ranked by territory count descending, per `capTiebreak = "territoryCount"`. The ranking is total and deterministic; ties resolve by a stated, reproducible rule rather than by enumeration order | CF | FR-55, DR-20 |

### Only two ways a match ends

Domination (TC-VIC-01) or the round cap (TC-VIC-03). DR-20 admits no third, and TC-VIC-02 asserts that a
finished match is genuinely inert rather than merely flagged — an engine that still returns legal actions
after `GameOver` will produce a replay that diverges from its own log.

---

## F.16 TC-PER — Persistence, save and resume

**Level: Integration · 7 cases.** These run against a real containerised PostgreSQL, not an in-memory
substitute — the append-only guarantee of NFR-12 is a *database privilege*, and a fake cannot assert it.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-PER-01** | A match saved mid-attack-phase with cards in several hands | Resume and recompute | State is identical, and the **legal-action set is identical** to the one before saving. Card hands, phase, current seat, army counts and `rng_position` all match | INV | FR-58, NFR-14 |
| **TC-PER-02** | A live match | Apply one action | Match, seats, territory state and cards are all persisted within **one transaction** for that action. No action leaves a snapshot half-written | INV | FR-56 |
| **TC-PER-03** | A match created from a map file, then the file edited on disk | Reload the match | The match reads its frozen `effective_map`, not the edited file. Keys agree between the snapshot and the stored effective map | INV | FR-10 |
| **TC-PER-04** | A populated `moves` log, and a connection using the application's own role | Attempt `UPDATE` and `DELETE` on a log row | Both fail on **database privilege**, not on application logic. The test connects as the application role precisely so that an application-layer guard cannot satisfy it | INV | FR-57, NFR-12 |
| **TC-PER-05** | A live match | Abort the transaction between the snapshot write and the `moves` insert | The match is **exactly as it was**: same version, same `rng_position`, no orphan log row, no half-applied action | INV | FR-56, NFR-13 |
| **TC-PER-06** | A registered player holding seats in finished and unfinished matches | Request the resumable list | Only unfinished matches in which the player holds a seat are returned. A match the player does not hold a seat in never appears | INV | FR-04 |
| **TC-PER-07** | A match created with `diceSides = 7` and `attackRange = 3`, played for several turns and saved. Then `shared/rules.json` is edited on disk to `diceSides = 6`, `attackRange = 1` | Resume the match; replay the log from `moves`; enumerate legal attacks | Both values are read from `matches.options`, so the resumed match still rolls 1–7 and still attacks at range 3, and the replay reproduces the logged dice **face for face**. Neither value is ever read from `shared/rules.json` after `Start`. An attempt to create a match with either value out of range is rejected at creation | INV, IC | FR-84, FR-85, FR-10 |

### TC-PER-07 and the divergence no determinism test can see

TC-PER-05 has the worst *consequence*; this one is the hardest to *detect*. Suppose `diceSides` were read
live from `shared/rules.json`. A match created at 7 is resumed after the file is edited to 6. Every call
to `rng.NextInt` still consumes **exactly one draw**, so `rng_position` tracks the log perfectly and
**TC-DET-01 through TC-DET-04 all pass** — while every face, every combat outcome and therefore the whole
match diverges from what the log recorded.

Determinism tests check that the stream is *consumed* identically. They cannot check that it is
*interpreted* identically. That is why this case asserts the source of the value rather than the value,
and why `attackRange` is pinned here too: it does not consume dice, but a live read would silently change
what was legal in a match a reviewer is replaying.

### TC-PER-05 is the one that matters most and gets skipped most often

A half-applied action corrupts a match **permanently** rather than inconveniently: the snapshot says one
thing, the log says another, and replay diverges from that point forever. Every other persistence failure
is recoverable by reloading.

The case needs a deliberately aborted transaction, which is a little awkward to arrange and therefore
easy to postpone. §9.3 names it as one of the two integration tests worth building first.

---

## F.17 TC-API — REST and SignalR contract

**Level: Integration · 8 cases.** Against a running API, a real database and a real hub connection.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-API-01** | A map set containing at least one map that fails the gate | `GET /maps`, then `GET /maps/{key}` | Only maps passing V-01…V-12 are listed — an invalid map is not a selectable option. The response shape matches `appendices/A-api-contract.md` exactly, including render data | INV | FR-05, FR-06, FR-60 |
| **TC-API-02** | A live match at a known state | `GET /legal`; compute `Legal` directly from the engine | The two lists are equal as sets and equal in the serialised shape the contract declares. The API adds no action and removes none | IC | FR-21 |
| **TC-API-03** | Two clients holding the **same** `expectedVersion` | Submit a legal action from each, concurrently | One receives `200`; the other receives `409 Conflict` **with the current state**. The database shows **exactly one** applied move and one version increment | INV | FR-61 |
| **TC-API-04** | A live match | Submit unauthenticated; submit as a seat that is not the current seat; submit an action absent from `Legal` | `401`, `403` and `400` respectively. In all three cases **nothing is applied** — version, state and `rng_position` are unchanged | INV | FR-20, FR-22 |
| **TC-API-05** | A match where several seats hold cards | `GET` state as each seat in turn over REST | Each response contains that seat's own card identities and **no other seat's**. Other seats' hands appear as counts only | INV | FR-62 |
| **TC-API-06** | Several seats connected to the hub | Apply one action | Every connected seat receives `StateChanged`, each with **its own** redacted state. `DiceRolled` carries every die face. No seat receives another seat's cards through the hub | INV | FR-63, FR-29 |
| **TC-API-07** | A match whose current seat is `Ai` | `POST /ai-step` once | **Exactly one** action is applied and the version increases by **exactly one**. The response carries the resulting events. Minimum think time is applied at this layer, not inside the agent | INV | FR-73, FR-75 |
| **TC-API-08** | A match with a populated action log | `GET` the replay log | Actions are returned in applied order with their resulting version and `rng_position_after`. Replaying them reproduces the stored snapshot (the assertion TC-DET-03 makes from the engine side) | INV | FR-59 |

### TC-API-03, the case that verifies the whole concurrency design

Two concurrent submissions against one `expectedVersion` is the entire optimistic-concurrency design of
§6.7 reduced to a single assertion. It is also the case most likely to be skipped, because it needs two
genuinely concurrent requests rather than two sequential ones — a sequential pair passes trivially and
proves nothing.

---

## F.18 TC-SEC — Security and redaction

**Level: Integration · 4 cases.**

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-SEC-01** | A freshly registered account | Inspect the stored row and the whole schema | The password is stored **only** as an Argon2id PHC string. No plaintext column, no reversible encryption, no password in any log or error response | INV | FR-01, NFR-09 |
| **TC-SEC-02** | A live match; an authenticated player holding seat 2 | Submit an action claiming to be seat 3 | Rejected `403`. Seat identity is resolved **server-side from the session**, never taken from the request body. Nothing is applied | INV | FR-20, NFR-10 |
| **TC-SEC-03** | A match where every seat holds cards | Request state as each seat, over both REST and the hub | No response on either transport contains another seat's card identities. Asserted by scanning the serialised payload for every other seat's card IDs | INV | FR-62, NFR-11 |
| **TC-SEC-04** | Registered credentials, wrong credentials, and no credentials | Log in with each; start a guest session | Correct credentials issue a token; wrong credentials are rejected without revealing which field was wrong; a guest session is issued without an account and can play locally | INV | FR-02, FR-03 |

### Redaction is asserted on both transports

A redaction bug that is fixed on the REST path and missed on the hub leaks exactly as much as no
redaction at all. TC-SEC-03 scans both, and TC-API-05 and TC-API-06 assert the same property from the
contract side, which is why the property appears twice in the matrix rather than once.

---

## F.19 TC-AI — Agent behaviour

**Level: AI · 6 cases** (TC-AI-05 optional). Run against `OrderAndConquest.Sim`, headless, no database.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-AI-01** | All four heuristic agents, every seat count, both map kinds, thousands of seeded matches | Play to conclusion, recording every action against the `Legal` list computed immediately before it | **Zero** invalid actions. Not "few" — the rate is exactly zero, because every agent selects from the engine's own list | INV | FR-71, FR-74, NFR-20 |
| **TC-AI-02** | Hand-constructed positions where the better move is unambiguous — a capture that completes a continent versus an equivalent-odds capture that does not | Score candidates with `MarsEvaluator` | The expected ordering is returned for every constructed position. The case documents each position's intended answer so a reviewer can disagree with the fixture rather than the code | IC | FR-76 |
| **TC-AI-03** | `PassiveBot`, `ChaoticBot`, `AggressiveBot`, `MarsBot` | Play matches at 2, 3, 4, 5 and 6 seats on both `world_classic.json` and generated maps | All four complete every match without exception and without deadlock. A match that cannot progress fails the case | INV | FR-72, FR-77, FR-79 |
| **TC-AI-04** | An agent handed a `ThrowingRandomSource` | Ask each agent for a full decision, including MarsBot scoring a wide candidate set | Every agent returns an action **without exception**. No agent draws from the match random source while deciding. Asserted additionally with `CountingRandomSource`: `Position` is unchanged across the decision | INV | FR-76 |
| **TC-AI-05** **(OPT)** | The RL observation builder in training and in inference | Build the observation tensor for the same state through both paths | Byte-identical tensors. A divergence here makes every training result a measurement of a different game | GF | FR-80 |
| **TC-AI-06** | A tournament configuration and a fixed seed set | Run the tournament twice | A **bit-identical** win-rate matrix. Same pairings, same seeds, same results | GF | FR-82 |

### TC-AI-04 is a test, not a code comment

The speculative-`Apply` trap of §8.8 is the most expensive available mistake in this codebase. Calling
`Apply` to evaluate a candidate rolls dice; rolling dice advances `Position`; the match's random stream
then depends on **how many options the bot considered**. The result is a working game, a correct-looking
AI, and matches that cannot be replayed or trained against — with no symptom during play.

`ThrowingRandomSource` converts that into a first-run exception. TC-AI-04 is what keeps it converted when
someone adds a fifth bot two phases later.

> **Cross-reference note.** §5.6 attributes the `Position`-unchanged assertion to TC-AI-02. The catalogue
> places it in **TC-AI-04**, matching §9.5, and TC-AI-02 covers evaluator *ordering*. Both cases verify
> FR-76 and the matrix maps FR-76 to both, so the requirement is covered either way; the narrower
> statement belongs to TC-AI-04.

---

## F.20 TC-UI — Client behaviour

**Level: Client · 4 cases.** Each runs in a **built** client, once per client — three runs of the family.

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-UI-01** | A built client joined to a live match | Walk the screen inventory; attempt to reach an action absent from `Legal` | All 20 screens S-01…S-20 are present and reachable, including the four new ones (S-05, S-12, S-13, S-16). No illegal action is reachable through the interface by any route — not by tap, drag, keyboard or back-navigation | INV | FR-65, FR-68, NFR-21 |
| **TC-UI-02** | A live match; a `DiceRolled` event | Inspect interactivity against the legal list; trigger an attack | Exactly the territories and actions named in the server's legal-action response are interactive; every other element is inert. Dice **animate from the event's faces** rather than from a locally computed outcome | IC | FR-66, FR-69, NFR-22 |
| **TC-UI-03** | A pass-and-play match with two `LocalHuman` seats; a turn ending | Observe the client across the `HandOverDevice` event | The outgoing seat's hand is cleared **immediately** and a blocking hand-over screen appears before any incoming state is requested. Backgrounding and restarting during hand-over resumes at the blocking screen, never at a revealed hand | INV | FR-64, NFR-22 |
| **TC-UI-04** | All three clients joined to **one** match | Apply the same action; observe each | All three render the same state, the same army counts, the same ownership and the same legal set. *Counted at the Client level; the boundary it crosses is integration (§9.3)* | INV | FR-65, NFR-18 |

### Why TC-UI-03 checks the restart path

A hand-over screen that is correct in the happy path and wrong after a restart still leaks — and a
backgrounded mobile client restarting mid-hand-over is an ordinary event, not an edge case. NFR-22 says
*at any point*, and the restart is the point most easily missed.

---

## F.21 TC-SYS — End-to-end system

**Level: System · 6 cases.** Against a deployed API with a real client. These are the acceptance tests.

| ID | Scenario | Passes when | Oracle | Verifies |
|---|---|---|---|---|
| **TC-SYS-01** | A complete match from setup to victory | A winner is declared and the action log replays to the same final state | GF, INV | Composite: FR-54, FR-57 |
| **TC-SYS-02** | Every supported seat count | Matches at 2 (with `Neutral`), 3, 4, 5 and 6 seats each reach a legal conclusion. The `Neutral` seat is **never offered a turn** and the match never hangs waiting for it | INV | FR-12, FR-13, FR-14, FR-25, DR-15 |
| **TC-SYS-03** | Save and resume | A match saved mid-attack-phase resumes with identical state, identical legal actions and identical card hands | INV | FR-58, NFR-14 |
| **TC-SYS-04** | A generated map | A procedurally generated map plays a full match through the **same** engine and the same API, with no generated-map code path | INV | FR-07, FR-08 |
| **TC-SYS-05** | Configurable sea routes | Matches created at the minimum, default and maximum sea-route counts each play at least one naval action to completion | INV | FR-15, FR-16, FR-48 |
| **TC-SYS-06** | Special-force gameplay | One match in which an Air Force attack **and** a naval attack are both executed and both resolve by ordinary combat | INV | FR-42, FR-48, FR-31 |

### The two rows that carry the most weight

**TC-SYS-02's 2-seat row** is the one that surprises. A 2-seat match runs as **three** seats with a
`Neutral` (D-07). A match that hangs waiting for the neutral seat to act is precisely the failure this
row exists to catch, and it is invisible at 3 seats and above.

**TC-SYS-06 is the acceptance test for the entire extension set.** If it passes, the three locked
extensions work end to end. If Phase 11 can demonstrate nothing else, it can demonstrate this.

---

## F.22 TC-RL — Training and inference *(optional)*

**Level: Optional (RL) · 4 cases.** Skipped entirely if Phase 13 is not reached. No mandatory
requirement depends on any of them (NFR-24).

| ID | Precondition | Steps | Expected result | Oracle | Verifies |
|---|---|---|---|---|---|
| **TC-RL-01** **(OPT)** | Exported self-play episodes | Validate against the declared trajectory schema | Every episode matches the schema, and each recorded action mask **aligns with the legal set recorded at that step**. A mask that disagrees with the engine invalidates the trajectory | INV | FR-80 |
| **TC-RL-02** **(OPT)** | A policy network and a legal-action mask | Sample actions over a large batch | Masked logits make illegal actions unselectable: sampled actions are legal in **100%** of the sample, not merely almost all | INV | FR-81 |
| **TC-RL-03** **(OPT)** | A PyTorch model and its exported ONNX counterpart | Run both on the same observations | The same action distribution within floating-point tolerance. Export changing behaviour silently would make every figure in §10.3 meaningless | CF | FR-81, FR-78 |
| **TC-RL-04** **(OPT)** | A checkpoint recording `fortify.mode = "single_pair"`, loaded against an active configuration of `"one_step_all"` | Load the checkpoint | **Loading fails**, naming the mismatch. A policy trained under one fortify rule is not silently used under another | INV | FR-83 |

TC-RL-03 is what makes the ONNX boundary a boundary rather than an assumption.

---

## F.23 Count reconciliation

The counts below are derived from this catalogue and must equal §9.1. If a case is added, removed or
renumbered, both this table and §9.1 change together — §13.9 records that obligation.

### By family

| Family | Cases | Level | Family | Cases | Level |
|---|---|---|---|---|---|
| TC-ARC | 5 | Architecture | TC-SEA | 6 | Unit |
| TC-DET | 4 | Unit | TC-FRT | 4 | Unit |
| TC-MAP | 10 | Unit | TC-ELM | 3 | Unit |
| TC-DRF | 6 | Unit | TC-VIC | 4 | Unit |
| TC-CMB | 10 | Unit | TC-PER | 7 | Integration |
| TC-CRD | 10 | Unit | TC-API | 8 | Integration |
| TC-CAP | 6 | Unit | TC-SEC | 4 | Integration |
| TC-AIR | 6 | Unit | TC-AI | 6 | AI |
| TC-NAV | 6 | Unit | TC-UI | 4 | Client |
| | | | TC-SYS | 6 | System |
| | | | TC-RL | 4 | Optional (RL) |

### By level

| Level | Families | Cases |
|---|---|---|
| Architecture | TC-ARC | **5** |
| Unit | TC-DET, TC-MAP, TC-DRF, TC-CMB, TC-CRD, TC-CAP, TC-AIR, TC-NAV, TC-SEA, TC-FRT, TC-ELM, TC-VIC | **75** |
| Integration | TC-PER, TC-API, TC-SEC | **19** |
| Client | TC-UI | **4** |
| System | TC-SYS | **6** |
| AI | TC-AI | **6** |
| Optional (RL) | TC-RL | **4** |
| **Total** | | **119** |

`4 + 10 + 6 + 10 + 10 + 6 + 6 + 6 + 6 + 4 + 3 + 4 = 75` at the Unit level, and `7 + 8 + 4 = 19` at
Integration. Both agree with §9.1.

Three cases arrived after the original 116 were catalogued, all from the post-lock decisions D-29 and
D-30: **TC-CMB-09** (range-dependent attack legality), **TC-CMB-10** (configurable face count) and
**TC-PER-07** (both parameters frozen into the match). **TC-AIR-02 was re-scoped, not added** — its bound
changed from a literal 5 to `max(options.attackRange, airForce.maxRange)`, which still evaluates to 5 at
the defaults, so the family count is unchanged at 6.

### Mandatory versus optional

| | Count |
|---|---|
| Total cases | **119** |
| Optional — gated on the RL component | **5** (TC-RL-01, 02, 03, 04 and TC-AI-05) |
| **Mandatory** | **114** |

This is the "114 mandatory, 5 gated" split of §9.1. The fifth optional case is **TC-AI-05**, which lives
in the AI family rather than the RL family because it runs in `Sim`; it is counted at the AI level and is
optional because the observation tensor it compares exists only when Phase 13 is reached.

### Requirements coverage

Every one of the 85 functional requirements except FR-70 is named in a **Verifies** column above. FR-70
(preset messages instead of free text) is optional, is a client presentation decision, and requires the
*absence* of a control — verified by inspection, as §13.4 records rather than papers over.

---

**Appendix index:** [A](A-api-contract.md) · [B](B-database-schema.sql) · [C](C-map-specification.md) ·
[D](D-capability-mapping-decision-table.md) · [E](E-pseudocode.md) · F ·
[G](G-configuration-tables.md) · [H](H-additional-diagrams-and-screenshots.md)
