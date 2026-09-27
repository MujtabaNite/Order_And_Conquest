# 13 — Traceability Matrix

> **Deliverable T.** Every functional requirement traced forward to the use case that motivates it, the
> design section that specifies it, the implementation module that will contain it, and the test case that
> verifies it.
>
> This is the document that makes NFR-15 checkable and satisfies the master prompt's §37 rule that *every
> major functional requirement should map to at least one test*. It is also the document that will break
> first when something is renamed, which is the point of keeping it in one file.

## 13.1 How to read this matrix

| Column | What it names |
|---|---|
| **FR** | The requirement, from §3.2 |
| **UC** | The use case from §4.2 that motivates it. `—` means the requirement is internal and has no actor-facing use case; see §13.7 |
| **Design** | The section of this package that specifies the behaviour |
| **Module** | The implementation location, from the repository structure of §8.1 |
| **Test** | The verifying case(s) from the catalogue of §9 and `appendices/F-test-cases.md` |

**Module paths are relative to the project that owns them.** `Engine/Rules/CombatRules` means
`server/OrderAndConquest.Engine/Rules/CombatRules`; `Api/Services/MatchService` means
`server/OrderAndConquest.Api/Services/MatchService`. Client rows name the client directory, because a
per-client file layout is the one thing three different toolchains will not share.

**No name in the Module column is invented.** Every one appears in the folder and file tables of §8.2,
§8.3, §8.7 and §8.8. Where a requirement is satisfied by data rather than code, the data file is named —
`shared/rules.json` and `shared/maps/world_classic.json` are implementation locations in this project, by
the deliberate decision of NFR-16.

## 13.2 Functional requirements

### Accounts and sessions

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-01 | UC-01 | §5.9 | `Api/Controllers/AuthController`, `Data/Repositories/UserRepository` | TC-SEC-01 |
| FR-02 | UC-02 | §5.9 | `Api/Controllers/AuthController`, `Api/Auth/` | TC-SEC-04 |
| FR-03 | UC-03 | §5.1, §5.9 | `Api/Auth/` | TC-SEC-04 |
| FR-04 *(S)* | UC-17 | §5.5 | `Api/Controllers/PlayersController`, `Data/Repositories/MatchRepository` | TC-PER-06 |

### Maps

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-05 | UC-04 | §5.7 | `Api/Controllers/MapsController`, `Data/Repositories/MapRepository` | TC-API-01 |
| FR-06 | UC-04 | §5.7 | `Api/Controllers/MapsController`, `Api/Services/MapService` | TC-API-01 |
| FR-07 *(S)* | UC-21 | §5.7, §8.10 | `Engine/Generation/MapGenerator` | TC-MAP-06, TC-MAP-07 |
| FR-08 | UC-21 | §5.7 | `Engine/Validation/MapValidator` | TC-MAP-01…05, TC-MAP-10 |
| FR-09 | UC-04 | §7.11 | `shared/maps/world_classic.json`, `Engine/Validation/MapValidator` | TC-MAP-01 |
| FR-10 | UC-04 | §6.1, §5.7 | `Api/Services/MatchService`, `Data/Repositories/MatchRepository` | TC-PER-03, TC-SEA-05 |
| FR-11 | UC-21 | §7.7 | `Engine/Rules/CapabilityRules`, `Engine/Validation/MapValidator` (V-10) | TC-CAP-01, TC-MAP-04 |

### Match setup

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-12 | UC-04 | §5.1, §7.2 | `Api/Controllers/MatchesController`, `Engine/Rules/SetupRules` | TC-SYS-02 |
| FR-13 | UC-04, UC-06 | §5.1 | `Engine/State/SeatState`, `Engine/Rules/SetupRules` | TC-SYS-02 |
| FR-14 | UC-04 | §7.2 (D-07) | `Engine/Rules/SetupRules` | TC-SYS-02 |
| FR-15 | UC-05 | §7.10 | `Api/Controllers/MatchesController`, `shared/rules.json` | TC-SEA-01 |
| FR-16 | UC-05 | §7.10 | `Engine/Generation/SeaRouteGenerator` | TC-SEA-02, 03, 04, 05, 06 |
| FR-17 | UC-04, UC-07 | §7.2 | `Engine/Rules/SetupRules` | TC-DRF-06, TC-DET-02 |
| FR-18 | UC-04 | §7.4 | `Engine/Rules/SetupRules`, `shared/rules.json` | TC-DRF-06 |
| FR-19 | UC-04 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-01 |

