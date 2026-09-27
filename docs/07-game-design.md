# 7 — Game Design and Rules

> **Deliverable D.** The complete rule set: classic RISK as implemented, plus the three locked
> extensions. Every tunable number here is data in
> [`shared/rules.json`](../shared/rules.json), not a literal in code (NFR-16).
>
> **Scope statement.** The extensions add **two actions** and **one edge type**. There is no new unit
> type, no second combat system, no fuel, no transport, no hit points and no economy.

## 7.1 Rules

Order & Conquest implements classic RISK. Two to six seats compete to control every territory on a
connected map. On a turn a seat receives reinforcements, places them, attacks as often as it likes,
optionally fortifies once, and ends the turn — receiving a card if it captured anything.

| Element | Value | Source |
|---|---|---|
| Seats | 2–6 | Sourced |
| Classic board | 42 territories, 6 continents, 83 land edges | Sourced, verified against the data file |
| Starting armies | 3 seats → 35, 4 → 30, 5 → 25, 6 → 20 | Sourced |
| Two-seat variant | A third `Neutral` seat; the 3-seat row applies | D-07 |
| Territory allocation | Seat-by-seat claim, or seeded random | Configurable |
| Victory | World domination | Sourced |
| Round cap | 100 | Sourced (MARS) |
| Cap tiebreak | Highest territory count | Assumption |

### The `Neutral` seat

A `Neutral` seat owns territories and defends them at full strength, but never drafts, attacks, fortifies
or holds cards. It exists so that the two-player variant needs **no special rule** — only a seat
configuration (D-07). The turn loop skips it.

### The four rule objects

Everything below is built from exactly four things. Naming them here is what keeps the rest of the
chapter from growing:

| Object | What it is | Section |
|---|---|---|
| **Territory** | A node. Owned by exactly one seat, holding ≥ 1 army | §7.3 |
| **Army** | A counter standing on a territory. Identical to every other army | §7.4 |
| **Card** | A claim on reinforcements, carrying a symbol | §7.6 |
| **Edge** | A connection between two territories: land adjacency, or a sea route | §7.3, §7.10 |

There is no fifth object. Air Force and Naval Force are **capabilities held by a seat** (§7.7), not
objects on the board, and that is the single decision that keeps the extension set small.

## 7.2 Turn System

```
Draft  →  Attack  →  (Occupy)  →  Fortify  →  End turn
```

| Phase | What happens | Exit condition |
|---|---|---|
| **Claim** *(setup only)* | Seats claim unowned territories in order, then place remaining armies | Every territory owned, every starting army placed |
| **Draft** | Compulsory trade if holding 5+ cards; optional trade otherwise; place all reinforcements | Army pool empty |
| **Attack** | Any number of land, Air Force or Naval attacks | Seat declines further attacks |
| **Occupy** | Move armies into a captured territory | Armies moved |
| **Fortify** | One army movement between two owned territories | Move made or declined |
| **End turn** | Award one card if anything was captured; advance to the next active seat | — |

The phase order is fixed and there is **no new phase** for either extension. An Air Force attack and a
Naval attack are additional legal actions inside the existing `Attack` phase; a naval fortification is an
additional legal action inside the existing `Fortify` phase. The state machine in §4.10.2 is the
authoritative version of this table.

`Occupy` is entered only when an attack empties a defending territory, and is left as soon as the
armies are moved. It is a phase rather than part of the attack action because the number of armies moved
is a player decision that needs its own submission and its own legality check (§7.4).

### Round counting

A **round** is one full cycle through every active seat. The round counter increments when the turn
passes back to the lowest-indexed active seat, and it is what the round cap measures (§7.12). Eliminating
a seat mid-round does not restart the count.

## 7.3 Territory System

A **territory** is the only ownable object in the game. It has an owner, an army count, and a fixed
position in the map graph. Everything else about it is immutable map data.

