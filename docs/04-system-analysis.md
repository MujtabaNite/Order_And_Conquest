# 4 — System Analysis and Modelling

> **Deliverables E, F, G.** Use cases, flowcharts, data-flow diagrams levels 0–2, sequence diagrams and
> the state diagram. All diagrams are Mermaid source, so they are diffable and regenerate on render.
>
> One modelling convention governs this chapter: **the engine is the only process that changes game
> state.** Every diagram below is drawn so that this is visible rather than asserted.

## 4.1 System Overview

Order & Conquest is one authoritative server, one rules engine inside it, and three thin clients that
render what the server reports. Analysis therefore separates cleanly into three concerns:

| Concern | Question it answers | Modelled by |
|---|---|---|
| **Who does what** | Which actor triggers which capability | §4.2, §4.3 |
| **What flows where** | Which data crosses which boundary, and what is stored | §4.6–§4.8 |
| **What happens in what order** | Sequencing, concurrency and the legal phase transitions | §4.4, §4.5, §4.9, §4.10 |

### Actors

| Actor | Type | Description |
|---|---|---|
| **Guest Player** | Primary, human | Plays without an account. Single-player and pass-and-play only (FR-03) |
| **Registered Player** | Primary, human | Guest plus resumable history and remote seats (FR-01, FR-02, FR-04) |
| **Host** | Primary, human | The Registered or Guest Player who created a match; the only seat that configures it |
| **AI Agent** | Secondary, system | Occupies an `Ai` seat and selects an action from the engine's legal list (FR-71) |
| **Game Engine** | Secondary, system | The sole authority on rules. Not a user, but appears in flow and sequence models because every state change passes through it |
| **Trainer** | Secondary, human | A developer running headless simulation, tournaments and optional RL training (FR-79, FR-82) |

**`Neutral` is not an actor.** It is a seat kind with no agency: it owns territories and defends, but
never initiates anything (DR-15). Modelling it as an actor would imply behaviour it does not have.

## 4.2 Use Case Diagram

```mermaid
flowchart LR
    Guest(["Guest Player"])
    Reg(["Registered Player"])
    Host(["Host"])
    AI(["AI Agent"])
    Trainer(["Trainer"])

    subgraph SYS["Order & Conquest"]
        direction TB
        subgraph ACC["Account"]
            UC01(["UC-01 Register"])
            UC02(["UC-02 Log In"])
            UC03(["UC-03 Play as Guest"])
        end
        subgraph SETUP["Match Setup"]
            UC04(["UC-04 Create Match"])
            UC05(["UC-05 Configure Sea Routes"])
            UC06(["UC-06 Join Match"])
            UC07(["UC-07 Claim Territories"])
        end
        subgraph PLAY["Play a Turn"]
            UC08(["UC-08 Draft Reinforcements"])
            UC09(["UC-09 Trade Card Set"])
            UC10(["UC-10 Attack Adjacent"])
            UC11(["UC-11 Air Force Attack"])
            UC12(["UC-12 Naval Attack"])
            UC13(["UC-13 Occupy Territory"])
            UC14(["UC-14 Fortify"])
            UC15(["UC-15 End Turn"])
        end
        subgraph SESS["Session"]
            UC16(["UC-16 Hand Over Device"])
            UC17(["UC-17 Resume Match"])
            UC18(["UC-18 View Replay"])
            UC19(["UC-19 Take AI Turn"])
        end
        subgraph DEV["Developer"]
            UC20(["UC-20 Run Tournament"])
            UC21(["UC-21 Generate Map"])
        end
    end

    Guest --> UC03
    Guest --> UC06
    Reg --> UC01
    Reg --> UC02
    Reg --> UC06
    Reg --> UC17
    Reg --> UC18
    Host --> UC04
    Host --> UC05
    Guest --> UC07
    Guest --> UC08
    Guest --> UC09
    Guest --> UC10
    Guest --> UC11
    Guest --> UC12
    Guest --> UC14
    Guest --> UC15
    Guest --> UC16
    AI --> UC19
    Trainer --> UC20
    Trainer --> UC21

    UC04 -.->|include| UC05
    UC10 -.->|include| UC13
    UC11 -.->|include| UC13
    UC12 -.->|include| UC13
    UC08 -.->|extend| UC09
    UC15 -.->|extend| UC16
```

*Inheritance note:* Registered Player is a specialisation of Guest Player — every guest capability is
also available once logged in. Edges are drawn from `Guest` where the capability is shared, to keep the
diagram readable.

### Use case index

