# 00 — Decisions and Assumptions Register

> **Deliverable U.** Read this before any other chapter. It is the authority record for the whole
> package: where the master prompt's locked decisions overrode an existing source file, what was
> genuinely unspecified, and what was decided in order to proceed.
>
> Nothing here is silently blended. Where two sources conflict, the conflict is stated, the locked
> decision is followed, and the contradiction is recorded.

> ## 🔶 October 2026 — the prototype-edition rework
>
> **In plain words.** The team made a set of new decisions in October 2026 that change the shape of
> this project: one laptop hosts everything, all three clients are Android phones in landscape, the
> whole thing runs on a phone hotspot with no internet, and the database is fully normalised into 13
> tables. Those decisions are **Part G** of this file, numbered **D-31 to D-66**.
>
> Several earlier decisions were overtaken. They are **not deleted** — each one is still below, with a
> **Superseded by D-xx** banner saying what replaced it and why. If you are reading an entry with a
> banner, read the banner first.
>
> | | |
> |---|---|
> | **Superseded** | D-03, D-04 (part), D-07 (part), D-13, D-24, D-29/D-30 (storage only), constraint C-03 |
> | **Retired** | D-21, O-05 |
> | **Resolved** | O-02 — answered by D-33 |
> | **Still open** | O-01, O-03 (now `[P3]`), O-04, O-06 |
>
> New reader? Start with [`PROTOTYPE-EDITION.md`](PROTOTYPE-EDITION.md), then Part G below.

## Authority order applied throughout

| Rank | Source | Status |
|---|---|---|
| 0 | **Team decisions, October 2026** (`Prompts/Rework/`, recorded as D-31…D-65) | **Authoritative, and may override rank 1.** D-41 is the decision that permits this |
| 1 | `Prompts/Order_and_Conquest_Master_Claude_Prompt.pdf` v1.0 | Authoritative except where a D-31…D-65 entry supersedes it |
| 2 | Project source files `00-research.md`, `01-architecture.md`, `02-map-system.md`, `03-ai-and-rl.md`, `04-database.md` | Current design. Used wherever ranks 0–1 are silent. |
| 3 | *Risk Conquest* (2022 BSCS FYP report) | Historical reference only. Cited, not followed. |
| 4 | General engineering knowledge | Only for genuinely unspecified details, and only at the simplest level that works. |

**Governing constraint (prompt §3):** the project must not be made larger than necessary. A feature is
not required merely because it appears in the 2022 report or in general practice. Where something is
unspecified, the simplest implementation is chosen or the item is marked optional/future.

**Second governing constraint (D-31, October 2026):** optimise for *"three students with other
coursework can finish this"*, not for completeness. Where the two constraints agree — and they almost
always do — the stricter reading wins.

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

> **🔶 Superseded in part by D-51 (October 2026).** The *domain* is unchanged — there are still six
> symbols. What changed is that the symbol is **no longer a stored column**. A card's symbol is now its
> territory's `card_symbol`, or `Wild` when the card has no territory, so the `cards.symbol` CHECK
> constraint described below no longer exists. The six values live in the `card_symbols` lookup table
> instead. The trade set is still three cards.

| | |
|---|---|
| **Conflict** | `04-database.md` constrains `cards.symbol` to `('infantry','cavalry','artillery','wild')`. The prompt §13 locks six card types: Infantry, Cavalry, Artillery, Air Force, Naval Force, Wild. |
| **Decision** | The CHECK constraint becomes `('infantry','cavalry','artillery','airforce','naval','wild')`. See `appendices/B-database-schema.sql`. |
| **Explicitly unchanged** | The **trade set stays three cards** (3 alike / 3 different / 2 + Wild). Prompt §13 and §40 both forbid five-card sets. Adding two symbols does not change set size. |

### D-04 — `seaLanes` is renamed `crossesWater` to free the term "sea route"

> **🔶 Superseded in part by D-37, D-50 and D-53 (October 2026).** The rename itself **stands and is
> load-bearing** — `crossesWater` / `crosses_water` is still a render hint with no mechanical meaning,
> and "sea route" still means exactly one thing. What changed is the final sentence below: sea routes
> are **no longer generated per match and frozen into `matches.effective_map`**. They are a fixed list
> per map, authored by the team, stored in the `sea_routes` table, and they *do* now appear in
> `world_classic.json` as a `seaRoutes` array (empty until the team chooses the list).

