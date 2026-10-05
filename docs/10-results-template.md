# 10 — Results

> **This chapter is a template. It contains no results.**
>
> Every table below has empty cells. They are filled in Phase 14 from measured runs, with the machine,
> commit and date recorded. Nothing here is estimated, projected, illustrative or "expected".
>
> The specification is explicit (§39): no invented performance results, no invented AI accuracy or win
> rates, and a clear distinction between planned and completed work. A results chapter written before the
> results exist would undermine every factual claim in chapters 2 to 9 — including the ones that *are*
> sourced and verifiable.
>
> **How to use this chapter.** Fill each table from a real run. Where something was not built, write "not
> implemented" and say so in §10.1. Where a target was missed, record the measurement anyway — a missed
> target honestly reported is a finding; a missing row is a gap in the evidence.

## 10.1 Final System

### What was built

One row per component. `Status` is one of **Complete**, **Partial**, **Not implemented**. Nothing else —
"mostly working" is not a status.

| Component | Phase | Status | Notes |
|---|---|---|---|
| `OrderAndConquest.Engine` — pure rules | 2, 4, 11 | | |
| Classic 42-territory map and validator | 3 | | |
| Debug renderer | 3 | | |
| Core RISK rules | 4 | | |
| Persistence (PostgreSQL) | 6 | | |
| REST API | 6 | | |
| SignalR realtime | 6 | | |
| Heuristic AI — PassiveBot | 7 | | |
| Heuristic AI — ChaoticBot | 7 | | |
| Heuristic AI — AggressiveBot | 7 | | |
| Heuristic AI — MarsBot | 7 | | |
| Unity client | 8 | | |
| Godot client | 9 | | |
| Flutter + Flame client | 10 | | |
| Capability system | 11 | | |
| Air Force | 11 | | |
| Naval Force | 11 | | |
| Sea routes | 11 | | |
| Procedural map generation | 12 | | |
| Map artwork | 12 | | |
| RL simulation environment *(optional)* | 13 | | |
| PPO training pipeline *(optional)* | 13 | | |
| ONNX inference agent *(optional)* | 13 | | |

### Requirements met

| | Count | Of | % |
|---|---|---|---|
| Mandatory FRs implemented | | 70 | |
| Should-have FRs implemented | | 8 | |
| Optional FRs implemented | | 5 | |
| NFRs verified | | 24 | |

Any mandatory requirement not implemented is listed here individually with the reason. An unexplained gap
in a mandatory requirement is the single most important thing a reader of this chapter needs to find.

| Unmet requirement | Why | Consequence |
|---|---|---|
| | | |

### Screens delivered

Against the S-01…S-20 inventory of §5.3, per client. The four extension screens — S-05 sea-route
configuration, S-12 Air Force targeting, S-13 Naval Force action, S-16 capability panel — are called out
separately because they are the ones added by Phase 11.

| Client | Core screens (of 16) | Extension screens (of 4) |
|---|---|---|
| Unity | | |
| Godot | | |
| Flutter + Flame | | |

## 10.2 Gameplay

### Matches played for evaluation

| Configuration | Matches | Seeds | Completed | Average rounds |
|---|---|---|---|---|
| 2 seats + Neutral, classic | | | | |
| 3 seats, classic | | | | |
| 4 seats, classic | | | | |
| 5 seats, classic | | | | |
| 6 seats, classic | | | | |
| 4 seats, generated | | | | |
| 4 seats, classic, sea routes at maximum | | | | |

"Completed" counts matches that ended by domination. The gap between matches played and matches completed
is the round-cap rate, and it is a number worth reporting rather than hiding: a high rate means the agents
are too cautious, which is a finding about the AI, not a defect in the rules (§7.12).

### Round-cap terminations

| Configuration | Reached round cap | % |
|---|---|---|
| | | |

### Rule behaviour observed in play

Not performance — correctness in real matches, which is what a demonstration shows.

| Observation | Measured |
|---|---|
| Matches in which an Air Force attack was used | |
| Matches in which a naval attack was used | |
| Matches in which a naval fortification was used | |
| Matches in which a seat lost Naval capability by losing a coastal territory | |
| Matches in which a forced card trade occurred | |
| Air Force attacks that created a disconnected pocket (§7.8) | |

