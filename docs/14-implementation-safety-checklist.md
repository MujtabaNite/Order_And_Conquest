# 14 — Implementation Safety Checklist

> **The closing checklist required by §42 of the master prompt, and the first document the team should
> read.** It is deliberately short. Everything here is stated in full somewhere in chapters 5 to 9; this
> page exists so that nothing load-bearing depends on having read them.
>
> Its single purpose: **the minimum sequence of work that reaches a playable game, without being trapped by
> an advanced feature on the way.**

## 14.1 The minimum path to a playable game

Six steps. Nothing outside this list is required for a game that can be demonstrated.

| # | Step | Finished when | Reference |
|---|---|---|---|
| 1 | Solution skeleton, CI, dependency test | `Engine` references nothing but the base library, and the build proves it | §8.1, TC-ARC-01 |
| 2 | Engine state, actions, events, `Start`/`Legal`/`Apply` | `Apply` returns a new state and mutates nothing | §5.4, TC-ARC-02 |
| 3 | Classic map + debug renderer | `world_classic.json` passes V-01…V-12; 42 territories and 83 edges draw as circles and lines | §8.10, TC-MAP-01…04 |
| 4 | Core RISK rules + deterministic tests | A match plays engine-only from setup to domination; the five dice probabilities assert | §7.5, TC-DET-01…04 |
| 5 | One client board, pass-and-play | **Two humans complete a match. No server. No database.** | §8.11 Phase 5 |
| 6 | Persistence, API, SignalR | Create, act, save, resume over HTTP; `409` on a stale version; redaction holds | §6.7, TC-PER-*, TC-SEC-* |

**Stop at step 5 and play the game.** That milestone is the project's insurance policy: from there a
demonstrable artefact exists, and every later phase improves something rather than enabling it.

Everything after step 6 — three clients, four bots, the three extensions, procedural maps, RL, artwork — is
work on a game that already runs.

## 14.2 Do not start X before Y

| Do not start | Before | Because |
|---|---|---|
| Any rule | The purity and dependency tests | A rule written into an impure engine is rewritten later, not fixed |
| Any client screen | Step 4's engine-only match | The client would be the first place a rule is tested, and rules would migrate into it |
| The API | A working engine | An API over a half-built engine ends up holding rules "temporarily" |
| The second and third clients | One complete client | Three half-clients demonstrate nothing; one complete client demonstrates the architecture |
| Artwork | A playable board | The debug renderer exists precisely so art cannot block play (O-01) |
| Procedural generation | The classic map passing the same gate | The gate is what makes generation safe; without it a generator emits unplayable boards |
| RL | Four working heuristic bots and a headless simulator | Without an opponent to beat and a simulator to run, there is nothing to train against |

**When step 5's client work does start**, the UI/UX pack in [`../design/`](../design/) is the input: it
fixes the design tokens, all 20 screens against the 13 endpoints and 9 action types, the board, dice and
card specifications, the interaction grammar, and annotated wireframes for every screen in both desktop
and mobile form. It was written so that screen design needs no re-derivation from chapters 5 to 7 —
[`../design/00-index.md`](../design/00-index.md) is its entry point. It decides **no rule**: FR-67 holds,
and wherever a reader expects a game number the pack names the server field that carries it.

## 14.3 The six traps

Each of these produces a system that appears to work. Each has one cheap guard.

| # | Trap | Guard |
|---|---|---|
| 1 | **An agent calls `Apply` to evaluate a move**, consuming the match random source. The game plays, and replay and training are silently broken | Pass agents a `ThrowingRandomSource`. TC-AI-04 turns this into a first-run exception (§8.8) |
| 2 | **Sea routes included in the Air Force range BFS.** One field, two characters, and the locked rule is false while the feature looks fine | TC-AIR-03 recomputes reach with land edges only (DR-18) |
| 3 | **Capability cached for performance.** Losing the last coastal territory then leaves Naval actions available | Capability is derived on every call, never stored. TC-CAP-04 and 05 (FR-41) |
| 4 | **The comparison for tied dice inverted.** Every probability shifts; nothing crashes; every agent learns a different game | TC-CMB-03, against the exact fractions of §7.5 (DR-07) |
| 5 | **Dictionary iteration order leaking into state.** Passes on one machine, fails on another, costs days to diagnose | Sort every collection before it reaches the RNG or a hash. TC-DET-04 on a second CI image (§8.3) |
| 6 | **`diceSides` or `attackRange` read live from `shared/rules.json`** instead of from `matches.options`. A resumed match consumes **exactly one draw per roll as before**, so `rng_position` tracks the log perfectly — while every face and every outcome differs | **TC-PER-07 only.** It asserts the *source* of the value, not the value (D-29, D-30) |

