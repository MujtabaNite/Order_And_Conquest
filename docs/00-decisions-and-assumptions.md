# 00 — Decisions and Assumptions Register

> **Deliverable U.** Read this before any other chapter. It is the authority record for the whole
> package: where the master prompt's locked decisions overrode an existing source file, what was
> genuinely unspecified, and what was decided in order to proceed.
>
> Nothing here is silently blended. Where two sources conflict, the conflict is stated, the locked
> decision is followed, and the contradiction is recorded.

## Authority order applied throughout

| Rank | Source | Status |
|---|---|---|
| 1 | `Prompts/Order_and_Conquest_Master_Claude_Prompt.pdf` v1.0 | **Authoritative.** Locked decisions cannot be overridden. |
| 2 | Project source files `00-research.md`, `01-architecture.md`, `02-map-system.md`, `03-ai-and-rl.md`, `04-database.md` | Current design. Used wherever rank 1 is silent. |
| 3 | *Risk Conquest* (2022 BSCS FYP report) | Historical reference only. Cited, not followed. |
| 4 | General engineering knowledge | Only for genuinely unspecified details, and only at the simplest level that works. |

**Governing constraint (prompt §3):** the project must not be made larger than necessary. A feature is
not required merely because it appears in the 2022 report or in general practice. Where something is
unspecified, the simplest implementation is chosen or the item is marked optional/future.

---

## Part A — Conflicts between the locked prompt and existing project files

These are contradictions, not gaps. In every case rank 1 wins and the contradiction is recorded here.

### D-01 — Namespace and project names: `Conquest.*` → `OrderAndConquest.*`

| | |
|---|---|
| **Conflict** | Prompt §17/§27 mandates `OrderAndConquest.Engine`, `.Api`, `.Data`, `.Ai`, `.Sim`, `.Tests`. `01-architecture.md` and `04-database.md` use `Conquest.*`. |
| **Decision** | `OrderAndConquest.*` throughout. Solution file `OrderAndConquest.sln`. |
| **Consequence** | Every code reference in the older documents is renamed in this package. The *design* those documents describe is unchanged — this is a naming decision only. |
| **Risk if ignored** | Two names for one project in the FYP report reads as an unfinished draft to an examiner. |

### D-02 — `Conquest.MapGen` is dissolved into `OrderAndConquest.Engine`

| | |
|---|---|
| **Conflict** | `01-architecture.md` lists a sixth project, `Conquest.MapGen`. The prompt's component list (§17) and repository structure (§27) do not contain it, and §27 says *"Do not add projects merely for naming symmetry. If a directory is not used, omit it."* |
| **Decision** | Map **generation and validation** move to `OrderAndConquest.Engine/Map/`. They are pure, seeded, I/O-free computation, so they satisfy the engine purity rules unchanged. Map **loading and serving** (file reads, HTTP) stay in `OrderAndConquest.Api`. |
| **Consequence** | Five class libraries plus a test project, matching §17 exactly. One fewer assembly, one fewer project reference graph, no capability lost. |
| **Note** | `DelaunatorSharp` becomes an Engine dependency. It is a pure computational-geometry library with no I/O, so NFR-01 still holds. |

### D-03 — Card symbol domain extends from 4 values to 6

| | |
|---|---|
| **Conflict** | `04-database.md` constrains `cards.symbol` to `('infantry','cavalry','artillery','wild')`. The prompt §13 locks six card types: Infantry, Cavalry, Artillery, Air Force, Naval Force, Wild. |
| **Decision** | The CHECK constraint becomes `('infantry','cavalry','artillery','airforce','naval','wild')`. See `appendices/B-database-schema.sql`. |
| **Explicitly unchanged** | The **trade set stays three cards** (3 alike / 3 different / 2 + Wild). Prompt §13 and §40 both forbid five-card sets. Adding two symbols does not change set size. |

### D-04 — `seaLanes` is renamed `crossesWater` to free the term "sea route"

