# 08 · Wireframes

Every screen, desktop and mobile, with **what each region binds to**. The frames are deliberately
plain: this document fixes layout, hierarchy and data binding, not visual treatment — that is
[01](01-design-system.md).

No hex literal appears below. Every colour is a token ([01 §1.10](01-design-system.md) check 1).

**Reading the tables:** `state.*` is `GET /api/matches/{id}/state?seat=n`, `legal` is
`GET /api/matches/{id}/legal?seat=n`, `map.*` is the map file, `rules.*` is `../shared/rules.json`,
and `event.*` is a push event. A region bound to nothing is static copy.

---

## 8.1 S-01 Splash

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│                                                            │
│                    ORDER & CONQUEST                        │
│                       type-display                         │
│                                                            │
│                  ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁                         │
│                  indeterminate, after 400 ms               │
│                                                            │
│                                             v0.1.0  ·  ⬤   │
│                                           type-body-sm  ok │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Title | static |
| Progress bar | appears only if route **3** `GET /maps` has not returned in 400 ms (§06.6) |
| Version | build constant |
| Connectivity dot | route **3** outcome — `legal` green on success, `danger` on failure → §06.7 offline `EmptyState` |

Mobile: identical, full screen. The only screen with no layout variation.

---

## 8.2 S-02 Sign in / Register / Guest

```
┌────────────────────────────────────────────────────────────┐
│  ORDER & CONQUEST                                          │
│                                                            │
│   ┌──────────────────────────────────────────────┐         │
│   │  [ Sign in ]  [ Register ]                   │  tabs   │
│   │ ──────────────────────────────────────────── │         │
│   │  Username                                    │         │
│   │  [________________________________]  40 h    │         │
│   │  Password                                    │         │
│   │  [________________________________]          │         │
│   │                                              │         │
│   │  ⚠ Username or password is incorrect.        │         │
│   │                                              │         │
│   │  [            Sign in            ]  48 h     │         │
│   └──────────────────────────────────────────────┘         │
│                                                            │
│              Continue as guest  →                          │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Tabs | local |
| Fields | local; password never logged, never echoed (NFR-09, D-23) |
| Error | route **1** / **2** problem document. `401` carries **no distinction** between unknown user and bad password (§A.5) |
| Sign in | route **2**; `429` → back off (§06.5) |
| Continue as guest | **no network call** (D-24). Goes straight to S-03 (§02.4) |

Mobile: single column, `space-4` gutter, fields full width, guest link above the keyboard safe area.

> The error copy is one string for both failure modes on purpose. Distinguishing them would confirm
> which usernames exist.

---

## 8.3 S-03 Main menu

```
┌────────────────────────────────────────────────────────────┐
│  ORDER & CONQUEST                          Mujtaba   ⚙     │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   [        New match        ]  48 h                        │
│                                                            │
│   IN PROGRESS                                              │
│   ┌──────────────────────────────────────────────┐         │
│   │ World Classic · 4 seats · round 7     ▸      │         │
│   │ ● you  ◆ Mars  ▲ Chaos  ○ Neutral            │         │
│   ├──────────────────────────────────────────────┤         │
│   │ World Classic · 2 seats · round 2     ▸      │         │
│   └──────────────────────────────────────────────┘         │
│                                                            │
│   [ Replay viewer ]   [ Settings ]                         │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Account name | route **2** response; **absent** for a guest |
| New match | → S-04 |
| In-progress list | route **13** `GET /players/{id}/matches` — finished matches excluded by `ix_matches_status` (FR-04) |
| Each row | `mapKey`, `seats.length`, `round`, seat glyphs + patterns (UX-03) |
| Row tap | → S-08 directly, **not** via the lobby (§02.2 `resume`) |
| Empty, account | *"No matches in progress."* + **New match** |
| Empty, **guest** | *"Sign in to keep a match history."* + **Sign in** — route 13 needs a `player_id` (§06.7) |

Mobile: list rows at `control-h-lg` × 2 for the two-line layout; the two secondary buttons become a
bottom row.

---

## 8.4 S-04 Match setup · S-05 Sea routes

One stepped flow across two screens. S-05 is step 4.