| Property | Mutable? | Where it lives |
|---|---|---|
| Owner seat | **Yes** | `territory_state.owner_seat` |
| Army count | **Yes** | `territory_state.armies` |
| Key, name, continent | No | `matches.effective_map` |
| Land neighbours | No | `matches.effective_map` |
| Coastal flag | No | `matches.effective_map` |
| Card symbol | No | `matches.effective_map` |
| Capability profile | No | Derived from the two fields above (§7.7) |

Two rules hold at all times and are asserted after every applied action:

1. **Every territory has exactly one owner.** There is no unowned territory once the Claim phase ends.
2. **Every territory holds at least one army** (DR-04, CK-11). This is why occupation and fortification
   both have a "leave at least 1 behind" clause.

### Adjacency

Land adjacency is **symmetric and authored**: if `alaska` lists `kamchatka`, then `kamchatka` lists
`alaska`, and load-time validation rejects a map where it does not (V-04). The classic board has 83 such
edges, which the validator counts rather than trusts.

Adjacency is the substrate for three different things, and it is worth being explicit that they are not
the same question:

| Question | Edge set used |
|---|---|
| Can I attack this territory by land? | Land adjacency, distance exactly 1 |
| Can my Air Force reach it? | Land adjacency, distance 1…5 (§7.8) |
| Can I attack or fortify across water? | **Sea routes only** (§7.9, §7.10) |

### Continents

A continent is a named set of territories carrying a reinforcement bonus. A bonus is awarded only for
holding **every** territory in the continent (DR-09), checked at the start of Draft.

| Continent | Territories | Border territories | Bonus | Static value |
|---|---|---|---|---|
| North America | 9 | 3 | 5 | 0.185 |
| South America | 4 | 2 | 2 | 0.250 |
| Europe | 7 | 4 | 5 | 0.179 |
| Africa | 6 | 3 | 3 | 0.167 |
| Asia | 12 | 5 | 7 | 0.117 |
| Australia | 4 | 1 | 2 | **0.500** |

Static value is `bonus / (size × borders)` — reinforcement per unit of defensive cost (§2.3). A **border
territory** is one adjacent to a territory outside its own continent; it is the count of places the
continent must be defended. Australia's 0.500 is nearly three times the next value, and it is the reason
Australia is the standard opening target in classic play.

Static value is not decoration: it is the constant that makes generated continent bonuses derivable
rather than guessed (§7.11), and it is the term `V_bonus` scales in the MARS evaluation function (§5.6).

### Coastal status

A territory is **coastal** or **landlocked**. Coastal status is a map field, and it does exactly two
things: it puts `NavalForce` in the territory's capability profile (§7.7), and it makes the territory
eligible as a sea-route endpoint (§7.10).

| | Count | Detail |
|---|---|---|
| Coastal | 36 | Naval-capable, sea-route eligible |
| Landlocked | 6 | Alberta, Ontario, Northern Europe, Ukraine, Irkutsk, Afghanistan |

Coastal status is a **design decision, not geography** — the classic board is stylised and several
territories are arguable either way. Six landlocked territories spread across four continents is what
makes Naval capability something a seat can lose, rather than something everyone permanently has.

## 7.4 Army System

Armies are **identical and anonymous**. There is one kind of army. An army on a territory contributes to
that territory's count, defends it, and can attack from it; nothing distinguishes one army from another,
and no army belongs to a "type".

> This is the rule that the Air Force and Naval Force extensions were written *around*. Introducing an
> air unit or a naval unit would mean a second army type, a second combat interaction and a transport
> rule — precisely the scope expansion the specification forbids. Instead, **capability is a property of
> the seat, not of the armies**, so the army model stays at one type (§7.7).

### Starting armies

| Seats | Armies each |
|---|---|
| 3 | 35 |
| 4 | 30 |
| 5 | 25 |
| 6 | 20 |

A 2-player match runs as 3 seats — two players plus a `Neutral` — and therefore uses the 35 row (D-07).

