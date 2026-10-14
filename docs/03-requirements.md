# 3 — Requirement Analysis

> **Deliverable C.** Every requirement below is numbered, testable, tier-tagged and traced in
> [13 — Traceability Matrix](13-traceability-matrix.md).

> **In plain words.** This chapter is the checklist of everything the system must do. Each line has an
> ID so a test can point at it, a priority, and a **tier** saying whether it is needed for the demo
> (`[P1]`), for the two extensions (`[P2]`), or is written down but not being built (`[P3]`).

**Tiers.** `[P1]` demo-critical — classic RISK across three Android clients on the local network, with
accounts, rooms, humans + AI and database persistence · `[P2]` the Air Force and Naval Force
extensions · `[P3]` deferred (D-47): procedural maps, reinforcement learning, replay viewer,
tournament runner, extra bots, SignalR, desktop/iPad.

**Priority.** **M** mandatory · **S** should have · **OPT** optional.

> **Retired requirements keep their numbers.** Five requirements were retired by the October 2026
> decisions and are listed in §3.2.13 with the decision that retired each one. **No ID is ever
> reused**, because every reference in §13, §9 and `appendices/E-pseudocode.md` points at a number.

## 3.1 Requirement Elicitation

There is no external client for this project, so requirements were derived rather than gathered. Five
sources, in the authority order fixed by `00-decisions-and-assumptions.md`:

| Source | What it supplied | How it was processed |
|---|---|---|---|
| **Team decisions, October 2026** (D-31…D-66) | Prototype scope, the laptop host, Android-landscape clients, local-network-only operation, required login, build order, the fixed sea-route list, the normalised 13-table database | **Authoritative, and may override the master specification** (D-41). Each one became, modified or retired a requirement; every change is recorded |
| **Master specification** (locked decisions) | Air Force, Naval Force, capability profiles, sea routes, the six card types, three clients, one engine, ~~six database tables~~ | Authoritative where no team decision supersedes it. Locked items became mandatory requirements directly |
| **Project design documents** | Architecture, seat model, map format, database schema, AI and RL design | Used where the specification is silent. Conflicts recorded as D-01…D-07, never blended |
| **Published RISK rules** | Board, setup, combat, cards, victory | Became the domain requirements in §3.4. Numeric values extracted to `shared/rules.json` |
| **2022 report** | Requirement structure, use-case template, three AI personalities, screen inventory | Historical reference. Its structure was adopted; its defects were corrected and recorded (§2.4) |

Four elicitation decisions are worth recording because they shaped the list:

1. **Locked decisions were transcribed, not interpreted.** "Air Force range 5, land adjacency only, sea
   routes excluded" became FR-35 and FR-36 as two separate requirements, because they are two separately
   testable claims.
2. **Where the specification stated a mechanic but not a quantity**, the quantity became an assumption
   with an ID (AIR-1, NAV-1, SEA-1) rather than a requirement. Requirements state *what must be true*;
   the tunable number lives in configuration.
3. **Features present only in the older documents were re-examined against the specification's scope
   list rather than inherited.** This is what reclassified submersion masks as optional (D-05).
4. **The demo environment became a source of requirements** (October 2026). Task day runs on a phone
   hotspot with no internet (D-34), and that is not a deployment detail — it generates FR-86…FR-90,
   every one of which is `[P1]`. A system that satisfies every other requirement and cannot be reached
   from a phone demonstrates nothing.

## 3.2 Functional Requirements

### 3.2.1 Accounts and sessions

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-01 | The system shall register an account with a unique username, storing the password only as an Argon2id hash in PHC string format. | M | `[P1]` |
| FR-02 | The system shall authenticate a registered user and issue a bearer token valid for the configured lifetime (default 12 hours). | M | `[P1]` |
| FR-03 | ~~The system shall permit play without an account (guest)~~ | — | **RETIRED** |
| FR-04 | The system shall list a player's resumable matches. | S | `[P1]` |