The last row exists because the disconnected pocket is documented intended behaviour, and showing it
happening in real matches is the cheapest evidence that the locked rule was implemented as specified
rather than quietly softened.

### Average match duration

| Configuration | Wall-clock, human play | Wall-clock, AI only |
|---|---|---|
| | | |

## 10.3 AI

> **No win rate, accuracy figure or strength claim may be entered here before the tournament has been
> run.** If Phase 13 was not reached, the honest content of this section is the heuristic tournament plus
> a statement that RL was not completed — which is a legitimate result, not a failure to report.

### Heuristic tournament

Round-robin, seeded, on both map kinds. Cell = row agent's win rate against the column agent.

| | PassiveBot | ChaoticBot | AggressiveBot | MarsBot |
|---|---|---|---|---|
| **PassiveBot** | — | | | |
| **ChaoticBot** | | — | | |
| **AggressiveBot** | | | — | |
| **MarsBot** | | | | — |

| Parameter | Value |
|---|---|
| Matches per pairing | |
| Seeds used | |
| Seat counts | |
| Map kinds | |

### Invalid-action rate

| Agent | Actions taken | Invalid | Rate |
|---|---|---|---|
| PassiveBot | | | |
| ChaoticBot | | | |
| AggressiveBot | | | |
| MarsBot | | | |
| Trained policy *(optional)* | | | |

**The target is exactly zero (NFR-20), and any non-zero value is a defect, not a statistic.** An agent
selects from the `Legal` list, so a non-zero rate means the list and the validator disagree — which is a
bug in the engine, not in the agent.

### RL training — optional

| Field | Value |
|---|---|
| Curriculum stages completed | |
| Total environment steps | |
| Wall-clock training time | |
| Hardware | |
| Final checkpoint | |
| Fortify mode trained under | |

| Stage | Seats | Map | Cards | Steps | Win rate vs MarsBot at stage end |
|---|---|---|---|---|---|
| 1 | 2 | 12-territory generated | Off | | |
| 2 | 3 | 24-territory generated | On | | |
| 3 | 4 | Classic 42 | On | | |
| 4 | 3–6 | Classic + generated | On | | |

### The evaluation gate

> The trained policy ships as the default opponent **only** if it beats `MarsBot` over a pre-registered
> number of seeded matches. Otherwise `MarsBot` remains the default and the RL component is reported as
> experimental (§8.9).

| Field | Value |
|---|---|
| Pre-registered match count | *(fixed before the evaluation run, not after)* |
| Trained policy win rate vs MarsBot | |
| Gate met? | |
| Default shipped opponent | |

Recording the match count *before* the run is the whole point of the word "pre-registered". Choosing the
sample size after seeing the outcome is how an inconclusive result becomes a claimed one.

### Inference latency — optional

| Measurement | Value |
|---|---|
| Mean per action, CPU | |
| p95 per action, CPU | |
| NFR-07 target | 50 ms |
| Met? | |

## 10.4 Performance

Every row is a requirement with a number in it. The measurement is the evidence that the requirement holds.

| NFR | Target | Mean | p95 | Met? |
|---|---|---|---|---|
| NFR-04 | `Legal` on the classic map < 100 ms | | | |
| NFR-05 | Action round trip on localhost < 250 ms | | | |
| NFR-06 | Heuristic agent decision < 500 ms | | | |
| NFR-07 | Trained-policy inference < 50 ms CPU *(optional)* | | | |
| NFR-08 | 100-round action log returned < 2 s | | | |

### Reference machine

| Field | Value |
|---|---|
| CPU | |
| RAM | |
| OS | |
| .NET version | |
| PostgreSQL version | |
| Storage | |

The reference machine must be recorded, because "under 100 ms" without a machine is not a verifiable claim.
NFR-04 and NFR-06 are stated against the development machine deliberately (§3.3) — this is a student
project, not a service with a capacity target.

### Simulation throughput

Relevant only if Phase 13 was reached; it is the number that determines whether training is feasible at
all.

| Measurement | Value |
|---|---|
| Matches per second, single thread, `ChaoticBot` vs `ChaoticBot`, classic map | |
| Matches per second, all cores | |
| Peak memory during a simulation run | |