During Claim, seats take turns placing one army at a time: first to claim unowned territories, then to
reinforce territories they already hold, until every starting army is placed.

### Reinforcement calculation

At the start of each Draft phase:

```
armies = max(3, ⌊territories held / 3⌋) + Σ continent bonuses + card trade value
```

| Term | Rule |
|---|---|
| Territory term | Integer division by 3, with a **floor of 3** regardless of territory count (DR-08) |
| Continent term | Full continents only (DR-09, §7.3) |
| Card term | The escalation value if a set was traded this phase (§7.6) |

The floor of 3 is what keeps a seat reduced to one or two territories able to act at all. It dominates
further than it looks: `max(3, ⌊t/3⌋)` equals 3 for every count from 1 to **11**, so the **twelfth**
territory is the first one that actually increases income.

| Territories held | 1–11 | 12–14 | 15–17 | 18–20 | … | 42 |
|---|---|---|---|---|---|---|
| Territory term | **3** | 4 | 5 | 6 | … | 14 |

The early-game consequence is worth stating plainly: taking a third, sixth or ninth territory buys
position and card progress, but **not a single extra army**. TC-DRF-02 pins the whole 1–11 range rather
than one sample, because an off-by-one here is a rule that is wrong for eleven different board states and
right for the twelfth.

### Placement

All reinforcements must be placed before the phase ends — a seat cannot bank armies between turns. Armies
may be placed on any territory the seat owns, in any distribution, with one exception: the territory
bonus from a traded card is placed **on that specific territory** (§7.6).

### Occupation

When an attack empties a defending territory, the attacker must move in **at least as many armies as dice
rolled**, and must leave at least 1 behind (DR-06). The upper bound is "all but one".

Occupation is **identical for land, Air Force and Naval captures** (D-18). There is no separate landing
rule, no reduced garrison and no beachhead penalty; the capture mechanism differs only in which target
was legal, never in what happens afterwards.

### Fortification

One fortification per turn, moving armies between two territories the seat owns, leaving at least 1
behind.

| Mode | Rule | Status |
|---|---|---|
| `single_pair` | One move between two connected owned territories | **Default** |
| `one_step_all` | Any number of moves between adjacent owned pairs | Configuration |
| `connected_path` | One move along any path of owned territories | Configuration |

Published rule sets disagree, so the mode is data (D-16). A trained RL checkpoint records which mode it
learned under and refuses to load against a different one (FR-83) — an agent trained on one movement rule
and played under another is subtly and unaccountably weaker.

**A naval fortification across a sea route consumes the same single fortification** (D-19, FR-49). A free
extra naval move would be a new mechanic.

## 7.5 Combat

**One resolution path for every attack in the game** (FR-31). Land, Air Force and Naval attacks differ
only in which targets are legal.

### Rules

1. The attacker needs ≥ 2 armies in the origin, and **at least one more army than dice rolled**.
2. The attacker rolls 1–3 dice; the defender rolls 1–2 (at most the armies present).
3. Both sets are sorted descending. Highest is compared with highest, second with second.
4. **The defender wins ties.**
5. Each comparison costs the loser one army.
6. If the defender reaches 0, the attacker occupies (§7.4).

### Exact probabilities

These are test oracles, not illustrations (TC-CMB-06):

| Attacker : defender dice | Attacker wins | Decimal |
|---|---|---|
| 1 : 1 | 15 / 36 | 0.4167 |
| 2 : 1 | 125 / 216 | 0.5787 |
| 3 : 1 | 855 / 1296 | 0.6597 |
| 1 : 2 | 55 / 216 | 0.2546 |
| 3 : 2 — attacker takes both | 2890 / 7776 | 0.3717 |

> **Why these are asserted rather than trusted.** Inverting rule 4 shifts every figure above by several
> percent. It is invisible during play, it passes every smoke test, and it silently corrupts every agent
> trained against it. A statistical assertion against these fractions catches it in seconds.

### Dice are engine-side