### 3.2.2 Maps

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-05 | The system shall list available maps. | M | `[P1]` |
| FR-06 | The system shall return a complete map definition by key, including render data, read from the database. | M | `[P1]` |
| FR-07 | The system shall generate a map from a seed and parameters, such that the same seed and parameters always produce an identical map. | OPT | `[P3]` |
| FR-08 | The system shall validate every map against one shared gate before use, and reject an invalid map with a specific machine-readable reason. | M | `[P1]` |
| FR-09 | The system shall provide the classic world map: exactly 42 territories, 6 continents, 83 land-adjacency edges, continent sizes 9/4/7/6/12/4 and bonuses 5/2/5/3/7/2. | M | `[P1]` |
| FR-10 | The system shall reference the chosen map from the match and shall treat a map used by any match as immutable: a changed board is a **new map row**, never an edit to an existing one, so that map changes cannot alter a match in progress. | M | `[P1]` |
| FR-11 | The system shall derive each territory's capability profile by rule CAP-1 and reject a map whose authored profile disagrees with the derivation. | M | `[P1]` |

> **FR-10 changed mechanism, not guarantee** (D-50). It previously froze a normalised copy of the map
> into `matches.effective_map`. The guarantee — *a map edit cannot alter a running match* — is
> unchanged; it is now delivered by an immutability rule plus a foreign key rather than by a private
> copy. Chapter 6 §6.3 states the honest cost of that swap.

### 3.2.3 Match setup

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-12 | The system shall create a match with 2 to 6 seats. | M | `[P1]` |
| FR-13 | The system shall accept, per seat, a kind of `Human`, `Ai` or `Neutral`, and a bot name for every `Ai` seat. | M | `[P1]` |
| FR-14 | The system shall create a 2-player match as three seats, the third being `Neutral`, and shall not create a `Neutral` seat in a 3-to-6-player match. | M | `[P1]` |
| FR-15 | ~~The system shall accept a sea-route **count** chosen by the creating seat~~ | — | **RETIRED** |
| FR-16 | ~~The system shall generate exactly that many valid sea routes and freeze them into the effective map~~ | — | **RETIRED** |
| FR-17 | The system shall allocate initial territories either by seat-by-seat claiming or by seeded random assignment, as selected. | M | `[P1]` |
| FR-18 | The system shall issue starting armies per the configured table (3 seats → 35, 4 → 30, 5 → 25, 6 → 20). | M | `[P1]` |
| FR-19 | The system shall build the deck from the map: one card per territory plus the configured number of wilds, retaining every card symbol regardless of whether the corresponding extension is enabled. | M | `[P1]` |

> **Two requirements for this group are numbered FR-86 and FR-87**, at the end of the set — the fixed
> sea-route list and the frozen rule settings. They are new, and new requirements take the next free
> numbers rather than being inserted here, because FR-20 and FR-21 already mean something else
> (§3.2.4) and renumbering a baselined set would silently invalidate every reference in §13, §9 and
> `appendices/E-pseudocode.md`.

### Turn and phase control

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-20 | The system shall maintain the current phase and current seat, and accept actions only from the current seat. | M | `[P1]` |
| FR-21 | The system shall compute the complete set of legal actions for the current seat and expose it. | M | `[P1]` |
| FR-22 | The system shall reject an illegal action with no change to state and no consumption of randomness. | M | `[P1]` |
| FR-23 | The system shall compute reinforcements as `max(3, ⌊territories held / 3⌋) + continent bonuses + card trade value`. | M | `[P1]` |
| FR-24 | The system shall award a continent bonus only when a seat holds every territory of that continent. | M | `[P1]` |
| FR-25 | The system shall advance phase and turn, skipping `Neutral` seats and eliminated seats. | M | `[P1]` |

### Combat

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-26 | The system shall permit a land attack only between territories within the configured attack range of one another over land edges — **default range 1, which is land-adjacency** — from a territory the attacker owns holding at least 2 armies and at least one more army than dice rolled. | M | `[P1]` |
| FR-27 | The system shall roll 1–3 attacker dice and 1–2 defender dice, compare in descending order, and resolve ties **in the defender's favour**. | M | `[P1]` |
| FR-28 | On capture, the system shall require the attacker to move in at least as many armies as dice rolled, leaving at least 1 behind. | M | `[P1]` |
| FR-29 | The system shall generate every die from the match's injected seeded random source and return every roll as an event. | M | `[P1]` |
| FR-30 | The system shall record that the seat captured at least one territory this turn, for card eligibility. | M | `[P1]` |
| FR-31 | The system shall resolve land, Air Force and Naval Force attacks through **one** combat implementation. | M | `[P1]` |

### Configurable combat parameters

