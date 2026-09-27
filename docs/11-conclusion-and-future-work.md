# 11 — Conclusion and Future Work

## 11.1 What This Document Is

This package is a **specification, not a report of completed work.** At the time of writing, no part of the
system described in chapters 5 to 8 has been implemented. Chapters 9 and 10 are a test plan and a results
template, and their empty cells are deliberate.

Saying so plainly matters more than it may appear. An FYP document that reads as though a system exists,
when the system is planned, misrepresents the project's state to the person assessing it and — more
practically — to the team members who will read it in week three looking for what to build. Every claim in
this package is therefore one of three kinds, and the kind is marked wherever it is not obvious:

| Kind | Marked as | Example |
|---|---|---|
| A **sourced fact** | Cited | The classic board has 42 territories in 6 continents (§2.3) |
| A **design decision** | A `D-nn` register entry | Air Force is limited to one attack per turn (D-11) |
| **Planned work** | Stated in future or conditional terms | "Phase 11 adds capability cards…" (§8.11) |

The two things this package contains that are neither — and are worth separating out — are the **measured
findings** of §7.8, computed from the map data file rather than asserted, and the **six open questions**
(O-01…O-06) that are recorded as unresolved rather than papered over.

## 11.2 What Was Decided

The project began with a locked feature set, five source design documents, a prior 2022 student report and
a research paper. The work of this specification was to reconcile them into something a student team can
build without discovering a contradiction in week ten.

Twenty-six decisions were recorded (`D-01`…`D-26`), of which seven resolved genuine conflicts between the
supplied sources. The decisions that shaped the system most are these:

| Decision | What it prevented |
|---|---|
| **Capability is a property of the seat, derived from ownership and hand — never of an army** (CAP-1, CAP-2) | Two new unit types, a transport rule and a second combat interaction |
| **Only Air Force and Naval Force unlock anything** (D-09) | Inventing mechanical differences for Infantry, Cavalry and Artillery, which classic RISK does not have |
| **One combat resolution for every attack** (FR-31) | Three parallel combat systems — the explicit scope prohibition of §40 |
| **A sea route is an edge, not a territory** (DR-16) | Ownable ocean, a naval map layer, and a second victory surface |
| **The host chooses the sea-route count; the system chooses the endpoints** (SEA-1) | A route-drawing interface, unreproducible boards, and hosts building favourable maps |
| **The board is stored as data, not as schema** (§6.1) | Six further database tables, and running matches changing when a map file is edited |
| **A seat is `LocalHuman \| RemoteHuman \| Ai \| Neutral`; "game mode" is not a concept** (§5.1) | Separate code paths for single-player, pass-and-play, multiplayer and AI matches |
| **Air Force is limited to one attack per turn** (AIR-1) | The land attack becoming dead code, since range 5 contains range 1 |

The last one is the clearest illustration of why the assumption register exists. The specification locked
range 5 and locked land-adjacency-only measurement, but said nothing about frequency — and without a limit
the extension would have silently deleted the base game's main action. One integer in a configuration file
was the smallest correct fix, and it is recorded as an assumption, not presented as a rule from the source.

## 11.3 What Was Measured

Two facts in this package were computed rather than asserted, both from
[`shared/maps/world_classic.json`](../shared/maps/world_classic.json) over the land adjacency graph:

1. **The classic board's graph diameter is 10**, and range 5 reaches 1330 of 1722 ordered territory pairs —
   77.2%. Range 5 is therefore a real constraint, not a formality, and it is an eightfold expansion over
   ordinary adjacency's 9.6% (§7.8).

2. **Reach at range 5 varies from 11 of 41 territories to 40 of 41**, mean 31.7. Eastern Australia is the
   minimum, and Eastern Australia is currently one of the seven air-capable territories — which makes it
   the worst position on the board from which to use the capability.

The second is a genuine design finding that neither the source documents nor the specification anticipated.
It is recorded as open question **O-04** rather than silently corrected, because whether it is a flaw or a
deliberate balance depends on a judgement the team and supervisor should make, not on a one-line data edit
made while writing documentation.

It is also an argument for the approach: the finding cost one script against a data file, and it would not
have emerged from any amount of careful prose.

## 11.4 Honest Assessment of the Plan

### Where the plan is strong

| | Why |
|---|---|
| The core is reachable early | A playable two-human match exists at Phase 5 — before the database, the API, any AI, the extensions, procedural maps or artwork (§8.11) |
| The advanced features are genuinely detachable | RL, procedural maps and artwork each sit at a leaf of the dependency graph. Cutting any of them changes nothing else (§8.11) |
| The hard rules are testable against closed-form oracles | Combat probabilities, reinforcement arithmetic and Air Force reach are all checkable without trusting the implementation (§9.1) |
| The scope prohibitions are structural, not stylistic | One combat path, one army type, one rules engine, six tables. Each is a thing the design makes *hard* to violate, not merely discouraged |

### Where the plan carries real risk

Stating these is more useful than a summary that does not.