| ID | Use case | Primary actor | FRs |
|---|---|---|---|
| UC-01 | Register account | Registered Player | FR-01 |
| UC-02 | Log in | Registered Player | FR-02 |
| UC-03 | Play as guest | Guest Player | FR-03 |
| UC-04 | Create match | Host | FR-12, FR-13, FR-17, FR-18, FR-19 |
| UC-05 | Configure sea routes | Host | FR-15, FR-16 |
| UC-06 | Join match | Guest / Registered | FR-13, FR-63 |
| UC-07 | Claim territories | Player | FR-17, FR-21 |
| UC-08 | Draft reinforcements | Player | FR-23, FR-24, FR-35 |
| UC-09 | Trade card set | Player | FR-33, FR-34, FR-37 |
| UC-10 | Attack an adjacent territory | Player | FR-26…FR-31 |
| UC-11 | Launch an Air Force attack | Player | FR-42…FR-46 |
| UC-12 | Launch a Naval attack | Player | FR-47, FR-48, FR-50 |
| UC-13 | Occupy a captured territory | Player | FR-28, FR-30 |
| UC-14 | Fortify | Player | FR-49, FR-52 |
| UC-15 | End turn | Player | FR-25, FR-32 |
| UC-16 | Hand over device | Player | FR-64, FR-62 |
| UC-17 | Resume match | Registered Player | FR-04, FR-58 |
| UC-18 | View replay | Registered Player | FR-59 |
| UC-19 | Take AI turn | AI Agent | FR-71…FR-76 |
| UC-20 | Run tournament | Trainer | FR-79, FR-82 |
| UC-21 | Generate a map | Trainer | FR-07, FR-08 |

## 4.3 Use Case Specifications

Specifications follow the template used by the 2022 report, for continuity with institutional
expectations (§2.4). Eight use cases are specified in full — the ones where the rules are non-obvious or
where the new capabilities change behaviour. The remainder are mechanically similar.

---

### UC-04 — Create Match

| Field | Content |
|---|---|
| **Use case name** | Create Match |
| **Actor(s)** | Host (primary) · Game Engine (secondary) |
| **Summary description** | The host selects a map, configures 2–6 seats and their kinds, chooses a sea-route count, and creates a match. The server normalises the map, generates sea routes, freezes the result, deals starting armies and persists the match at version 1. |
| **Pre-condition** | The host has a session (guest or authenticated). At least one map passes validation. |
| **Post-condition** | A match exists in `Lobby` or `Setup` with a frozen effective map, the configured seats, a deck built from the effective map, and version 1. A room code is issued. |
| **Basic path** | 1. Host opens *Create Match*. 2. System lists validated maps (FR-05). 3. Host selects a map. 4. Host sets seat count 2–6 and each seat's kind; an `Ai` seat also takes an agent name (FR-13). 5. Host sets the sea-route count within `[min, max]` (FR-15). 6. Host sets options: allocation mode, fortify mode, round cap, difficulty. 7. Host confirms. 8. System validates the map against the shared gate (FR-08). 9. System generates exactly the requested number of valid sea routes and freezes them into the effective map (FR-16, FR-10). 10. System builds the deck: one card per territory plus wilds (FR-19). 11. System issues starting armies from the configured table (FR-18). 12. System persists match, seats and territory state in one transaction and returns the match with a room code. |
| **Alternative path** | 4a. Host selects 2 seats → system inserts a third `Neutral` seat automatically and applies the 3-seat army count (FR-14, D-07). 5a. Count outside `[min, max]` → `400` with the permitted range; no match created. 8a. Map fails validation → `422` naming the failed gate rule; no match created. 9a. Generation cannot place the requested number of routes within the attempt bound → `422` stating how many were placeable; **no partial match is created** (D-13). 12a. Transaction fails → nothing persisted; host may retry. |
| **Business rules** | Seats: 2–6 (FR-12). A 2-seat match becomes three seats with one `Neutral`. Sea-route endpoints are chosen by the system, never by the host (C-07). The effective map is frozen at creation; later edits to map files cannot affect this match (FR-10). |
| **Non-functional** | NFR-02 — the same seed and configuration must yield the same effective map. NFR-13 — creation is atomic. |

---

### UC-05 — Configure Sea Routes

| Field | Content |
|---|---|
| **Use case name** | Configure Sea Routes |
| **Actor(s)** | Host (primary) |
| **Summary description** | The host chooses **how many** sea routes the match will contain. The system chooses where they go. |
| **Pre-condition** | Match creation is in progress. `navalForce.enabled` is true. |
| **Post-condition** | A sea-route count within the configured bounds is attached to the pending match options. |
| **Basic path** | 1. System displays the permitted range and the default. 2. Host selects a count. 3. System accepts it into the pending options. |
| **Alternative path** | 2a. Host selects a value outside the range → rejected inline, with the range shown. 1a. `navalForce.enabled` is false → the screen is not shown and the count is 0; the match is classic-only (D-13). |
| **Business rules** | The host chooses a **count only**. No interface exists anywhere in the system for drawing a route between two named territories — this is an explicit non-goal (Part E). Endpoints must be coastal, must not already be land-adjacent, and must not duplicate an existing route (FR-16). |
| **Non-functional** | NFR-21 — an out-of-range count must not be selectable in the interface. |