| | |
|---|---|
| **Conflict** | `02-map-system.md` uses `seaLanes` for a **cosmetic** subset of ordinary land-adjacency edges (Alaska ↔ Kamchatka is "a normal edge to the rules; the client just draws it dashed"). The prompt §14 introduces **sea routes** as a genuinely distinct edge type, used only by Naval Force and explicitly excluded from Air Force range. Two different things one word apart is a guaranteed implementation bug. |
| **Decision** | The cosmetic render hint is renamed **`crossesWater`** in `map.json`. The term **"sea route"** is reserved exclusively for the generated Naval-Force edge type. Prompt §39 requires consistent terminology; this is that consistency made enforceable. |
| **Consequence** | `crossesWater` is a render-only array of pairs and carries **no** mechanical meaning. ~~Sea routes never appear in `world_classic.json` at all — they are generated per match and frozen into `matches.effective_map`.~~ **See D-37.** |

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

> **🔶 Superseded in part by D-55 (October 2026).** The **rule stands**: a 2-player match is three
> seats, one of them Neutral, so the 3-player starting-army row of 35 applies with no special case.
> Only the seat-kind *name* changed — the composition is now `[Human, Human-or-Ai, Neutral]`, because
> `LocalHuman` and `RemoteHuman` collapsed into one `Human` kind. Confirmed as **D-62**: the Neutral
> seat appears in 2-player matches only, never in a 3–6 player lobby.

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

> **🔶 Superseded entirely by D-37 (October 2026).** Sea routes are **not generated and the host does
> not choose a count**. They are a **fixed list per map**, authored by the team in
> `shared/maps/world_classic.json` and seeded into the `sea_routes` table. The team wants *more* routes
> than classic RISK has; the schema supports any number. The `min` / `max` / `default` keys below are
> removed from `shared/rules.json`, the setup stepper is removed from the UI, and screen S-05 is
> retired. The **endpoint validity rules in the last paragraph survive unchanged** and are now checked
> by `tools/generate_map_seed.py` and `tools/verify_db.sql` V1–V2.
>
> Classic-only play is still reached by one flag — now `match_rules.naval_force_enabled = false`, which
> is the **default** (D-54).

| Locked | Assumed |
|---|---|
| The seat chooses **how many** sea routes at match setup; the system chooses the endpoints; a configurable min and max are enforced; generated routes are **frozen** into the match's effective map. | `min 2`, `max 10`, `default 4`. |

~~`min = 2` rather than 0, so that whenever the Naval Force extension is enabled there is something for
it to do — a match with zero sea routes silently disables a locked feature.~~ *The concern was real and
has moved: the task-day guide now warns that enabling Naval Force with an empty `sea_routes` table
gives the capability nothing to do (§6.10).*

Endpoint validity rules (§7.10) — **still current**: both endpoints coastal; not already land-adjacent;
no duplicate route; different continents preferred but not required. The bounded attempt count and the
generation-failure path are gone with the generator.

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
| D-21 | Difficulty → agent mapping | **🔶 RETIRED (D-56).** Was: Easy = Passive, Normal = Mars `W_p` 0.85, Hard = Mars `W_p` 0.7375, Brutal = ONNX | Difficulty is no longer a user-facing concept. The lobby offers **bot names** — Passive, Chaotic, Aggressive, Mars — and the host picks one per AI seat. The `W_p` tuning values survive in `shared/rules.json → ai.mars`; only the Easy/Normal/Hard/Brutal wrapper is gone |
| D-22 | Minimum AI think time | 400 ms, applied at the API layer | From `01-architecture.md`. At the API, not in the agent, so RL training runs at full speed. |
| D-23 | Password hashing | Argon2id, PHC string format | The 2022 report stored `p_Password` in plaintext. Recorded as a correction, not a continuation. |
| D-24 | Guest play | **🔶 SUPERSEDED by D-38.** Was: permitted without an account | Sign-up and login are now **required**. The reason the exemption existed — "single-player must not require registration" — no longer applies: there is no single-player mode, only a room with humans and bots (D-44), and every seat in a room needs an identity the server can address. Accounts still exist for resumable history |
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

