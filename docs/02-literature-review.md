# 2 — Literature Review and Related Systems

> **Sourcing note (prompt §39).** This chapter distinguishes three things throughout: facts drawn from a
> cited source, observations about systems examined directly, and this project's own positioning. No
> performance figure appears here that is not attributed. Where a source was not retrievable in full,
> that is stated rather than paraphrased around. Full citations: [12 — References](12-references.md).

## 2.1 Strategy Games

Strategy games divide broadly by how time is handled and by how much information players share.

| Axis | Categories | Where Order & Conquest sits |
|---|---|---|
| Time | Real-time · turn-based | **Turn-based.** State changes only when a player acts; there is no tick loop |
| Information | Perfect · imperfect | **Near-perfect.** The board is fully visible; only opponents' cards are hidden |
| Determinism | Deterministic · stochastic | **Stochastic.** Combat is resolved by dice |
| Players | Two-player · multiplayer | **2–6 seats** |

This placement has direct engineering consequences and is worth stating for that reason rather than as
taxonomy.

Turn-based pacing means the naive authoritative-server model is sufficient. Gambetta's treatment of
client-server game architecture notes explicitly that the naive approach — client sends input, server is
authoritative, client renders the response — is *"fine for slow turn based games"*, and that prediction,
rollback and interpolation exist to hide latency in real-time games. A turn-based game absorbs the round
trip. That single observation removes a large class of complexity from this project, and it is why §5.1
contains no prediction layer.

Near-perfect information means redaction is narrow and tractable: the server must hide opponents' card
identities and nothing else. A full fog-of-war model would require per-seat visibility computation on
every state read; hiding one collection does not.

Stochastic combat means the random source must be part of the persisted state, not incidental to it.
This is the origin of the `rng_seed` / `rng_position` design in §6 — a deterministic game could be
replayed from its action log alone, but a stochastic one cannot.

## 2.2 Territory-Conquest Games

The territory-conquest subgenre shares a recognisable core: a map partitioned into regions, ownership of
regions as the unit of progress, army counts as the unit of strength, and adjacency as the constraint on
action. Within that frame, systems differ mainly in three places — how reinforcements are calculated,
how combat is resolved, and what additional levers exist beyond moving armies.

| Design lever | Common approaches | Order & Conquest |
|---|---|---|
| Reinforcement | Proportional to territories · fixed income · resource-driven | Proportional (`max(3, ⌊t/3⌋)`) plus continent bonuses plus card trades |
| Combat | Dice · deterministic strength comparison · simultaneous resolution | **Dice**, defender wins ties — unchanged from classic RISK |
| Movement | Adjacency-only · path-based · transport-based | Adjacency, plus two extensions: land-range-5 (Air Force) and sea routes (Naval Force) |
| Additional levers | Cards · tech trees · diplomacy · economy | **Cards only** |

The last row is the one that matters for scope. Every additional lever multiplies the state space, the
UI surface, the test matrix and the AI's action space simultaneously. This project adds exactly one new
edge type and two new actions and adds no new resource, currency or unit type — a decision recorded as
D-09 and D-12 and enforced by the checklist in `docs/14-implementation-safety-checklist.md`.

## 2.3 Classic RISK

Classic RISK supplies the rule baseline. The numbers below are taken from published rule descriptions
(Wikipedia; UltraBoardGames) and are the values implemented in `shared/rules.json`.

### Board

42 territories across 6 continents, connected by 83 adjacency edges.

| Continent | Territories | Borders | Bonus | MARS static value |
|---|---|---|---|---|
| North America | 9 | 3 | 5 | 0.185 |
| South America | 4 | 2 | 2 | 0.250 |
| Europe | 7 | 4 | 5 | 0.179 |
| Africa | 6 | 3 | 3 | 0.167 |
| Asia | 12 | 5 | 7 | 0.117 |
| Australia | 4 | 1 | 2 | **0.500** |