---

### UC-08 — Draft Reinforcements

| Field | Content |
|---|---|
| **Use case name** | Draft Reinforcements |
| **Actor(s)** | Player (primary) · Game Engine (secondary) |
| **Summary description** | At the start of a turn the player receives armies from territory count, continent bonuses and any card trade, then places them on owned territories. |
| **Pre-condition** | It is the player's turn and the phase is `Draft`. The player is not eliminated. |
| **Post-condition** | The player's army pool is zero and the placed armies appear on owned territories. Phase advances to `Attack`. |
| **Basic path** | 1. System computes `max(3, ⌊t/3⌋) + continent bonuses + trade value` (FR-23, FR-24). 2. System presents the total and the legal placement targets. 3. Player places armies on owned territories, one or many at a time. 4. When the pool reaches zero the player confirms and the phase advances. |
| **Alternative path** | 1a. The player holds ≥ 5 cards → the system requires a trade before any placement is legal; the legal-action list contains only trade actions (FR-35). 3a. The player targets a territory they do not own → the action is not legal and is not offered (FR-66); a direct API call is rejected with no state change (FR-22). 1b. The player traded a set naming a territory they own → 2 extra armies are placed directly on that territory, capped at 2 per turn (FR-37). |
| **Business rules** | Minimum 3 armies regardless of territory count (DR-08). A continent bonus requires every territory of that continent (DR-09). Card trade value comes from the next position in the escalation table, which advances once per trade for the whole match and never resets (DR-13). |
| **Non-functional** | NFR-04 — legal-action computation within 100 ms at p95. |

---

### UC-10 — Attack an Adjacent Territory

| Field | Content |
|---|---|
| **Use case name** | Attack an Adjacent Territory |
| **Actor(s)** | Player (primary) · Game Engine (secondary) |
| **Summary description** | The player attacks a land-adjacent enemy territory. Dice are rolled by the engine from the match's seeded random source; losses are applied; if the defender reaches zero the attacker occupies. |
| **Pre-condition** | Phase is `Attack`. The player owns the origin, which holds ≥ 2 armies and at least one more than the dice to be rolled. The target is land-adjacent and owned by another seat. |
| **Post-condition** | Army counts on both territories are updated. On capture, ownership transfers, the conquest flag is set for the turn, and the phase moves to `Occupy`. |
| **Basic path** | 1. Player selects origin, target and dice count 1–3 (FR-26). 2. Engine draws attacker and defender dice from the injected random source (FR-29). 3. Engine compares highest with highest and second with second, **defender winning ties** (FR-27). 4. Engine applies one army loss per comparison to the loser. 5. Engine emits a `DiceRolled` event carrying every die face. 6. If the defender reaches 0 armies → UC-13 Occupy. 7. Otherwise the player may attack again or advance the phase. |
| **Alternative path** | 1a. Origin holds fewer than 2 armies → the attack is not in the legal list. 1b. Dice requested ≥ armies in origin → not legal. 3a. All comparisons lost by the attacker → origin loses armies, no capture. 6a. The defender loses its last territory → UC-15 elimination handling; the eliminating seat receives its cards (FR-38). |
| **Business rules** | Defender wins ties (DR-07). At least 1 army always remains in the origin (DR-06). Every die comes from the match random source, never from a system clock or an unseeded generator (NFR-02). |
| **Non-functional** | NFR-02 — identical seed and action sequence reproduce identical dice. NFR-05 — round trip within 250 ms at p95. |

---

### UC-11 — Launch an Air Force Attack

| Field | Content |
|---|---|
| **Use case name** | Launch an Air Force Attack |
| **Actor(s)** | Player (primary) · Game Engine (secondary) |
| **Summary description** | A player holding Air Force capability attacks a territory up to 5 land edges away. Combat is resolved by the ordinary rules; only the adjacency test differs. |
| **Pre-condition** | Phase is `Attack`. The player holds Air Force capability by CAP-2 (FR-39). The player has not already used the turn's Air Force attack (FR-45). Origin and army constraints are as for UC-10. |
| **Post-condition** | As UC-10, plus the turn's Air Force attack is consumed. |
| **Basic path** | 1. System computes the set of targets within `maxRange` by shortest path **over land adjacency edges only** (FR-43). 2. Player selects origin, target and dice count. 3. Combat resolves through the **same** code path as UC-10 (FR-44, FR-31). 4. On capture, occupation follows the ordinary rules (UC-13). |
| **Alternative path** | 1a. The player holds no Air Force capability → no Air Force action appears in the legal list. 1b. The turn's Air Force attack is already used → no Air Force action appears. 1c. The target is reachable only by crossing a sea route → **it is not a legal target**; sea routes are excluded from range entirely (C-08). 4a. The captured territory is not adjacent to any other territory the player owns → this is permitted and expected; the player holds a disconnected pocket (D-11, TC-AIR-04). |
| **Business rules** | Range is 1–5 inclusive (D-17). Range is measured on the land graph only (DR-18). One Air Force attack per seat per turn (AIR-1). No fuel, no airfields, no bombing, no hit points, no air unit — the capability changes which targets are legal and nothing else. |
| **Non-functional** | NFR-04 — range computation is a bounded breadth-first search from one node and stays inside the legal-action budget. |