```
┌────────────────────────────────────────────────────────────┐
│  ‹ Match setup                              1 2 3 ●4 5     │
├────────────────────────────────────────────────────────────┤
│  MAP                                                       │
│   (•) World Classic   42 territories · 6 continents        │
│   ( ) Generate…        [ Generate ]                        │
│                                                            │
│  SEATS                            [ − ]  4  [ + ]          │
│   0  ● You            Human                                │
│   1  ◆ Mars           AI  ▾ Balanced                       │
│   2  ▲ Chaos          AI  ▾ Aggressive                     │
│   3  ■ Vega           Local human                          │
│                                                            │
│  RULES                                                     │
│   Dice faces      [ − ]  d6  [ + ]   ⟦●⟧  classic          │
│   Attack range    [ − ]   1  [ + ]          classic        │
│   Allocation      (•) Random  ( ) Claim                    │
│                                                            │
│  SEA ROUTES                       [ − ]  4  [ + ]          │
│   permitted 2 – 10 · default 4                             │
│   Endpoints are chosen by the system.                      │
│                                                            │
│  ⚠ More faces make ties rarer, which very slightly         │
│    favours the attacker. 6 is the classic rule.  Learn more│
│                                                            │
│                            [ Cancel ]  [ Create match ]    │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Map list | route **3** `GET /maps`; detail from route **4** |
| Generate | route **5** `POST /maps/generate`; `422` → inline, naming the failed V-01…V-12 rule |
| Seat count | 2 – 6 (FR-12). `400` echoes the bound |
| Seat kind / agent | `kind = "Ai"` ⟺ `agent` present (CK-09) — the dropdown is disabled unless kind is AI |
| Seat colour | `seat-n` + pattern; uniqueness enforced server-side (`400`) |
| **Dice faces** | `rules.combat.diceSidesMin`…`Max` = **2…20**, default **6** (D-29, FR-84). Preview token shows pip-vs-numeral mode (UX-06) |
| **Attack range** | `rules.combat.attackRangeMin`…`Max` = **1…10**, default **1** (D-30, FR-85) |
| Allocation | FR-16 |
| Sea routes | `rules.seaRoutes.min`/`max`/`default` = **2 / 10 / 4**. Forced to **0** when naval force is disabled (D-13, `400`) |
| Helper text | **qualitative only** — computing odds here would be combat logic in a client ([04 §4.8](04-dice-ui-ux.md)) |
| Learn more | opens [04 §4.7](04-dice-ui-ux.md)'s reference table as static copy |
| Create match | route **6** `POST /matches` → S-06 |

Mobile: one step per screen, the stepper dots in the header, `Create match` pinned to the bottom.

> **Nothing on this screen computes an odds figure.** That is the single rule S-04 exists to respect,
> and the reason the helper text is words rather than a percentage.

---

## 8.5 S-06 Lobby

```
┌────────────────────────────────────────────────────────────┐
│  LOBBY                                   room  7F3K        │
├────────────────────────────────────────────────────────────┤
│  0  ● You              Human          ready                │
│  1  ◆ Mars             AI             ready                │
│  2  ▲ Chaos            AI             ready                │
│  3  ■ —                open seat      waiting…             │
│  ─  ○ Neutral          neutral        never acts           │
├────────────────────────────────────────────────────────────┤
│  World Classic · d6 · range 1 · 4 sea routes               │
│                                                            │
│                       [       Start       ]                │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Room code | route **6** response |
| Seat rows | `state.seats[]` — `seatIndex`, `kind`, `displayName`, `colour`, `status` |
| Open seat | filled by route **7** `POST /join`; `409` if already held |
| **Neutral row** | shown, greyed and stippled, labelled *"never acts"* (D-07) |
| Rules summary | `state.options` — **read-only from here on** ([04 §4.8](04-dice-ui-ux.md)) |
| Start | → S-07 or S-08 depending on allocation mode |
| Live updates | `StateChanged` |

> The Neutral row is listed rather than hidden. A 2-player match runs as **3 seats** (D-07), and a
> player who never sees the third seat will read the turn order as broken (§06.10).

---

## 8.6 S-08 Main board — desktop

