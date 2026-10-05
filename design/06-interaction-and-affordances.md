# 06 · Interaction and Affordances

The states everyone forgets. This document turns **FR-66** into one expression, then specifies every
loading, empty, error and conflict state the interface can reach — including the four routes
**TC-UI-01** names explicitly: *tap, drag, keyboard and back-navigation*.

---

## 6.1 FR-66, as one expression

> **FR-66 (M)** — *each client shall make interactive only those territories and actions named in
> the server's legal-action response.*

Every client implements it the same way, and it is three lines:

```
legal      = GET /api/matches/{id}/legal?seat=me        // the only source
offered(x) = legal.any(a => a.matches(x))               // x is a territory or a control
enabled(x) = offered(x)                                 // there is no second clause
```

The third line is the whole rule. `enabled` has **no** additional condition — not "and it is my
turn", not "and I have enough armies", not "and the phase is Attack". Those are all already true of
anything in `legal`, because the server built the list from the state. Adding a condition is how a
client slowly reimplements the rules.

### The corollary that does the real work

Because `enabled` is exactly `offered`, **the interface has no opinion to be wrong about.** There is
no state in which the UI believes something is legal and the server disagrees, which is what makes
`400` (§6.5) a reliable bug signal instead of noise.

### What may be derived, and what may not

| May be derived client-side | Why it is safe |
|---|---|
| Whether a territory is adjacent | Map **data**, not rule logic — it ships in the map file |
| Whether a fortify destination is across a sea route | Same — map data (§02.5) |
| Which seat a colour belongs to | Palette, not rule |
| Sorting dice descending for display | Presentation of values already received (§04.4) |
| Whether a capability is about to be lost by a trade | Comparison of two server-supplied lists (§05.5) |
| Distance labels on in-range territories | **No** — these come from the legal list's `range` field |

The line is: **reading the map is allowed, evaluating a rule is not.** Adjacency is a fact about the
world; legality is a judgement about the game.

---

## 6.2 The action bar

One bar, same position in every phase, so muscle memory survives a phase change.

```
desktop, 72 px tall, pinned bottom-centre over the ocean margin
┌────────────────────────────────────────────────────────────────────┐
│  [⚔ Attack]  [✈ Air Force]  [⚓ Naval]  [🛡 Fortify]    [End phase ▸] │
└────────────────────────────────────────────────────────────────────┘
   phase-specific commands, left-aligned          always rightmost
```

| Rule | |
|---|---|
| Commands present | Only those with at least one matching entry in `legal` (§6.3) |
| `End phase` | **Always rightmost**, in every phase that offers `EndPhase`. Never moves, never re-labels except `End turn` in the `EndTurn` phase |
| Absent `End phase` | Only in `Claim` and `Occupy`. In `Occupy` the bar is replaced entirely by S-14's modal |
| Mobile | The bar becomes the bottom sheet's peek row; `End phase` stays rightmost |
| Width | Commands never reflow position as they appear and disappear — each has a fixed slot, and an unavailable command leaves its slot empty rather than letting the others slide |

That last row is a small thing with a real payoff: a player reaching for *Fortify* must not hit
*Naval* because the Air Force command vanished when the turn's air attack was spent.

---

## 6.3 Absent, not disabled

> **An action the server has not offered does not appear.**

| Situation | Treatment | Why |
|---|---|---|
| `AirAttack` not in `legal` — no capability | Command **absent** | A greyed button invites a tap FR-66 guarantees is inert |
| `AirAttack` not in `legal` — already used this turn | Command **absent**, and the S-16 panel states *"Air attack used this turn"* | The explanation belongs where explanations live |
| `NavalAttack` not in `legal` — capability held, no route touches an owned territory | Command **absent**; S-16 shows the capability as held | Appendix D §D.5, TC-NAV-03 |
| A territory not in any legal action | `inert` state — no hover, no cursor change, no hit test | §03.7 |
| `EndPhase` not offered (`Occupy`, forced trade) | Command **absent** | §02.7 |

### The one exception

A control is **disabled rather than absent** when it is a *parameter* of an action that is itself
offered — a stepper at its bound, a Trade button with two of three cards selected. The action is
available; the current parameter value is not yet valid. That is a different statement and it reads
differently: the control is present because the path forward is through it.