Two requirements added after the requirement set was first baselined, in response to supervisory review
(D-29, D-30). They keep the next free identifiers rather than being inserted in sequence, because
renumbering a baselined set would silently invalidate every reference in §13.2, §9 and
`appendices/E-pseudocode.md`.

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-84 | The system shall take the number of die faces from configuration rather than from a constant, defaulting to **6**, and shall draw every die uniformly from `1…diceSides` using the match random source. The comparison rule of FR-27, including the defender's advantage on ties, shall hold unchanged at every face count. | M | `[P1]` |
| FR-85 | The system shall take the maximum land-attack distance from configuration rather than from a constant, defaulting to **1**, and shall compute reachable targets by breadth-first search to that depth over **land edges only** — never over sea routes — regardless of who owns the intervening territories. | M | `[P1]` |

Both values shall be **frozen into the match** at creation and read from the match thereafter, so that
editing configuration cannot alter a match already in progress (the FR-10 guarantee, extended to these two
keys). A change to either shall be rejected for an in-flight match rather than applied.

### Cards

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-32 | The system shall award at most one card per turn, and only if the seat captured at least one territory that turn. | M | `[P1]` |
| FR-33 | The system shall recognise a valid set as exactly three cards: three of one symbol, three different symbols, or two of one symbol plus a Wild. | M | `[P1]` |
| FR-34 | The system shall award the trade value for the next position in the configured escalation table, advancing that position once per trade for the whole match. | M | `[P1]` |
| FR-35 | The system shall require a seat holding 5 or more cards to trade a set before placing reinforcements. | M | `[P1]` |
| FR-36 | The system shall require a seat holding 6 or more cards after eliminating an opponent to trade down to fewer than 5 immediately. | M | `[P1]` |
| FR-37 | The system shall grant 2 additional armies placed directly on a territory named by a traded card that the seat owns, capped at 2 additional armies per turn. | M | `[P1]` |
| FR-38 | The system shall transfer an eliminated seat's cards to the eliminating seat. | M | `[P1]` |

### Capability system

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-39 | The system shall treat a seat as holding capability X if and only if it owns at least one territory whose profile contains X, or holds at least one card whose profile contains X. | M | `[P1]` |
| FR-40 | The system shall treat Infantry, Cavalry and Artillery as card symbols only, granting no action. | M | `[P1]` |
| FR-41 | The system shall derive capability from current state on demand and shall not store it. | M | `[P1]` |

### Air Force

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-42 | The system shall offer an Air Force attack from a territory the seat owns to a territory it does not own, when the seat holds Air Force capability and the target lies within the configured maximum range. | M | `[P2]` |
| FR-43 | The system shall measure Air Force range as shortest-path distance over **land adjacency edges only**, excluding sea routes entirely. | M | `[P2]` |
| FR-44 | The system shall resolve an Air Force attack by the same dice combat and occupation rules as a land attack. | M | `[P2]` |
| FR-45 | The system shall limit Air Force attacks to the configured number per seat per turn. | M | `[P2]` |
| FR-46 | The system shall apply the same minimum-army and dice constraints to an Air Force attack as to a land attack. | M | `[P2]` |

### Naval Force

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-47 | The system shall represent a sea route as an edge between two coastal territories, distinct from land adjacency, and shall never represent a sea route as a territory. | M | `[P2]` |
| FR-48 | The system shall offer a Naval attack across a sea route when the seat holds Naval capability, owns the origin, and does not own the target. | M | `[P2]` |
| FR-49 | The system shall offer a Naval fortification across a sea route between two territories the seat owns, counting against the same one fortification per turn as a land fortification. | M | `[P2]` |
| FR-50 | The system shall resolve a Naval attack by the same dice combat and occupation rules as a land attack. | M | `[P2]` |
| FR-51 | The system shall never grant Naval capability to a landlocked territory automatically. | M | `[P2]` |

### Fortification, elimination and victory

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-52 | The system shall permit one fortification per turn, moving armies between two territories the seat owns and leaving at least 1 behind, according to the configured fortify mode. | M | `[P1]` |
| FR-53 | The system shall eliminate a seat when it loses its last territory, and record which seat eliminated it. | M | `[P1]` |
| FR-54 | The system shall declare victory when one seat owns every territory in the effective map. | M | `[P1]` |
| FR-55 | The system shall end a match that reaches the configured round cap and rank seats by territory count. | M | `[P1]` |