---

### UC-12 — Launch a Naval Attack

| Field | Content |
|---|---|
| **Use case name** | Launch a Naval Attack |
| **Actor(s)** | Player (primary) · Game Engine (secondary) |
| **Summary description** | A player holding Naval capability attacks across a sea route. A sea route behaves as an adjacency edge for that player; combat is unchanged. |
| **Pre-condition** | Phase is `Attack`. The player holds Naval capability by CAP-2. A sea route in the frozen effective map connects an origin the player owns to a target they do not own. Origin and army constraints as UC-10. |
| **Post-condition** | As UC-10. |
| **Basic path** | 1. System lists sea routes from territories the player owns to territories they do not (FR-48). 2. Player selects a route and a dice count. 3. Combat resolves through the same code path as UC-10 (FR-50, FR-31). 4. On capture, occupation follows the ordinary rules, moving armies across the sea route. |
| **Alternative path** | 1a. The player holds no Naval capability → no naval action appears. 1b. No sea route touches a territory the player owns → no naval action appears. 1c. The match was created with `navalForce.enabled = false` → the capability system reports no naval actions at all. |
| **Business rules** | A sea route is an **edge**, never a territory, and is never captured or occupied (DR-16). Crossing costs no units (NAV-1). A landlocked territory is never an endpoint (DR-17, FR-51). Sea routes do not extend Air Force range (C-08). |
| **Non-functional** | NFR-02, NFR-05 as UC-10. |

---

### UC-16 — Hand Over Device

| Field | Content |
|---|---|
| **Use case name** | Hand Over Device |
| **Actor(s)** | Player, outgoing and incoming (primary) |
| **Summary description** | In a pass-and-play match the device must pass between local seats without the outgoing player seeing the incoming player's cards. |
| **Pre-condition** | The match has more than one `LocalHuman` seat. A turn has just ended and the next seat is also `LocalHuman`. |
| **Post-condition** | The incoming seat's redacted state is displayed. The outgoing seat's hand is no longer on screen at any point during the transition. |
| **Basic path** | 1. Outgoing player ends their turn. 2. Server advances the turn and emits `HandOverDevice` naming only the incoming seat (FR-63). 3. Client **immediately** clears all hand information and displays a blocking hand-over screen naming the incoming seat. 4. Incoming player confirms. 5. Client requests state redacted for the incoming seat (FR-62). 6. Play resumes. |
| **Alternative path** | 2a. The next seat is `Ai` or `Neutral` → no hand-over screen; the turn proceeds (UC-19). 3a. The client is backgrounded or restarted during hand-over → it resumes at the blocking screen, never at a revealed hand. |
| **Business rules** | Redaction is performed **server-side** (FR-62). The client is never sent another seat's card identities and therefore cannot leak them through a rendering error. |
| **Non-functional** | NFR-22 — no seat's cards are visible to a previous seat at any point. NFR-11 — the response contains no other seat's card identities. |

---

### UC-19 — Take AI Turn

| Field | Content |
|---|---|
| **Use case name** | Take AI Turn |
| **Actor(s)** | AI Agent (primary, system) · Game Engine (secondary) |
| **Summary description** | When the current seat is an `Ai` seat, the server asks the configured agent to choose one action from the engine's legal list, applies it, and streams the resulting events. This repeats until the AI seat's turn ends. |
| **Pre-condition** | The current seat's kind is `Ai` and an agent name is configured (FR-13). |
| **Post-condition** | The AI seat's turn is complete and every resulting event has been broadcast. |
| **Basic path** | 1. Server computes the legal-action list (FR-21). 2. Server passes state and that list to the agent (FR-71). 3. Agent returns exactly one action from the list. 4. Server applies a minimum think-time delay before releasing the result (FR-75). 5. Server applies the action, persists it and broadcasts the events (FR-56, FR-57, FR-63). 6. Repeat from 1 while the current seat remains the same AI seat. |
| **Alternative path** | 3a. MarsBot evaluates candidate attacks by expected value — `winChance × V(won) + (1 − winChance) × V(lost)` — and does **not** roll dice to evaluate, so scoring never advances the match random source (FR-76). 3b. The `Brutal` difficulty's trained policy is unavailable → the server falls back to MarsBot and logs the substitution (FR-78). 6a. The match ends on this action → `GameOver` is broadcast and no further AI action is requested. |
| **Business rules** | An agent selects from the engine's legal list and therefore **cannot** produce an illegal action (FR-74, NFR-20). Think time is applied at the API layer, never inside the agent, so headless simulation and RL training run at full speed (D-22). |
| **Non-functional** | NFR-06 — a heuristic agent chooses within 500 ms. NFR-20 — invalid-action rate exactly zero. |