So: **absent means "not a thing you can do"; disabled means "not finished yet".**

---

## 6.4 Input grammar

TC-UI-01 requires that no illegal action be reachable by **tap, drag, keyboard or back-navigation**.
Each gets a rule.

### Pointer and touch

| Gesture | Meaning | Where |
|---|---|---|
| Tap / click a legal territory | Select as origin, or commit as target if an origin is selected | Board |
| Tap an inert territory | **Nothing.** No selection, no toast, no flash | Board |
| Tap the selected origin again | Deselect | Board |
| Drag | **Pan the board only.** Never an action | Board |
| Pinch / scroll wheel | Zoom, 0.5× … 3.0× | Board |
| Long-press / hover | Inspect — owner, armies, continent, capability profile. **Read-only** | Board, dice, cards |
| Double-tap | **Unbound.** Reserved, so a fast double-tap on a legal target is one action, not two (§6.5) | Everywhere |

**Drag is never an action.** A drag-to-attack gesture would have to decide mid-gesture whether the
territory under the finger is a legal target, and on release it would commit an action the player
could not read first. Attack is a two-tap selection with a visible confirm step, at every viewport.

### Keyboard

Full parity on desktop; required for accessibility, not a power-user extra.

| Key | Action |
|---|---|
| `Tab` / `Shift-Tab` | Move through: phase bar → seat list → **legal territories only** → panel → action bar |
| `Arrow` keys | Within the board, move to the nearest legal territory in that direction |
| `Enter` / `Space` | Activate the focused element |
| `Escape` | Cancel the current selection; **never** commits, **never** leaves a blocking screen |
| `1` … `3` | Set attacker dice count, when such a count is offered |
| `E` | End phase, when offered |
| `?` | Keyboard help overlay |

The `Tab` order traverses **legal territories only**. An inert territory is not focusable, which is
how FR-66 is honoured for keyboard users without a second code path: the same `offered(x)` predicate
that drives the hit test drives `tabindex`.

### Back-navigation

The route TC-UI-01 names last and the one most often left unhandled. Back is Android's back
gesture, the browser's back button, a mouse's back key, and `Escape`.

| Screen | Back does |
|---|---|
| S-01 Splash | nothing |
| S-02 Sign in | exits the app, with confirm |
| S-03 Main menu | exits the app, with confirm |
| S-04 / S-05 Setup | returns to the previous step, then to S-03; discards nothing until S-03 |
| S-06 Lobby | leaves the match, **with confirm** |
| S-07 … S-16 | **closes the open panel only.** From S-08 with nothing open: offers *leave match*, with confirm. Never submits, never advances a phase |
| **S-14 Occupy** | **nothing.** No back, no `Escape`, no gesture. The phase has no `EndPhase` (§E.4.5) |
| **S-17 Hand-over** | **nothing.** Dismissal is the explicit button only, and the hand stays cleared |
| S-18 Game over | returns to S-03 |
| S-19 Replay | returns to S-03 |

Two screens swallow back entirely, and both for correctness rather than flow: S-14 because there is
no legal alternative to occupying, S-17 because back would be a way to see the previous seat's cards
again. **TC-UI-03** tests the second one by backgrounding and restarting the app mid-hand-over.

---

## 6.5 Conflicts and rejections

Every non-2xx response is an RFC 9457 problem document
(`../appendices/A-api-contract.md` §A.2). Five of them can reach a gameplay screen.

| Status | Means | UI response | Retry? |
|---|---|---|---|
| **`400`** | The action was **not in the legal set** (FR-22) | `Toast` *danger*: "That move is no longer available." Re-read `legal`. **Log it loudly in debug builds** | Never |
| **`403`** | Authenticated, but not this seat | `Dialogue` *error*, return to S-03. This is not a race | **Never** |
| **`404`** | Match gone | `Dialogue`, return to S-03 | Never |
| **`409`** | `expectedVersion` did not match | **Re-render from the attached `state`.** No message, no dialogue | **Never** |
| **`422`** | Unsatisfiable at creation — map invalid, sea-route count unplaceable | Inline error on S-04/S-05 naming the failed rule. Nothing was created | After correction |