### Turn structure

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-20 | UC-15 | §5.4, §7.2 | `Engine/GameEngine.cs`, `Api/Auth/` seat filter | TC-API-04, TC-SEC-02 |
| FR-21 | all | §5.4 | `Engine/GameEngine.cs` (`Legal`) | TC-API-02, TC-AI-01, TC-ARC-05 |
| FR-22 | — | §5.4 | `Engine/GameEngine.cs` (`Apply`) | TC-ARC-02, TC-DET-03 |
| FR-23 | UC-08 | §7.4 | `Engine/Rules/DraftRules` | TC-DRF-01, 02, 05 |
| FR-24 | UC-08 | §7.3 | `Engine/Rules/DraftRules` | TC-DRF-03, 04 |
| FR-25 | UC-15 | §7.2 | `Engine/GameEngine.cs` | TC-ELM-03, TC-SYS-02 |

### Combat

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-26 | UC-10 | §7.5 | `Engine/Rules/CombatRules` | TC-CMB-01 |
| FR-27 | UC-10 | §7.5 | `Engine/Rules/CombatRules` | TC-CMB-02, 03, 06 |
| FR-28 | UC-13 | §7.4 | `Engine/Rules/CombatRules` | TC-CMB-07 |
| FR-29 | UC-10 | §5.4, §7.5 | `Engine/Random/SeededRandom`, `Engine/Rules/CombatRules` | TC-DET-01, TC-API-06 |
| FR-30 | UC-13 | §7.6 | `Engine/State/SeatState` | TC-CRD-02 |
| FR-31 | UC-10, UC-11, UC-12 | §7.5 | `Engine/Rules/CombatRules` | TC-CMB-08, TC-AIR-06, TC-NAV-04, TC-ARC-05 |

### Cards

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-32 | UC-15 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-02 |
| FR-33 | UC-09 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-03, 04, 05, 06 |
| FR-34 | UC-09 | §7.6 | `Engine/Rules/CardRules`, `shared/rules.json` | TC-CRD-07 |
| FR-35 | UC-08 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-08 |
| FR-36 | UC-09 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-09 |
| FR-37 | UC-09 | §7.6 | `Engine/Rules/CardRules` | TC-CRD-10 |
| FR-38 | — | §7.12 | `Engine/Rules/CardRules`, `Engine/Rules/VictoryRules` | TC-ELM-01 |

### Capability

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-39 | — | §7.7 | `Engine/Rules/CapabilityRules` | TC-CAP-02, 03 |
| FR-40 | — | §7.7 | `Engine/Rules/CapabilityRules` | TC-CAP-06 |
| FR-41 | — | §7.7 | `Engine/Rules/CapabilityRules` | TC-CAP-04, 05 |

### Air Force

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-42 | UC-11 | §7.8 | `Engine/Rules/AirForceRules` | TC-AIR-01 |
| FR-43 | UC-11 | §7.8 | `Engine/Rules/AirForceRules` | TC-AIR-02, 03 |
| FR-44 | UC-11 | §7.8 | `Engine/Rules/AirForceRules`, `Engine/Rules/CombatRules` | TC-AIR-06 |
| FR-45 | UC-11 | §7.8 (AIR-1) | `Engine/Rules/AirForceRules`, `shared/rules.json` | TC-AIR-04 |
| FR-46 | UC-11 | §7.8 | `Engine/Rules/AirForceRules` | TC-AIR-05 |