Static value is `V_bonus / (V_size × V_borders)` from the MARS paper — reinforcement per unit of
defensive cost. It is reproduced here because it is the single most useful design constant in the
project: Australia scores four times Asia, which is the quantitative statement of why Australia is the
standard opening target, and it is also what makes procedurally generated continent bonuses derivable
rather than guessed (§5.7).

*(Values computed from `shared/maps/world_classic.json`; they reproduce the figures in the project's
own research notes.)*

### Setup

| Players | Starting armies |
|---|---|
| 3 | 35 |
| 4 | 30 |
| 5 | 25 |
| 6 | 20 |

Two-player RISK uses a neutral third force. Order & Conquest implements this as a third `Neutral` seat
rather than as a special rule (decision D-07), so the 3-player row applies with no special case.

### Turn structure

1. **Reinforce** — `armies = max(3, ⌊territories held / 3⌋) + continent bonuses + card trade value`
2. **Attack** — repeatedly, while legal
3. **Fortify** — one move, then the turn ends

### Combat

- The attacker needs at least 2 armies in the attacking territory, and **one more army than dice rolled**.
- Attacker rolls 1–3 dice; defender rolls 1–2.
- Highest die is compared with highest, second with second. **The defender wins ties.**
- On capture, the attacker moves in at least as many armies as dice rolled, leaving at least 1 behind.

The exact single-battle probabilities, used as test oracles in §9.2:

| Matchup | Attacker wins |
|---|---|
| 1 vs 1 | 15 / 36 |
| 2 vs 1 | 125 / 216 |
| 3 vs 1 | 855 / 1296 |
| 1 vs 2 | 55 / 216 |
| 3 vs 2 (attacker takes both) | 2890 / 7776 |

These fractions exist in this document for a specific reason. Defender-wins-ties is a one-line rule
whose inversion shifts every probability above by several percent, is invisible during play, and would
silently corrupt every agent trained against it. Asserting the fractions catches it in seconds
(TC-CMB-06).

### Cards

44 cards: 42 territory cards plus 2 wilds. One card is awarded per turn, and **only if the player
captured at least one territory** that turn. A set is three cards: three alike, three different, or two
plus a wild. Trading is forced at 5 cards held; a player who exceeds 5 after eliminating an opponent
must trade down. A player trading a set who owns a named territory on one of the cards receives +2
armies on that territory, capped at 2 per turn.

Trade values escalate: **4, 6, 8, 10, 12, 15, 20, 25**, then +5 each time. Of these, 4, 6, 8, 20 and 25
are explicitly attested in the consulted sources; 10, 12 and 15 are inferred from the sequence. This is
precisely why the table lives in `shared/rules.json` as data rather than in code (decision D-15) — the
inferred values can be corrected without a rebuild.

### Victory

World domination — control of every territory. Secret-mission variants exist and are not implemented
(D-26).

## 2.4 Related Student Project — *Risk Conquest* (2022)

A prior BSCS final-year project at the same institution implemented a digital RISK. It is used here as a
**historical reference**, per the authority order in `00-decisions-and-assumptions.md`, and not as a
specification.

### What it contributes

| Contribution | Use in this project |
|---|---|
| Requirement structure and use-case specification template (Use Case Name / Actors / Summary / Pre-condition / Post-condition / Basic Path / Alternative Path / Business Rules / NFRs) | Adopted directly in §4.3, for continuity with institutional expectations |
| Three AI personalities — Passive, Chaotic, Aggressive | Adopted as Stage-1 agents (§5.6), with the behaviour definitions kept |
| Screen inventory (splash, account creation, avatar, main menu, create/join room, game settings with AI difficulty, waiting room, claim, draft, attack, fortify, card bonus) | Used as the baseline for §5.3, extended with the screens the new capabilities require |
| Pseudocode conventions | Followed in `appendices/E-pseudocode.md` |

