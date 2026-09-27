# 9 — Testing

> **Deliverable S.** The test strategy, the four test levels, and the mapping from every test area the
> specification requires to concrete test-case identifiers.
>
> The enumerated cases — preconditions, steps, expected results — are
> [`appendices/F-test-cases.md`](../appendices/F-test-cases.md). This chapter says what is tested, at which
> level, and against what oracle.
>
> **§9.6 contains no results.** It is a template with empty cells. Filling it requires running the suite,
> and inventing numbers for a documentation deliverable would make every other number in this package
> untrustworthy (§39).

## 9.1 Strategy

### What makes this system testable

Three design decisions, made for other reasons, happen to make the test strategy cheap. They are worth
naming because they are what a smaller test suite is buying:

| Decision | Testing consequence |
|---|---|
| The engine is pure and has no dependencies (NFR-01) | Every game rule is a unit test. No database, no HTTP, no fixtures beyond a map file and a seed |
| Randomness is injected and positioned (NFR-02) | A test can pin dice outcomes exactly, or assert a distribution over millions of trials, using the same interface |
| `Legal` is a list, not a permission structure | The same list is the UI's enablement source, the RL action mask and the server's validation, so **one** test of legality covers all three consumers |

A rules engine that read a database would need integration tests for rules. This one does not, and that is
the single largest reason the suite below is finishable by a student team.

### The four levels

| Level | Scope | Runs against | Count |
|---|---|---|---|
| **Unit** | One rule, one function, one validator | `Engine`, `Ai` in memory | 73 |
| **Integration** | Two or more components across a real boundary | `Api` + `Engine` + PostgreSQL + SignalR | 18 |
| **Client** | Interface behaviour in a built client | Each of the three clients | 4 |
| **System** | A complete match, end to end | Deployed API + a client | 6 |
| **AI** | Agent behaviour and reproducibility | `Sim` | 6 |
| **Architecture** | Structural constraints the code must satisfy | The compiled solution | 5 |
| **Optional (RL)** | Training and inference correctness | `rl/` + `Sim` | 4 |

**116 test cases in total: 111 mandatory, 5 gated on the optional RL component.** No test case is
mandatory if the requirement it verifies is optional, and none of the 111 depends on RL existing (NFR-24).

Architecture tests are listed separately because they are not tests of behaviour. They assert facts about
the build — which assemblies reference which — and they fail at the only moment the failure is cheap to fix.

### Families

| Prefix | Area | Cases | Primary requirement |
|---|---|---|---|
| `TC-ARC` | Architecture and structure | 5 | NFR-01, NFR-03, NFR-16, NFR-17 |
| `TC-DET` | Determinism and replay | 4 | NFR-02 |
| `TC-MAP` | Map validation and generation | 10 | FR-05…09 |
| `TC-DRF` | Setup, reinforcement and draft | 6 | FR-17, FR-18, FR-23, FR-24, DR-08, DR-09 |
| `TC-CMB` | Dice combat and occupation | 8 | FR-26…31 |
| `TC-CRD` | Cards, sets, escalation, forced trades | 10 | FR-32…38 |
| `TC-CAP` | Capability derivation | 6 | FR-39…41 |
| `TC-AIR` | Air Force | 6 | FR-42…46 |
| `TC-NAV` | Naval Force | 6 | FR-47…51 |
| `TC-SEA` | Sea routes | 6 | FR-15, FR-16 |
| `TC-FRT` | Fortification | 4 | FR-52 |
| `TC-ELM` | Elimination | 3 | FR-53 |
| `TC-VIC` | Victory and match end | 4 | FR-54, FR-55 |
| `TC-PER` | Persistence, save and resume | 6 | FR-56…59, NFR-12…14 |
| `TC-API` | REST and SignalR contract | 8 | FR-60…64 |
| `TC-SEC` | Security and redaction | 4 | NFR-09…11 |
| `TC-AI` | Agent behaviour | 6 | FR-71…78, NFR-20 |
| `TC-UI` | Client behaviour | 4 | FR-65…70, NFR-21, NFR-22 |
| `TC-SYS` | End-to-end system | 6 | Composite |
| `TC-RL` | Training and inference *(optional)* | 4 | FR-79…83 |

### Oracles

A test is only as good as what it compares against. Four kinds of oracle are used, and every case in
appendix F declares which:

| Oracle | Used for | Example |
|---|---|---|
| **Closed form** | A value computable independently of the implementation | The five combat probabilities of §7.5 |
| **Independent computation** | A property recomputed by different means inside the test | Air Force reach, recomputed by a naive BFS written in the test, compared against `Legal` |
| **Invariant** | A property that must hold after *any* action | Every territory has ≥ 1 army; army totals change only by combat losses |
| **Golden file** | A recorded expected output, reviewed once by a human | A serialised state hash after a fixed action sequence |