The floor every in-match screen stands on (§02.1).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE  Claim ▸ Draft ▸ ATTACK ▸ Occupy ▸ Fortify      round 7   ● your turn  │ 56
├────────────┬────────────────────────────────────────────────┬────────────────┤
│ SEATS      │                                                │ YOUR HAND   3  │
│ ● You      │        ╭─────╮          ╭─────╮                │ ───────────────│
│  14t 33a   │        │ 12  │──────────│  3  │                │ 4 6 8 ▸10◂ …   │
│  ✈ ⚓       │        ╰─────╯          ╰─────╯                │  ┌──┐┌──┐┌──┐  │
│ ◆ Mars     │          ukraine         ural                  │  │✈ ││🛡││✦ │  │
│  11t 24a ▨▨│                                                │  └──┘└──┘└──┘  │
│ ▲ Chaos    │     ╭─────╮         ╭─────╮                    │  1 valid set   │
│  9t 18a ▨▨▨│     │  4  │ ─ ─ ─ ─ │  7  │                    │  [ Trade ▸ ]   │
│ ○ Neutral  │     ╰─────╯         ╰─────╯                    │ ───────────────│
│  8t 8a     │   north_africa     egypt                       │ CAPABILITIES   │
│            │                                                │  🛡 Infantry ✓ │
│            │   ═══════ sea route ═══════                    │  ✈ AirForce ✓  │
│            │                                                │  ⚓ Naval ✓     │
│            │                            legend  ─ land      │     from Brazil│
│            │                            ─ ─ across water    │                │
│            │                            ═══ sea route       │                │
├────────────┴────────────────────────────────────────────────┴────────────────┤
│  [⚔ Attack]  [✈ Air Force]  [⚓ Naval]                        [ End phase ▸ ] │ 72
└──────────────────────────────────────────────────────────────────────────────┘
    240                      board, fit to width                      300
```

| Region | Binds to |
|---|---|
| `PhaseBar` | `state.phase`, `state.round`, `state.currentSeat` |
| Seat list | `state.seats[]` — `territoryCount`, `armyTotal`, `cardCount` as face-down backs (UX-12), `capabilities` |
| Territory shape | `map.territories[].shape` — **absent until Phase 12**, so the debug renderer draws circles at `label` (UX-09) |
| Territory fill | `state.territories[k].ownerSeat` → `seat-n` + pattern, with a 1.5 px `border-strong` stroke ([07 §7.3](07-responsive-and-accessibility.md)) |
| `ArmyBadge` | `state.territories[k].armies`, on a `bg-surface` pill at the `label` anchor (UX-10) |
| Land edge | `map.neighbours` |
| **Dashed edge** | `map.crossesWater` — **10 edges**, render hint only, labelled *"land border across water"* (UX-08) |
| **Sea route** | `state.seaRoutes[]` — distinct style, `⚓` badge; **never** confused with the dashed edges ([03 §3.6](03-map-ui-ux.md)) |
| Continent outline | `map.continents[].colour` at 70 %, **outline only** (UX-04) |
| Hand panel | → [05 §5.8](05-card-ui-ux.md) |
| `CapabilityPanel` | `state.seats[me].capabilities` + its source. **No Wild row** (D-20) |
| Action bar | one slot per command, **present only if `legal` contains a match** (§06.2, §06.3) |
| `End phase` | **always rightmost** |

Panels sit over the ocean margins, so the land mass is never occluded.

---

## 8.7 S-08 Main board — mobile

```
┌─────────────────────────┐
│ ATTACK · r7 · your turn │  phase bar, 48
├─────────────────────────┤
│                         │
│      ╭───╮     ╭───╮    │
│      │12 │─────│ 3 │    │  board, pannable
│      ╰───╯     ╰───╯    │  pinch 0.5× – 3.0×
│                         │  snaps to 0.537
│   ╭───╮  ─ ─  ╭───╮     │
│   │ 4 │       │ 7 │     │
│   ╰───╯       ╰───╯     │
│                         │
│                   [⊕]   │  zoom to tactical
├─────────────────────────┤
│ ═══════ grab ═══════    │
│ ⚔ 6 targets   ✈ 2   ⚓ 1 │  peek, 56
│ [Cards 3] [Seats] [Caps]│
│            [End phase ▸]│
└─────────────────────────┘
```

| Region | Binds to |
|---|---|
| Phase bar | compressed `state.phase` · `round` · turn |
| Board | display-first below 859 px ([07 §7.2](07-responsive-and-accessibility.md)) |
| Zoom button | snaps to the **0.537 tactical threshold** |
| Peek row | counts **derived from `legal`** — `6 targets` is `legal.count(Attack)` |
| Tabs | open the sheet at `half` / `full` |
| `End phase` | rightmost, as on desktop |

Tapping `⚔ 6 targets` opens the **territory list** — the primary selection path on a phone, at full
`control-h-lg` rows, grouped by continent. Direct touch remains available at a 22 px hit radius with
a disambiguation popover ([03 §3.11](03-map-ui-ux.md)).

---

## 8.8 S-07 Claim

```
desktop: board + bottom banner           mobile: board + sheet at peek
┌───────────────────────────────┐        ┌─────────────────────────┐
│ CLAIM · round 1 · your turn   │        │ CLAIM · your turn       │
│                               │        │ ╭───╮ ╭───╮             │
│   22 territories unclaimed    │        │ │ ? │ │ ? │             │
│   Tap a grey territory.       │        │ ╰───╯ ╰───╯             │
│                               │        │ ══════ grab ══════      │
│   [ territory list ▾ ]        │        │ 22 unclaimed            │
└───────────────────────────────┘        │ [ Choose territory ▾ ]  │
                                         └─────────────────────────┘