### `409` and `400` mean different things, and the difference is the diagnosis

Both look like "the server refused my action". They are opposite bugs:

| | `409` | `400` |
|---|---|---|
| My `version` | **stale** | current |
| My `legal` list | stale | current |
| Cause | A double-tap, or another seat acted between my read and my write | **I submitted an action that was never offered** |
| Blame | Nobody — it is the expected race | **The client.** FR-66 was violated |
| Frequency in a correct client | Occasional | **Zero** |

So a `400` on a gameplay action is never a user-facing problem to be smoothed over — it is a client
defect that §6.1's single-clause `enabled` is designed to make impossible. Debug builds should make
it impossible to ignore; release builds recover silently by re-reading `legal`.

### The double-tap is the reason `409` exists

`../appendices/A-api-contract.md` §A.8 is explicit: the version check *"exists for the double-tap,
not for multiplayer contention: a turn-based game has one writer at a time, and on localhost a
double-tap is genuinely faster than a round trip. A laggy client tapping attack twice must not roll
twice."*

Three defences, in order, because one is not enough:

1. **`expectedVersion` on every submit** — the server's guarantee, and the only one that actually
   holds.
2. **The commit control disables itself on tap** until the response lands, with a `Button` loading
   state.
3. **Double-tap is unbound** (§6.4), so the second tap of a fast double-tap has nothing to activate.

And because `409` carries the current state, recovery is a re-render, not a re-fetch. The player
sees the one attack that happened, never two and never a spinner.

---

## 6.6 Loading

| Case | Treatment |
|---|---|
| S-01 liveness check | Branding stays; a thin indeterminate bar after 400 ms |
| `GET /legal` in flight | Board stays interactive with the **previous** legal set; the odds readout is a `Skeleton`, never a stale number |
| Action submitted | The commit control shows a spinner; the board does not block |
| `ai-step` loop | The phase bar shows *"Mars is thinking"*; board inert but visible. Minimum think time ~400 ms is applied **server-side** (D-22), so the client adds no artificial delay |
| Reconnecting | Persistent `info` banner: *"Reconnecting…"*; board visible, every control inert |

Two rules:

- **Never block the board to load a panel.** The board is the context in which the panel makes
  sense.
- **A number is either current or a `Skeleton`.** It is never a stale value, and never `0` as a
  placeholder. An odds readout showing a leftover `66 %` while a new one loads is worse than showing
  nothing, because it is indistinguishable from an answer.

---

## 6.7 Empty states

| Where | Line | Action |
|---|---|---|
| S-03, no resumable matches | *"No matches in progress."* | **New match** |
| S-03, **guest session** | *"Sign in to keep a match history."* | **Sign in** — route 13 needs a `player_id` (§02.4) |
| S-10, no cards | *"No cards yet. Capture a territory to earn one."* | — |
| S-10, no valid set | *"No set can be formed from your hand."* | — (§05.7) |
| S-16, no capabilities beyond Infantry | *"Only Infantry. Capture a coastal territory or hold an Air Force card."* | — |
| S-13, capability but no route | *"No sea route touches your territories."* | — |
| S-19, no log | *"Nothing to replay yet."* | — |
| Offline | *"Can't reach the server."* | **Retry** |

Every one names **what would change it**. "No cards yet" is a dead end; "capture a territory to
earn one" is a rule the player may not know, delivered where it is relevant.

The guest row is the one that would otherwise be a bug: route 13 is unavailable without an account,
so a guest's resume list is permanently empty, and a spinner there would never resolve.

---

## 6.8 Confirmation policy

Confirmation is friction. It is spent only where an action is both **irreversible** and
**misclickable**.