### Persistence

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-56 | The system shall persist the match snapshot — match, seats, territory state, cards — within one transaction per applied action. | M | `[P1]` |
| FR-57 | The system shall append every applied action to a log recording the action, resulting events, resulting version and resulting random-source position, and shall never update or delete a log row. | M | `[P1]` |
| FR-58 | The system shall resume a match from its snapshot without replaying the log, restoring the random source from its stored seed and position. | M | `[P1]` |
| FR-59 | The system shall return the complete action log of a match for replay. | S | `[P3]` |

### API and synchronisation

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-60 | The system shall expose the REST contract in `appendices/A-api-contract.md`. | M | `[P1]` |
| FR-61 | The system shall accept an expected version with every action and reject a mismatch with `409 Conflict` and the current state, applying nothing. | M | `[P1]` |
| FR-62 | The system shall redact state per seat so that a response for one seat never contains another seat's card identities. | M | `[P1]` |
| FR-63 | ~~The system shall push `StateChanged`, `DiceRolled`, `TurnChanged`, `SeatEliminated`, `GameOver` and `HandOverDevice` over a real-time connection.~~ | — | **RETIRED** |
| FR-64 | ~~The system shall require a blocking hand-over step before revealing state to the next local seat in a pass-and-play match.~~ | — | **RETIRED** |

### Clients

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-65 | Each client shall render the board, army counts, ownership, continents, sea routes and current phase from server-supplied state only. | M | `[P1]` |
| FR-66 | Each client shall make interactive only those territories and actions named in the server's legal-action response. | M | `[P1]` |
| FR-67 | No client shall implement combat, reinforcement, card, capability, range or victory logic. | M | `[P1]` |
| FR-68 | Each client shall provide the screens listed in §5.3, including sea-route configuration, Air Force targeting and Naval Force action screens. | M | `[P1]` |
| FR-69 | Each client shall animate dice from the `DiceRolled` event rather than computing an outcome. | S | `[P1]` |
| FR-70 | Clients shall offer preset messages and emoji, not free text. | OPT | `[P3]` |

### Artificial intelligence

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-71 | The system shall expose every agent behind one interface taking state and the engine's legal-action list and returning one action. | M | `[P1]` |
| FR-72 | The system shall provide PassiveBot and MarsBot. | M | `[P1]` |
| FR-73 | The system shall play the current `Ai` seat **itself**, without a client request, and record each resulting event in the action log. | M | `[P1]` |
| FR-74 | No agent shall be able to emit an illegal action, because every agent selects from the engine's legal list. | M | `[P1]` |
| FR-75 | The system shall apply a configurable minimum think time per AI action at the API layer, not inside the agent. | S | `[P1]` |
| FR-76 | MarsBot shall evaluate candidate attacks by expected value and shall not consume the match random source while evaluating. | M | `[P1]` |
| FR-77 | ~~The system shall map difficulty settings onto agents and their configured parameters.~~ | — | **RETIRED** |
| FR-78 | The system shall load a trained policy for inference and fall back to MarsBot when no policy is available. | OPT | `[P3]` |

### Simulation and learning

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-79 | The system shall run headless matches with no user interface and no database. | S | `[P3]` |
| FR-80 | The system shall write self-play trajectories, including state graphs, actions, legal-action masks and rewards. | OPT | `[P3]` |
| FR-81 | The system shall train a policy by PPO and export it in an interchange format loadable by the C# inference path. | OPT | `[P3]` |
| FR-82 | The system shall run a seeded tournament across agents and map kinds and report a win-rate matrix. | S | `[P3]` |
| FR-83 | A trained policy shall record the fortify mode it was trained under, and loading shall fail if it differs from the active configuration. | OPT | `[P3]` |

### 3.2.12 Local network, the demo environment and frozen settings

New in October 2026. Every one of these is `[P1]`, and together they are the difference between a
system that works and a system that can be demonstrated on task day (D-34, D-49).