Traps 1 and 5 have no symptom during play. Trap 6 is worse than either: it has no symptom during play
**and the entire determinism suite stays green**, because TC-DET-01…04 check that the draw *count* and the
random-source position match the log — and both do. Only a test that asks *where the number came from*
catches it.

These three are the ones worth spending a CI job on before they can be introduced.

## 14.4 Scope tripwires

If a pull request does any of the following, it is out of scope by §40 and needs explicit approval — not a
code review comment.

- [ ] Adds a **unit type**. There is one: an army. The extensions add two *actions*, not units
- [ ] Adds a **second combat path**. Land, Air Force and Naval all resolve through `CombatRules` (FR-31)
- [ ] Makes a trade set anything other than **three cards**. Five capability categories are not five-card sets
- [ ] Lets a **player draw sea routes**. The host chooses a count; the system chooses endpoints (SEA-1)
- [ ] Makes every territory **naval-capable**, or a landlocked territory naval by default (DR-17)
- [ ] Gives **Air Force range across sea routes** (DR-18)
- [ ] Adds diplomacy, alliances, player trading, fog of war, commanders, heroes, resources, economy, tech trees or missions
- [ ] Puts a **game rule in SQL**, or a rule in a client (NFR-17, TC-ARC-04)
- [ ] Adds a **database table**. There are six. A seventh needs a recorded reason (§6.1)
- [ ] Adds a **hard-coded tunable number** to a rules module (NFR-16, TC-ARC-03)
- [ ] Makes anything mandatory **depend on RL, ONNX, `rl/` or `Sim/`** (NFR-24, §13.6)
- [ ] Introduces OAuth, enterprise IAM, anti-cheat, microservices or container orchestration (NFR-23, §26)
- [ ] Turns an **optional requirement into a mandatory one** — the smallest-looking edit that can make the project unbuildable

## 14.5 If time runs short, cut in this order

Cutting from the top costs nothing structurally. Each item is a leaf of the §8.11 dependency graph.

| Order | Cut | What is lost | What still works |
|---|---|---|---|
| 1 | RL (Phase 13) | An experimental opponent | `MarsBot` ships as the default. §10.3 reports RL as not completed — a legitimate result |
| 2 | Map artwork (Phase 12) | Visual polish | The debug renderer. Every rule, test and demo (O-01) |
| 3 | Procedural maps (Phase 12) | Variable boards | The classic 42-territory board |
| 4 | The third client (Phase 10) | One platform | Two complete clients, and the architecture claim is already demonstrated by two |
| 5 | The second client (Phase 9) | Another platform | A complete, playable, tested game |

**Never cut:** the engine's purity, the determinism tests, the append-only log, per-seat redaction, or
step 5's playable milestone. Those are what every other claim in this package rests on.

Record every cut in `00-decisions-and-assumptions.md` and in §10.1's status table as **Not implemented**.
A cut that is reported is a scope decision; a cut that is not reported is a gap in the evidence.

## 14.6 Before submission

| | Check | Where |
|---|---|---|
| [ ] | Every FR has a test result, or a recorded reason it does not | §13.2, §13.4 |
| [ ] | §10 contains measured numbers, or says "not implemented" — never an estimate | §10, §39 |
| [ ] | The reference machine is recorded beside every timing | §10.4 |
| [ ] | No win rate, accuracy or strength claim appears without a run behind it | §10.3, §39 |
| [ ] | The six algorithm/method citations of §12.7 have been completed against the published record | §12.7 |
| [ ] | The three retrieval gaps are still stated, not quietly dropped | §12.9 |
| [ ] | Open questions O-01…O-06 are answered, or still recorded as open | §11.5 |
| [ ] | **D-27, D-28 and the `territoryBonusMaxPerTurn` reading were confirmed before Phase 4** — each changes a test oracle | §11.5, Appendix G §G.16 |
| [ ] | Screenshots **14, 15, 16 and 24** exist — the configurable dice face count, the two extensions, and the three-client claim | §10.5 |
| [ ] | This checklist's §14.4 tripwires were not tripped | §14.4 |

---

> The most important outcome is not a beautiful document. The most important outcome is a document that
> describes a system the student team can actually build. Where a choice appeared between an impressive
> architecture and a smaller reliable implementation, this specification chose the smaller reliable
> implementation.

**Previous:** [13 — Traceability Matrix](13-traceability-matrix.md) · **Package index:**
[`README.md`](../README.md)