### Naval Force and sea routes

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-47 | — | §7.10 | `Engine/Models/SeaRoute` | TC-SEA-02, TC-MAP-03 |
| FR-48 | UC-12 | §7.9 | `Engine/Rules/NavalRules` | TC-NAV-01, 05 |
| FR-49 | UC-14 | §7.9, §7.4 | `Engine/Rules/NavalRules`, `Engine/Rules/FortifyRules` | TC-NAV-03, TC-FRT-04 |
| FR-50 | UC-12 | §7.9 | `Engine/Rules/NavalRules`, `Engine/Rules/CombatRules` | TC-NAV-04 |
| FR-51 | — | §7.9 | `Engine/Rules/CapabilityRules`, `Engine/Validation/MapValidator` | TC-NAV-06, TC-CAP-01 |

### Fortification, elimination and victory

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-52 | UC-14 | §7.4 | `Engine/Rules/FortifyRules`, `shared/rules.json` | TC-FRT-01, 02, 03 |
| FR-53 | — | §7.12 | `Engine/Rules/VictoryRules` | TC-ELM-01, 02 |
| FR-54 | — | §7.12 | `Engine/Rules/VictoryRules` | TC-VIC-01, 02 |
| FR-55 | — | §7.12 | `Engine/Rules/VictoryRules`, `shared/rules.json` | TC-VIC-03, 04 |

### Persistence

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-56 | — | §6.7 | `Data/Repositories/MatchRepository`, `Data/Mapping/` | TC-PER-02, 05 |
| FR-57 | — | §6.7 | `Data/Repositories/MatchRepository`, `Data/Migrations/` | TC-PER-04 |
| FR-58 | UC-17 | §6.7 | `Data/Repositories/MatchRepository`, `Api/Services/MatchService` | TC-PER-01, TC-DET-03 |
| FR-59 *(S)* | UC-18 | §5.5 | `Api/Controllers/MatchesController` | TC-API-08 |

### API and realtime

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-60 | — | §5.5 | `Api/Contracts/`, `shared/contracts/` | TC-API-01 |
| FR-61 | — | §6.7 | `Api/Services/MatchService`, `Data/Repositories/MatchRepository` | TC-API-03 |
| FR-62 | UC-16 | §5.5, §5.9 | `Api/Services/RedactionService` | TC-API-05, TC-SEC-03 |
| FR-63 | UC-06 | §5.5 | `Api/Hubs/MatchHub` | TC-API-06 |
| FR-64 | UC-16 | §5.3 | `Api/Hubs/MatchHub`, all three clients | TC-UI-03 |

### Clients

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-65 | — | §5.3 | `clients/unity`, `clients/godot`, `clients/flutter` | TC-UI-01 |
| FR-66 | — | §5.3 | all three clients | TC-UI-02 |
| FR-67 | — | §5.3 | all three clients | TC-ARC-04 |
| FR-68 | — | §5.3 (S-01…S-20) | all three clients | TC-UI-01, §10.1 screen inventory |
| FR-69 *(S)* | UC-10 | §5.3 | all three clients | TC-UI-02 |
| FR-70 *(OPT)* | — | §5.3 (D-25) | all three clients | **None — inspection only.** See §13.4 |

### AI

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-71 | UC-19 | §5.6 | `Ai/IAgent.cs` | TC-AI-01 |
| FR-72 | UC-19 | §5.6 | `Ai/PassiveBot.cs`, `ChaoticBot.cs`, `AggressiveBot.cs`, `MarsBot.cs` | TC-AI-03 |
| FR-73 | UC-19 | §5.5, §5.6 | `Api/Services/AiTurnService` | TC-API-07 |
| FR-74 | — | §5.6 | `Ai/IAgent.cs` + `Engine/GameEngine.cs` (`Legal`) | TC-AI-01 |
| FR-75 *(S)* | UC-19 | §5.6 | `Api/Services/AiTurnService` | TC-API-07 |
| FR-76 | — | §5.6, §8.8 | `Ai/Evaluation/MarsEvaluator.cs` | TC-AI-02, TC-AI-04 |
| FR-77 *(S)* | UC-19 | §5.6 | `Ai/AgentRegistry.cs`, `shared/rules.json` | TC-AI-03 |
| FR-78 *(OPT)* | UC-19 | §5.6, §8.9 | `Ai/OnnxPolicyAgent.cs`, `Ai/AgentRegistry.cs` | TC-RL-03 |