| | |
|---|---|
| **Conflict** | `02-map-system.md` uses `seaLanes` for a **cosmetic** subset of ordinary land-adjacency edges (Alaska ↔ Kamchatka is "a normal edge to the rules; the client just draws it dashed"). The prompt §14 introduces **sea routes** as a genuinely distinct edge type, used only by Naval Force and explicitly excluded from Air Force range. Two different things one word apart is a guaranteed implementation bug. |
| **Decision** | The cosmetic render hint is renamed **`crossesWater`** in `map.json`. The term **"sea route"** is reserved exclusively for the generated Naval-Force edge type. Prompt §39 requires consistent terminology; this is that consistency made enforceable. |
| **Consequence** | `crossesWater` is a render-only array of pairs and carries **no** mechanical meaning. Sea routes never appear in `world_classic.json` at all — they are generated per match and frozen into `matches.effective_map`. |

### D-05 — Submersion masks are classified **optional**, not a v1 requirement

| | |
|---|---|
| **Conflict** | Submersion is the headline feature of `02-map-system.md` (`MaskResolver`, `bonusPolicy`, a frozen `matches.mask` column, rejection-not-repair). The prompt's in-scope list does **not** include it. Its only mention is oblique — "submerged variants where supported" in RL curriculum stage 4 (§33). |
| **Decision** | Classified **optional / time-permitting**. Prompt §3 and §40 forbid promoting optional items to mandatory requirements, and the prompt's silence is not an endorsement. |
| **What is kept** | The design stays documented (§5.7, `appendices/C-map-specification.md`), and the `matches.mask` column stays in the schema — it is nullable and costs nothing. The graph-neural-network state encoder is retained **independently**, because procedural maps alone already produce variable territory counts (§2.6). |
| **What is not done** | No submersion FR. No submersion in the implementation phases. No submersion in the v1 test plan. Mid-match submersion remains deferred, as `02-map-system.md` already recorded. |

### D-06 — 2022 report internal inconsistency on claim-phase troops

| | |
|---|---|
| **Conflict** | The 2022 report gives 38 starting troops in §3.2 and 30 in its Annexure. |
| **Decision** | Neither is used. The sourced starting-army table governs: **3 players → 35, 4 → 30, 5 → 25, 6 → 20** (`shared/rules.json` → `setup.startingArmies`). |
| **Recorded because** | Prompt §39 requires distinguishing source facts from design decisions, and an examiner comparing the two documents will find the discrepancy. |

### D-07 — Two-player matches use a third Neutral seat

| | |
|---|---|
| **Conflict** | `00-research.md` notes a "2p → neutral-force variant" without fixing the army count. |
| **Decision** | A 2-player match is `[LocalHuman, Ai-or-Human, Neutral]` — three seats. The **3-player row (35 armies)** therefore applies with no special case. `Neutral` never attacks and never fortifies; the server skips its turn. |
| **Why** | It reuses the existing seat kind from `01-architecture.md` and adds no rule. The alternative — a bespoke 2-player rule set — is a second rules path for one configuration. |

---

## Part B — Subsystems that exist only in the locked prompt

Air Force, Naval Force, per-territory capability profiles and sea routes appear in **none** of the five
existing design documents and **none** of the 2022 report. They are new design work. Each decision
below is labelled with what it is.

### D-08 — Capability profile derivation (rule **CAP-1**)

> **This is a game-design decision, not a factual claim.** Prompt §13 requires it be presented as such.

```
profile(t) = {Infantry}
           ∪ ({NavalForce}  if t.coastal)
           ∪ {t.cardSymbol}
```

Two authored fields per territory — `coastal` (boolean) and `cardSymbol` (one of six) — derive the
whole profile. The profile is **also written explicitly** into `world_classic.json` and re-derived on
load and asserted equal (test **TC-MAP-05**), so the data cannot drift from the rule.

| Why this shape | |
|---|---|
| Minimal authored surface | Two fields, not a five-way matrix of 42 rows. |
| Fully data-driven | Retuning capability distribution is a data edit; no engine change. |
| Satisfies §13 | A profile legitimately contains multiple capabilities, and a coastal territory can supply Naval Force plus whatever its profile says. |
| Adds no units | See D-09. |

### D-09 — Infantry, Cavalry and Artillery unlock nothing

| | |
|---|---|
| **Decision** | Infantry, Cavalry and Artillery are **card symbols only**, with no distinct mechanics — exactly as in classic RISK. **Air Force and Naval Force are the only two capabilities that unlock an action.** |
| **Why** | Prompt §40 forbids inventing extra military units or unit types. In classic RISK the three symbols already have no mechanical difference; giving them one would be exactly the invention §40 prohibits. |
| **Consequence** | The "capability system" has precisely two mechanical members. That is the entire extension, and it is why it fits without a second combat system. |