### Database

| Measurement | Value |
|---|---|
| Action apply transaction, p95 | |
| Match load (snapshot), p95 | |
| Full replay of a 100-round match | |
| `matches` row size with a frozen classic `effective_map` | |
| `matches` row size with a frozen generated map | |

The last two rows matter for one reason: the whole six-table schema rests on the frozen map being a
reasonable size to store per match (§6.1). If it is not, the decision is worth revisiting, and the
measurement is what would tell us.

## 10.5 Screenshots

> Screenshots are captured in Phase 14 and placed in
> [`appendices/H-additional-diagrams-and-screenshots.md`](../appendices/H-additional-diagrams-and-screenshots.md).
> This section lists the required set so that nothing is missed while a build is available, and so that the
> same scenes are captured from all three clients and are actually comparable.

Each screenshot is captured from **every client that implements the screen**.

| # | Screen | Screen ID | Must show |
|---|---|---|---|
| 1 | Sign in / Register / Guest | S-02 | The guest path, which needs no account (D-24) |
| 2 | Main menu | S-03 | The in-progress list with a resumable match |
| 3 | Match setup | S-04 | Seat kinds including an AI seat; the **dice-faces** and **attack-range** steppers at their defaults |
| 4 | Map selection | S-04 | Classic and at least one generated map |
| 5 | Sea-route configuration | **S-05** | The count selector with its min/max bounds visible |
| 6 | Lobby — seat list | S-06 | A 2-player configuration showing the third `Neutral` seat |
| 7 | Claim phase | S-07 | Unclaimed territories selectable, everything else inert |
| 8 | Game board — classic | S-08 | Ownership colours, army counts, sea routes drawn distinctly from land edges |
| 9 | Game board — generated map | S-08 | A different territory count |
| 10 | Reinforcement | S-09 | The computed army count and its breakdown |
| 11 | Card hand and trade | S-10 | A valid three-card set and the escalation value offered |
| 12 | Attack — target selection | S-11 | Only legal targets highlighted (FR-66) |
| 13 | Dice resolution | S-11 | The dice faces from the `DiceRolled` event, and a tie resolved to the defender |
| 14 | **Dice resolution at `diceSides = 7`** | S-11 | **Numeral faces including a 7** — the only visual evidence for D-29 / FR-84 |
| 15 | Air Force targeting | **S-12** | The reachable set at range 5, with an unreachable territory visible for contrast |
| 16 | Naval Force action | **S-13** | A target reachable only across a sea route |
| 17 | Occupy | S-14 | The minimum-armies bound equal to the dice rolled (DR-06) |
| 18 | Fortification | S-15 | A naval fortification, labelled as crossing a sea route |
| 19 | Capability panel | **S-16** | A seat holding Air Force but not Naval, or the reverse |
| 20 | Hand-over | S-17 | The blocking screen, with the outgoing seat's hand already cleared |
| 21 | Game over | S-18 | Both a domination result and a round-cap ranking |
| 22 | Replay viewer | S-19 | A logged attack replayed with its original dice faces |
| 23 | Settings — this match | S-20 | Dice faces and attack range shown **read-only** |
| 24 | Three clients, one match | — | The same board state in Unity, Godot and Flutter side by side |
| 25 | Debug renderer | — | The Phase 3 board, to evidence that rules were playable before artwork |

S-01 (Splash) is deliberately not captured: it carries branding and a connectivity check, and
evidences nothing. Every other screen in the §5.3 inventory appears above.

Screenshots 14, 15, 16 and 24 are the ones a reader will look for. 15 and 16 are the only visual
evidence that the locked extensions behave as specified; **14 is the only visual evidence for the
configurable dice face count**, which is the question the supervisor actually asked; 24 is the only
visual evidence for the three-client architecture claim, and it is the single most persuasive image
this project can produce.

Screenshot 25 evidences a process claim rather than a feature — that the core was playable before
art existed (§8.10). It is worth keeping even after the artwork lands.

---

**Previous:** [9 — Testing](09-testing.md) · **Next:** [11 — Conclusion and Future Work](11-conclusion-and-future-work.md)
