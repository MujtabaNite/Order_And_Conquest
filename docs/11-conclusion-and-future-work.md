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

Thirty decisions were recorded (`D-01`…`D-30`), of which seven resolved genuine conflicts between the
supplied sources and **the last two arrived after the rules were locked**, from a supervisory question. The
decisions that shaped the system most are these:

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

### The two decisions that arrived after the lock

**D-29** (`combat.diceSides`, default 6, settable 2–20) and **D-30** (`combat.attackRange`, default 1,
settable 1–10) came from a supervisory question — *can the die have a face count other than six, and can
the attack distance be set rather than fixed?* Both are now specified end to end, and both are worth
recording here for one reason: **they changed no behaviour at all at their defaults.**

| | Why it was cheap |
|---|---|
| `diceSides` | Faces are drawn as `NextInt(1, diceSides + 1)`. The **number** of draws per roll is unchanged, so determinism and `rng_position` semantics are identical at every value. `defenderWinsTies` is a strict `>` on two drawn values and does not interact with the range at all |
| `attackRange` | **Range 1 *is* adjacency**, so the default legal set is exactly the neighbour list. Above 1 the land branch calls the same bounded search the Air Force already used, at a different argument |

Two consequences the team should carry forward. First, D-30 means the Air Force is now distinguished from
an ordinary land attack by **two things only** — the once-per-turn limit and the capability requirement —
and at `attackRange ≥ 5` it confers no extra reach whatsoever. That is a legitimate configuration, not a
defect, but it is the kind of thing that reads as a bug to someone who has not been told.

Second, and more seriously, both keys are **frozen into the match at creation** and must never be read
live from `shared/rules.json` — see §11.4.

## 11.3 What Was Measured

**Six facts in this package were computed rather than asserted.** None is a citation and none is a
judgement; each came from a script run against a data file, and two of them contradicted what careful
prose had assumed.

### From the map, over the land adjacency graph

Both from [`shared/maps/world_classic.json`](../shared/maps/world_classic.json):

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

### From exhaustive enumeration of the rules

3. **Every combat probability, at every face count, by enumeration rather than by formula.** The five
   published d6 fractions are reproduced exactly, and their d7 counterparts computed: 1v1 rises from
   0.4167 to 0.4286, 3v2 from 0.3717 to 0.3903. Every denominator is `N^(a+d)`, so the published figures
   are simply the `N = 6` instance — which is why supporting any face count needed **no new test oracle**.
   The 1v1 closed form `(N−1)/(2N)` was verified against enumeration for **every N from 2 to 20**.

   The useful part is the direction: the defender's advantage *is* the tie, `P(tie) = 1/N`, so **more faces
   means a slightly weaker defender**, approaching a coin flip from below. Players — and the team's first
   instinct — assume more faces means swingier combat. It does not (Appendix G §G.4).

4. **A forced trade is always satisfiable at the configured card rules, and not at the alternatives.**
   Sweeping every 5-card hand over the six symbols: `any_distinct` yields **0** unsatisfiable hands under
   either wild rule, while `classic_triple` yields **39** with `joker` and **51** with `pair_only` — the
   smallest counterexample being `{Infantry, Infantry, Cavalry, Cavalry, AirForce}`.

   This quantifies the rules file's own warning that **D-27** and **D-28** change how often FR-35 is
   satisfiable. It also turns an abstract open decision into a concrete cost: choosing `classic_triple`
   requires an engine change, because `LegalDraft` would otherwise return an empty list and `Legal` would
   stop being total (Appendix G §G.5).

### From the design pack, computed against the tokens and anchors

5. **The whole board cannot offer compliant touch targets on a phone, and that is arithmetic.** The two
   closest territory anchors are **89.4 px** apart on the 1600 px canvas, and every territory has a
   neighbour within 145.6 px, so the board is uniformly dense. A 48 px target therefore needs a viewport of
   **≥ 859 px** — which no phone provides at fit-to-width. The design answers it with a territory list as
   the primary selection path rather than pretending a 20 px target works (`design/07` §7.2).