Golden files are used sparingly and only for determinism. A golden file records what the code *did*, not
what it *should* do, so a family of tests built on them will happily lock in a bug. The other three
oracles are preferred wherever one exists — which, for a dice game with a published rule set, is almost
everywhere.

### Property-based and statistical testing

Two places need more than example-based tests:

- **Combat probability** (TC-CMB-06). Asserted statistically over a large seeded sample against the exact
  fractions, with a tolerance derived from the sample size. The test is seeded, so it cannot flake.
- **Invariants after arbitrary action sequences** (TC-ARC-05, TC-AI-03). `ChaoticBot` plays thousands of
  seeded matches; after every applied action the invariant set is asserted. This is the test that finds
  the rule interaction nobody thought to write a case for — a card trade during a forced trade after an
  elimination that crossed a continent boundary.

### Test data

| Fixture | Purpose |
|---|---|
| `world_classic.json` | The authored board. The same file the product ships |
| `tiny_12.json` | A 12-territory hand-authored map for fast rule tests and curriculum stage 1 |
| `invalid_*.json` | One deliberately broken map per validation rule V-01…V-12 |
| Fixed seeds | A small set of named seeds with recorded outcomes, used across determinism tests |

The `invalid_*` set is what makes the validation gate real. A validator with no negative tests is a
validator that has never been shown to reject anything.

### Continuous integration

| Gate | Blocks |
|---|---|
| Solution builds, all analysers clean | Merge |
| Architecture tests (`TC-ARC-*`) | Merge |
| Unit tests | Merge |
| Integration tests against a containerised PostgreSQL | Merge |
| Contract generation is up to date (`shared/contracts/` regenerated with no diff) | Merge |
| System and AI tests | Nightly |
| RL tests | On demand |

The contract gate deserves comment: it is what prevents the Dart client from drifting from the C# DTOs
(§8.6, NFR-18). A developer who adds a field and does not regenerate gets a red build, not a null in a
client three weeks later.

### Coverage

No line-coverage target is set. A percentage is satisfiable by tests that assert nothing, and it says
nothing about whether the defender wins ties. The measurable coverage claim this project makes instead is
structural and is checked in Phase 14:

> **Every functional requirement maps to at least one test case, and every rules module in
> `Engine/Rules/` is named by at least one test family.** The mapping is
> [`13-traceability-matrix.md`](13-traceability-matrix.md).

Coverage *is* measured and reported in §9.6 as information, because an engine module at 20% is worth
looking at. It is not a gate.

## 9.2 Unit Tests

Every area the specification's §36 requires, mapped to cases and oracles. The left column is the
specification's own list.

| Required area | Cases | Oracle |
|---|---|---|
| Initial allocation and starting armies | TC-DRF-06 | Closed form: the configured 35/30/25/20 table; invariant: every territory allocated exactly once, every army issued placed |
| Reinforcement calculation | TC-DRF-01, 02 | Closed form: `max(3, ⌊t/3⌋)`. Includes the floor at 1–9 territories (DR-08) |
| Continent bonus | TC-DRF-03, 04, 05 | Closed form. Full continent awards; **one missing territory awards nothing** |
| Legal attack adjacency | TC-CMB-01, TC-MAP-02 | Independent computation from the map file's neighbour lists |
| Air Force 5-edge range | TC-AIR-01, 02, 03 | Independent BFS written in the test; sea routes excluded from the edge set |
| Sea-route validation | TC-SEA-02, 03, 04 | Invariant: both endpoints coastal, not land-adjacent, no duplicates |
| Naval movement/attack/fortification | TC-NAV-01, 02, 03, 04 | Invariant: identical combat resolution to land; fortify allowance shared |
| Dice combat | TC-CMB-02, 03, 04, 05, 06 | **Closed form** — the five exact fractions of §7.5 |
| Card set recognition | TC-CRD-03, 04, 05, 06 | Enumeration over all symbol combinations; four- and five-card sets rejected |
| Card trade progression | TC-CRD-07 | Closed form against the escalation table; monotonic and match-wide |
| Forced trade condition | TC-CRD-08, 09 | Invariant: no other action is legal while holding 5+ at draft |
| Territory-card bonus | TC-CRD-10 | Closed form: +2 on the named territory, capped at 2 per turn |
| Elimination | TC-ELM-01, 02, 03 | Invariant: cards transfer; the seat is skipped permanently |
| Victory | TC-VIC-01, 02, 03 | Invariant: domination detected the instant the last territory changes hands |
| Fortification | TC-FRT-01, 02, 03 | Invariant across all three configured modes |
| Capability unlocking | TC-CAP-01…06 | Independent computation of CAP-1 and CAP-2 from ownership and hand |
| Map validation | TC-MAP-01…05, and the `invalid_*` set | Negative tests: one broken map per rule V-01…V-12 |
| Deterministic RNG behaviour | TC-DET-01…04 | Golden state hash + position agreement |