| ID | Requirement | Pri | Tier |
|---|---|---|---|
| FR-86 | The system shall load the map's **fixed** sea-route list from the database, and shall reject a route whose endpoints are not both coastal, which duplicates a land border, or which duplicates another route. | M | `[P2]` |
| FR-87 | The system shall copy every rule setting into the match at creation and read those settings **from the match** thereafter, never from a configuration file, and shall reject an attempt to change a setting on a match that has started. | M | `[P1]` |
| FR-88 | Each client shall accept a **host address typed by the player** (IPv4 address and port), shall attempt a connection on demand, and shall report an unreachable host with a message naming the likely cause rather than a stack trace. | M | `[P1]` |
| FR-89 | Each client shall poll `GET /matches/{id}/state?since={version}` at the configured interval (default 1,000 ms); the server shall return `304 Not Modified` when the client's version is current. | M | `[P1]` |
| FR-90 | Each client shall be configured to permit cleartext HTTP to the host, because the demo network has no certificate authority. | M | `[P1]` |
| FR-91 | The system shall complete a full match with **no internet connection available**, requiring no cloud service, external API, content-delivery network or runtime font download. | M | `[P1]` |
| FR-92 | The system shall issue a room code of the configured length (default 4) from an alphabet that excludes visually ambiguous characters, and shall guarantee uniqueness among matches that are in the lobby or in progress. | M | `[P1]` |
| FR-93 | Each client shall detect a lost connection, show a non-blocking indication while retrying, and resume from the current server version on reconnection without losing or replaying an action. | M | `[P1]` |
| FR-94 | The laptop shall display its own reachable IPv4 address and port, so that it can be read aloud and typed into each phone. | M | `[P1]` |
| FR-95 | The project shall document, for each frozen per-match setting, the exact column, the allowed range and a verification step, so that a setting can be changed on request during task day. | M | `[P1]` |

> **FR-95 is a documentation requirement, and it is deliberate.** D-39 keeps the dice-face count and
> the attack range out of the user interface, which means the only way to honour *"make the dice
> 8-sided"* on task day is a written procedure that works under pressure. That procedure is
> [`16-task-day-change-guide.md`](16-task-day-change-guide.md), and FR-95 is what makes it a
> deliverable rather than a courtesy.

### 3.2.13 Retired requirements

**No identifier is ever reused.** Each row below states what retired it and where the need went.

| ID | Was | Retired by | Where the need went |
|---|---|---|---|
| FR-03 | Play without an account (guest) | **D-38** | Nowhere — sign-up and login are required. The reason the exemption existed, "single-player must not require registration", no longer applies: there is no single-player mode, only a room (D-44) |
| FR-15 | The creating seat chooses a sea-route count | **D-37** | FR-86. The list is fixed per map and authored by the team |
| FR-16 | The system generates that many routes and freezes them | **D-37** | FR-86 and `tools/generate_map_seed.py`, which enforces the same three validity rules |
| FR-63 | Push six event types over a real-time connection | **D-43** | FR-89. Clients poll; the server answers `304` when nothing changed. The event names survive as the shapes inside `moves.events` |
| FR-64 | A blocking hand-over step between local seats | **D-44** | Nothing to replace. With no single-device play there is no device to hand over. Per-seat redaction (FR-62) still does the work the hand-over screen was protecting |
| FR-77 | Map difficulty settings onto agents | **D-56** | Nowhere — difficulty is no longer user-facing. The host picks a bot by name, and the `W_p` tuning dial survives in `shared/rules.json` |

### 3.2.14 Totals

| | Count |
|---|---|
| Identifiers allocated | **FR-01…FR-95** |
| Retired | **6** (FR-03, 15, 16, 63, 64, 77) |
| Live requirements | **89** |
| Mandatory | 74 · **should-have** 4 · **optional** 11 |
| `[P1]` demo-critical | **66** |
| `[P2]` extensions | **15** |
| `[P3]` deferred | **8** |

Every `[P3]` and every OPT requirement is optional in the strict sense of NFR-24: the system is
complete and demonstrable with all of them absent. That is checked by deleting those rows from the
traceability matrix and confirming no `[P1]` requirement loses a dependency (§13).

FR-84 and FR-85 were added after the set was baselined and are listed with the Combat group rather than
at the end, for the same reason FR-86…FR-95 are *not* inserted into their topical groups: renumbering a
baselined set silently invalidates every reference in §13, §9 and `appendices/E-pseudocode.md`. Both
default to the value that reproduces classic RISK, so the count of requirements that change observable
behaviour at default configuration is **zero**.

## 3.3 Non-Functional Requirements