6. **The seat palette fails for three specific colour-vision pairs, and greyscale does not rescue it.**
   Simulated at full severity, deuteranopia collapses Teal against Slate (ΔE 3.8) and Cobalt against Violet
   (ΔE 5.4), and tritanopia collapses Jade against Teal (ΔE 5.4), while normal vision separates every pair
   comfortably (closest ΔE 28.7). Relative luminance does not separate them either — Violet and Crimson are
   1.4 apart. This is why ownership is encoded **twice**, by colour *and* pattern (`design/07` §7.4).

   The same pass found two tokens genuinely failing contrast — `warning` at 2.44 : 1 behind body text, and
   `border-strong` at 1.92 : 1 behind a boundary that must be identifiable — and both were corrected.

Findings 3 and 6 are the ones worth generalising from: each cost one script, each contradicted a plausible
assumption already written down in prose, and neither would have emerged from any amount of careful
re-reading.

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
| **Three clients is the largest single cost** | Three complete UIs in three toolchains, each needing the full S-01…S-20 inventory, is plausibly more work than the engine, the API, the database and the AI combined. It is a stated project requirement (**C-04**, Locked — *"none may be dropped"*), so it stays unless the committee amends it; the measured case for amending it is [`../PLATFORM-SCOPE-PROPOSAL.md`](../PLATFORM-SCOPE-PROPOSAL.md). It remains the constraint most likely to compress everything else |
| **Phase 11 ordering** | The recommended phase order completes three clients before adding the extension actions, which means revisiting all three. §8.11 documents running Phase 11 earlier for this reason; if that adjustment is not made, budget three extra client passes |
| **RL is unlikely to reach a strong result** | PPO on a multi-agent stochastic board game with a 100-round horizon is a research-scale problem. The plan treats RL as optional and gated for exactly this reason, and §10.3 is written so that "did not beat MarsBot" is a reportable outcome rather than a hole |
| **Dart realtime transport is unresolved** | SignalR has no first-party Dart client. The fallback — REST polling — is adequate for a turn-based game, but it is a fallback, and the decision should be made in Phase 10 rather than during integration (§8.6) |
| **Coastal status is an unvalidated design judgement** | 36 of 42 territories are coastal by authored decision, not by geography. It determines Naval reach across the whole board and has never been playtested (O-02) |
| **The capability mapping is unplaytested** | Appendix D's 42 rows are a first pass. Seven air-capable territories and five Air Force cards are plausible numbers, not measured ones (O-03, O-04) |
| **The frozen-parameter trap is the most dangerous defect the package can contain** | If `diceSides` or `attackRange` were ever read live from `shared/rules.json` instead of from `matches.options`, a resumed match would consume **exactly one random draw per roll as before** — so `rng_position` would track the log perfectly, **every determinism test would pass**, and every face and every outcome would differ. TC-DET-01…04 *cannot* detect it. **TC-PER-07 is the only guard**, and it is the only test in the suite that asserts where a value came from rather than what it equals. It must not be "simplified" into an equality check (Appendix G §G.15) |
| **The mobile board cannot meet touch-target guidance, by arithmetic** | The two closest territory anchors are 89.4 px apart on a 1600 px canvas, so a 48 px target needs a viewport ≥ 859 px — more than any phone at fit-to-width. This is not a layout problem to be solved later; it is a property of putting 42 territories on one screen. The design pack answers it with a compliant territory-list path, and that path is **not** optional polish — on a phone it is the primary way to play (`design/07` §7.2) |

### What would make this specification wrong

The most useful thing a plan can state is its own failure condition. This one is wrong if:

- the engine acquires a dependency, in which case NFR-01 falls and with it every determinism and
  testability claim built on it;
- a client acquires rule logic, in which case the three clients begin to diverge and the traceability
  matrix becomes fiction;