The three personalities deserve a specific note. ChaoticBot — a uniformly random legal agent — is not
filler. It is the baseline every stronger agent must beat, it exercises code paths scripted bots never
reach, and it is the fastest opponent available for a 10,000-match smoke test. It earns its place on
engineering grounds, independent of its provenance.

### What is deliberately not carried forward

| 2022 approach | This project | Reason |
|---|---|---|
| Passwords stored in a plaintext `p_Password` column | Argon2id PHC-format hashes | A plaintext credential store is a defect, not a design choice (D-23) |
| A denormalised `Map` table carrying per-match board state | `matches.effective_map` (frozen JSON) + `territory_state` + `seats` | The original shape cannot represent a second concurrent match on the same map, and cannot be replayed |
| Rules implemented within the client | One server-side engine | §1.2; the root cause of duplication, non-replayability and non-reusable AI |
| Claim-phase troop count given as 38 in §3.2 and 30 in the Annexure | Sourced starting-army table (35/30/25/20) | An internal contradiction; recorded as D-06 |
| Free-text chat implied by "View/Send Messages" | Preset messages only, and optional | Less to moderate; the report itself specifies preset messages and emoji (D-25) |

Recording these is not criticism for its own sake. Prompt §39 requires distinguishing source facts from
design decisions, and an evaluator comparing the two documents will find the differences regardless.

## 2.5 AI in Strategy Games

Approaches to game-playing AI divide by how much of the work is done by search and how much by an
evaluation of position.

| Approach | Fit for RISK |
|---|---|
| Rule-based / scripted behaviour | Ships immediately; predictable; a competent player beats it quickly |
| Evaluation function + shallow search | Good fit — the position value is the hard part, and RISK positions are amenable to feature-based scoring |
| Deep search (minimax, alpha-beta) | Poor fit — stochastic combat and an enormous branching factor undermine deterministic search |
| Monte Carlo Tree Search | Plausible but expensive; each playout is a full match |
| Learned policy (deep RL) | Promising, and the subject of §2.6; not required for playability |

**The branching factor is the governing fact.** The MARS paper reports RISK as having approximately
3.3 × 10²⁴ distinct opening positions, against roughly 400 for chess. Deterministic deep search is not
available at that scale, which moves the burden onto position evaluation.

### MARS (Johansson & Olsson, 2006)

The most directly applicable published work. A multi-agent-system RISK bot in which each territory is an
agent bidding for reinforcements, coordinated by a position-value function:

```
V = P_sv + P_fn + P_fnu + P_en + P_enu + P_cb + V_bonus × (V_cp + P_oc + P_eoc)
```

with tuned coefficients (`C_sv` 70, `C_fn` 1.2, `C_en` −0.3, `C_fnu` 0.05, `C_enu` −0.03, `C_cb` 0.5,
`C_oc` 20, `C_eoc` 4) and behaviour knobs (`W_p` 0.7375 — the minimum win probability required to
attack; `W_p1` 0.25; `P_db` 3.5; `P_ob` 170; `G_l` 5).

**Reported result:** MARS agents placed first or second in 507 of 792 matches.

Two things are taken from this paper. The first is the evaluation function itself, implemented directly
as `MarsBot` (§5.6). The second is `W_p`, which turns out to be the project's difficulty dial: raising it
produces a cautious opponent and lowering it a reckless one, both through one code path. The paper also
supplies the 100-round cap used to terminate AI-versus-AI matches, without which training runs do not
reliably end.

## 2.6 Reinforcement Learning

### The record is mostly negative, and this matters

The MARS paper notes that an earlier attempt to apply temporal-difference learning to RISK (Keppler &
Choi, 2000) trained *"without significant success."* That is the honest state of the field for this
specific game, and it is the reason reinforcement learning is optional in this project rather than
central.

### The one clear success

Carr (2020) reports a RISK agent achieving a **35% win rate against the five strongest Lux Delux AIs**.
With six players and uniform chance, the baseline is 16.7%, so this is roughly double chance against
strong opposition.