Every die comes from the match's injected seeded random source and is returned in a `DiceRolled` event
(FR-29). Clients animate the faces they are given; they never generate one (FR-69). This is what makes
replay exact and cheating uninteresting (§5.9).

## 7.6 Cards

### Deck

44 cards: one per territory (42) plus 2 Wilds. Each territory card carries the symbol its territory
carries in the map data.

| Symbol | Count | Grants a capability? |
|---|---|---|
| Infantry | 12 | No |
| Cavalry | 10 | No |
| Artillery | 8 | No |
| Air Force | 7 | **Yes** |
| Naval Force | 5 | **Yes** |
| Wild | 2 | No — a Wild has no territory, so it has no profile (D-20) |

### Award

At most one card per turn, and only if the seat captured at least one territory that turn (DR-11). Ten
conquests in a turn award one card, not ten.

### Sets and trading

A set is **exactly three cards** (DR-12, C-05):

- three of the same symbol, or
- three different symbols, or
- two of one symbol plus a Wild.

Six symbols do not change this. Five-card sets are explicitly excluded.

#### Two clauses that six symbols *do* change (D-27, D-28)

The three bullets above are inherited verbatim from classic RISK, where there are exactly three symbols.
With five non-Wild symbols, two of them stop being unambiguous:

| | Classic RISK (3 symbols) | Order & Conquest (5 symbols) | Decided |
|---|---|---|---|
| "three different symbols" | Identical to "one of each" — only one such combination exists | Any 3-subset of 5, or specifically Infantry + Cavalry + Artillery? | **Any three distinct** (D-27) |
| "two of one symbol plus a Wild" | The official rule is broader: *any* two cards plus a Wild | Is `{Infantry, Cavalry, Wild}` a set? Is `{X, Wild, Wild}`? | **Yes to both** — a Wild stands for any symbol (D-28) |

Both are `shared/rules.json` keys (`cards.distinctSetRule`, `cards.wildSubstitution`), so the other branch
is a data edit rather than a rewrite. Under the chosen pair, the predicate reduces to: *a three-card hand
containing at least one Wild is always a set*, and a hand with no Wild is a set when its symbols are all
equal or all distinct. The derivation is in
[`appendices/E-pseudocode.md`](../appendices/E-pseudocode.md) §E.8.1, and **TC-CRD-06** asserts whichever
branch is configured.

These are flagged rather than absorbed because they change how often a forced trade (FR-35) can be
satisfied — which is a balance property, not a formatting detail — and therefore need a reviewer's
confirmation before Phase 4.

### Escalation

| Trade | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9+ |
|---|---|---|---|---|---|---|---|---|---|
| Armies | 4 | 6 | 8 | 10 | 12 | 15 | 20 | 25 | +5 each |

4, 6, 8, 20 and 25 are sourced; 10, 12 and 15 are inferred. That is exactly why the table is data
(D-15). The position is **match-wide and monotonic** — it advances once per trade regardless of who
traded, and never resets (DR-13).

### Forced trades and the territory bonus

| Situation | Rule |
|---|---|
| Holding 5+ cards at the start of Draft | Must trade before placing anything (FR-35) |
| Holding 6+ after eliminating an opponent | Must trade down below 5 immediately (FR-36) |
| Traded a card naming a territory the seat owns | +2 armies placed directly on that territory, **capped at 2 per turn** (FR-37) |
| Eliminated an opponent | Receive all of their cards (FR-38) |

### Cards as capability

A card in hand contributes its symbol to the holder's capability set (§7.7). This is the second route to
Air Force or Naval capability and it is **temporary by construction**: trading the set spends the card
and can remove the capability the same turn. The interaction is intended — a seat can trade for
reinforcements and lose its Air Force attack in the same Draft phase, and that trade-off is the reason
card capability is interesting rather than merely additive.

## 7.7 Capability System