| Action | Confirm? | Why |
|---|---|---|
| `ClaimTerritory` | No | Reversible by the next claim round in effect, and high-frequency |
| `PlaceArmies` | No | High-frequency; the army pool makes the state obvious |
| `TradeSet` | **Yes — the preview** | Irreversible, escalates for everyone, and can silently cost a capability (§05.5) |
| `Attack` / `AirAttack` / `NavalAttack` | **Yes — one tap on an armed target** | Irreversible and the central decision. The odds readout *is* the confirmation surface |
| `Occupy` | No | Already a blocking modal with an explicit commit |
| `Fortify` | No | One per turn, and the legal list prevents an invalid one |
| `EndPhase` from `Attack` | **Yes, if** an attack is still legal | Ending the attack phase early is a common misclick with no undo |
| `EndPhase` from `Fortify` | **Yes, if** the fortification is unused | Same — a wasted fortification is invisible once the turn ends |
| Leave match | **Yes** | |

The two conditional `EndPhase` confirmations are the only *state-dependent* ones, and both ask the
same question: *you still have something available — are you sure?* Both are derivable from the
legal list alone: if `legal` contains an `Attack`, an attack is still possible.

---

## 6.9 Preset messages — FR-70, optional

**D-25**: free-text chat is **not built**. Preset messages and emoji are in scope as an *optional*
client feature; free text is not.

| | |
|---|---|
| Surface | A collapsed chip row in the seat list, desktop; a tab in the bottom sheet, mobile |
| Content | A fixed list of ~12 phrases plus ~8 emoji, shipped as data |
| Input | **Selection only.** No text field exists anywhere in the client |
| Rate limit | One per seat per turn, client-side |
| Pass-and-play | **Hidden entirely** — messaging yourself is not a feature |

FR-70 is **OPT** (NFR-24: optional requirements stay optional), so this panel must be removable
without touching anything else. It is specified as a self-contained surface for that reason: cutting
it removes a chip row and a data file, and no other screen changes.

The absence of a text field is the requirement, not a side effect. There is no moderation story, no
profanity filter and no abuse surface in this product because there is nowhere to type.

---

## 6.10 Pass-and-play seat handling

One device, several `LocalHuman` seats. Three rules that are easy to miss:

| Rule | Detail |
|---|---|
| `Neutral` is never handed the device | A `Neutral` seat gets `403` on **every** route (§A.4, D-07). A 2-player match runs as **3 seats** including `Neutral` (D-07) — so the turn order visibly skips one seat, and the UI must present that as normal, not as an error |
| Hand-over is per **seat**, not per turn | `HandOverDevice` fires when the next seat is a *different* `LocalHuman`. Consecutive turns by the same local seat do not trigger it |
| The hand is cleared **first** | §05.6, TC-UI-03. Clear, then show S-17, then request the incoming seat's state |

The `Neutral` skip deserves a visible explanation the first time it happens, because a player
watching the turn marker jump from seat 0 to seat 2 will otherwise believe the app lost a turn. A
one-time `info` toast — *"Neutral armies don't take turns"* — costs nothing and answers it.

---

## 6.11 Design acceptance checks

Verified by inspection in Phase 8. Not additions to the 119-case catalogue — **TC-UI-01** and
**TC-UI-02** already pin reachability and interactivity, **TC-UI-03** the hand-over, and
**TC-API-02** the `403`.

| # | Check | Rule |
|---|---|---|
| DA-46 | `enabled(x)` has exactly one clause, in every client. Grep for a second condition | §6.1, FR-66 |
| DA-47 | No unavailable *action* is rendered disabled; no in-progress *parameter* is rendered absent | §6.3 |
| DA-48 | Drag performs no action on any screen | §6.4, TC-UI-01 |
| DA-49 | `Tab` reaches legal territories only; inert territories are not focusable | §6.4 |
| DA-50 | Back and `Escape` do nothing on S-14 and S-17, including after a restart | §6.4, TC-UI-03 |
| DA-51 | A `409` produces a re-render from the attached state and no dialogue | §6.5 |
| DA-52 | A `400` on a gameplay action is impossible in normal play, and loud in debug builds | §6.5 |
| DA-53 | No numeric readout ever shows a stale value while loading | §6.6 |
| DA-54 | Every empty state names what would change it | §6.7 |
| DA-55 | No text input field exists anywhere in any client | §6.9, D-25 |
| DA-56 | The `Neutral` seat is never offered a turn or a hand-over, and the skip is explained once | §6.10, D-07 |

---

[← 05 Card UI/UX](05-card-ui-ux.md) · [07 Responsive and accessibility →](07-responsive-and-accessibility.md)