The method matters more than the number: the network was used as a **position evaluator inside a game-
tree search**, over a graph convolutional network trained with TD(λ) — not as a policy selecting moves
directly. That is a strong hint about which architecture shape works for this game, and it is
incorporated into §5.6 as the reason the value head is treated as load-bearing.

> **Retrieval gap, stated (prompt §39).** The paper's specific layer sizes, search depth and training
> budget were not retrievable during this project's research phase. The architecture in §5.6 and
> `docs/08-implementation-plan.md` §8.9 is therefore *informed by* Carr's reported approach, not
> reproduced from it. No claim is made that this project replicates that result.

### Why a graph neural network rather than a fixed-width network

The obvious encoding — 42 territories × (owner, armies) into a 126-input MLP — fails on this project's
own feature set:

- A procedurally generated map may have 60 territories, or 24.
- The RL curriculum deliberately starts on small generated maps and scales up.
- Optional submersion, if enabled, changes the count per match.

A fixed-width input layer cannot represent a varying node count. A graph neural network can, because its
parameter count is independent of the number of nodes — which also means the *same weights* train
through the entire curriculum with no architecture change. Carr's use of a graph convolutional network
for the same game is corroborating rather than merely fashionable.

### Algorithm selection

PPO is chosen over TD(λ) and DQN for three reasons: it handles a multi-head factored action space
naturally, it is stable enough to train unattended (which matters when the same team is building three
clients), and it is the best-documented option, so debugging it is tractable.

### Expected cost, stated up front

Self-play on a game this size is realistically **tens of millions of steps** before an agent reliably
beats a tuned evaluation function — days to weeks of wall-clock on a desktop CPU. This is stated here
rather than discovered later, and it is exactly why §1.4 makes O8 optional and gates it on beating
MarsBot head-to-head.

## 2.7 Research Gap and Project Positioning

### The gap

Across the systems and literature reviewed, three gaps recur.

1. **Rules engines are not separable.** Commercial implementations are closed; student implementations
   put rules in the UI. In neither case can the rules be reused as a simulation environment, which is
   the precondition for training or evaluating an agent against the real game.
2. **Published RISK AI work assumes the classic 42-territory board.** MARS's evaluation function and
   Carr's encoder are both presented on the fixed board. Neither addresses variable-size maps, which is
   where a graph encoding stops being a preference and becomes a requirement.
3. **Extensions to RISK are rarely scoped.** Air and naval forces are usually added as new unit types
   with their own movement and combat rules, which changes the game's character and multiplies the
   implementation surface.

### This project's position

| Gap | Response | Where |
|---|---|---|
| Rules not separable | A pure, I/O-free, deterministic engine that is simultaneously the game's rules, the AI's environment and the RL environment — one implementation, three consumers | §5.4 |
| Fixed-board assumption | A graph-based state encoder, driven by variable territory counts arising from procedural generation | §5.6 |
| Unscoped extensions | Air Force and Naval Force implemented as **modifications to the adjacency test**, not as new unit types. Two new actions, one new edge type, zero new combat systems | §7.8–§7.10 |

### What is not claimed

Prompt §39 forbids fabricated research claims, so the boundaries are stated explicitly:

- No claim that this project advances the state of the art in reinforcement learning.
- No claim to reproduce Carr's 35% result. The RL component is optional and gated (O8).
- No performance or AI win-rate figures appear anywhere in this package before they are measured.
  §10.3 and §10.4 are **templates**, and they are labelled as such.
- The capability mapping in `appendices/D-capability-mapping-decision-table.md` is a game-design
  decision presented for team review, not a factual or historical claim about real forces (prompt §13).

The contribution offered is engineering, not research: a correct, deterministic, testable RISK
implementation with a bounded extension set, built so that the same rules serve play, AI and learning
without divergence.

---

**Previous:** [1 — Introduction](01-introduction.md) · **Next:** [3 — Requirement Analysis](03-requirements.md)