---

### UC-17 — Resume Match

| Field | Content |
|---|---|
| **Use case name** | Resume Match |
| **Actor(s)** | Registered Player (primary) |
| **Summary description** | A player reopens an unfinished match. The server restores the snapshot and the random source, producing a state indistinguishable from the one saved. |
| **Pre-condition** | The player holds a seat in a match whose status is not finished. |
| **Post-condition** | The match state and legal-action list are identical to those at the moment of saving. |
| **Basic path** | 1. Player requests their resumable matches (FR-04). 2. Player selects one. 3. Server loads the snapshot — match, seats, territory state, cards — **without replaying the log** (FR-58). 4. Server restores the random source from `rng_seed` and advances it to `rng_position`. 5. Server returns state redacted for that seat, plus the legal-action list and the current version. |
| **Alternative path** | 2a. The player holds no seat in that match → `403`. 3a. The snapshot is missing or inconsistent → the match is reported unrecoverable rather than partially loaded; the action log remains available for replay (FR-59). |
| **Business rules** | Resume reads the snapshot; the log exists for replay and audit, not for reconstruction (FR-57, FR-58). Restoring `rng_position` is what makes the *next* dice roll match what it would have been (NFR-02). |
| **Non-functional** | NFR-14 — the resumed legal-action set is identical to the one before saving (TC-PER-01). |

## 4.4 System Flowchart

The lifecycle from launching a client to a finished match.

```mermaid
flowchart TD
    START(["Launch client"]) --> AUTH{"Account?"}
    AUTH -->|"Register"| REG["Create account<br/>Argon2id hash stored"]
    AUTH -->|"Log in"| LOGIN["Authenticate, issue token"]
    AUTH -->|"Guest"| GUEST["Guest session"]
    REG --> MENU
    LOGIN --> MENU
    GUEST --> MENU

    MENU["Main menu"] --> CHOICE{"Action"}
    CHOICE -->|"Resume"| LOADM["Load snapshot<br/>restore RNG position"]
    CHOICE -->|"Replay"| REPLAY["Stream action log"]
    CHOICE -->|"Join"| JOINM["Join by room code"]
    CHOICE -->|"Create"| CREATE["Select map, seats,<br/>sea-route count, options"]

    CREATE --> VAL{"Map passes<br/>validation gate?"}
    VAL -->|"No"| ERRV["Reject, naming the failed rule"]
    ERRV --> CREATE
    VAL -->|"Yes"| GENSR{"Sea routes<br/>placeable?"}
    GENSR -->|"No"| ERRS["Reject, naming how many<br/>routes were placeable"]
    ERRS --> CREATE
    GENSR -->|"Yes"| FREEZE["Freeze effective map<br/>build deck, deal armies<br/>persist at version 1"]

    FREEZE --> ALLOC{"Allocation<br/>mode"}
    ALLOC -->|"Claim"| CLAIM["Seats claim territories<br/>in turn order"]
    ALLOC -->|"Random"| RAND["Seeded random assignment"]
    CLAIM --> LOOP
    RAND --> LOOP
    JOINM --> LOOP
    LOADM --> LOOP

    LOOP[["Turn loop — see 4.5"]]
    LOOP --> OVER{"Victory or<br/>round cap?"}
    OVER -->|"No"| LOOP
    OVER -->|"Yes"| RESULT["Rank seats, mark finished,<br/>broadcast GameOver"]
    RESULT --> MENU
    REPLAY --> MENU
```

## 4.5 Game Flowchart

One turn, including both new capabilities. Everything in this diagram happens inside the engine.