| ID | Category | Requirement | How verified |
|---|---|---|---|
| NFR-01 | Architecture | The engine assembly shall reference no web framework, no ORM, no database driver and no file-system API. | Automated dependency assertion (TC-ARC-01) |
| NFR-02 | Determinism | Identical map, options, seed and action sequence shall produce identical state and identical events. | TC-DET-01…04 |
| NFR-03 | Purity | Applying an action shall not mutate the input state. | TC-ARC-02 |
| NFR-04 | Performance | Legal-action computation on the classic map shall complete within 100 ms at the 95th percentile on the reference development machine. | Benchmark, §9.6 |
| NFR-05 | Performance | Action submission round trip on localhost shall complete within 250 ms at the 95th percentile. | Benchmark, §9.6 |
| NFR-06 | Performance | A heuristic agent shall choose an action within 500 ms. | Benchmark, §9.6 |
| NFR-07 | Performance | Trained-policy inference shall complete within 50 ms per action on CPU. | Benchmark, §9.6 **OPT** |
| NFR-08 | Performance | Returning the action log of a 100-round match shall complete within 2 s. | Benchmark, §9.6 |
| NFR-09 | Security | Passwords shall be stored only as Argon2id PHC strings; no plaintext and no reversible encryption anywhere. | Schema inspection + TC-SEC-01 |
| NFR-10 | Security | Every action shall be authorised server-side against seat ownership; a client claim of seat identity shall not be trusted. | TC-SEC-02 |
| NFR-11 | Security | A state response for a seat shall contain no other seat's card identities. | TC-SEC-03 |
| NFR-12 | Integrity | The action log shall be append-only, enforced by database privileges and not only by application code. | TC-PER-04 |
| NFR-13 | Reliability | A crash mid-action shall leave no partially applied action. | TC-PER-05 |
| NFR-14 | Reliability | A resumed match shall produce a legal-action set identical to the one before saving. | TC-PER-01 |
| NFR-15 | Testability | Every functional requirement shall map to at least one test case, and every rules module in `Engine/Rules/` shall be named by at least one test family. | Traceability matrix, §13 |
| NFR-16 | Maintainability | All tunable numbers shall live in configuration data, not in code; changing one shall not require a rebuild. | Source review (TC-ARC-03) |
| NFR-17 | Maintainability | No client shall contain rule logic. | Source-level check (TC-ARC-04) |
| NFR-18 | Maintainability | Client data-transfer types shall be generated from one published contract. | Build step |
| NFR-19 | Portability | The schema shall avoid database-vendor-specific column types, using text with constraints in place of enumerations and arrays. | Schema review |
| NFR-20 | Correctness | Every agent's invalid-action rate shall be exactly zero. | TC-AI-01 |
| NFR-21 | Usability | A client shall permit only actions the server reports as legal; an illegal action shall not be reachable through the interface. | TC-UI-01 |
| NFR-22 | Usability | Pass-and-play shall not reveal a seat's cards to a previous seat at any point. | TC-UI-02 |
| NFR-23 | Deployability | The system shall run as one API process and one database instance, requiring no container orchestration and no cloud service. | Deployment §5.1 |
| NFR-24 | Scope | Optional requirements shall remain optional: the mandatory set shall be fully deliverable with every OPT requirement removed. | Dependency review, §13 |

**NFR-24 is a real requirement, not a formality.** It is checked by deleting every OPT row from the
traceability matrix and confirming no mandatory requirement loses a dependency. That check is what keeps
"optional" honest.

### Explicit non-targets

No requirement is stated for concurrent match throughput, horizontal scaling, sub-100 ms network latency,
or availability. The system is specified for one machine and one instance (NFR-23). Inventing scaling
targets would produce numbers nobody measures.

**Submersion masks generate no requirement, functional or non-functional.** The design is documented
(§5.7, `appendices/C-map-specification.md`) and the nullable `matches.mask` column is retained, but
decision D-05 classifies the feature as optional/time-permitting. It therefore appears in no FR, no
implementation phase and no v1 test case. The graph-based state encoder is justified independently, by
procedural map generation alone (§2.6).

## 3.4 Domain Requirements

Rules of the game itself. These are constraints the software must satisfy because the domain says so, not
because a stakeholder asked.