> **This section describes a game-design decision. It is not a factual or historical claim about real
> military forces.** The full 42-row mapping, with a review column, is
> [`appendices/D-capability-mapping-decision-table.md`](../appendices/D-capability-mapping-decision-table.md).

### Territory profiles — rule CAP-1

Every territory carries a **capability profile**, derived from two authored fields:

```
profile(t) = {Infantry}
           ∪ ({NavalForce}  if t.coastal)
           ∪ {t.cardSymbol}
```

The profile is also written explicitly into the map file and re-derived on load and asserted equal
(V-10, TC-MAP-05), so the data cannot drift from the rule.

### Seat capability — rule CAP-2

> A seat holds capability **X** if and only if it owns at least one territory whose profile contains X,
> **or** holds at least one card whose profile contains X.

Capability is **derived on demand and never stored** (FR-41). There is no capability column, no counter
and no timer, so it can never desynchronise from ownership. Losing your last coastal territory loses
Naval capability the instant the territory changes hands.

### Only two capabilities do anything

| Capability | Unlocks |
|---|---|
| Infantry | Nothing |
| Cavalry | Nothing |
| Artillery | Nothing |
| **Air Force** | The Air Force attack (§7.8) |
| **Naval Force** | Naval attack and naval fortification (§7.9) |

This is decision D-09 and it is the reason the extension set fits. In classic RISK, Infantry, Cavalry and
Artillery already have **no** mechanical difference — they are set-matching symbols. Giving them one
would be inventing unit types, which is explicitly forbidden. So the capability system has exactly two
mechanical members.

### Distribution on the classic board

| | Count | Detail |
|---|---|---|
| Coastal, therefore Naval-capable | 36 | §7.3 |
| Landlocked | 6 | Never Naval-capable from the territory itself |
| Air-capable | 7 | One per continent, two in Asia |

## 7.8 Air Force

### Locked rules

| Rule | Value |
|---|---|
| Action | Long-range attack |
| Maximum range | **5** |
| Range measured over | **Land adjacency edges only** |
| Sea routes | **Excluded from range entirely** |
| Combat | Standard dice combat, unchanged |
| Not included | Fuel, airfields, bombing, hit points, air units |

### Assumed rules

| Rule | Value | ID |
|---|---|---|
| Attacks per seat per turn | 1 | AIR-1 (D-11) |
| Minimum range | 1 — range is 1…5 inclusive | D-17 |
| Occupation | Ordinary occupy rules | D-18 |

Without a per-turn limit, the Air Force attack is a strict superset of the land attack — range 5 includes
range 1 — and the land attack becomes dead code. One integer in `rules.json` is the smallest fix that
keeps both actions meaningful.

### How far range 5 actually reaches — measured

Computed from [`shared/maps/world_classic.json`](../shared/maps/world_classic.json) over the land
adjacency graph. **The graph diameter is 10.**

| Range | Ordered pairs reachable | Share of all 1722 |
|---|---|---|
| 1 (ordinary adjacency) | 166 | 9.6% |
| 2 | 394 | 22.9% |
| 3 | 676 | 39.3% |
| 4 | 996 | 57.8% |
| **5 (the locked value)** | **1330** | **77.2%** |
| 6 | 1554 | 90.2% |
| 7 | 1650 | 95.8% |
| 8 | 1692 | 98.3% |
| 9 | 1716 | 99.7% |
| 10 | 1722 | 100.0% |

Range 5 is a **real constraint** on this board, not a formality: it leaves 22.8% of ordered pairs out of
reach. It is also a large increase over adjacency — 9.6% to 77.2%, an eightfold expansion of the target
set — which is precisely why AIR-1 exists.

### Range 5 is not worth the same everywhere

Average reach at range 5 is 31.7 of the other 41 territories, but the spread is wide:

| | Territory | Reaches at range 5 |
|---|---|---|
| Most | Ukraine | 40 of 41 |
| Least | **Eastern Australia** | **11 of 41** |

The three most distant pairs on the board — all at distance 10 — are Eastern Australia ↔ Central
America, ↔ Eastern United States and ↔ Quebec.

