# Appendix A — API Contract

> **Deliverable L.** The complete REST and SignalR contract for `OrderAndConquest.Api`.
>
> This appendix is the wire-level expansion of [§5.5 API Design](../docs/05-system-design.md#55-api-design).
> The endpoint list, its thirteen routes and the requirement mapping are fixed there; this file adds the
> request bodies, response bodies, status codes and error shapes a developer needs in order to write the
> controllers and the three clients. Where this file and §5.5 could disagree, §5.5 is authoritative and
> this file is the defect.
>
> **Scope discipline.** Thirteen endpoints, no more. §22 of the master specification instructs that the
> endpoint list is a starting contract, *not* a licence to add more. Nothing here introduces a subsystem:
> every route below already appears in §5.5 with its FR.

---

## A.1 Conventions

| Aspect | Decision |
|---|---|
| Base path | `/api` |
| Content type | `application/json; charset=utf-8` |
| Casing | `camelCase` on the wire, `PascalCase` in C#. `System.Text.Json` default policy |
| Territory and card keys | `snake_case` strings, exactly as in the map file — `northern_europe`, `wild_1` |
| Enum values | `PascalCase` strings on the wire, never integers. `"Attack"`, not `2` |
| Time | ISO-8601 UTC with `Z`. Audit only; never a rule input |
| Authentication | `Authorization: Bearer <jwt>` when present. Absent means a guest session (FR-03) |
| Idempotency | Only `POST /actions` is state-changing, and it is guarded by `expectedVersion` rather than an idempotency key |
| Versioning | None in v1. The path carries no `/v1`, because a breaking change to a contract with three first-party clients and no third-party consumers is a coordinated release, not a negotiation |

### Why `camelCase` is written down

The Dart client's DTOs are generated from JSON Schema (§8.6, NFR-18), and a casing mismatch
deserialises to `null` rather than failing. Fixing the policy in the contract is what makes the generated
Dart and the hand-written C# agree by construction.

---

## A.2 Error model

Every non-2xx response is an [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) problem document, which is
what ASP.NET Core produces by default:

```jsonc
{
  "type":     "https://orderandconquest.dev/errors/illegal-action",
  "title":    "The submitted action is not in the legal action set.",
  "status":   400,
  "detail":   "Attack from 'peru' to 'china' is not legal: territories are not adjacent.",
  "instance": "/api/matches/5f2c.../actions",
  "errors":   { "action": ["not in legal set"] }
}
```

### Status codes and what each one means here

| Code | Meaning in this API | Client behaviour |
|---|---|---|
| `200 OK` | Applied or fetched | Render the returned state |
| `201 Created` | Match or account created | Navigate to the new resource |
| `400 Bad Request` | Malformed body, or an action **not in the legal set** (FR-22) | Show an error; this is a client bug or a stale board |
| `401 Unauthorized` | A registered-only route called without a valid token | Prompt to log in |
| `403 Forbidden` | Authenticated, but not the seat being acted for (TC-API-02) | Never retry. This is an authorisation failure, not a race |
| `404 Not Found` | No such match, map or player | — |
| `409 Conflict` | `expectedVersion` did not match (FR-61) | **Re-render from the attached state. Do not retry the action** |
| `422 Unprocessable Content` | Semantically valid but unsatisfiable: map fails validation, sea-route count unplaceable | Show the named failure; nothing was created |
| `429 Too Many Requests` | Rate limit on the auth routes only (NFR-10) | Back off |
| `500` | Unhandled | Report; the action was not applied — the transaction is atomic (NFR-13) |

### The two codes worth stating precisely

**`409` carries the current state.** The body is a problem document *plus* a `state` and `version` member,
so a losing client re-renders in one round trip instead of two. A `409` is **never retried
automatically**: re-submitting an action chosen against a stale board would be a different move than the
player intended (§5.5).

**`422` never partially creates.** If sea-route generation cannot place the requested count within
`maxGenerationAttempts`, the response states how many were placeable and **no match row exists**
(D-13, UC-04 alternative path 9a). A partially created match is worse than a refused one.

---

## A.3 Endpoint index

Thirteen routes. Twelve are the §22 baseline; `join` is the single addition, because a `RemoteHuman` seat
must be claimable from a second device (§5.5).

| # | Method | Path | Auth | FR | State-changing |
|---|---|---|---|---|---|
| 1 | `POST` | `/api/auth/register` | — | FR-01 | Yes |
| 2 | `POST` | `/api/auth/login` | — | FR-02 | No |
| 3 | `GET` | `/api/maps` | — | FR-05 | No |
| 4 | `GET` | `/api/maps/{key}` | — | FR-06 | No |
| 5 | `POST` | `/api/maps/generate` | — | FR-07, FR-08 | No |
| 6 | `POST` | `/api/matches` | Optional | FR-12…FR-19 | Yes |
| 7 | `POST` | `/api/matches/{id}/join` | Bearer | FR-13 | Yes |
| 8 | `GET` | `/api/matches/{id}/state?seat=n` | Seat | FR-62 | No |
| 9 | `GET` | `/api/matches/{id}/legal?seat=n` | Seat | FR-21 | No |
| 10 | `POST` | `/api/matches/{id}/actions` | Seat | FR-61 | **Yes — the only one** |
| 11 | `POST` | `/api/matches/{id}/ai-step` | Seat | FR-73 | Yes |
| 12 | `GET` | `/api/matches/{id}/replay` | Seat | FR-59 | No |
| 13 | `GET` | `/api/players/{id}/matches` | Bearer | FR-04 | No |

**One state-changing gameplay endpoint.** Every rule change in the system flows through route 10 (or
route 11, which calls the same service on an agent's behalf). That is what makes the append-only log
complete by construction: there is no second write path to forget to log.

### Seat authorisation

Routes marked *Seat* are guarded by a filter that resolves the caller to a seat in that match
(§8.2 `Auth/`). It enforces:

| Situation | Result |
|---|---|
| Caller's `user_id` holds seat `n` | Allowed |
| Match has a `LocalHuman` seat `n` and the caller is the match's creating session | Allowed — pass-and-play is one device holding several seats |
| Seat `n` is `Ai` and the route is `ai-step` | Allowed |
| Caller holds a different seat | `403` |
| Caller holds no seat in the match | `403` |
| Seat `n` is `Neutral` | `403` on every route — a neutral seat never acts (D-07) |

---

## A.4 Authentication

### 1 · `POST /api/auth/register` → `201`

```jsonc
// request
{ "username": "commander", "password": "<plaintext, TLS only>", "displayName": "Commander" }
```

```jsonc
// 201
{ "userId": "9f1e...", "username": "commander", "displayName": "Commander",
  "token": "<jwt>", "expiresAt": "2026-10-04T12:00:00Z" }
```

The password is hashed with **Argon2id** and stored as a PHC string (NFR-09, TC-SEC-01). It is never
logged, never echoed, and never stored in any other form. `409` if the username is taken
(case-insensitively, per `ux_users_username_lower`).

### 2 · `POST /api/auth/login` → `200`

```jsonc
{ "username": "commander", "password": "<plaintext, TLS only>" }
```

Returns the same body as register. `401` on bad credentials, with **no distinction** between an unknown
username and a wrong password (TC-SEC-02). Rate-limited (NFR-10).

**Guest play needs neither route.** A guest session creates no `users` row and holds seats with
`user_id IS NULL` (FR-03). This is what lets Phases 1–5 run with no authentication at all.

---

## A.5 Maps

### 3 · `GET /api/maps` → `200`

```jsonc
{ "maps": [
    { "key": "world_classic", "name": "Classic World", "territories": 42,
      "continents": 6, "formatVersion": 2, "kind": "authored", "valid": true },
    { "key": "tiny_12", "name": "Tiny 12", "territories": 12,
      "continents": 3, "formatVersion": 2, "kind": "authored", "valid": true }
] }
```

Only maps that **pass the V-01…V-12 gate** are listed (FR-05). An invalid map is not a selectable option,
which is why `valid` is always `true` here — the field exists for the diagnostic endpoint's benefit and
for a client that caches the list.

### 4 · `GET /api/maps/{key}` → `200`

Returns the full map document: `continents`, `territories` (each with `name`, `continent`, `label`,
`coastal`, `cardSymbol`, `capabilities`, `neighbours`), `crossesWater`, and render polygons when present.
The shape is [`shared/maps/world_classic.json`](../shared/maps/world_classic.json) verbatim; see
[Appendix C](C-map-specification.md) for the field-by-field specification. `404` if unknown.

`crossesWater` is **render-only** — it tells a client to draw a bridge glyph. It is not a sea route and
carries no rule meaning (D-04).

### 5 · `POST /api/maps/generate` → `200`

```jsonc
// request
{ "seed": 20260927,
  "params": { "territories": 42, "continents": 6, "minContinentSize": 4, "maxContinentSize": 12 } }
```

Returns a generated map in the same shape as route 4, plus `"kind": "generated"` and the echoed `seed`.
The same seed and params return a **byte-identical** map (NFR-02, TC-MAP-06). Generation runs the same
V-01…V-12 gate; a failure discards and reseeds internally rather than returning an invalid map (§8.10).
`422` if the parameters cannot produce a valid map within the attempt bound.

This route does **not** create a match. The generated map is returned to the client, and the client passes
it — or its `generated:<seed>` key — to route 6.

---

## A.6 Match lifecycle

### 6 · `POST /api/matches` → `201`

```jsonc
// request
{
  "mapKey": "world_classic",
  "seats": [
    { "kind": "LocalHuman", "displayName": "Commander", "colour": "#c0392b" },
    { "kind": "Ai",         "displayName": "Mars",      "colour": "#2980b9", "agent": "mars" },
    { "kind": "Ai",         "displayName": "Chaos",     "colour": "#27ae60", "agent": "chaotic" }
  ],
  "options": {
    "seaRouteCount":       4,
    "allocation":          "claim",       // "claim" | "random"
    "fortifyMode":         "single_pair", // "single_pair" | "one_step_all" | "connected_path"
    "roundCap":            100,
    "difficulty":          "Hard",
    "turnTimerSeconds":    0,             // built now, unenforced until Phase 6
    "navalForceEnabled":   true,
    "airForceEnabled":     true
  },
  "seed": 20260927          // optional; server generates one when absent
}
```

```jsonc
// 201
{
  "matchId":  "5f2c...",
  "roomCode": "K4P9TQ",
  "version":  1,
  "status":   "setup",
  "phase":    "claim",
  "seats": [ { "seatIndex": 0, "kind": "LocalHuman", "displayName": "Commander",
               "colour": "#c0392b", "status": "active", "startingArmies": 35 }, /* ... */ ],
  "effectiveMap": { /* frozen: territories, adjacency, continents, capabilities, seaRoutes */ },
  "state": { /* initial redacted state for the creating seat */ }
}
```

What the server does, in order (UC-04):

1. Validate the map against the V-01…V-12 gate → `422` naming the failed rule.
2. **Insert a `Neutral` third seat** if two were requested, and apply the 3-seat army count of 35
   (FR-14, D-07).
3. Generate **exactly** `seaRouteCount` valid sea routes and freeze them into `effectiveMap`
   (FR-16, FR-10) → `422` if unplaceable, stating how many were placeable, **creating nothing**.
4. Build the deck from the effective map: one card per territory plus two wilds — 44 on the classic
   board (FR-19, D-14).
5. Issue starting armies from the configured table (FR-18).
6. Persist match, seats, territory state and cards in **one transaction**, at `version = 1` (NFR-13).

Validation on the request itself:

| Rule | Failure |
|---|---|
| `seats.length` between 2 and 6 | `400` (FR-12) |
| `kind = "Ai"` ⟺ `agent` present | `400` (CK-09) |
| `seaRouteCount` within `[seaRoutes.min, seaRoutes.max]` | `400`, echoing the permitted range (FR-15) |
| `seaRouteCount = 0` required when `navalForceEnabled = false` | `400` (D-13) |
| `colour` unique across seats | `400` |

**The host never names sea-route endpoints.** The request carries a *count*. There is no field anywhere
in this contract for a territory pair, and adding one is an explicit §40 prohibition (UC-05, C-07).

### 7 · `POST /api/matches/{id}/join` → `200`

```jsonc
{ "roomCode": "K4P9TQ", "seatIndex": 1 }     // seatIndex optional; server picks the first open seat
```

Claims an open `RemoteHuman` seat for the authenticated caller. `409` if the seat is already held,
`404` on an unknown room code, `403` if the match is not accepting joins. Phase 6; the route exists from
Phase 1 so that going online changes configuration rather than contract.

### 13 · `GET /api/players/{id}/matches` → `200`

```jsonc
{ "matches": [
    { "matchId": "5f2c...", "mapKey": "world_classic", "status": "in_progress",
      "seatIndex": 0, "phase": "attack", "round": 12, "currentSeat": 0,
      "seatCount": 3, "updatedAt": "2026-09-27T11:02:14Z", "yourTurn": true }
] }
```

Backed by the partial index `ix_matches_status` (FR-04). Finished matches are excluded. `403` unless
`{id}` is the caller.

---

## A.7 Reading state

### 8 · `GET /api/matches/{id}/state?seat=n` → `200`

```jsonc
{
  "matchId": "5f2c...",
  "version": 42,
  "status":  "in_progress",
  "phase":   "attack",
  "round":   12,
  "currentSeat": 0,
  "seat":    0,                       // the seat this view is redacted FOR
  "tradeIndex": 3,                    // match-wide, public (DR-13)
  "seats": [
    { "seatIndex": 0, "kind": "LocalHuman", "displayName": "Commander", "colour": "#c0392b",
      "status": "active", "territoryCount": 17, "armyTotal": 41, "cardCount": 3,
      "cards": [ { "cardKey": "peru", "symbol": "Artillery" },
                 { "cardKey": "wild_1", "symbol": "Wild" },
                 { "cardKey": "ural", "symbol": "Infantry" } ],
      "capabilities": ["Infantry","Cavalry","Artillery","NavalForce"],
      "airForceUsedThisTurn": false },

    { "seatIndex": 1, "kind": "Ai", "agent": "mars", "displayName": "Mars", "colour": "#2980b9",
      "status": "active", "territoryCount": 14, "armyTotal": 33, "cardCount": 2,
      "cards": null,                  // REDACTED — count is public, identity is not
      "capabilities": ["Infantry","Cavalry","AirForce","NavalForce"],
      "airForceUsedThisTurn": false }
  ],
  "territories": {
    "alaska": { "ownerSeat": 0, "armies": 3 },
    "alberta": { "ownerSeat": 1, "armies": 5 }
    /* one entry per territory in the effective map — NOT 42 by assumption */
  },
  "seaRoutes": [ { "id": 0, "a": "brazil", "b": "west_africa" } ],
  "armyPool": 0,                      // undeployed armies for `seat`, non-zero only in Claim/Draft
  "pendingOccupy": null,              // { from, to, minArmies, maxArmies } while phase = occupy
  "mustTrade": false                  // true when `seat` holds 5+ cards at Draft (FR-35)
}
```

#### Redaction (FR-62, NFR-11, TC-API-05, TC-SEC-03)

| Field | Own seat | Other seats |
|---|---|---|
| Territory ownership and armies | Full | Full |
| Card **identities** | Full | **`null`** |
| Card **count** | Full | Full — public information in RISK |
| Capability set | Full | Shown — it is *derivable* from visible ownership (CAP-2), so hiding it would be theatre |
| Trade-table position | Full | Full — match-wide |

Redaction happens **server-side**. The client never receives another seat's card identities and therefore
cannot leak them through a rendering error. This is what makes the pass-and-play hand-over screen a
correctness requirement rather than polish (UC-16).

### 9 · `GET /api/matches/{id}/legal?seat=n` → `200`

The endpoint that makes three clients affordable.

```jsonc
{
  "version": 42,
  "phase":   "attack",
  "seat":    0,
  "mustAct": true,
  "actions": [
    { "type": "Attack",     "from": "kamchatka", "to": "alaska",  "maxDice": 3, "winChance": 0.662 },
    { "type": "Attack",     "from": "ural",      "to": "ukraine", "maxDice": 2, "winChance": 0.579 },
    { "type": "AirAttack",  "from": "peru",      "to": "egypt",   "maxDice": 3, "winChance": 0.470, "range": 4 },
    { "type": "NavalAttack","from": "brazil",    "to": "west_africa", "seaRouteId": 0,
      "maxDice": 3, "winChance": 0.662 },
    { "type": "EndPhase" }
  ]
}
```

The client's whole job: highlight every `from`, draw an arrow to every `to`, enable *End attack* because
`EndPhase` is present. **Any territory not named in this list is not interactive.** No adjacency
computation, no range computation, no combat maths in any of the three clients (NFR-17, TC-ARC-04).

`winChance` is computed server-side from the closed-form odds table (§7.5) so that all three clients show
the same number and none of them implements the mathematics.

`mustAct` is `true` when the phase cannot be left without acting — notably a forced card trade, where
`actions` contains **only** `TradeSet` entries (FR-35, TC-CRD-08).

#### The action vocabulary

Derived from the phase machine of §4.10.2. Nine types; no phase and no type exists for either extension
beyond these.

| `type` | Legal in | Fields | Notes |
|---|---|---|---|
| `ClaimTerritory` | `claim` | `territory` | Setup allocation, `allocation = "claim"` |
| `PlaceArmies` | `claim`, `draft` | `territory`, `count` | Must own the target (FR-22) |
| `TradeSet` | `draft` | `cards` (exactly **three** keys) | Exactly three. Never four, never five (DR-12, C-05) |
| `Attack` | `attack` | `from`, `to`, `dice` | Land adjacency |
| `AirAttack` | `attack` | `from`, `to`, `dice` | ≤ 5 **land** edges; once per turn (AIR-1) |
| `NavalAttack` | `attack` | `from`, `to`, `dice`, `seaRouteId` | Across a frozen sea route |
| `Occupy` | `occupy` | `count` | ≥ dice rolled, ≤ all but one (DR-06) |
| `Fortify` | `fortify` | `from`, `to`, `count` | Land or sea route; mode from `options.fortifyMode` |
| `EndPhase` | any | — | Declines the remainder of the phase |

**Three attack types, one combat resolver.** `Attack`, `AirAttack` and `NavalAttack` differ only in the
adjacency test used to build the legal list. All three resolve through the same code path, and
TC-AIR-06 / TC-NAV-04 assert exactly that (FR-31, §40 "no separate combat systems").

---

## A.8 Submitting an action

### 10 · `POST /api/matches/{id}/actions` → `200`

The only state-changing gameplay route.

```jsonc
// request
{
  "seat": 0,
  "expectedVersion": 42,
  "action": { "type": "Attack", "from": "kamchatka", "to": "alaska", "dice": 3 }
}
```

```jsonc
// 200
{
  "version": 43,
  "events": [
    { "type": "DiceRolled", "from": "kamchatka", "to": "alaska",
      "attacker": [6,4,2], "defender": [5,3],
      "attackerLosses": 1, "defenderLosses": 1 },
    { "type": "TerritoryHeld", "territory": "alaska", "armies": 1 }
  ],
  "state": { /* new redacted state, as route 8 */ },
  "legal": { /* next legal actions, as route 9 — saves a round trip */ }
}
```

Returning `legal` alongside `state` is deliberate: the common case is "act, then act again", and one
response that answers both is one round trip instead of two on every single action of the match.

#### `expectedVersion` (FR-61, TC-API-03)

The server compares it against `matches.version` **inside the same transaction** that applies the action.
Zero rows updated → nothing applied → `409` with the current state attached:

```jsonc
// 409
{ "type": "https://orderandconquest.dev/errors/version-conflict",
  "title": "The match has advanced since this action was chosen.",
  "status": 409, "version": 43, "state": { /* current, redacted */ } }
```

This exists for the **double-tap**, not for multiplayer contention: a turn-based game has one writer at a
time, and on localhost a double-tap is genuinely faster than a round trip. A laggy client tapping *attack*
twice must not roll twice.

#### Event vocabulary

Every die face the engine rolled appears in `events`. That is what makes a replay visually identical
rather than merely outcome-identical, and it is why the client animates dice it is *told about* instead of
generating its own (FR-29).

| Event | Payload |
|---|---|
| `ArmiesPlaced` | `territory`, `count` |
| `TerritoryClaimed` | `territory`, `seat` |
| `SetTraded` | `cards`, `armiesAwarded`, `newTradeIndex` |
| `TerritoryBonusAwarded` | `territory`, `armies` (+2, capped at 2 per turn — FR-37) |
| `DiceRolled` | `from`, `to`, `attacker[]`, `defender[]`, `attackerLosses`, `defenderLosses` |
| `TerritoryCaptured` | `territory`, `fromSeat`, `toSeat` |
| `TerritoryHeld` | `territory`, `armies` |
| `ArmiesOccupied` | `from`, `to`, `count` |
| `ArmiesFortified` | `from`, `to`, `count`, `viaSeaRoute` |
| `CardAwarded` | `cardKey`, `symbol` — own seat only; redacted to `{ "seat": n }` for others |
| `SeatEliminated` | `seat`, `by`, `cardsTransferred` |
| `PhaseChanged` | `from`, `to` |
| `TurnChanged` | `seat`, `round` |
| `GameOver` | `winnerSeat`, `reason` (`"domination"` \| `"roundCap"`), `standings[]` |

### 11 · `POST /api/matches/{id}/ai-step` → `200`

```jsonc
{ "seat": 2, "expectedVersion": 42 }
```

Asks the server to play **exactly one action** for an `Ai` seat (UC-19, TC-API-07). Response shape is
identical to route 10. The version increments by exactly one per call, so a client drives an AI turn by
calling until `currentSeat` changes — which is what lets it animate each attack instead of the board
teleporting.

| Rule | Behaviour |
|---|---|
| Seat is not `Ai` | `400` |
| Seat is not `currentSeat` | `409` |
| Minimum think time | Applied **at this layer**, ~400 ms configurable (FR-75, D-22) |
| Trained policy unavailable | Falls back to MarsBot and logs the substitution (FR-78) |

Think time lives in the API and never in the agent, because the same agent must run at full speed during
headless simulation and RL training. An agent that answers in 2 µs makes the board flicker and looks
broken.

### 12 · `GET /api/matches/{id}/replay` → `200`

```jsonc
{ "matchId": "5f2c...", "mapKey": "world_classic", "seed": 20260927,
  "effectiveMap": { /* the frozen map — a replay must not re-read the map file */ },
  "moves": [
    { "seq": 1, "seatIndex": 0, "round": 0, "phase": "claim",
      "action": { "type": "ClaimTerritory", "territory": "alaska" },
      "events": [ { "type": "TerritoryClaimed", "territory": "alaska", "seat": 0 } ],
      "versionAfter": 2, "rngPositionAfter": 0 }
    /* ... */
  ] }
```

The full append-only log in `seq` order (FR-59, TC-API-08). Card identities in a **finished** match are
not redacted — the game is over and the replay is the record of it. In an unfinished match, other seats'
`CardAwarded` events remain redacted.

Returned within 2 s for a 100-round match (NFR-08).

---

## A.9 SignalR hub — `/hubs/match`

Server-to-client only. **Clients never invoke hub methods to change state**; every change goes through
route 10. The hub exists so clients do not poll.

| Event | Payload | Consumers |
|---|---|---|
| `StateChanged` | `version`, redacted state | All seats — **each receives its own redaction** (NFR-11, TC-API-06) |
| `DiceRolled` | attacker/defender faces, losses | All seats — drives the dice animation |
| `TurnChanged` | `seat`, `phase`, `round`, `deadline` | All seats |
| `SeatEliminated` | `seat`, `by` | All seats |
| `GameOver` | `winnerSeat`, `standings` | All seats |
| `HandOverDevice` | `incomingSeat` | Pass-and-play client only |

Client-invokable methods, both non-mutating:

| Method | Purpose |
|---|---|
| `JoinMatchGroup(matchId, seat)` | Subscribe. Authorised by the same seat filter as the REST routes |
| `LeaveMatchGroup(matchId)` | Unsubscribe |

**Even in single-player on localhost, state arrives over SignalR.** That means the "waiting for another
player" code path is exercised from day one instead of being bolted on when Phase 6 goes online.

`HandOverDevice` names **only the incoming seat** and carries no card data. The client must clear all hand
information *before* rendering the hand-over screen (UC-16, NFR-22, TC-UI-02).

---

## A.10 Contract generation

The C# request/response records in `Api/Contracts/` are the **source of truth**. CI generates JSON Schema
from them into `shared/contracts/`, and the Flutter client's Dart DTOs are generated from those schemas by
`json_serializable` (§8.6, NFR-18).

| Gate | Effect |
|---|---|
| `shared/contracts/` regenerated with no diff | Blocks merge (§9.1) |

Two of three clients can reference C# types directly; the third cannot. A hand-written Dart mirror of
twenty DTOs drifts the first time a field is added — silently, because a missing key deserialises to
`null`. A contract change that is not propagated therefore fails the **build**, not a client three weeks
later.

`shared/contracts/` is **generated, never hand-authored**, and is created in Phase 6 with the first
contract (§8.1). Its absence before Phase 6 is by design, not an omission.

---

## A.11 Requirement coverage

| FR | Route or mechanism |
|---|---|
| FR-01, FR-02 | Routes 1, 2 |
| FR-03 | Guest session: no `users` row, `user_id IS NULL` |
| FR-04 | Route 13 |
| FR-05…FR-08 | Routes 3, 4, 5 |
| FR-10 | `effectiveMap` frozen at route 6; replayed from the match, never the file |
| FR-12…FR-19 | Route 6 |
| FR-21 | Route 9 |
| FR-22 | `400` on an action outside the legal set |
| FR-26…FR-31 | Route 10, `Attack` / `AirAttack` / `NavalAttack` → one resolver |
| FR-32…FR-38 | Route 10, `TradeSet` + `SetTraded` / `CardAwarded` / `SeatEliminated` |
| FR-42…FR-46 | `AirAttack`, `range` field, `airForceUsedThisTurn` |
| FR-47…FR-51 | `NavalAttack`, `seaRouteId`, `seaRoutes[]` |
| FR-54, FR-55 | `GameOver` with `reason` |
| FR-56…FR-59 | Route 12, and the one-transaction write behind route 10 |
| FR-60 | This appendix |
| FR-61 | `expectedVersion` → `409` |
| FR-62 | §A.7 redaction |
| FR-63, FR-64 | §A.9 hub |
| FR-71…FR-78 | Route 11 |

---

**Appendix index:** A · [B](B-database-schema.sql) · [C](C-map-specification.md) ·
[D](D-capability-mapping-decision-table.md) · [E](E-pseudocode.md) · [F](F-test-cases.md) ·
[G](G-configuration-tables.md) · [H](H-additional-diagrams-and-screenshots.md)