### Four of these are load-bearing

Most of the table is routine. Four cases catch defects that are silent in play and destructive downstream:

**TC-CMB-03 — the defender wins ties.** Inverting one comparison shifts every combat probability by
several percent. The game still plays. Every smoke test still passes. Every agent trained against it
learns a different game (§7.5).

**TC-AIR-03 — sea routes are excluded from Air Force range.** The two edge types are one field apart in
the map model, and including sea routes in the range BFS is a two-character mistake that makes the locked
rule false while leaving the feature apparently working.

**TC-CAP-04 and 05 — capability is lost, not just gained.** Capability is derived, never stored (FR-41),
so losing the last coastal territory must remove Naval actions immediately. A cache added for performance
would break exactly this test and nothing else.

**TC-DET-04 — identical state across platforms.** The dictionary-enumeration trap of §8.3. Passing on one
machine and failing on another is the defect class that costs the most time to diagnose, and the test that
catches it costs one CI job on a second runner image.

### Architecture tests

| ID | Asserts |
|---|---|
| TC-ARC-01 | `Engine` references no web framework, no ORM, no database driver, no file-system API (NFR-01) |
| TC-ARC-02 | `Apply` does not mutate its input state — asserted by deep-comparing the input before and after (NFR-03) |
| TC-ARC-03 | No tunable number appears as a literal in a rules module; all come from the bound `RuleSet` (NFR-16) |
| TC-ARC-04 | No client project contains rule logic — no adjacency computation, no range computation, no combat resolution (NFR-17) |
| TC-ARC-05 | Exactly one rules implementation exists; long randomised `ChaoticBot` runs preserve every invariant |

## 9.3 Integration Tests

Each area from §36, with the boundary each case actually crosses.

| Required area | Cases | Boundary |
|---|---|---|
| API ↔ engine | TC-API-01, 02, 03, 04 | HTTP → controller → engine → response. Covers `401`, `403` on a wrong seat, `409` on a stale version, `400` on an illegal action |
| API ↔ database | TC-PER-02, 03, 04, 05 | Real PostgreSQL. Key agreement with `effective_map`, append-only privilege, transactional atomicity |
| SignalR state updates | TC-API-06 | Hub fan-out: each connected seat receives its **own** redacted state (FR-63, NFR-11) |
| Save/resume | TC-PER-01, 06 | Full round trip. The legal-action set after resume is **identical**; a procedural map and its sea routes are not regenerated (FR-10) |
| AI turns | TC-API-07 | `POST /ai-step` advances exactly one action and increments the version by one |
| All three clients against the same backend | TC-UI-04 | Three clients joined to one match observe the same state after the same action. *Counted at the Client level; listed here because the boundary it crosses is integration* |

Plus: TC-API-05 (redaction on the REST path), TC-API-08 (replay ordering), TC-SEC-01…04.

### The two integration tests worth building first

**TC-API-03 — the stale-version conflict.** Two clients submit against the same `expectedVersion`. One
gets `200`, one gets `409` with the current state, and the database shows **one** applied move. This single
case verifies the entire concurrency design of §6.7. It is also the case most likely to be skipped,
because it needs two concurrent requests and a little care to arrange.

**TC-PER-05 — crash atomicity.** The transaction is aborted between the snapshot write and the `moves`
insert. Afterwards the match must be exactly as it was: same version, same `rng_position`, no orphan log
row (NFR-13). A half-applied action is the one persistence failure that corrupts a match permanently
rather than inconveniently.

## 9.4 System Tests

Each area from §36, executed against a deployed API with a real client.

| ID | Scenario | Passes when |
|---|---|---|
| TC-SYS-01 | Complete match from setup to victory | A winner is declared; the log replays to the same final state |
| TC-SYS-02 | Multiple seats | Matches at 2 (with `Neutral`), 3, 4, 5 and 6 seats each reach a legal conclusion |
| TC-SYS-03 | Save and resume | A match saved mid-attack-phase resumes with identical state, legal actions and card hands |
| TC-SYS-04 | Generated map | A procedurally generated map plays a full match through the same engine and API |
| TC-SYS-05 | Configurable sea routes | Matches created at the minimum, default and maximum sea-route counts each play a naval action |
| TC-SYS-06 | Special-force gameplay | One match in which an Air Force attack and a naval attack are both executed and both resolve by ordinary combat |

TC-SYS-02's 2-seat row is the one that most often surprises: it must run as **three** seats with a
`Neutral` (D-07), and the `Neutral` must never be offered a turn. A 2-seat match that hangs waiting for
the neutral seat to act is the failure this case exists to catch.