> **Design observation, flagged for review.** Eastern Australia is currently one of the seven
> air-capable territories, and it is the *worst* position on the board from which to use the capability.
> A seat holding only Eastern Australia's Air Force capability gains far less than one holding a central
> territory's. This may be intended — Australia is already the strongest defensive continent, so a weak
> offensive capability there is arguably balanced — or it may be an artefact of distributing one
> air-capable territory per continent. It is one data edit either way, and it is recorded as open
> question **O-04**.

### A disconnected pocket is intended behaviour

A successful Air Force attack at distance 5 captures a territory that may be adjacent to nothing else the
attacker owns. The attacker holds an isolated pocket, must garrison it from the armies moved in, and
cannot reinforce it by land fortification.

This is a **direct consequence of the locked rule, not a defect**. It is documented here so nobody
"fixes" it, and it is asserted by TC-AIR-04.

### Legality summary

An Air Force attack is offered when **all** of the following hold:

1. Phase is `Attack`.
2. The seat holds Air Force capability by CAP-2.
3. The seat has not used its Air Force attack this turn.
4. The origin is owned, holds ≥ 2 armies, and more than the dice to be rolled.
5. The target is not owned by the attacker.
6. The land-graph shortest-path distance from origin to target is between 1 and 5 inclusive, computed
   **without sea routes in the edge set**.

## 7.9 Naval Force

### Locked rules

| Rule | Value |
|---|---|
| Operates over | Sea routes |
| Enables | Movement, attack and fortification across a sea route |
| Combat | **Same** resolution as a land attack |
| Landlocked territories | **Never** automatically naval |
| Capability acquired via | Territory or card (CAP-2) |

### Assumed rule

| Rule | Value | ID |
|---|---|---|
| Units required to use a route | **0** | NAV-1 (D-12) |

Zero is the simplest implementation that satisfies the locked behaviour: a sea route behaves exactly like
a land-adjacency edge **for a seat holding Naval capability**. No naval unit type, no transport capacity,
no loading step, no second combat system.

### What Naval Force does

| Action | Rule |
|---|---|
| Naval attack | Attack across a sea route from an owned territory to one the seat does not own. Ordinary combat, ordinary occupation |
| Naval fortification | Move armies across a sea route between two owned territories — **consuming the turn's single fortification** (D-19) |

### What a sea route is not

- **Not a territory.** It cannot be owned, captured, garrisoned or counted toward reinforcement (DR-16).
- **Not usable by Air Force.** Sea routes are excluded from range measurement entirely (C-08).
- **Not free for everyone.** A seat without Naval capability sees no naval actions at all.
- **Not automatic for landlocked territories** (DR-17, FR-51).

### Legality summary

A naval attack is offered when **all** of the following hold:

1. Phase is `Attack`.
2. `navalForce.enabled` is true for this match.
3. The seat holds Naval capability by CAP-2.
4. A sea route in the frozen effective map joins an owned origin to a target the seat does not own.
5. The origin holds ≥ 2 armies and more than the dice to be rolled.

## 7.10 Sea Routes

### What the host chooses, and what it does not

> The host chooses **how many** sea routes the match has. The system chooses **where they go**.

There is no interface anywhere in the system for drawing a route between two named territories. Host-drawn
routes are an explicit non-goal (C-07, Part E) — they would let a host construct an arbitrarily favourable
board, and they would make every match's graph unreproducible from its seed.

### Bounds

| Setting | Value | Status |
|---|---|---|
| Minimum | 2 | SEA-1 (D-13) |
| Maximum | 10 | SEA-1 |
| Default | 4 | SEA-1 |

Minimum 2 rather than 0, so that whenever Naval Force is enabled there is something for it to do. A match
with zero routes would silently disable a locked feature; classic-only play is reached by
`navalForce.enabled = false`, which is one flag and is honest about what it does.

### Generation