| ID | Domain rule |
|---|---|
| DR-01 | The board is a connected graph. If world domination is unreachable, the map is invalid. |
| DR-02 | Adjacency is symmetric. A one-directional edge is a load error, not a warning. |
| DR-03 | Continents partition the territories exactly — every territory in exactly one continent. |
| DR-04 | A territory always has at least 1 army, and always exactly one owner. |
| DR-05 | Total armies on the board equal armies placed minus armies lost. Armies are never created by movement. |
| DR-06 | The attacker must leave at least 1 army behind; a territory cannot be vacated. |
| DR-07 | The defender wins ties. |
| DR-08 | Reinforcements are never fewer than 3. |
| DR-09 | A continent bonus requires every territory of that continent. |
| DR-10 | The deck has exactly one card per territory, plus wilds. |
| DR-11 | At most one card is awarded per turn, and only after a capture. |
| DR-12 | A trade set is exactly three cards. |
| DR-13 | Trade values escalate monotonically across the whole match and never reset. |
| DR-14 | A seat with no territories is eliminated and never acts again. |
| DR-15 | `Neutral` seats defend but never attack, fortify or trade. |
| DR-16 | Sea routes connect two coastal territories and are never territories themselves. |
| DR-17 | A landlocked territory is never naval-capable by default. |
| DR-18 | Air Force range is measured on land adjacency only. |
| DR-19 | One combat resolution exists. Air and naval attacks are ordinary attacks with a different adjacency test. |
| DR-20 | A match ends only by domination or by the round cap. |

## 3.5 Constraints

| ID | Constraint | Origin |
|---|---|---|---|
| C-01 | Exactly one rules engine exists. Three clients, one rule set. | Locked |
| C-02 | The engine performs no I/O and is deterministic given an injected seeded random source. | Locked |
| C-03 | Six database tables: users, matches, seats, territory state, cards, moves. No more. | Locked |
| C-04 | Three clients must all ship: Unity, Godot, Flutter + Flame. None may be dropped. | Locked |
| C-05 | Card trade sets remain three cards despite six card types. | Locked |
| C-06 | Dice combat is not replaced. | Locked |
| C-07 | Sea-route endpoints are chosen by the system; the seat chooses only the count. | Locked |
| C-08 | Air Force range excludes sea routes. | Locked |
| C-09 | Reinforcement learning is not required for playability. | Locked |
| C-10 | No cloud infrastructure is required. | Locked |
| C-11 | Project and namespace names use the `OrderAndConquest.*` prefix. | Locked (D-01) |
| C-12 | Server: C# / .NET, ASP.NET Core, PostgreSQL. | Design |
| C-13 | RL training in Python; the trained model crosses into C# as an interchange file only. | Design |
| C-14 | Single team, fixed deadline. Scope is the binding constraint, and it is managed by the decision register. | Project |

## 3.6 Assumptions

Assumptions with an ID are recorded in full, with reasoning, in
[`00-decisions-and-assumptions.md`](00-decisions-and-assumptions.md). Summarised here for completeness:

| ID | Assumption |
|---|---|
| CAP-1 | A capability profile is `{Infantry} ∪ ({NavalForce} if coastal) ∪ {cardSymbol}`, authored explicitly and validated against the derivation. |
| CAP-2 | A seat holds capability X iff it owns a territory or holds a card whose profile contains X. |
| AIR-1 | One Air Force attack per seat per turn — the smallest limiter that stops Air Force strictly dominating land attack. |
| NAV-1 | A sea route costs no units. It behaves as a land edge for a seat holding Naval capability. |
| SEA-1 | Sea-route count: minimum 2, maximum 10, default 4. |
| D-06 | Starting armies follow the sourced table; the 2022 report's conflicting figures (38 / 30) are not used. |
| D-07 | A 2-player match is three seats with one `Neutral`, so the 3-player army count applies. |
| D-14 | Coastal status and card-symbol distribution on the classic board are game-design decisions open to team revision. |
| D-15 | Trade values 10, 12 and 15 are inferred, not sourced, and remain data for that reason. |
| D-16 | Fortify mode defaults to a single pair; the alternatives are configuration. |
| D-17 | Air Force range spans distance 1 to 5 inclusive. |
| D-19 | A naval fortification consumes the seat's single fortification for the turn. |
| D-20 | A Wild card carries no capability, having no territory. |

### Environmental assumptions

- The development and demonstration machine can run the API and PostgreSQL simultaneously.
- Each client runs on a device with a network path to the server; localhost is sufficient for v1.
- No internet connection is required for any mandatory requirement.

### The assumption that matters most

**That the specified scope is the whole scope.** This package treats the locked decision set as complete
and adds nothing to it. Where the specification is silent, the answer is the simplest thing that works or
an explicit deferral — never a new subsystem. Every entry above exists so that an assumption can be
challenged and changed as data, rather than discovered later as code.

---

**Previous:** [2 — Literature Review](02-literature-review.md) · **Next:** [4 — System Analysis and Modelling](04-system-analysis.md)