- **a frozen match parameter is read live**, in which case replays diverge silently while the entire
  determinism suite stays green (§11.4);
- the assumption register stops being updated, in which case decisions revert to being undocumented and
  §2's authority order no longer has anything to point at.

None of the four is a technical limit. All four are discipline, and all four are cheap to check —
TC-ARC-01, TC-ARC-04, TC-PER-07, and reading the register's last-modified date.

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

#### Three decisions that need an answer before Phase 4

Unlike O-01…O-06, these have a **deadline**: each changes a test oracle, so answering them after the card
rules are implemented means rewriting tests rather than writing them.

| ID | Question | Cost of each answer |
|---|---|---|
| **D-27** | `distinctSetRule`: `any_distinct` (any three distinct non-Wild symbols) or `classic_triple` (specifically Infantry + Cavalry + Artillery)? | `any_distinct` keeps a forced trade **always** satisfiable. `classic_triple` makes it unsatisfiable in **39** of the 5-card hands, which requires an engine change in `LegalDraft` *and* a UI empty state — not just a rules-file edit |
| **D-28** | `wildSubstitution`: `joker` (a Wild stands for any symbol) or `pair_only` (a Wild only completes a pair)? | Under `classic_triple`, `pair_only` raises those 39 bad hands to **51**. Under `any_distinct` neither option produces one |
| **—** | `territoryBonusMaxPerTurn`: is "capped at 2 per turn" two **armies** or two **bonuses**? | The pseudocode counts armies, so as written a turn yields **one** +2 bonus. If two separate bonuses were intended the value should be **`4`** (Appendix G §G.5) |

All three are recorded in [`shared/rules.json`](../shared/rules.json) with the alternatives spelled out,
and all three were quantified by enumeration rather than left as opinions (§11.3).

### Deferred features already specified but not required

| Item | Status | Where it is specified |
|---|---|---|
| Submersion masks | Optional, no v1 requirement | D-05; §3.2 explicitly generates no FR for it |
| Territory artwork and polygons | Phase 12, optional | §7.11, O-01 |
| Additional authored maps | Straightforward once the format is stable | §8.10 |
| `one_step_all` and `connected_path` fortify modes | Implemented as configuration, untested in play | §7.4, D-16 |
| **Replay viewer** | **In scope, not an extension** — FR-59 *(S)*, UC-18, route 12, screen S-19, covered by TC-UI-01 | §4.3 UC-18, §5.3, Appendix A route 12 |
| Trained-policy opponent as the shipped default | Gated on the §10.3 evaluation | §8.9 |

### Genuine extensions — each requiring explicit approval

Everything below is outside the current scope, and §40 forbids adding any of it silently. Listed so that a
future reader knows these were considered and deliberately excluded, not overlooked:

| Extension | Why it was excluded now |
|---|---|
| Mission / objective cards | A second victory surface; standard rules permit omitting them (D-26) |
| Tournament and ranking systems | Requires accounts, matchmaking and persistence well beyond six tables |
| Spectator mode | Cheap to add later, given per-seat redaction already exists |
| Additional map sizes and shapes | The generator already supports variable territory counts |
| Web delivery | The Flutter client is the route; the Godot client cannot provide it (§8.5) |
| Cross-platform mobile polish | The Flutter client exists; the work is UX, not architecture |
| Free-text chat | Not built (D-25). Preset messages are the optional substitute (FR-70); no text input field exists anywhere in any client |

The cheapest item on that list is **spectator mode**: a seat-less redaction path over a redaction system
that already exists, and the natural first extension because it adds no subsystem at all. It is a better
first choice than anything on the list that needs new state.

> The replay viewer used to appear here and has been moved up a section. It is **not** an extension: it
> has a requirement (FR-59), a use case (UC-18), an API route (12), a screen (S-19) and a test (TC-UI-01).
> Listing a specified Should-have as out-of-scope future work is exactly the kind of drift §40 exists to
> catch, so it is recorded rather than quietly deleted.

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