```

| Region | Binds to |
|---|---|
| Unclaimed count | `legal.count(ClaimTerritory)` |
| Legal territories | `legal` → `ClaimTerritory(t)`; everything else **inert** |
| Second stage | once all are claimed, `legal` becomes `PlaceArmies(t, 1)` — **count fixed at 1**, so **no stepper** (§02.5) |
| `EndPhase` | **not offered** in `Claim` (§02.7) |

> The two stages of Claim use different actions with the same screen. The absence of a stepper in
> stage two is specification, not simplification: `LegalClaim` offers only `n = 1`.

---

## 8.9 S-09 Draft

```
┌───────────────────────────────────────────────┐
│  REINFORCEMENTS                        14     │  type-num-lg
│  ───────────────────────────────────────────  │
│   territories  14 ÷ 3                   4     │
│   ▸ Africa  bonus                       3     │  continent Chip (UX-04)
│   ▸ Australia  bonus                    2     │
│   card set traded                       5     │
│  ───────────────────────────────────────────  │
│   next set is worth 12 armies                 │
│  ───────────────────────────────────────────  │
│   PLACE                                       │
│   ukraine        12 → [ − ]  3  [ + ]         │
│   ural            3 → [ − ]  0  [ + ]         │
│                                               │
│   remaining                             11    │
│                       [ Place ]  [ End ▸ ]    │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Total | `state.armyPool` |
| Breakdown | `max(3, ⌊t/3⌋)` + continent bonuses + trade value — **displayed from the state, not recomputed** (FR-67) |
| Continent chips | `map.continents[].colour`, chip only (UX-04) |
| Next set value | `state.tradeIndex` → the escalation ladder ([05 §5.4](05-card-ui-ux.md)) |
| Placement rows | `legal` → `PlaceArmies(t, n)`; the stepper's max is the largest `n` offered |
| Remaining | `state.armyPool` minus staged placements |
| **Forced trade** | if `state.mustTrade`, this entire panel is **replaced** by S-10's trade panel — no pool, no targets, no dismissal ([05 §5.7](05-card-ui-ux.md)) |

Mobile: `BottomSheet` at `half`; the breakdown collapses to a single tappable summary row.

---

## 8.10 S-10 Cards · S-16 Capabilities

Specified in full at [05 §5.8–5.9](05-card-ui-ux.md) (hand, ladder, preview, forced trade) and
[01 §1.7](01-design-system.md) (iconography). The capability panel:

```
┌───────────────────────────────────────────────┐
│  CAPABILITIES                                 │
│  ───────────────────────────────────────────  │
│  🛡 Infantry      held    every territory      │
│  🐎 Cavalry       held    ukraine, ural        │
│  💥 Artillery     —                            │
│  ✈ AirForce      held    card · North Africa  │
│                           ⚠ used this turn     │
│  ⚓ NavalForce    held    brazil (coastal)      │
│  ───────────────────────────────────────────  │
│  no Wild row — a Wild has no profile (D-20)   │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Rows | `state.seats[me].capabilities` |
| Source | derived from owned territories (`map.cardSymbol`, `coastal`) and cards in hand — `seatHoldsCapabilityFromTerritories` / `...FromCards` both `true` |
| Air Force note | `state.seats[me].airForceUsedThisTurn` |
| **Writes** | **none.** S-16 is pure derived display (CAP-2, D-10, §02.3) |
| Wild | **never listed** (D-20) |

---

## 8.11 S-11 Attack · S-12 Air Force · S-13 Naval

```
┌───────────────────────────────────────────────┐
│  ATTACK                                       │
│   from   ukraine            12 armies         │
│   to     ural                3 armies  ◆ Mars │
│  ───────────────────────────────────────────  │
│   dice   [ − ]  3  [ + ]      max 3           │
│                                               │
│   win chance               66 %               │
│   ███████████████████░░░░░░░░░                │
│  ───────────────────────────────────────────  │
│   ⟦6⟧ ⟦4⟧ ⟦3⟧   attacker        d7            │
│   ⟦6⟧ ⟦2⟧       defender                      │
│    6 ─┬─ 6   TIE → defender holds             │
│    4 ─┴─ 2   attacker wins                    │
│    3         unpaired, discarded              │
│   Attacker −1      Defender −1                │
│                                               │
│              [ Cancel ]  [ Attack ]           │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| From / to | the selected `legal` entry |
| Dice stepper | `maxDice` from `legal`; **each count is a separate legal action** ([04 §4.9](04-dice-ui-ux.md)) |
| **Win chance** | **`winChance` from `legal`** — never computed (FR-67). `Skeleton` while in flight |
| Dice tray | `event.DiceRolled` — draw order above, sorted comparison below ([04 §4.4](04-dice-ui-ux.md)) |
| Face count badge | `state.options.diceSides`; read-only (TC-PER-07) |
| Tie row | always labelled **in words**; `defenderWinsTies` is the most-misremembered rule |
| Losses | `event.attackerLosses` / `defenderLosses` |

S-12 adds a **range column** — `legal[].range`, rendered by the shared `RangeReadout` (UX-07) — and
is absent when the capability is missing or the turn's air attack is spent (§06.3).
S-13 adds the sea-route row and offers **both** `NavalAttack` and a plain `Fortify` across the route
(§02.5).

---

## 8.12 S-14 Occupy — blocking

```
┌───────────────────────────────────────────────┐
│  OCCUPY  ural                                 │
│                                               │
│   You rolled 3 dice, so at least 3 armies     │
│   must move in.                               │
│                                               │
│   ukraine  12  →  [ − ]  3  [ + ]  →  ural    │
│                                               │
│   ukraine keeps 9 · ural garrisoned with 3    │
│                                               │
│                        [      Occupy      ]   │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Stepper range | `legal` → `Occupy(n)`, bounded below by the dice rolled (DR-06) and above by `origin.armies − mustLeaveBehind` (DR-04) |
| **No dismissal** | no Cancel, no back, no `Escape`, no gesture (§06.4) |
| Guarantee | the offered range is **never empty** — a capture never costs the attacker an army, proved in `../appendices/E-pseudocode.md` §E.4.5 |

> This is the only modal in the product with no way out, and the engine proof is what makes that
> safe rather than reckless.

---

## 8.13 S-15 Fortify

```
┌───────────────────────────────────────────────┐
│  FORTIFY            one per turn              │
│   from   ukraine            12 armies         │
│   to     ural                3 armies         │
│          ⚓ by sea route                       │
│   move   [ − ]  5  [ + ]       max 11         │
│                        [ Cancel ]  [ Move ]   │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Destinations | `legal` → `Fortify(from, to, n)` |
| **"by sea route"** | derived from the **map** — the action itself does not say (§02.5). Confirmed afterwards by `ArmiesFortified.viaSeaRoute` |
| Max | largest `n` offered; `mustLeaveBehind` already applied server-side |
| One per turn | `state.fortifyUsed`; a naval fortification consumes the same one (D-19, FR-49) |

---

## 8.14 S-17 Hand-over — blocking