1. **Both values must be frozen into the match, not read live from `rules.json`.** They are stored as
   real typed columns in **`match_rules`** — `dice_sides` and `attack_range` — alongside the allocation
   and fortify modes. *(Storage location changed by **D-52**, October 2026: it was `matches.options`, a
   `jsonb` blob. The freezing requirement is unchanged and is now stronger, because a `CHECK` constraint
   enforces the 2–20 and 1–10 ranges that a JSON blob could not.)*
   `diceSides` changes the *values* drawn from the random
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
| O-01 | **STILL OPEN.** Territory polygon artwork for the 42 classic territories | `02-map-system.md`: adjacency first, geometry later. The engine, bots and tests all run against the debug board view, and the design pack now specifies a **board placeholder** (an ocean rectangle with simple territory shapes) that every screen is drawn on, so artwork blocks nothing. Blocking gameplay on artwork is the single most avoidable schedule risk in this project. | Team, after the demo |
| O-02 | **🔶 RESOLVED by D-33 (October 2026).** Was: whether the Flutter client ships offline | It does not, and neither do the other two. **The laptop is the host.** The engine, the API and PostgreSQL all run there; all three phone apps are thin clients that hold no rules. Nothing is compiled into a handset via FFI, and no client needs to run a database. The question is closed, not deferred | Closed |
| O-03 | **STILL OPEN, now `[P3]`.** Whether RL ships at all | Gated on beating MarsBot over ≥ 1000 seeded matches. Deferred by D-47, so the honest answer for this prototype is "not in this version". If it is never attempted, §10.3 reports it as not implemented — a legitimate result | Measured, if ever |
| O-04 | **STILL OPEN.** Whether the 7 air-capable territories are the right **set**, not just the right count | Re-measured on 13 October 2026 by `tools/generate_map_seed.py --stats`, which reproduced the original figures exactly: reach at range 5 varies from **11 of 41** (Eastern Australia) to **40 of 41** (Ukraine), mean **31.7**. Eastern Australia is currently air-capable and is the worst position on the board from which to use the capability. Possibly intended, possibly an artefact of one-per-continent distribution. Genuinely a playtest question, and one data edit. See §7.8 | Playtest |
| O-05 | **🔶 RETIRED by D-65 (October 2026).** Was: turn timer duration | The column is **gone** from the schema. Nothing in this game expires: the design pack already forbade timed input, and PROMPT B forbids turn timers outright. A remote-play timer would be a new feature, not a configuration | Closed |
| O-06 | **STILL OPEN.** Preset message list | Optional client feature; content is not a systems decision. Note that D-25 already rules out free-text chat, and the design pack forbids any chat surface, so this is a question about a feature nothing currently plans to build | Team |

---

## Part E — What this project is explicitly **not** building

Restating prompt §40 as a checklist, because scope creep in an FYP is usually additive and quiet.

**Game mechanics — none of these:** diplomacy · alliances as a rule · player-to-player card or army
trading · fog of war · commanders · heroes · resources · economy · tech trees · mission cards ·
per-unit hit points · fuel · airfields · bombing runs · transport capacity · naval unit types.

**Rules that must not be replaced:** dice combat stays · classic card trading stays · three-card sets
stay · land adjacency stays the basis of normal attack.

**Sea routes:** not arbitrary user-drawn routes — **a fixed list per map, authored by the team**
(D-37). ~~the seat picks a count, the system picks endpoints~~. Not every territory naval — landlocked
territories are never automatically naval. Not usable by Air Force for range.

**Combat:** one resolution path. No separate air combat system. No separate naval combat system.

**Architecture:** no microservices · no cloud infrastructure requirement · no container orchestration ·
three rules engines are never created, only one · no client contains rule logic · **no table added
without a recorded reason** (there are 13 — D-40, superseding "there are six") · no design pattern
introduced without a named problem it solves.

**Requirements:** RL is not required for playability. Procedural maps are not required for playability.
Submersion is not required at all (D-05). No optional feature is promoted to mandatory.