```mermaid
flowchart TD
    T([Turn begins]) --> SKIP{Seat eliminated<br/>or Neutral?}
    SKIP -->|Yes| NEXT
    SKIP -->|No| FORCE{Holds 5+ cards?}

    FORCE -->|Yes| MUST[Only trade actions are legal]
    MUST --> TRADE
    FORCE -->|No| MAY{Trade a set?}
    MAY -->|Yes| TRADE[Remove 3 cards<br/>award next escalation value<br/>advance table position]
    MAY -->|No| CALC
    TRADE --> BONUS{Owns a territory<br/>named on a traded card?}
    BONUS -->|Yes| PLUS2[+2 armies on that territory<br/>max 2 per turn]
    BONUS -->|No| CALC
    PLUS2 --> CALC

    CALC["armies = max(3, floor(t/3))<br/>+ continent bonuses<br/>+ trade value"] --> PLACE[Place armies<br/>on owned territories]
    PLACE --> POOL{Pool empty?}
    POOL -->|No| PLACE
    POOL -->|Yes| ATK

    ATK{Attack?}
    ATK -->|No| FORT
    ATK -->|Land| CHKL[Target land-adjacent<br/>origin has 2+ armies<br/>and > dice rolled]
    ATK -->|Air Force| CHKA{Holds Air capability<br/>AND attack unused<br/>AND land distance <= 5?}
    ATK -->|Naval| CHKN{Holds Naval capability<br/>AND sea route exists?}

    CHKA -->|No| ATK
    CHKN -->|No| ATK
    CHKA -->|Yes| COMBAT
    CHKN -->|Yes| COMBAT
    CHKL --> COMBAT

    COMBAT[["ONE combat resolution<br/>attacker 1-3 dice, defender 1-2<br/>compare descending<br/>DEFENDER WINS TIES"]]
    COMBAT --> CAP{Defender at 0?}
    CAP -->|No| ATK
    CAP -->|Yes| OCC[Occupy: move in at least<br/>dice rolled, leave 1 behind<br/>set conquered-this-turn]
    OCC --> ELIM{Defender lost<br/>last territory?}
    ELIM -->|Yes| TAKE[Eliminate seat<br/>transfer its cards]
    TAKE --> OVER6{Holder now has 6+?}
    OVER6 -->|Yes| DOWN[Must trade down below 5<br/>immediately]
    OVER6 -->|No| WIN
    DOWN --> WIN
    ELIM -->|No| ATK
    WIN{Owns every territory?}
    WIN -->|Yes| GO([Victory])
    WIN -->|No| ATK

    FORT{Fortify?}
    FORT -->|"Yes - land or sea route<br/>one move only"| DOFORT[Move armies between two<br/>owned territories, leave 1]
    FORT -->|No| CARD
    DOFORT --> CARD
    CARD{Conquered at least<br/>one territory this turn?}
    CARD -->|Yes| DRAW[Award exactly one card]
    CARD -->|No| NEXT
    DRAW --> NEXT
    NEXT[Advance to next<br/>non-eliminated seat] --> CAPR{Round cap reached?}
    CAPR -->|Yes| ENDCAP([End: rank by territory count])
    CAPR -->|No| T
```

Two things in that diagram are worth naming because they are the extensions in their entirety:

- `CHKA` and `CHKN` are **guards on which targets are legal**. Both funnel into the same `COMBAT` node.
- There is exactly one `COMBAT` node. That is FR-31 drawn rather than stated.

## 4.6 Data Flow Diagram — Level 0 (Context)

```mermaid
flowchart LR
    P(["Player"])
    T(["Trainer"])

    SYS(("0<br/>Order &amp; Conquest<br/>System"))

    P -->|"credentials, match configuration,<br/>chosen action, expected version"| SYS
    SYS -->|"redacted state, legal actions,<br/>dice events, turn and result notifications"| P

    T -->|"tournament and generation parameters,<br/>seeds"| SYS
    SYS -->|"win-rate matrix, generated maps,<br/>trajectory files"| T
```

The context diagram has two external entities. **AI agents are not external** — they run inside the
server process, in `OrderAndConquest.Ai`, and appear at level 1.

## 4.7 Data Flow Diagram — Level 1

```mermaid
flowchart TB
    P(["Player"])
    T(["Trainer"])

    P1(("1<br/>Account<br/>Management"))
    P2(("2<br/>Match<br/>Setup"))
    P3(("3<br/>Turn<br/>Processing"))
    P4(("4<br/>AI Turn<br/>Service"))
    P5(("5<br/>Persistence<br/>&amp; Replay"))
    P6(("6<br/>Map<br/>Service"))

    D1[("D1 users")]
    D2[("D2 matches")]
    D3[("D3 seats")]
    D4[("D4 territory_state")]
    D5[("D5 cards")]
    D6[("D6 moves")]
    D7[("D7 map files<br/>read-only")]

    P -->|credentials| P1
    P1 -->|token or guest session| P
    P1 <-->|username, hash| D1

    P -->|"map key, seat config,<br/>sea-route count"| P2
    P2 -->|"match id, room code"| P
    P6 -->|validated map| P2
    P2 -->|"frozen effective map,<br/>options, seed"| D2
    P2 -->|seat rows| D3
    P2 -->|initial ownership and armies| D4
    P2 -->|shuffled deck| D5

    P -->|"action + expectedVersion"| P3
    P3 -->|"legal actions, redacted state,<br/>events"| P
    P3 <-->|snapshot| D2
    P3 <-->|snapshot| D3
    P3 <-->|snapshot| D4
    P3 <-->|snapshot| D5
    P3 -->|"append action, events,<br/>version, rng position"| D6

    P3 -->|"state + legal actions<br/>when current seat is Ai"| P4
    P4 -->|chosen action| P3

    P -->|resume or replay request| P5
    P5 -->|"restored state / action log"| P
    P5 -->|read snapshot| D2
    P5 -->|read snapshot| D3
    P5 -->|read snapshot| D4
    P5 -->|read snapshot| D5
    P5 -->|read log| D6

    T -->|"seed, parameters"| P6
    P6 -->|generated map| T
    P6 -->|read authored maps| D7
    T -->|tournament request| P4
    P4 -->|win-rate matrix| T
```