```
┌───────────────────────────────────────────────┐
│                                               │
│                      ◆                        │
│                                               │
│              Pass the device to               │
│                    MARS                       │
│                                               │
│       The previous player's cards have        │
│       been cleared.                           │
│                                               │
│            [        Continue        ]         │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Seat glyph / name | `event.HandOverDevice` — names **only the incoming seat**, carries **no card data** |
| **Reads** | **nothing.** The incoming seat's state is requested **after** Continue (§02.3) |
| Order | clear hand → show this → then request state. `motion-instant`, no fade (§01.8) |
| Dismissal | the button only. Back, `Escape` and gestures do nothing (§06.4) |
| Restart | backgrounding and relaunching resumes **here**, never at a revealed hand (TC-UI-03) |

> The reassurance line is load-bearing. Without it the incoming player cannot tell a cleared hand
> from a rendering delay, and will tap back to check.

---

## 8.15 S-18 Game over

```
┌────────────────────────────────────────────────────────────┐
│                      ● YOU WIN                             │  type-display
│                   world domination                         │
├────────────────────────────────────────────────────────────┤
│   #   seat         territories  armies  cards  eliminated  │
│   1   ● You            42         88      3       —        │
│   2   ▲ Chaos           0          0      0    round 14    │
│   3   ◆ Mars            0          0      0    round 11    │
│   ─   ○ Neutral         0          0      0    round  9    │
├────────────────────────────────────────────────────────────┤
│   14 rounds · 38 min · 212 actions                         │
│          [ Replay ]   [ Main menu ]                        │
└────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Winner | `event.GameOver.winnerSeat` |
| Reason | `event.GameOver.reason` — `"domination"` or `"roundCap"` |
| Standings | `event.GameOver.standings[]` |
| **Final hands** | revealed for **every** seat — the only point at which redaction ends ([05 §5.10](05-card-ui-ux.md)) |
| Replay | route **12** → S-19 |

---

## 8.16 S-19 Replay