**Added October 2026 (D-31, D-34, D-44, D-47):** no internet requirement of any kind at run time — no
cloud service, no external API, no CDN, no font download · no single-device play, so no hand-over
screen · no guest sessions · no desktop or iPad layout · no turn timer · no WebSocket or SignalR
transport · no chat, friends list, shop, currency, ads, battle pass, daily rewards, lives, energy or
leaderboard, at any tier.

---

## Part G — The prototype-edition decisions, October 2026

> **In plain words.** In October 2026 the team decided what this project actually is: a **prototype**
> that three students with other coursework can finish, demo and defend. One laptop runs everything.
> Three Android phones connect to it over a phone hotspot. No internet. Classic RISK first; the Air
> Force and Naval Force extensions come after it works.
>
> Everything in this part is new since D-30. Three statuses are used, and the difference matters:
>
> | Status | Meaning |
> |---|---|
> | **Confirmed — team, Oct 2026** | The team decided it. Build to it. |
> | **Proposed — needs team confirmation** | Adopted as the working default so the documents are consistent, but the team has not formally ratified it. Each one is reversible as a data or document edit, and the reversal cost is stated. |
> | **Retired** | Was decided, no longer applies, nothing replaces it. |

### G.1 — Confirmed: what this project is · D-31…D-42

**Status for every row: Confirmed — team, Oct 2026.**