| Constraint | Rule | Why |
|---|---|---|
| Both endpoints coastal | Hard | A landlocked territory is never an endpoint (FR-51) |
| Not already land-adjacent | Hard | A sea route duplicating a land edge adds nothing |
| No duplicate route | Hard | — |
| Different continents | Soft preference | Inter-continental routes are more interesting; not worth failing generation over |
| Attempt bound | 500, then a specific failure | Never a partial match |

Generation runs once, at match creation, from the match seed, and the result is **frozen** into
`matches.effective_map` (FR-16, FR-10). Routes are never regenerated, so a resumed match has the routes
it started with, and the same seed and count always produce the same board.

### Terminology — a deliberate rename

The map format's `crossesWater` field is a **render hint** marking ordinary land edges the client should
draw as crossing water, such as Alaska ↔ Kamchatka. It has **no mechanical meaning**.

The two concepts were one word apart in the original design documents, so the cosmetic field was renamed
(D-04). "Sea route" now refers to exactly one thing in this project.

| | `crossesWater` | Sea route |
|---|---|---|
| Is it an edge in the rules? | It *marks* a land edge | It **is** a distinct edge type |
| Who can use it? | Everyone — it is a land edge | Only a seat holding Naval capability |
| Counts for Air Force range? | Yes, it is a land edge | **No** |
| Where is it stored? | `shared/maps/*.json` | Generated per match; only in `matches.effective_map` |

## 7.11 Maps

### The authored classic board

42 territories, 6 continents, 83 land edges, connected, with continent sizes 9/4/7/6/12/4 and bonuses
5/2/5/3/7/2 (FR-09). Every one of those figures is asserted on load.

Territory **polygons are not on the critical path.** The map file carries adjacency, continent membership,
coastal status, card symbol and a label anchor — everything the rules need. Artwork is Phase 12 (O-01),
and until then the clients render a debug board from label anchors. The engine, agents, tests and
pass-and-play all work fully without a single polygon.

### Procedural maps

Generated maps use the pipeline in §5.7 and pass **the same validation gate** as the authored board
(FR-08). Continent bonuses are derived from the classic static-value band rather than chosen, so a
generated continent costs about what an equivalent classic continent costs.

Procedural maps are **not required for playability** (Part E). They exist because variable territory
counts are what justify the graph-based state encoder (§2.6), and because they are the cheapest source of
training variety.

## 7.12 Victory and Match End

### Elimination

A seat that loses its last territory is eliminated: its status changes, its cards transfer to the
eliminating seat, and the turn loop skips it permanently (FR-53, FR-38). If the transfer puts the
eliminating seat at 6+ cards, it must trade down below 5 at once (FR-36).

Elimination is a consequence of the territory rule in §7.3, not a separate mechanic — a seat is exactly
the territories it holds, so holding none is being out of the game. A `Neutral` seat can be eliminated the
same way.

### Ending the match

| Ending | Condition | Result |
|---|---|---|
| **World domination** | One seat owns every territory in the effective map | That seat wins (FR-54) |
| **Round cap** | The configured cap (100) is reached | Seats ranked by territory count (FR-55) |

The round cap is not decoration. AI-versus-AI matches between two cautious agents can fail to terminate,
and a training run that never ends produces nothing. 100 rounds is the value the MARS paper used.

**No other victory condition exists.** Secret mission cards are not implemented (D-26); standard rules
permit omitting them.

### Rule summary card

| Question | Answer |
|---|---|
| How many combat systems? | **One** |
| How many new unit types? | **Zero** |
| How many new actions? | **Two** — Air Force attack, Naval attack/fortify |
| How many new edge types? | **One** — sea routes |
| How many new phases? | **Zero** |
| How many capabilities unlock anything? | **Two** of five |
| Did the card set size change? | **No** — still three |
| Did dice combat change? | **No** |

---

**Previous:** [6 — Database Design](06-database-design.md) · **Next:** [8 — Implementation](08-implementation-plan.md)