| Risk | Honest assessment |
|---|---|
| **Three clients is the largest single cost** | Three complete UIs in three toolchains, each needing the full S-01…S-20 inventory, is plausibly more work than the engine, the API, the database and the AI combined. It is a stated project requirement (C-02), so it stays — but it is the constraint most likely to compress everything else |
| **Phase 11 ordering** | The recommended phase order completes three clients before adding the extension actions, which means revisiting all three. §8.11 documents running Phase 11 earlier for this reason; if that adjustment is not made, budget three extra client passes |
| **RL is unlikely to reach a strong result** | PPO on a multi-agent stochastic board game with a 100-round horizon is a research-scale problem. The plan treats RL as optional and gated for exactly this reason, and §10.3 is written so that "did not beat MarsBot" is a reportable outcome rather than a hole |
| **Dart realtime transport is unresolved** | SignalR has no first-party Dart client. The fallback — REST polling — is adequate for a turn-based game, but it is a fallback, and the decision should be made in Phase 10 rather than during integration (§8.6) |
| **Coastal status is an unvalidated design judgement** | 36 of 42 territories are coastal by authored decision, not by geography. It determines Naval reach across the whole board and has never been playtested (O-02) |
| **The capability mapping is unplaytested** | Appendix D's 42 rows are a first pass. Seven air-capable territories and five Air Force cards are plausible numbers, not measured ones (O-03, O-04) |

### What would make this specification wrong

The most useful thing a plan can state is its own failure condition. This one is wrong if:

- the engine acquires a dependency, in which case NFR-01 falls and with it every determinism and
  testability claim built on it;
- a client acquires rule logic, in which case the three clients begin to diverge and the traceability
  matrix becomes fiction;
- the assumption register stops being updated, in which case decisions revert to being undocumented and
  §2's authority order no longer has anything to point at.

None of the three is a technical limit. All three are discipline, and all three are cheap to check —
TC-ARC-01, TC-ARC-04, and reading the register's last-modified date.

## 11.5 Future Work

Divided by how much of a decision each item needs. Nothing here is a commitment, and nothing here is
required for the project to be complete.

### Already-open questions — decisions the team owes itself

These are the register's O-01…O-06 and they are not "future work" in the sense of extra features; they are
existing questions with no answer yet. They are restated here because a conclusion that omits them would
read as more settled than the project is.

| ID | Question | Resolved by |
|---|---|---|
| O-01 | Whether territory artwork is produced, or the debug renderer ships | Team capacity |
| O-02 | Whether the 36 coastal / 6 landlocked split gives good naval play | Playtest |
| O-03 | Whether five Air Force cards and seven air-capable territories are the right frequencies | Playtest |
| O-04 | Whether the *set* of seven air-capable territories is right, given the measured reach spread | Playtest |
| O-05 | Whether the card-escalation values inferred in D-15 match the team's intent | Supervisor confirmation |
| O-06 | Whether the round cap of 100 suits human play as well as it suits training | Playtest |

Four of the six are answered by playing the game, which is another argument for Phase 5 arriving early.

### Deferred features already specified but not required

| Item | Status | Where it is specified |
|---|---|---|
| Submersion masks | Optional, no v1 requirement | D-05; §3.2 explicitly generates no FR for it |
| Territory artwork and polygons | Phase 12, optional | §7.11, O-01 |
| Additional authored maps | Straightforward once the format is stable | §8.10 |
| `one_step_all` and `connected_path` fortify modes | Implemented as configuration, untested in play | §7.4, D-16 |
| Trained-policy opponent as the shipped default | Gated on the §10.3 evaluation | §8.9 |

### Genuine extensions — each requiring explicit approval

Everything below is outside the current scope, and §40 forbids adding any of it silently. Listed so that a
future reader knows these were considered and deliberately excluded, not overlooked:

| Extension | Why it was excluded now |
|---|---|
| Mission / objective cards | A second victory surface; standard rules permit omitting them (D-26) |
| Tournament and ranking systems | Requires accounts, matchmaking and persistence well beyond six tables |
| Spectator mode | Cheap to add later, given per-seat redaction already exists |
| Replay viewer UI | The data is already stored (`moves`); only the UI is missing |
| Additional map sizes and shapes | The generator already supports variable territory counts |
| Web delivery | The Flutter client is the route; the Godot client cannot provide it (§8.5) |
| Cross-platform mobile polish | The Flutter client exists; the work is UX, not architecture |

The two most valuable items on that list are the cheapest: **a replay viewer** costs a UI over data the
schema already holds, and **spectator mode** costs a seat-less redaction path over a redaction system that
already exists. Both are better first extensions than anything requiring a new subsystem.

### What should not be added

Restated from the scope rules, because a future-work section is exactly where scope creep enters a document:

> No additional game mechanics. No additional unit types. No diplomacy, alliances, trading between
> players, fog of war, commanders, heroes, resources, economy, technology trees or missions without
> explicit approval. No replacement for dice combat. No microservices. No additional database tables
> without justification. No turning an optional feature into a mandatory one.

## 11.6 Conclusion

The specification describes a classic RISK implementation with three controlled extensions — a capability
system, a long-range Air Force attack, and Naval Force operating over generated sea routes — served by one
pure C# rules engine to three clients, with a staged heuristic AI and an optional PPO reinforcement-learning
component.

The design choice the whole package rests on is small and worth stating one final time: **the extensions add
two actions and one edge type, and nothing else.** No new unit, no second combat system, no new phase, no
new victory condition, no new table. That is what makes a feature set which sounds ambitious fit inside a
final-year project.

Whether the result is a good game is a question for playtesting, and six of the open questions say so
honestly. Whether it is a buildable one is the question this document was written to answer, and the answer
it gives is a fourteen-phase plan in which a playable game exists at phase five and every advanced feature
can be cut without touching anything else.

> The most important outcome is not a beautiful document. The most important outcome is a document that
> describes a system the student team can actually build. Where a choice appeared between an impressive
> architecture and a smaller reliable implementation, this specification chose the smaller reliable
> implementation.

The minimum sequence of work to reach a playable game is
[`14-implementation-safety-checklist.md`](14-implementation-safety-checklist.md). It is the last document in
this package and the first one the team should read.

---

**Previous:** [10 — Results](10-results-template.md) · **Next:** [12 — References](12-references.md)