TC-SYS-06 is the acceptance test for the entire extension set. If it passes, the three locked extensions
work; if the project can demonstrate nothing else about Phase 11, it can demonstrate this.

## 9.5 AI Tests

| Required area | ID | Asserts |
|---|---|---|
| Legal-action compliance | TC-AI-01 | **Zero** invalid actions across every agent over many thousands of seeded matches (NFR-20) |
| Legal-action compliance | TC-AI-02 | `MarsEvaluator` returns the expected ordering on hand-constructed positions where the better move is unambiguous |
| Legal-action compliance | TC-AI-03 | All four bots complete matches without exception, at every seat count, on both map kinds |
| Deterministic/reproducible seeds | TC-AI-04 | An agent given a `ThrowingRandomSource` chooses an action without exception — i.e. **no agent consumes the match random source** (§8.8) |
| Tournament evaluation | TC-AI-06 | The same tournament configuration and seed set produces a bit-identical win-rate matrix on a rerun |
| *Optional* | TC-AI-05 | The observation tensor built for training and the one built for inference are byte-identical for the same state |

### Why TC-AI-04 is in this list and not in a comment

The speculative-`Apply` trap (§8.8) is the most expensive available mistake in this codebase: it produces a
working game, correct-looking AI, and matches that cannot be replayed or trained against. There is no
symptom to notice during play.

`ThrowingRandomSource` turns that into a first-run exception. TC-AI-04 is the test that keeps it that way
when someone later adds a fifth bot.

### RL tests — optional

| ID | Asserts |
|---|---|
| TC-RL-01 | Exported episodes match the declared trajectory schema; masks align with the recorded legal sets |
| TC-RL-02 | Masked logits make illegal actions unselectable — sampled actions are legal in 100% of a large sample |
| TC-RL-03 | The exported ONNX model and the PyTorch model produce the same action distribution for the same observation, within floating-point tolerance |
| TC-RL-04 | Loading a checkpoint whose recorded fortify mode differs from the active configuration **fails** (FR-83) |

TC-RL-03 is the one that justifies the ONNX boundary being a boundary rather than an assumption. Export
silently changing behaviour would make every evaluation number in §10.3 meaningless.

## 9.6 Results

> **This section is a template.** Every cell below is empty because the suite has not been run. No figure
> in this package is estimated, projected or illustrative (§39). Phase 14 fills these tables from real
> runs and records the machine and commit they came from.

### Environment

| Field | Value |
|---|---|
| Date of run | *(to be recorded)* |
| Commit | *(to be recorded)* |
| CPU / RAM / OS | *(to be recorded)* |
| .NET version | *(to be recorded)* |
| PostgreSQL version | *(to be recorded)* |

### Suite outcome

| Level | Cases | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|---|
| Architecture | 5 | | | | |
| Unit | 73 | | | | |
| Integration | 18 | | | | |
| Client | 4 | | | | Run per client; three runs |
| System | 6 | | | | |
| AI | 6 | | | | |
| RL *(optional)* | 4 | | | | Skipped entirely if Phase 13 is not reached |
| **Total** | **116** | | | | |

### Coverage — reported, not gated

| Assembly | Line % | Branch % |
|---|---|---|
| `OrderAndConquest.Engine` | | |
| `OrderAndConquest.Ai` | | |
| `OrderAndConquest.Api` | | |
| `OrderAndConquest.Data` | | |

### Performance against the stated targets

Each row is an NFR with a number in it. The target is a requirement; the measurement is the evidence.

| NFR | Target | Measured (p95) | Met? |
|---|---|---|---|
| NFR-04 | `Legal` on the classic map < 100 ms | | |
| NFR-05 | Action round trip on localhost < 250 ms | | |
| NFR-06 | Heuristic agent decision < 500 ms | | |
| NFR-07 | Trained-policy inference < 50 ms on CPU *(optional)* | | |
| NFR-08 | Action log of a 100-round match returned < 2 s | | |

### Determinism evidence

| Check | Result |
|---|---|
| Identical state hash for a fixed seed and action sequence, two runs | |
| Identical state hash across two operating systems | |
| Replay from the `moves` log reproduces the stored snapshot | |
| `matches.rng_position` equals the last move's `rng_position_after` on every completed match | |

### Defects found and fixed

| ID | Found by | Description | Resolution |
|---|---|---|---|
| | | | |

This table is expected to be non-empty. A testing chapter reporting that a fourteen-phase project produced
no defects would not be credible, and the defects a determinism suite finds are the interesting part of the
result.

---

**Previous:** [8 — Implementation](08-implementation-plan.md) · **Next:** [10 — Results](10-results-template.md)