### Simulation and reinforcement learning

| FR | UC | Design | Module | Test |
|---|---|---|---|---|
| FR-79 *(S)* | UC-20 | §5.6, §8.9 | `server/OrderAndConquest.Sim/` | TC-AI-03 |
| FR-80 *(OPT)* | UC-20 | §8.9 | `server/OrderAndConquest.Sim/`, `rl/environment/` | TC-RL-01 |
| FR-81 *(OPT)* | — | §8.9 | `rl/training/`, `rl/models/`, `rl/export/` | TC-RL-02, TC-RL-03 |
| FR-82 *(S)* | UC-20 | §8.9 | `server/OrderAndConquest.Sim/` | TC-AI-06 |
| FR-83 *(OPT)* | — | §8.9 | `rl/export/`, `Ai/OnnxPolicyAgent.cs` | TC-RL-04 |

## 13.3 Coverage summary

| | Count |
|---|---|
| Functional requirements | **83** |
| With at least one test case | **82** |
| With a design section | **83** |
| With an implementation module | **83** |
| With a motivating use case | **60** |
| With no use case (invariants, consequences, infrastructure) | **23** — see §13.7 |
| Verified by inspection only | **1** (FR-70, optional) |

Every rules module named in §8.3 is exercised by at least one test family, which is the second half of
NFR-15:

| Module | Families that name it |
|---|---|
| `SetupRules` | TC-DRF, TC-SEA, TC-SYS |
| `DraftRules` | TC-DRF |
| `CombatRules` | TC-CMB, TC-AIR, TC-NAV |
| `CardRules` | TC-CRD, TC-ELM |
| `CapabilityRules` | TC-CAP, TC-NAV, TC-MAP |
| `AirForceRules` | TC-AIR |
| `NavalRules` | TC-NAV, TC-FRT |
| `FortifyRules` | TC-FRT, TC-NAV |
| `VictoryRules` | TC-VIC, TC-ELM |
| `MapValidator` | TC-MAP |
| `MapGenerator`, `SeaRouteGenerator` | TC-MAP, TC-SEA |
| `SeededRandom` | TC-DET |

## 13.4 The one requirement with no test, stated plainly

**FR-70 — preset messages and emoji instead of free text — has no test case.** It is optional (OPT), it is
a client presentation decision (D-25), and the thing it requires is the *absence* of a free-text input
field. That is verified by looking at the screen, and a test asserting that a text box does not exist in
three separate UI toolchains would cost more than it is worth.

This is recorded here rather than papered over with a placeholder identifier. §37 requires every *major*
functional requirement to map to a test; an optional cosmetic one is the case that rule leaves room for.

Two rows deserve a note for the opposite reason — they are traced to something wider than a single case:

- **FR-68** (the S-01…S-20 screen inventory) is traced to TC-UI-01 *and* to the screen table of §10.1.
  Twenty screens across three clients is a delivery checklist, not a test assertion, and §10.1 is where
  the count is recorded.
- **FR-21** (`Legal`) is traced to three cases in three different families, because it is the requirement
  every other legality test depends on. If TC-AI-01 passes over thousands of matches, FR-21 holds more
  strongly than any single unit test could show.

## 13.5 Non-functional requirements

Verification method for each, from §3.3, with the §9 case or measurement that supplies the evidence.