### D-10 — Capability acquisition (assumption **CAP-2**)

| | |
|---|---|
| **Prompt text** | §12: *"A player can acquire Naval capability by acquiring the relevant territory/card from a territory that provides that capability."* The exact predicate is not locked. |
| **Assumption** | A seat holds capability **X** iff it owns ≥ 1 territory whose profile contains X, **or** holds ≥ 1 card whose profile contains X. |
| **Simplest consistent rule** | It is a set-membership query over state the engine already has. No new state, no counters, no research tree, no timers. |
| **Consequence** | Capability is **derived, never stored** — so it can never desynchronise from ownership, and it needs no database column. A landlocked-only seat genuinely has no Naval capability until it takes a coastal territory or draws a naval card. |

### D-11 — Air Force limiter (assumption **AIR-1**)

| Locked | Assumed |
|---|---|
| Long-range attack; **max range 5**; range measured by **land adjacency only**; sea routes **excluded** from range; normal dice combat; no fuel, no airfields, no bombing, no hit points. | `airForce.attacksPerTurn = 1`. |

Prompt §11 says that if an exact quantity or cost is unspecified, use the simplest consistent rule and
label it an assumption. Without a limiter, Air Force attack is a strict superset of normal attack
(range 5 includes range 1) and normal attack becomes dead code. One integer in `rules.json` is the
smallest fix that preserves both actions.

**Measured, not asserted:** on the classic board the land graph has **diameter 10**, and range 5
reaches **77.2%** of ordered territory pairs (1330 of 1722). Range 5 is therefore a real constraint on
this board, not a formality. Computed from `shared/maps/world_classic.json`; reproduced in §7.8.

A consequence worth stating: a successful Air Force attack at distance 5 creates a territory
disconnected from the attacker's other holdings. That is a direct and intended result of the locked
rule, not a bug. It is documented in §7.8 and covered by **TC-AIR-04**.

### D-12 — Naval Force cost (assumption **NAV-1**)

| Locked | Assumed |
|---|---|
| Operates over sea routes; enables movement, attack and fortification; **same** combat resolution; landlocked territories never automatically naval; capability acquired via territory or card. | `navalForce.unitsRequiredPerRoute = 0`. |

Prompt §12 explicitly permits this: *"If the exact number of Naval units required to exercise a route is
not locked by the supplied sources, choose the simplest implementation, document the assumption."*

**The simplest implementation is zero.** A sea route behaves exactly like a land-adjacency edge **for a
seat that holds Naval capability**. This introduces no naval unit type, no transport capacity, no
loading step and no second combat system — which is what §40 requires.

### D-13 — Sea-route generation bounds (assumption **SEA-1**)

| Locked | Assumed |
|---|---|
| The seat chooses **how many** sea routes at match setup; the system chooses the endpoints; a configurable min and max are enforced; generated routes are **frozen** into the match's effective map. | `min 2`, `max 10`, `default 4`. |

`min = 2` rather than 0, so that whenever the Naval Force extension is enabled there is something for
it to do — a match with zero sea routes silently disables a locked feature. Classic-only play is
reached by `navalForce.enabled = false`, one flag, rather than by a zero count.

Endpoint validity rules (§7.10): both endpoints coastal; not already land-adjacent; no duplicate route;
different continents preferred but not required; bounded attempt count then a specific failure.

### D-14 — Capability distribution on the classic board

> **Game-design decision for team review.** Prompt §13 forbids presenting a capability mapping as
> established fact or inventing real-world military claims. The full 42-row table, with the rule used
> and a review column, is `appendices/D-capability-mapping-decision-table.md`.

Summary of what was decided:

| | Count | |
|---|---|---|
| Coastal | 36 | Naval-capable from the start |
| Landlocked | 6 | `alberta`, `ontario`, `northern_europe`, `ukraine`, `irkutsk`, `afghanistan` |
| Air-capable | 7 | one per continent, two in Asia |
| Card symbols | 42 | Infantry 12 · Cavalry 10 · Artillery 8 · Air Force 7 · Naval Force 5 |
| Deck | 44 | 42 territory cards + 2 Wild |