```
┌──────────────────────────────────────────────────────────────┐
│  REPLAY   World Classic · d7 · range 1        round 7 / 14   │
├────────────────────────────────┬─────────────────────────────┤
│                                │ ACTION LOG                  │
│       the same board as S-08    │ 41 ● Attack ukraine → ural │
│       rendered from route 12    │    ⟦6⟧⟦4⟧⟦3⟧ vs ⟦6⟧⟦2⟧     │
│                                │    −1 / −1                  │
│                                │ 42 ● Occupy ural, 3         │
│                                │ 43 ● End phase              │
│                                │ 44 ◆ Draft +11              │
├────────────────────────────────┴─────────────────────────────┤
│   ⏮  ◀  ▶  ⏭      ──────●────────────────   speed 1×         │
└──────────────────────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| Board | **S-08's renderer**, driven from route **12** instead of route 8 (§02.9) |
| Log | the full 14-event vocabulary — richer than the 6 pushed events (§02.6) |
| Dice | replayed from the logged faces, in **draw order**, so the replay is visually identical (FR-29) |
| Header | `state.options` — face count and range, read-only |
| **Deck order** | **never shown**, to any seat, at any point (NFR-11) |

> If S-19 ever becomes a second renderer, TC-UI-04's "all three clients render the same state" has
> quietly become two renderers per client.

---

## 8.17 S-20 Settings

```
┌───────────────────────────────────────────────┐
│  SETTINGS                                     │
│   Theme            ( ) Light (•) Dark ( ) Auto│
│   Music                  ──●──────   40 %     │
│   Effects                ────────●   90 %     │
│   Animation speed        ──────●──   1.0×     │
│   Reduced motion         [ ✓ ] follow system  │
│   Text size              ──●──────   100 %    │
│  ───────────────────────────────────────────  │
│   THIS MATCH                                  │
│   Dice faces       d7      fixed at creation  │
│   Attack range      1      fixed at creation  │
│   Sea routes        4      fixed at creation  │
│  ───────────────────────────────────────────  │
│   [ Leave match ]                             │
└───────────────────────────────────────────────┘
```

| Region | Binds to |
|---|---|
| All controls | **local device state. S-20 writes nothing to the server** (§02.3) |
| Animation speed | scales every `motion-*` token; fastest ⇒ `motion-instant` throughout (§01.8) |
| **This match** | `state.options`, **read-only**, each labelled *"fixed at creation"* ([04 §4.8](04-dice-ui-ux.md)) |
| Leave match | confirm, then S-03 |

> The three read-only rows exist to close off a trap. Editing `shared/rules.json` mid-match must not
> change a running match: the draw count per roll would be unchanged, so the RNG position would
> track the log perfectly while every face differed, and a replay would diverge with every
> determinism test still passing. **TC-PER-07** is the guard; this screen is why no player is ever
> invited to try.

---

## 8.18 Coverage — all 20 screens, both platforms

Every screen has a specified desktop form **and** a specified mobile form. This table is the audit:
no row says "to be decided".

| Screen | Desktop form | Mobile form | Mobile specified in |
|---|---|---|---|
| S-01 Splash | full screen | **identical**, full screen | §8.1 |
| S-02 Sign in | centred card, 420 px | single column, `space-4` gutter, guest link above the keyboard safe area | §8.2 |
| S-03 Main menu | centred column | full-width rows at 2 × `control-h-lg`; secondary buttons become a bottom row | §8.3 |
| S-04 Match setup | one scrolling page, all sections | **one step per screen**, stepper dots in the header, `Create match` pinned to the bottom | §8.4 |
| S-05 Sea routes | section of S-04 | step 4 of the mobile stepper | §8.4 |
| S-06 Lobby | centred seat table | full-width seat rows; rules summary collapses to one line | §8.5 |
| S-07 Claim | board + bottom banner | board + sheet at `peek`, with *Choose territory* list | §8.8 |
| S-08 Main board | 3-column: 240 seats / board / 300 hand | **full-bleed board + `BottomSheet`**, peek row carries `legal` counts, zoom-to-tactical button | **§8.7, full frame** |
| S-09 Draft | right panel | `BottomSheet` at `half`; breakdown collapses to one tappable summary row | §8.9 |
| S-10 Cards | right panel, expanded | `BottomSheet` at `full`, 2 cards per row, Trade pinned to the sheet bottom | **[05 §5.9](05-card-ui-ux.md), full frame** |
| S-11 Attack | right panel | `BottomSheet` at `half`; dice tray sized 48 px tokens | §8.11, [02 §2.3](02-screen-inventory-and-flows.md) |
| S-12 Air Force | right panel + range overlay | `BottomSheet` at `full` — the range list needs the height | §8.11, [02 §2.3](02-screen-inventory-and-flows.md) |
| S-13 Naval | right panel | `BottomSheet` at `half` | §8.11, [02 §2.3](02-screen-inventory-and-flows.md) |
| S-14 Occupy | centred modal, `elev-3` | **full-width blocking modal**, no dismissal on either platform | §8.12 |
| S-15 Fortify | right panel | `BottomSheet` at `half` | §8.13, [02 §2.3](02-screen-inventory-and-flows.md) |
| S-16 Capabilities | right panel section | `BottomSheet` at `full` | §8.10, [02 §2.3](02-screen-inventory-and-flows.md) |
| S-17 Hand-over | blocking full screen | **identical** — blocking full screen, by requirement | §8.14 |
| S-18 Game over | centred standings table | full-width rows, standings scroll | §8.15 |
| S-19 Replay | board + 320 px log panel | board + `BottomSheet` log at `half`; transport bar pinned | §8.16 |
| S-20 Settings | centred column | full-width rows | §8.17 |

| | |
|---|---|
| Screens wireframed | **20 of 20**, desktop **and** mobile |
| Screens whose mobile form **changes structure** | **12** — S-04, S-05, S-07…S-13, S-15, S-16, S-19 |
| Screens that reflow only | **6** — S-02, S-03, S-06, S-14, S-18, S-20 |
| Screens identical on both | **2** — S-01, S-17 |
| Hex literals | **none** (check 1, [01 §1.10](01-design-system.md)) |
| Regions bound to a named source | every one, or marked static |
| Screens that write nothing | S-01, S-16, S-19, S-20 |
| Screens with no dismissal | S-14, S-17 |

> **The mobile forms are not reflowed desktop layouts.** Thirteen of the twenty change structure, and
> S-08 changes *interaction model* — below 859 px the territory list becomes the primary selection path,
> because [07 §7.2](07-responsive-and-accessibility.md) measures that **42 of 42 territories** fall below
> a 48 px touch target at every phone width. That is the finding behind
> [`../PLATFORM-SCOPE-PROPOSAL.md`](../PLATFORM-SCOPE-PROPOSAL.md).

### Design acceptance checks

| # | Check | Rule |
|---|---|---|
| DA-71 | Every region in every frame resolves to a named `state` / `legal` / `map` / `rules` / `event` field, or is static | §8.1–8.17 |
| DA-72 | No wireframe shows a number the client would have to compute | FR-67 |
| DA-73 | `End phase` is rightmost in every frame that has it | §06.2 |
| DA-74 | S-14 and S-17 have no dismissal affordance in any frame | §06.4 |
| DA-75 | No hex literal appears in this document | §01.10 |

---

[← 07 Responsive and accessibility](07-responsive-and-accessibility.md) · [00 Index](00-index.md)