| NFR | Verified by | Evidence lands in |
|---|---|---|
| NFR-01 engine has no infrastructure dependency | TC-ARC-01 | §9.6 suite outcome |
| NFR-02 determinism | TC-DET-01…04 | §9.6 determinism evidence |
| NFR-03 `Apply` does not mutate input | TC-ARC-02 | §9.6 suite outcome |
| NFR-04 `Legal` < 100 ms p95 | Benchmark | §9.6, §10.4 |
| NFR-05 action round trip < 250 ms p95 | Benchmark | §9.6, §10.4 |
| NFR-06 heuristic decision < 500 ms | Benchmark | §9.6, §10.4 |
| NFR-07 policy inference < 50 ms *(OPT)* | Benchmark | §10.3 |
| NFR-08 100-round log < 2 s | Benchmark | §9.6, §10.4 |
| NFR-09 Argon2id only, no plaintext | TC-SEC-01 + schema inspection | §9.6 |
| NFR-10 server-side seat authorisation | TC-SEC-02, TC-API-04 | §9.6 |
| NFR-11 no other seat's cards in a response | TC-SEC-03, TC-API-05, TC-API-06 | §9.6 |
| NFR-12 append-only log by privilege | TC-PER-04 | §9.6 |
| NFR-13 no partially applied action | TC-PER-05 | §9.6 |
| NFR-14 identical legal set after resume | TC-PER-01 | §9.6 |
| NFR-15 every FR tested, every rules module named | **This document**, §13.3 | §13.3 |
| NFR-16 tunables in configuration, not code | TC-ARC-03 | §9.6 |
| NFR-17 no rule logic in a client | TC-ARC-04 | §9.6 |
| NFR-18 client DTOs generated from one contract | CI contract-regeneration gate (§9.1) | Build |
| NFR-19 no vendor-specific column types | Schema review (§6.8) | §6.8 portability table |
| NFR-20 invalid-action rate exactly zero | TC-AI-01 | §10.3 |
| NFR-21 illegal actions unreachable in the UI | TC-UI-01 | §9.6 |
| NFR-22 pass-and-play reveals nothing | TC-UI-02, TC-UI-03 | §9.6 |
| NFR-23 one process, one database | Deployment diagram §5.1 | §10.1 |
| NFR-24 optional stays optional | **This document**, §13.6 | §13.6 |

## 13.6 The NFR-24 check

> NFR-24: *the mandatory set shall be fully deliverable with every OPT requirement removed.*

The check is mechanical: delete every OPT row from §13.2 and confirm no mandatory row loses a dependency.

| OPT requirement | Deleting it removes | Does any mandatory FR depend on it? |
|---|---|---|
| FR-70 preset messages | A client presentation feature | No |
| FR-78 trained-policy inference | `Ai/OnnxPolicyAgent.cs` | No — `AgentRegistry` resolves `MarsBot` |
| FR-80 trajectory export | `rl/environment/` | No |
| FR-81 PPO training and export | `rl/training/`, `rl/models/`, `rl/export/` | No |
| FR-83 checkpoint fortify-mode metadata | A guard inside the RL export path | No |