**Coastal status is a game-design decision, not geography.** The classic board is a stylised map; several
territories are arguable either way. The six landlocked territories were chosen because they are
interior on the published board *and* because the distribution puts at least one landlocked territory in
four of six continents, which makes Naval capability meaningful to acquire. Every entry is data and may
be changed by the team without touching the engine.

---

## Part C — Details the locked prompt leaves open, and questions reopened after the lock

### C.1 — Genuinely unspecified details

| ID | Item | Decision | Why this one |
|---|---|---|---|
| D-15 | Card trade values 10, 12, 15 | Kept in `rules.json` as data | Only 4, 6, 8, 20, 25 are sourced. The rest are inferred, and staying data is the honest encoding of that. |
| D-16 | Fortify variant | `single_pair` default; `one_step_all` and `connected_path` are data | Published rule sets disagree. The active mode is recorded in an RL checkpoint's metadata and asserted at load, so an agent cannot be trained on one rule and played under another. |
| D-17 | Air Force range includes distance 1 | Yes — range is 1…5 | Excluding adjacency would need a special case, and the locked text says "max range 5" with no minimum. AIR-1 already prevents dominance. |
| D-18 | Whether Air Force can occupy | Yes, ordinary occupy rules | §11 says combat resolution is unchanged. Occupy is part of combat resolution. |
| D-19 | Naval fortify counts against the one fortify per turn | Yes | One fortify action per turn, land or naval. A second free naval fortify would be a new mechanic. |
| D-20 | Whether a Wild card carries a capability | No | A Wild card has no territory, so it has no profile. It is a set-matching joker only. |
| D-21 | Difficulty → agent mapping | Easy = Passive, Normal = Mars `W_p` 0.85, Hard = Mars `W_p` 0.7375, Brutal = ONNX | `03-ai-and-rl.md`; retained because it is already a design decision there and the prompt is silent. |
| D-22 | Minimum AI think time | 400 ms, applied at the API layer | From `01-architecture.md`. At the API, not in the agent, so RL training runs at full speed. |
| D-23 | Password hashing | Argon2id, PHC string format | The 2022 report stored `p_Password` in plaintext. Recorded as a correction, not a continuation. |
| D-24 | Guest play | Permitted without an account | Single-player must not require registration. Accounts exist for resumable history and later online play. |
| D-25 | Free-text chat | Not built | The 2022 report specifies preset messages and emoji. Preset messages are in scope as an optional client feature; free text is not. |
| D-26 | Secret mission cards | Not built | Standard rules permit omitting them. World domination is the only victory condition (§7.12). |
| D-27 | What "three different symbols" means once there are five non-Wild symbols | **Any three distinct non-Wild symbols** — `cards.distinctSetRule: "any_distinct"` | In classic RISK there are exactly three symbols, so "three different" and "one of each" are the same sentence. With five, they are not. Requiring specifically Infantry + Cavalry + Artillery would make an AirForce or NavalForce card nearly dead for the "different" route, which is a balance change nobody asked for. Surfaced while writing `IsSet` in `appendices/E-pseudocode.md`. |
| D-28 | Whether a Wild substitutes for **any** symbol, or only completes a pair | **Any symbol** — `cards.wildSubstitution: "joker"` | §7.6 says "two of one symbol plus a Wild", which is *narrower* than the official classic-RISK rule ("any two cards plus a Wild"). Under `joker` the two readings coincide for pairs and additionally decide the two hands §7.6 leaves out: `{Infantry, Cavalry, Wild}` and `{X, Wild, Wild}`. The classic reading is chosen because classic RISK is the stated foundation of the whole design. |

> **D-27 and D-28 need a reviewer's confirmation before Phase 4.** Both change how often a forced trade
> (FR-35) is satisfiable, and therefore change every card-family test oracle and any agent trained against
> them. Both are `shared/rules.json` keys rather than code, so confirming the other branch is a data edit
> and a re-run of TC-CRD-06 — not a rewrite. The reasoning is set out in
> [`appendices/E-pseudocode.md`](../appendices/E-pseudocode.md) §E.8.1.

### C.2 — Post-lock additions from supervisory review

D-15…D-28 above record things the locked prompt left *silent*. The two entries below are different in
provenance and the register should not blur them: the prompt is not silent on six-sided dice or on
adjacency-based attack — it specifies both. **Supervisory review asked whether each could be a
configurable parameter rather than a constant.** They are recorded here, after the lock, as scope
additions rather than as clarifications.

