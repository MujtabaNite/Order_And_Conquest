# Order & Conquest — Database Design (normalised, prototype edition)

Files that go with this document:

| File | What it is |
|---|---|
| `erd_overview.png` | The diagram to show at the meeting: all 13 tables, keys and relationships only |
| `erd_full.png` | Same diagram with every column (use in the report) |
| `order_and_conquest_schema.sql` | The real PostgreSQL schema (13 tables, all constraints) |
| `seed_world_classic.sql` | Loads the classic map: 6 continents, 42 territories, 83 land borders |

Both diagrams were generated from the running database, so they cannot disagree with the SQL.

---

## 1. The one-minute version

The database stores three kinds of things:

1. **Map data** (blue): what the board *is* — continents, territories, borders, sea routes. Loaded once, never changes during play.
2. **Accounts** (green): who can log in.
3. **Match data** (orange): what is happening in one game — whose turn, who owns what, who holds which cards, and a log of every move.

Reading the diagram: a line with a **crow's foot** (three prongs) means "many", a double bar means "exactly one", a small circle means "optional". So `matches ──< seats` reads "one match has many seats".

---

## 2. Your question: map as JSON, or map as tables?

| | JSON blob (repo's original design) | Normalised tables (this design) |
|---|---|---|
| ERD shows the map | No, it is one column | Yes |
| Database enforces "a border connects two territories that exist" | No, only code checks it | Yes (foreign keys) |
| Database enforces "a border is stored once, not twice" | No | Yes |
| Can query the map in SQL | Awkward | Easy (§6 describes a test that counts Air Force reach with one query) |
| Tables to maintain | 6 | 13 |
| Extra work | None | One seed script (already written) |
| Risk: editing a map changes a running game | Impossible (copied into the match) | Prevented by a rule: *a map used by a match is never edited; add a new map instead* |

**Decision: normalised tables.** You asked for a fully normalised design, and it is easier to explain to an examiner. It does *not* make the game slower: the server reads the map from the database **once** when a match starts and keeps it in memory. It never joins these tables on every move.

---

## 3. The 13 tables

### A. Map data

| Table | One row is… | Notes |
|---|---|---|
| `card_symbols` | one of the 6 card symbols | Lookup table: Infantry, Cavalry, Artillery, AirForce, NavalForce, Wild |
| `maps` | one board | `world_classic` today; a second map later is just another row |
| `continents` | a continent on a map | Holds its bonus armies and colour |
| `territories` | a territory | Belongs to a continent; has `is_coastal` and its card symbol |
| `territory_adjacency` | a land border between two territories | Stored **once** (smaller id first), so the 83 classic borders are 83 rows |
| `sea_routes` | a fixed naval route between two coastal territories | **Empty for now** — needed only when you add Naval Force |

### B. Accounts

| Table | One row is… | Notes |
|---|---|---|
| `users` | a registered player | Stores a password **hash**, never the password. Username is unique ignoring upper/lower case |

### C. Match data

| Table | One row is… | Notes |
|---|---|---|
| `matches` | one game | Room code, status, phase, whose turn, `version` (stops two phones acting at once), dice seed |
| `match_rules` | the frozen rule settings of one game | Exactly one row per match. Dice sides, attack range, Air/Naval switches |
| `seats` | one player slot in a game | Kind is `Human`, `Ai` or `Neutral`. A human seat needs a user; an AI seat needs a bot name |
| `match_territories` | who owns a territory in this game and how many armies | Armies must be at least 1 |
| `match_cards` | one card in this game's deck | In the deck, in a player's hand, or discarded |
| `moves` | one action that was played | Append-only history, used to resume and replay |

---

## 4. Design decisions (add these to your decisions register)

| ID | Decision | Why |
|---|---|---|
| D-31 | The map is stored as normalised tables, not a JSON blob | Shown in the ERD; the database enforces map integrity |
| D-32 | Capability is **not stored**. A player's capabilities are worked out from the territories and cards they own | Storing it would let it disagree with ownership (the repo already decided this: D-10) |
| D-33 | A card's symbol is **not stored**. It is the territory's `card_symbol`, or Wild if the card has no territory | One fact, one place |
| D-34 | Rule settings are real columns in `match_rules`, one row per match, copied at creation | Editing a default can never change a game in progress. This is the "frozen options" rule (D-29/D-30) in table form |
| D-35 | Sea routes are a separate table from land borders | The Air Force range search must use land borders only (rule C-08). Separate tables make mixing them up impossible |
| D-36 | Air Force and Naval Force are **off by default** (`air_force_enabled`, `naval_force_enabled` = false) | The first version is exactly classic RISK, matching your build order |
| D-37 | The old `LocalHuman` / `RemoteHuman` seat kinds become one kind, `Human` | You have no pass-and-play, so the distinction is gone |
| D-38 | The "six tables" constraint (C-03) is replaced by 13 tables | Approved by you: you said locked decisions can change |

### Two deliberate exceptions to strict normalisation

Being honest about these will help you in the viva.

1. **`map_id` is repeated** in `territories`, `territory_adjacency` and `sea_routes`. Strictly it could be looked up through the continent or territory. We keep it so the database can use a *composite foreign key* and **reject** a border that links territories from two different maps. Because the foreign key forces the values to match, the copy can never disagree.
2. **`moves.action` and `moves.events` are JSON.** It is an append-only log read back as a whole, and each action type has a different shape. Splitting it into one table per action type would add many tables for no benefit.

---

## 5. How to change things on task day

| The committee says… | You do… |
|---|---|
| "Make the dice 8-sided" | Create the match with `dice_sides = 8` in `match_rules` (allowed 2–20). Do it before the match starts |
| "Let units attack two territories away" | Create the match with `attack_range = 2` (allowed 1–10) |
| "Turn on the Air Force" | `air_force_enabled = true` (and `air_max_range`, default 5) |
| "Add another sea route" | Insert one row into `sea_routes` (example at the bottom of the seed file) |
| "Use a different map" | Insert a new row in `maps`, then its continents, territories and borders |

The values are read from `match_rules`, never from a config file, once a match exists. So changing a default mid-demo cannot corrupt a game that is already running.

---

## 6. What was tested

Everything below was run on PostgreSQL 16, not just written:

- The schema and seed load in one go on an empty database (13 tables).
- The seed produces **42 territories, 6 continents, 83 land borders, 36 coastal territories**, and 10 borders marked as crossing water (drawing hint only). These match the repo's JSON map.
- A recursive SQL query over the border table finds **1,330** territory pairs within 5 land steps. That is exactly the figure the repo states for Air Force range (77.2% of 1,722 pairs).
- A sample match was created with 2 human seats, 1 bot seat, 42 owned territories, a 44-card deck (12 Infantry, 10 Cavalry, 8 Artillery, 7 AirForce, 5 NavalForce, 2 Wild) and one logged move.
- The database **rejected** each of these on purpose: a territory with 0 armies, a border written backwards, a human seat with no user, one user taking two seats, a second rules row, dice outside 2–20, a winner while the game is still running, a reused active room code, a Wild symbol on a territory, and a card in a hand with no holder.

## 7. Not done yet (so you are not surprised)

- **`sea_routes` is empty.** Choosing the fixed list is a game-design decision for your team. A good route links two coastal territories that are not already land neighbours, ideally on different continents. The three validation queries at the bottom of the schema file check this.
- **Append-only `moves`** is a convention, not enforced. The repo's older design blocked updates and deletes with database permissions; add that if your supervisor asks.
- **No sessions table.** Login is assumed to use tokens (JWT). If you want refresh tokens or "log out everywhere", add one table later.
- **Docs to update** in the repo: chapter 6, appendix B, §5.8 of chapter 5, constraint C-03, and the README (it still says 6 tables).