| ID | Decision | Consequence, and what it replaced |
|---|---|---|
| **D-31** | **Prototype scope.** Optimise for "three students can finish this", not for completeness | The second governing constraint of this register. Where completeness and feasibility disagree, feasibility wins. Promoted to rank 0 in the authority order |
| **D-32** | **All three clients are Android, landscape only** — Unity (Mujtaba), Godot (Abdullah), Flutter + Flame (Jarrar) | Frames are **915 × 412** and **800 × 360**. The only portrait artwork in the project is one "rotate your phone" screen. Desktop and iPad layouts become `[P3]`. Closes `PLATFORM-SCOPE-PROPOSAL.md`, which was withdrawn on 13 October 2026 — all three clients ship, and constraint C-04 stands unamended |
| **D-33** | **The laptop is the host.** The engine (one C# library, the single source of rules), the API server and PostgreSQL all run on the laptop. The three phone apps are **thin clients** that hold no rules and show what the server says is legal | The engine is **not** compiled into the phone apps — no FFI, no embedded database. **Resolves O-02.** Removes the "engine in client" wording from §5 |
| **D-34** | **Local network only on task day.** Phone hotspot, no internet | The system must never require a cloud service, an external API, a CDN or a font download **at run time**. Fonts ship with the app. New: `15-lan-demo-runbook.md` |
| **D-35** | **Humans and AI bots play in the same match.** Every demo match is a room: remote human seats plus AI seats | "Game mode" remains a configuration of seat kinds, not a column |
| **D-36** | **Build order: classic RISK first.** Air Force and Naval Force are added only after classic RISK works end to end, and both ship **switched off** | Drives the phase order in `08-implementation-plan.md` and the `[P1]`/`[P2]` split of every requirement |
| **D-37** | **Sea routes are a fixed list per map, not generated per match.** The team wants more routes than classic RISK has; the schema supports any number | **Supersedes D-13 entirely.** Removes the "choose 2–10 routes at match creation" feature, the `seaRoutes.min/max/default` keys from `rules.json`, and screen S-05. The exact list is a later team decision; `sea_routes` ships empty |
| **D-38** | **Sign-up and login are required.** Guest play is removed | **Supersedes D-24.** Removes UC-03, the guest link from sign-in, and the "guest play needs neither route" section of the API contract |
| **D-39** | **Dice sides and attack range stay configurable in the engine but are not shown in the UI** | They are per-match settings frozen at creation (`match_rules`). Because the committee may ask for a change on task day, `16-task-day-change-guide.md` documents exactly how. Removes the dice-face and attack-range steppers from setup and Settings |
| **D-40** | **The database is fully normalised, in PostgreSQL on the laptop.** The map is stored as tables, not as a JSON blob. 13 tables | **Replaces constraint C-03 ("exactly six tables").** The scope rule that survives is *no table without a recorded reason*; chapter 6 §6.4 gives all 13 |
| **D-41** | **Locked decisions may change** where a team decision says so. Every change is recorded; none is silent | This is the decision that lets rank 0 outrank rank 1 in the authority order. It is also why every superseded entry above still carries its original text |
| **D-42** | **Documentation stays beginner-friendly and must not grow larger than it is now.** Prefer rewriting and tagging over adding | Quantified by D-57 |

### G.2 — Proposed: how it is built · D-43…D-49

**Status for every row: Proposed — needs team confirmation.** Each has a reversal cost, because a
proposal you cannot back out of is a decision.

| ID | Proposal | Reason | If the team says no |
|---|---|---|---|
| **D-43** | **Polling instead of SignalR / WebSockets.** Clients call `GET /matches/{id}/state?since={version}` about once a second; the server returns `304` when nothing has changed | Real-time sockets are a known risk in Unity (IL2CPP) and Flutter, and a turn-based game does not need them | Moderate: `appendices/A` gains a hub contract and §5 gains a transport. The SignalR text is kept under "Deferred", not deleted |
| **D-44** | **One mode: Room.** "Pass & Play" and "Player vs AI" stop being separate modes — Player vs AI is a room with one human and bots. The hand-over screen S-17 is removed | No single-device play is needed for the demo, and two fewer modes is two fewer navigation paths to test | Expensive: S-17 returns and `LocalHuman` has to come back as a seat kind (D-55) |
| **D-45** | **The server runs AI turns itself** when it is an AI seat's turn. The pull-style `ai-step` client call is removed | Fewer endpoints; three clients stay simple and identical | Cheap: one endpoint returns |
| **D-46** | **The API is about ten endpoints:** register, login, get map, create room, join room, add AI seat, start match, get state (poll), get legal actions, submit action | Smaller surface for three client teams to implement independently | Cheap: the contract is one file |
| **D-47** | **Deferred — kept in the documents, not built:** procedural map generation, the reinforcement-learning agent, the replay viewer (S-19), the tournament runner, bots beyond Passive and one scorer bot, SignalR, desktop and iPad layouts | Keeps the work and the writing; cuts the workload | Cheap per item: each is tagged `[P3]`, and un-deferring one is a tier change, not a rewrite |
| **D-48** | **The test plan is tiered.** Every test case is tagged `[P1]` (≈25 core tests that must pass for the demo), `[P2]` (extensions) or `[P3]` (deferred), and database tests are added | 119 test cases is too many to run by hand on a demo morning | Cheap: the tags are additive; no case was deleted |
| **D-49** | **Android networking rules go into the safety checklist:** cleartext HTTP must be enabled in all three apps; hotspots can isolate clients from each other; the laptop firewall must allow the server port; the host's IP must be shown on the laptop and typed into each phone | These are the things that break first on demo day, and none of them is a code bug | n/a — a checklist entry costs nothing |

### G.3 — Confirmed: the normalised database · D-50…D-55

**Status for every row: Confirmed — team, Oct 2026.** Source: the team's design pack in `_incoming/`.

> **Numbering note.** That pack proposed these as D-31…D-38, which collides with G.1. They are
> renumbered here as D-50…D-55, and two of its eight entries get **no new ID** because they restate
> decisions this register already holds: *"capability is not stored"* is **D-10**, and *"six tables
> becomes 13"* is **D-40**. The pack's own numbering is superseded by this mapping, so the two
> documents cannot be read as disagreeing.

| ID | Decision | Why |
|---|---|---|
| **D-50** | **The map is stored as normalised tables, not a JSON blob** | It shows up in the ERD, and the database enforces map integrity through foreign keys instead of trusting the loader. Supersedes the `matches.effective_map` design. Its honest cost — "a map used by a match is never edited" becomes a rule rather than a structural impossibility — is written out in chapter 6 §6.3 |
| **D-51** | **A card's symbol is not stored.** It is the territory's `card_symbol`, or `Wild` when the card has no territory | One fact, one place. **Supersedes the storage half of D-03**; the six-value domain is unchanged and now lives in the `card_symbols` lookup table |
| **D-52** | **Rule settings are real typed columns in `match_rules`,** one row per match, copied at creation and never read live afterwards | Editing a default can never change a game in progress. This is the "frozen options" rule of D-29/D-30 expressed as a schema, and it is stronger: a `CHECK` constraint enforces the 2–20 and 1–10 ranges that a `jsonb` blob could not |
| **D-53** | **Sea routes are a separate table from land borders** | The Air Force range search must use land borders only (C-08). Two tables make mixing them up impossible to write; one table with a flag makes it a filter someone can forget |
| **D-54** | **Air Force and Naval Force are off by default** — `air_force_enabled` and `naval_force_enabled` default to `false` | The first version is exactly classic RISK, matching the build order of D-36 |
| **D-55** | **The seat kinds `LocalHuman` and `RemoteHuman` become one kind, `Human`** | With no pass-and-play (D-44) the distinction has nothing to distinguish. **Supersedes the seat-kind half of D-07**; the Neutral-seat rule itself survives |

### G.4 — Proposed: the ten questions answered on 13 October 2026 · D-56…D-66

**Status for every row: Proposed — needs team confirmation.** These were the ten questions raised by
the rework; [`../REWORK-PLAN.md`](../REWORK-PLAN.md) §3 holds the full reasoning for each.

| ID | Question | Decision | Reversal cost |
|---|---|---|---|
| **D-56** | The bot roster — the two team prompts disagreed. One deferred "extra bots beyond Passive and one scorer bot"; the other required a lobby showing Passive, Chaotic, Aggressive and Mars | **Design all four, tier them.** The Figma lobby offers four bot rows. **Passive and Mars are `[P1]`**, Chaotic and Aggressive are `[P2]`, the ONNX/RL agent is `[P3]`. The lobby shows **bot names**, not difficulties — which is why **D-21 is retired** | Cheap. `seats.ai_agent` already permits all four names; promoting one is a tier change |
| **D-57** | How to pay for the four new documents, given D-42 says the documentation must not grow | **A budget: net growth of at most 5 %** of the 913 KB measured on 13 October 2026, so **≤ 959 KB**. Paid for by compressing the RL sections of chapter 2, the deferred phases of chapter 8 and the desktop material in the design pack into summaries under "Deferred" headings. Nothing is deleted | n/a — a budget |
| **D-58** | PostgreSQL is not installed on the machine where this rework was done, so §6.8's load test could not be run | **Write the verification, do not claim it.** `tools/verify_db.sql` prints every count, runs six map validations and attempts the ten impossible inserts inside a transaction it rolls back. Every database claim is labelled **"not verified on this machine"** until a team member runs it, which is step 6 of the LAN runbook | n/a — honesty about evidence |
| **D-59** | The sea-route list is empty and someone has to choose it | **Propose eight, seed none.** `appendices/C` carries a proposed list of 8 routes, each validated against the three rules, for the team to accept or edit. The seed stays empty until they do, and Naval Force is off by default anyway | Cheap. Edit `seaRoutes` in the JSON, re-run the generator |
| **D-60** | Room code length — the old API contract used 6 characters, the new schema and the Figma prompt both use 4 | **4 characters**, uppercase, from a 32-character alphabet that excludes `I`, `O`, `0` and `1` — about a million combinations, which is ample for one hotspot, and four characters is far quicker to read aloud across a room | Cheap: one generator function and the examples in `appendices/A` |
| **D-61** | Login token lifetime on a long demo day | **12 hours, no refresh token, no sessions table.** A token issued at the start of task day cannot expire during it | Cheap: a config value in `appendices/G` |
| **D-62** | Is the Neutral seat always present, or only in 2-player matches? | **2-player matches only**, exactly as D-07 decided — it is what makes the 3-player starting-army row of 35 apply with no special case. A 3–6 player lobby does not draw the Neutral row | n/a — restates D-07 |
| **D-63** | Does the 44-card deck keep its Air Force and Naval Force symbols in the classic-only build? | **Yes, unchanged.** 12 Infantry / 10 Cavalry / 8 Artillery / 7 AirForce / 5 NavalForce + 2 Wild. A symbol is a set-matching token; `air_force_enabled = false` removes the *action*, not the card. Changing the deck for the first version would change every card-family test oracle twice | Expensive: it is a deck change and a test-oracle change |
| **D-64** | Is the `moves` log enforced append-only? | **A convention at `[P1]`,** asserted by TC-DB-11: nothing in the server issues an `UPDATE` or `DELETE`. The `REVOKE UPDATE, DELETE` privilege version is `[P3]` and sits commented into the schema, ready to switch on if a supervisor asks how an append-only log is *guaranteed* | Cheap: uncomment two lines |
| **D-65** | The turn-timer column (**O-05**) | **Retired.** The column is removed from the schema. Nothing in this game expires: the design pack already forbade timed input, and the Figma prompt forbids turn timers outright. A remote-play timer would be a new feature, not a configuration | Moderate: a new column and a new rule |
| **D-66** | The polling interval and the stale-version rules that D-43 left unquantified | **1,000 ms** default, configurable. The server answers **`304 Not Modified`** when `since` equals the current version, and **`409 Conflict`** with the current state when a submitted action carries a stale version (the existing rule, kept). A client that has fallen far behind re-reads full state rather than replaying a gap | Cheap: config values in `appendices/G` |

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
| D-29 | `shared/rules.json` → `combat.diceSides`, §7.5, FR-84, **`match_rules.dice_sides`** (§6.7, storage moved by D-52), `appendices/E-pseudocode.md` §E.3.3/§E.6, TC-CMB-10, TC-PER-07, `design/04-dice-ui-ux.md` |
| D-30 | `shared/rules.json` → `combat.attackRange`, §7.5, §7.8, FR-85, **`match_rules.attack_range`** (§6.7, storage moved by D-52), `appendices/E-pseudocode.md` §E.4.3/§E.10, TC-CMB-09, TC-AIR-02, TC-PER-07, `design/03-map-ui-ux.md` |
| O-01…O-06 | §11 future work, `docs/09-testing.md` risk notes |
| Part E | `docs/14-implementation-safety-checklist.md` |
| **D-31, D-42, D-57** | `docs/PROTOTYPE-EDITION.md`, `README.md`, every chapter's scope framing |
| **D-32** | `design/*` (frames 915×412 / 800×360), `design/11-figma-prompt-mobile-landscape.md`, `design/10-figma-prompt-desktop.md` (marked out of scope), `PLATFORM-SCOPE-PROPOSAL.md` |
| **D-33, D-34, D-49** | §5.1–5.3 architecture and deployment, `docs/15-lan-demo-runbook.md`, `docs/14` networking traps, FR additions for typed-IP host discovery |
| **D-35, D-44, D-45** | §4 use cases, §5.1 modes, `design/02-screen-inventory-and-flows.md`, `appendices/A` |
| **D-36, D-47** | `docs/08-implementation-plan.md` phase order, every `[P2]`/`[P3]` tag |
| **D-37, D-53, D-59** | §7.10 sea routes, `appendices/C-map-specification.md`, `shared/maps/world_classic.json` → `seaRoutes`, `sea_routes` table, `tools/generate_map_seed.py` |
| **D-38** | §4 actors, FR login requirements, `appendices/A` auth routes, `users` table |
| **D-39, D-52** | `match_rules` columns, `docs/16-task-day-change-guide.md`, `appendices/G`, TC-PER-07 |
| **D-40, D-50, D-51, D-55** | `docs/06-database-design.md`, `appendices/B-database-schema.sql`, `appendices/B2`, `appendices/B3`, `docs/images/erd_*.png` |
| **D-41** | The authority order at the top of this file; every 🔶 banner in it |
| **D-43, D-46, D-66** | `appendices/A-api-contract.md`, §5 polling flow, `appendices/G` poll interval |
| **D-48** | `appendices/F-test-cases.md` tiers, `docs/09-testing.md`, `docs/13-traceability-matrix.md` |
| **D-54, D-63** | `match_rules` extension defaults, `match_cards`, §7 extension framing |
| **D-56** | `seats.ai_agent`, `design` lobby screens, `shared/rules.json` → `ai.bots` |
| **D-58** | `tools/verify_db.sql`, chapter 6 §6.9, `docs/15` step 6, §10 results |
| **D-60** | `matches.room_code`, `appendices/A` join route, `design` S-04b |
| **D-61** | `users` (no sessions table), `appendices/G` token lifetime, `docs/14` token-expiry trap |
| **D-62** | §7.1 starting armies, `seats`, FR-14 |
| **D-64** | `moves` table, TC-DB-11, `appendices/B` commented privilege block |
| **D-65** | `matches` (no timer column), `design/07` "nothing expires" |