Both are resolved by **generalisation with a default that reproduces the locked behaviour exactly**, which
is what makes them additive rather than a rules change:

| ID | Question | Decision | Why this one |
|---|---|---|---|
| D-29 | Whether the number of **die faces** is fixed at six | **Configurable** — `combat.diceSides`, default `6`, range 2…20 | The six faces come from the physical object, not from any rule. Every rule in §7.5 is stated over *ordered comparison of drawn values*, and none of them mentions the number six. Defaulting to 6 means a match created without touching the key is bit-for-bit the classic game, so the generalisation costs nothing at the default and the constant never reappears in code. |
| D-30 | Whether **attack distance** is fixed at adjacency | **Configurable** — `combat.attackRange`, default `1`, range 1…10 | Adjacency is distance 1 in the land graph, so "adjacent" is already the `R = 1` case of "within range R". At the default the legal set is identical to the neighbour list, and the upper bound of 10 is the measured diameter of the classic land graph (§7.8) — i.e. the whole landmass, beyond which larger values mean nothing. |

Four consequences follow that are easy to miss, and each is load-bearing:

1. **Both values must be frozen into the match, not read live from `rules.json`.** They are stored in
   `matches.options` alongside the allocation and fortify modes, for the same reason
   `matches.effective_map` is frozen (FR-10). `diceSides` changes the *values* drawn from the random
   source while leaving the *number* of draws untouched, so a match replayed under a different
   `diceSides` consumes identical `rng_position` values and silently produces different dice —
   determinism would appear to hold while the replay diverged. `attackRange` changes the legal set, so a
   replay under a different range would reject a logged action outright. Editing either key must be
   incapable of affecting a match already in progress.
2. **Defender-wins-ties is independent of the face count** (DR-07). The rule is `attacker > defender`, a
   strict comparison between two drawn values; it does not reference the size of the domain they are drawn
   from. No part of §7.5 needs restating for `diceSides ≠ 6`.
3. **The five exact combat fractions are the `diceSides = 6` instance of a general oracle, not a separate
   oracle.** Their denominators — 36, 216, 1296, 216, 7776 — are `6^(a+d)`. The oracle generalises to
   exhaustive enumeration over `N^(a+d)` equally likely outcomes, which is the "independent computation"
   oracle kind §9.1 already defines. See §7.5 and `appendices/F-test-cases.md` TC-CMB-02…06.
4. **At `attackRange ≥ 2`, range stops being what distinguishes the Air Force.** A ranged land attack is a
   breadth-first search to depth R over land edges — the *same computation* as the Air Force range check
   (D-11). The two therefore share one range function rather than growing a second one, which preserves
   DR-19's single combat resolution. What still distinguishes the Air Force is the `attacksPerTurn: 1`
   limiter (AIR-1) and the capability requirement (CAP-1, CAP-2) — **not** its reach. §7.8 states this
   explicitly, because an Air Force subsystem that looks redundant is one a later reader will delete.

Raising `attackRange` **cannot** make a sea route traversable. The range function is handed the land graph
and has no access to `map.seaRoutes` (C-08), so the structural exclusion that DR-18 and TC-AIR-03 depend on
survives any value of R. Likewise, the search is over land *edges* regardless of who owns the intervening
territories: reach is geographic, not controlled, exactly as it already is for the Air Force.

> **D-29 and D-30 are supervisor-facing and should be demonstrated, not just documented.** Each is one
> `shared/rules.json` value whose effect is visible in play — a seven-faced die changes the odds table, a
> range of 2 changes the highlighted attack targets on the board. §9.2's parameterised oracles and the dice
> renderer of `design/04-dice-ui-ux.md` exist so that both can be shown working rather than asserted.

---

## Part D — Unresolved, deliberately left open

These are recorded as open rather than decided, because deciding them now would be guessing.