**Store-access rule made visible:** process 3 is the only process with a write arrow into D4 and D5, and
the only process that appends to D6. Process 5 has read arrows only. This is FR-57 and NFR-12 expressed
as a structural property rather than a convention.

## 4.8 Data Flow Diagram — Level 2 (Process 3: Turn Processing)

```mermaid
flowchart TB
    IN(["Player or AI Turn Service"])

    P31(("3.1<br/>Authorise<br/>&amp; Version Check"))
    P32(("3.2<br/>Compute<br/>Legal Actions"))
    P33(("3.3<br/>Apply Action<br/>(Engine)"))
    P34(("3.4<br/>Resolve<br/>Combat"))
    P35(("3.5<br/>Award Card<br/>&amp; Check Elimination"))
    P36(("3.6<br/>Persist<br/>Transaction"))
    P37(("3.7<br/>Redact<br/>&amp; Broadcast"))

    D2[("D2 matches")]
    D3[("D3 seats")]
    D4[("D4 territory_state")]
    D5[("D5 cards")]
    D6[("D6 moves")]

    IN -->|"action, seat, expectedVersion"| P31
    D2 -->|"current version, seed, position"| P31
    D3 -->|seat ownership| P31
    P31 -->|"409 Conflict + current state"| IN
    P31 -->|authorised action| P32

    D4 --> P32
    D5 --> P32
    P32 -->|legal action set| P33
    P32 -->|"rejected: not in legal set,<br/>no state change"| IN

    P33 -->|"attack of any kind"| P34
    P34 -->|"dice faces, losses,<br/>new rng position"| P33
    P33 -->|"capture / turn end"| P35
    P35 -->|"card award, elimination,<br/>victory check"| P33

    P33 -->|"new state + events"| P36
    P36 -->|"version + 1, rng_position"| D2
    P36 -->|updated ownership and armies| D4
    P36 -->|card movements| D5
    P36 -->|seat status| D3
    P36 -->|"append: action, events,<br/>version, rng position"| D6

    P36 -->|committed state| P37
    P37 -->|"per-seat redacted state,<br/>legal actions, events"| IN
```

Three properties of this decomposition are deliberate:

1. **3.1 runs before 3.2.** A stale `expectedVersion` is rejected before any rule is evaluated, so a
   conflicting request costs a version read and nothing more (FR-61).
2. **3.4 is the only source of randomness,** and it returns the new random-source position to 3.3, which
   hands it to 3.6 for persistence. Determinism is a data-flow property here, not a coding convention.
3. **3.7 redacts after commit.** The stored state is complete; only the *view* is reduced (FR-62). One
   stored truth, many redacted views.

## 4.9 Sequence Diagrams

### 4.9.1 Human action — the normal path

```mermaid
sequenceDiagram
    autonumber
    actor Player
    participant C as Client
    participant API as OrderAndConquest.Api
    participant E as Engine
    participant DB as PostgreSQL
    participant Hub as SignalR hub

    Player->>C: taps target territory
    C->>API: POST /matches/{id}/actions<br/>{action, expectedVersion}
    API->>DB: read snapshot + version
    DB-->>API: state, version, rng_seed, rng_position
    alt version mismatch
        API-->>C: 409 Conflict + current state
        C->>C: re-render, discard input
    else version matches
        API->>E: Legal(state)
        E-->>API: legal actions
        alt action not in legal set
            API-->>C: 422 + reason (no state change)
        else action legal
            API->>E: Apply(state, action)
            E-->>API: new state + events + rng_position
            API->>DB: begin transaction, update snapshot, append move, commit
            DB-->>API: version + 1
            API-->>C: 200 {state, legal, events, version}
            API->>Hub: broadcast StateChanged, DiceRolled
            Hub-->>C: events to every connected seat
        end
    end
```