**Result: NFR-24 holds.** Removing all five leaves 78 requirements, all of the engine, the API, the
database, four heuristic agents and three clients — a complete, playable game. The five removed tests
(TC-RL-01…04 and FR-70's inspection) are exactly the ones §9.1 counts separately as "gated on the optional
RL component".

The same check in the other direction is worth stating, because it is the one that protects the project
schedule: **no mandatory requirement names `rl/`, `Sim/`, `OnnxPolicyAgent` or ONNX.** Those four names
appear in the Module column only on `(S)` and `(OPT)` rows. That is the structural form of §35's rule that
advanced features must not block the core.

## 13.7 Requirements with no use case

Twenty-three functional requirements have `—` in the UC column. This is not a gap, and inventing use cases
to fill it would make the use-case model worse.

| Kind | Examples | Why no use case |
|---|---|---|
| **Invariants** | FR-22, FR-39…FR-41, FR-47, FR-51 | They constrain what the system may do at all times. No actor "performs" them |
| **Consequences of other actions** | FR-38, FR-53, FR-54, FR-55 | Elimination and victory *happen* as a result of an attack. The actor's use case is UC-10, UC-11 or UC-12 |
| **Infrastructure obligations** | FR-56, FR-57, FR-60, FR-61 | Persistence and concurrency have no actor. UC-17 covers the part a player experiences |
| **Quality constraints on clients** | FR-65…FR-68 | They constrain *how* every use case is presented, so attaching them to one would be arbitrary |
| **Internal AI and RL structure** | FR-74, FR-76, FR-81, FR-83 | UC-19 and UC-20 cover the actor-visible behaviour |

A use-case diagram that contained a bubble for "do not mutate the input state" would be a worse diagram.
§31's prohibition on putting implementation detail into a DFD rests on the same principle.

## 13.8 Domain requirements

The twenty domain requirements of §3.4 are rules of RISK rather than obligations on the system, so they are
traced to the module that enforces them and the invariant that checks them, not to a use case.

| DR | Enforced in | Checked by |
|---|---|---|
| DR-01 connected board | `MapValidator` (V-03) | TC-MAP-02 |
| DR-02 symmetric adjacency | `MapValidator` (V-04) | TC-MAP-02 |
| DR-03 continents partition exactly | `MapValidator` (V-05) | TC-MAP-03 |
| DR-04 ≥ 1 army, exactly one owner | `Engine/State/TerritoryState` | TC-ARC-05 invariant set |
| DR-05 armies conserved | `CombatRules`, `FortifyRules` | TC-ARC-05 invariant set |
| DR-06 attacker leaves ≥ 1 behind | `CombatRules`, `FortifyRules` | TC-CMB-07, TC-FRT-01 |
| DR-07 defender wins ties | `CombatRules` | **TC-CMB-03** |
| DR-08 reinforcements ≥ 3 | `DraftRules` | TC-DRF-02 |
| DR-09 bonus needs the whole continent | `DraftRules` | TC-DRF-04 |
| DR-10 one card per territory plus wilds | `CardRules` | TC-CRD-01 |
| DR-11 ≤ 1 card per turn, after a capture | `CardRules` | TC-CRD-02 |
| DR-12 a set is exactly three cards | `CardRules` | TC-CRD-05, TC-CRD-06 |
| DR-13 escalation is monotonic, never resets | `CardRules` | TC-CRD-07 |
| DR-14 eliminated seats never act | `VictoryRules`, `GameEngine.cs` | TC-ELM-03 |
| DR-15 `Neutral` defends only | `GameEngine.cs` | TC-SYS-02 |
| DR-16 a sea route is never a territory | `Engine/Models/SeaRoute` | TC-SEA-02 |
| DR-17 landlocked is never naval by default | `CapabilityRules` | TC-NAV-06 |
| DR-18 air range on land edges only | `AirForceRules` | **TC-AIR-03** |
| DR-19 one combat resolution | `CombatRules` | **TC-CMB-08**, TC-ARC-05 |
| DR-20 domination or round cap only | `VictoryRules` | TC-VIC-03, TC-VIC-04 |

The three bold rows are the locked rules of the specification that a plausible-looking implementation can
get wrong while still appearing to work. They are the same three singled out in §9.2.

## 13.9 Maintaining this document

This matrix is the first thing a rename breaks, and a broken traceability matrix is worse than none —
it asserts a mapping that no longer holds.

| Change | What must be updated here |
|---|---|
| A rules module is renamed or split | The Module column, and §13.3's module table |
| A test case is added, removed or renumbered | The Test column; and the counts in §9.1 |
| A requirement is added | A row in §13.2, and the counts in §13.3 and §3.2 |
| An OPT requirement is promoted to mandatory | §13.6's NFR-24 check must be re-run — this is the change §40 warns about |

The last row is the important one. Promoting an optional requirement is the single edit that can make the
project unbuildable, because it is also the edit that looks smallest.

---

**Previous:** [12 — References](12-references.md) · **Next:**
[14 — Implementation Safety Checklist](14-implementation-safety-checklist.md)