| ID | Open question | Why it can wait | Who decides |
|---|---|---|---|
| O-01 | Territory polygon artwork for the 42 classic territories | `02-map-system.md`: adjacency first, geometry later. The engine, bots, tests and pass-and-play all run against the debug board view. Blocking gameplay on artwork is the single most avoidable schedule risk in this project. | Team, Phase 12 |
| O-02 | Whether the Flutter client ships offline | It cannot run PostgreSQL and Kestrel on a handset. Either it talks to a remote server or the engine is compiled in via FFI. Both are open. | Team, Phase 11 |
| O-03 | Whether RL ships at all | Gated on beating MarsBot over ≥ 1000 seeded matches. If it does not, MarsBot is the shipped opponent and the RL work is reported as a negative result. | Measured, Phase 14 |
| O-04 | Whether the 7 air-capable territories are the right **set**, not just the right count | Measured finding: reach at range 5 varies from **11 of 41** (Eastern Australia) to **40 of 41** (Ukraine), mean 31.7. Eastern Australia is currently air-capable and is the worst position on the board from which to use the capability. Possibly intended, possibly an artefact of one-per-continent distribution. Genuinely a playtest question, and one data edit. See §7.8. | Playtest |
| O-05 | Turn timer duration | The field exists (`matches.options.turnTimerSeconds`) and is unenforced at 0. It only becomes load-bearing with remote play. | Team, Phase 6+ |
| O-06 | Preset message list | Optional client feature; content is not a systems decision. | Team |

---

## Part E — What this project is explicitly **not** building

Restating prompt §40 as a checklist, because scope creep in an FYP is usually additive and quiet.

**Game mechanics — none of these:** diplomacy · alliances as a rule · player-to-player card or army
trading · fog of war · commanders · heroes · resources · economy · tech trees · mission cards ·
per-unit hit points · fuel · airfields · bombing runs · transport capacity · naval unit types.

**Rules that must not be replaced:** dice combat stays · classic card trading stays · three-card sets
stay · land adjacency stays the basis of normal attack.

**Sea routes:** not arbitrary user-drawn routes — the seat picks a count, the system picks endpoints.
Not every territory naval — landlocked territories are never automatically naval. Not usable by Air
Force for range.

**Combat:** one resolution path. No separate air combat system. No separate naval combat system.

**Architecture:** no microservices · no cloud infrastructure requirement · no container orchestration ·
three rules engines are never created, only one · no client contains rule logic · no dozens of database
tables (there are six) · no design pattern introduced without a named problem it solves.

**Requirements:** RL is not required for playability. Procedural maps are not required for playability.
Submersion is not required at all (D-05). No optional feature is promoted to mandatory.

---

## Part F — Traceability of this register

| Register entry | Where its consequence appears |
|---|---|
| D-01, D-02 | §5.2 components, §8.2 backend, `docs/08-implementation-plan.md` repository structure |
| D-03 | §6.5 constraints, `appendices/B-database-schema.sql` |
| D-04 | §7.10 sea routes, `appendices/C-map-specification.md`, `shared/maps/world_classic.json` |
| D-05 | §5.7 maps, §3.3 NFR scope note, absent from FRs and phases by design |
| D-06, D-07 | §7.1 rules, §7.2 turn system, `shared/rules.json` → `setup` |
| D-08, D-09, D-10 | §7.7 capability system, FR-11 / FR-39…41, `appendices/D-capability-mapping-decision-table.md` |
| D-11 | §7.8 Air Force, FR-42…46, TC-AIR-01…05 |
| D-12 | §7.9 Naval Force, FR-47…51, TC-NAV-01…05 |
| D-13 | §7.10 sea routes, FR-15/16, TC-SEA-01…05 |
| D-14 | `appendices/D-capability-mapping-decision-table.md`, TC-MAP-05 |
| D-15…D-26 | `shared/rules.json`, §7, §5.9 security |
| D-27, D-28 | `shared/rules.json` → `cards`, §7.6, `appendices/E-pseudocode.md` §E.8.1, TC-CRD-06 |
| D-29 | `shared/rules.json` → `combat.diceSides`, §7.5, FR-84, `matches.options` (§6.6), `appendices/E-pseudocode.md` §E.3.3/§E.6, TC-CMB-10, TC-PER-07, `design/04-dice-ui-ux.md` |
| D-30 | `shared/rules.json` → `combat.attackRange`, §7.5, §7.8, FR-85, `matches.options` (§6.6), `appendices/E-pseudocode.md` §E.4.3/§E.10, TC-CMB-09, TC-AIR-02, TC-PER-07, `design/03-map-ui-ux.md` |
| O-01…O-06 | §11 future work, `docs/09-testing.md` risk notes |
| Part E | `docs/14-implementation-safety-checklist.md` |