### 4.9.2 AI turn

```mermaid
sequenceDiagram
    autonumber
    participant API as OrderAndConquest.Api
    participant E as Engine
    participant A as Agent (MarsBot)
    participant DB as PostgreSQL
    participant Hub as SignalR hub

    loop while current seat is Ai
        API->>E: Legal(state)
        E-->>API: legal actions
        API->>A: ChooseAction(state, legal)
        note over A: scores attacks by expected value<br/>winChance x V(won) + (1-winChance) x V(lost)<br/>NEVER rolls dice while scoring
        A-->>API: one action from the list
        API->>API: wait out minimum think time<br/>(API layer, not the agent)
        API->>E: Apply(state, action)
        E-->>API: new state + events
        API->>DB: persist snapshot + append move
        API->>Hub: broadcast events
    end
    API->>Hub: TurnChanged
```

The note on the agent is the single most important line in this diagram. An agent that called `Apply`
speculatively to see what happens would consume the match random source, and the dice the player then
sees would differ from the dice they would have seen. Scoring is by expected value precisely so that
evaluation has no side effect.

### 4.9.3 Pass-and-play hand-over

```mermaid
sequenceDiagram
    autonumber
    actor P1 as Player A (outgoing)
    actor P2 as Player B (incoming)
    participant C as Client
    participant API as OrderAndConquest.Api
    participant Hub as SignalR hub

    P1->>C: End Turn
    C->>API: POST /actions {EndTurn}
    API->>API: advance turn, next seat is LocalHuman
    API->>Hub: HandOverDevice { toSeat: B }
    Hub-->>C: HandOverDevice
    C->>C: clear ALL hand data from view immediately
    C->>P2: blocking screen "Pass to Player B"
    P2->>C: Ready
    C->>API: GET /matches/{id}/state?seat=B
    API->>API: redact — B's cards only
    API-->>C: state redacted for B
    C->>P2: render board and B's hand
```

### 4.9.4 Resume

```mermaid
sequenceDiagram
    autonumber
    actor Player
    participant API as OrderAndConquest.Api
    participant DB as PostgreSQL
    participant E as Engine

    Player->>API: GET /players/{id}/matches?resumable=true
    API->>DB: select unfinished matches for this user
    DB-->>API: match list
    API-->>Player: match list
    Player->>API: GET /matches/{id}/state?seat=n
    API->>DB: read matches, seats, territory_state, cards
    note over API,DB: snapshot only — the move log is NOT replayed
    DB-->>API: snapshot + rng_seed + rng_position
    API->>API: reconstruct RNG, advance to rng_position
    API->>E: Legal(state)
    E-->>API: legal actions
    API-->>Player: redacted state + legal actions + version
```

## 4.10 State Diagrams

### 4.10.1 Match lifecycle

```mermaid
stateDiagram-v2
    [*] --> Lobby : match created, version 1
    Lobby --> Setup : all seats filled
    Lobby --> Abandoned : host cancels
    Setup --> InProgress : all territories allocated<br/>and starting armies placed
    InProgress --> InProgress : action applied, version + 1
    InProgress --> Finished : one seat owns every territory
    InProgress --> Finished : round cap reached,<br/>rank by territory count
    InProgress --> Abandoned : all human seats leave
    Finished --> [*]
    Abandoned --> [*]

    note right of InProgress
        Snapshot and move log are written
        in one transaction per action.
        Resume re-enters InProgress
        from the snapshot.
    end note
```

### 4.10.2 Turn phase machine

```mermaid
stateDiagram-v2
    [*] --> Claim : allocation = claim
    [*] --> Draft : allocation = random

    Claim --> Claim : place one army,<br/>next seat
    Claim --> Draft : every territory claimed<br/>and every army placed

    Draft --> Draft : place armies
    Draft --> Draft : trade set<br/>(mandatory at 5+ cards)
    Draft --> Attack : army pool empty

    Attack --> Occupy : defender reduced to 0
    Attack --> Attack : attack resolved,<br/>no capture
    Attack --> Fortify : player declines further attacks
    Occupy --> Attack : armies moved in
    Occupy --> GameOver : attacker owns every territory

    Fortify --> EndTurn : one move made, or declined
    EndTurn --> Draft : next seat,<br/>card awarded if conquered
    EndTurn --> GameOver : round cap reached

    GameOver --> [*]
```

**Air Force and Naval Force add no state.** They are additional transitions out of `Attack` into the same
`Occupy`, which is why this machine is identical to the classic-RISK one. If the extensions had needed a
new phase, that would have been the signal that they were too large — and the diagram is how that would
have been visible.

---

**Previous:** [3 — Requirement Analysis](03-requirements.md) · **Next:** [5 — System Design](05-system-design.md)
