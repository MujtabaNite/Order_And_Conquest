-- =====================================================================
-- Appendix B — Database Schema (PostgreSQL 13+)
-- Order & Conquest, prototype edition
-- =====================================================================
--
-- Deliverable L. The executable DDL for the design described in
-- docs/06-database-design.md. Every column in this file appears in the data
-- dictionary of appendices/B3-data-dictionary.md with its meaning and an
-- example value.
--
-- 13 tables in 3 groups (D-40, replacing the six-table constraint C-03):
--   A. MAP DATA   static; loaded once from appendices/B2-seed-world-classic.sql
--                 and never edited during play
--   B. ACCOUNTS   sign-up and login (D-38: login is required, no guest play)
--   C. MATCH DATA changes every turn
--
-- HOW TO LOAD IT
--   createdb order_and_conquest
--   psql -d order_and_conquest -f appendices/B-database-schema.sql
--   psql -d order_and_conquest -f appendices/B2-seed-world-classic.sql
--   psql -d order_and_conquest -f tools/verify_db.sql     -- prints every count
--
-- THREE RULES OF THUMB USED EVERYWHERE
--   * every fact is stored once, so no two copies can disagree
--   * anything that can be worked out is NOT stored. A seat's capabilities are
--     computed from the territories and cards it owns (D-10); a card's symbol
--     is its territory's symbol (D-51)
--   * constraints live in the database, so a bug in a client or in the server
--     can never save an impossible state
--
-- TIER: [P1]. Every table here is needed for the classic-RISK demo. The two
-- extension columns in match_rules are [P2] and default to false.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A. MAP DATA
-- ---------------------------------------------------------------------

-- Lookup table: the six card symbols. Territories and cards point here.
-- Six values, not four (D-03): Air Force and Naval Force were added.
CREATE TABLE card_symbols (
    symbol_code  text PRIMARY KEY,
    description  text NOT NULL
);
INSERT INTO card_symbols (symbol_code, description) VALUES
    ('Infantry',   'Classic RISK symbol. No action attached.'),
    ('Cavalry',    'Classic RISK symbol. No action attached.'),
    ('Artillery',  'Classic RISK symbol. No action attached.'),
    ('AirForce',   'Owning a territory/card with this symbol unlocks Air Force attacks.'),
    ('NavalForce', 'Owning a territory/card with this symbol unlocks Naval Force actions.'),
    ('Wild',       'Joker. Only appears on the 2 wild cards, never on a territory.');

CREATE TABLE maps (
    map_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    map_key        text    NOT NULL UNIQUE,          -- e.g. 'world_classic'
    name           text    NOT NULL,
    canvas_width   integer NOT NULL CHECK (canvas_width  > 0),
    canvas_height  integer NOT NULL CHECK (canvas_height > 0),
    created_at     timestamptz NOT NULL DEFAULT now()
);
-- RULE (D-50, replacing the frozen-blob design of D-04): a map that has been
-- used by a match is NEVER edited. To change a map, insert a NEW row
-- (e.g. 'world_classic_v2') and seed it again. This is what makes FR-10 true
-- without copying the whole board into every match.

CREATE TABLE continents (
    continent_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    map_id        integer NOT NULL REFERENCES maps(map_id),
    code          text    NOT NULL,                  -- 'NA', 'SA', 'EU' ...
    name          text    NOT NULL,
    bonus_armies  integer NOT NULL CHECK (bonus_armies >= 0),
    colour        text    NOT NULL,                  -- '#d4a05a'
    UNIQUE (map_id, code),
    UNIQUE (map_id, continent_id)                    -- needed by the composite FK below
);

CREATE TABLE territories (
    territory_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    map_id        integer NOT NULL,
    continent_id  integer NOT NULL,
    key           text    NOT NULL,                  -- 'northern_europe'
    name          text    NOT NULL,
    is_coastal    boolean NOT NULL,
    card_symbol   text    NOT NULL REFERENCES card_symbols(symbol_code)
                          CHECK (card_symbol <> 'Wild'),
    label_x       integer NOT NULL,                  -- where the name is drawn on the board
    label_y       integer NOT NULL,
    UNIQUE (map_id, key),
    UNIQUE (map_id, territory_id),                   -- needed by the composite FKs below
    -- Composite FK: the continent must belong to the SAME map as the territory.
    FOREIGN KEY (map_id, continent_id) REFERENCES continents (map_id, continent_id)
);
-- Capability profile is NOT a column (D-10, rule CAP-1). It is computed:
--   {Infantry} + {NavalForce if is_coastal} + {card_symbol}
-- Storing it would let it disagree with ownership, which is trap 3 of
-- docs/14-implementation-safety-checklist.md.

-- Land borders. Each border is stored ONCE; smaller id is always territory_a.
CREATE TABLE territory_adjacency (
    map_id         integer NOT NULL,
    territory_a    integer NOT NULL,
    territory_b    integer NOT NULL,
    crosses_water  boolean NOT NULL DEFAULT false,   -- drawing hint only, no game meaning
    PRIMARY KEY (territory_a, territory_b),
    CHECK (territory_a < territory_b),
    FOREIGN KEY (map_id, territory_a) REFERENCES territories (map_id, territory_id),
    FOREIGN KEY (map_id, territory_b) REFERENCES territories (map_id, territory_id)
);
-- crosses_water is the render hint renamed from 'seaLanes' by D-04, so the
-- phrase "sea route" means exactly one thing. A crosses_water border is an
-- ORDINARY land border to every rule in the engine.

-- Sea routes used only by Naval Force. A FIXED list per map (D-37), not
-- generated per match. Kept in a separate table from land borders on purpose:
-- Air Force range counts land borders only and must never accidentally reach
-- across one of these rows (C-08, D-53).
CREATE TABLE sea_routes (
    sea_route_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    map_id        integer NOT NULL,
    territory_a   integer NOT NULL,
    territory_b   integer NOT NULL,
    UNIQUE (territory_a, territory_b),
    CHECK (territory_a < territory_b),
    FOREIGN KEY (map_id, territory_a) REFERENCES territories (map_id, territory_id),
    FOREIGN KEY (map_id, territory_b) REFERENCES territories (map_id, territory_id)
);
-- Rules a seed must satisfy, checked by tools/verify_db.sql queries 8-10 and by
-- tools/generate_map_seed.py before it will emit a row:
--   both ends coastal, and not already a land border.
-- The table ships EMPTY. [P2]

-- ---------------------------------------------------------------------
-- B. ACCOUNTS
-- ---------------------------------------------------------------------

CREATE TABLE users (
    user_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username       text NOT NULL,
    password_hash  text NOT NULL,                    -- Argon2id hash, NEVER the password
    display_name   text NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    last_login_at  timestamptz
);
-- Unique ignoring case, so 'Mujtaba' and 'mujtaba' cannot both register.
CREATE UNIQUE INDEX ux_users_username ON users (lower(username));
-- D-23: the hash is Argon2id in PHC string format. The 2022 report stored
-- plaintext passwords; this is recorded as a correction, not a continuation.
-- There is NO sessions table: login issues a token with a 12-hour life
-- (D-61), which cannot expire during a task day. Add a table later if you
-- want refresh tokens or "log out everywhere". [P3]

-- ---------------------------------------------------------------------
-- C. MATCH DATA
-- ---------------------------------------------------------------------

CREATE TABLE matches (
    match_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    map_id           integer NOT NULL REFERENCES maps(map_id),
    created_by       uuid    NOT NULL REFERENCES users(user_id),
    room_code        text    NOT NULL,               -- 4 chars, typed to join, e.g. 'K7QF' (D-60)
    status           text    NOT NULL DEFAULT 'lobby'
                     CHECK (status IN ('lobby','in_progress','finished','abandoned')),
    phase            text    NOT NULL DEFAULT 'claim'
                     CHECK (phase IN ('claim','draft','attack','occupy','fortify','end_turn','game_over')),
    current_seat_no  smallint,                       -- whose turn (NULL while in lobby)
    round_no         integer  NOT NULL DEFAULT 0 CHECK (round_no >= 0),
    trade_index      integer  NOT NULL DEFAULT 0 CHECK (trade_index >= 0),  -- card sets traded so far
    version          bigint   NOT NULL DEFAULT 1 CHECK (version >= 1),      -- +1 per action; stops two phones acting at once
    rng_seed         bigint   NOT NULL,              -- dice are reproducible from seed + position
    rng_position     bigint   NOT NULL DEFAULT 0 CHECK (rng_position >= 0),
    winner_seat_no   smallint,
    created_at       timestamptz NOT NULL DEFAULT now(),
    started_at       timestamptz,
    finished_at      timestamptz,
    updated_at       timestamptz NOT NULL DEFAULT now(),
    CHECK ((winner_seat_no IS NOT NULL) <= (status = 'finished'))   -- a winner exists only when finished
);
-- A room code must be unique among games that are still running. A finished
-- match releases its code for re-use, which matters on a demo day where you
-- may create a dozen rooms.
CREATE UNIQUE INDEX ux_matches_active_room_code
    ON matches (room_code) WHERE status IN ('lobby','in_progress');
-- `version` is the whole concurrency design. A client submits the version it
-- last saw; the UPDATE carries `AND version = @expected`; zero rows affected
-- means 409 and nothing was written. See docs/06 section 6.8.
-- There is no map blob and no options blob here any more (D-50, D-52): the map
-- is reached through map_id, the rules through match_rules.
-- There is no turn-timer column: O-05 is retired (D-65).

-- Rule settings FROZEN for this match. Exactly 1 row per match (1:1).
-- Copied from shared/rules.json defaults when the match is created, and NEVER
-- read live afterwards (D-52) — so editing a default mid-demo cannot change a
-- game already in progress. This is trap 6 of the safety checklist in table
-- form, and TC-PER-07 asserts the SOURCE of the value, not the value.
CREATE TABLE match_rules (
    match_id               uuid PRIMARY KEY REFERENCES matches(match_id) ON DELETE CASCADE,
    dice_sides             smallint NOT NULL DEFAULT 6   CHECK (dice_sides   BETWEEN 2 AND 20),
    attack_range           smallint NOT NULL DEFAULT 1   CHECK (attack_range BETWEEN 1 AND 10),
    defender_wins_ties     boolean  NOT NULL DEFAULT true,
    territory_allocation   text     NOT NULL DEFAULT 'claim'
                           CHECK (territory_allocation IN ('claim','random')),
    fortify_mode           text     NOT NULL DEFAULT 'single_pair'
                           CHECK (fortify_mode IN ('single_pair','one_step_all','connected_path')),
    wild_cards             smallint NOT NULL DEFAULT 2   CHECK (wild_cards >= 0),
    round_cap              integer  NOT NULL DEFAULT 100 CHECK (round_cap > 0),
    -- Extensions: OFF by default (D-54) so the first version is exactly
    -- classic RISK, matching the build order of D-36. [P2]
    air_force_enabled      boolean  NOT NULL DEFAULT false,
    air_max_range          smallint NOT NULL DEFAULT 5   CHECK (air_max_range BETWEEN 1 AND 10),
    air_attacks_per_turn   smallint NOT NULL DEFAULT 1   CHECK (air_attacks_per_turn >= 1),
    naval_force_enabled    boolean  NOT NULL DEFAULT false
);
-- dice_sides and attack_range are NOT shown in the user interface (D-39).
-- They are set here at creation. docs/16-task-day-change-guide.md is the
-- step-by-step for changing either one if the committee asks.

CREATE TABLE seats (
    match_id            uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    seat_no             smallint NOT NULL CHECK (seat_no BETWEEN 0 AND 5),
    kind                text     NOT NULL CHECK (kind IN ('Human','Ai','Neutral')),
    user_id             uuid     REFERENCES users(user_id),
    ai_agent            text     CHECK (ai_agent IN ('PassiveBot','ChaoticBot','AggressiveBot','MarsBot')),
    colour              text     NOT NULL,
    status              text     NOT NULL DEFAULT 'active' CHECK (status IN ('active','eliminated','left')),
    eliminated_by_seat  smallint,
    eliminated_round    integer,
    final_rank          smallint CHECK (final_rank BETWEEN 1 AND 6),
    PRIMARY KEY (match_id, seat_no),
    -- Which columns must be filled depends on the kind of seat. Three kinds,
    -- not four: LocalHuman and RemoteHuman collapse into Human (D-55), because
    -- there is no single-device play any more (D-44).
    CHECK ( (kind = 'Human'   AND user_id IS NOT NULL AND ai_agent IS NULL)
         OR (kind = 'Ai'      AND user_id IS NULL     AND ai_agent IS NOT NULL)
         OR (kind = 'Neutral' AND user_id IS NULL     AND ai_agent IS NULL) ),
    CHECK (status = 'eliminated' OR (eliminated_by_seat IS NULL AND eliminated_round IS NULL)),
    CHECK (eliminated_by_seat IS NULL OR eliminated_by_seat <> seat_no),
    FOREIGN KEY (match_id, eliminated_by_seat) REFERENCES seats (match_id, seat_no)
);
-- One account cannot occupy two seats in the same match.
CREATE UNIQUE INDEX ux_seats_one_seat_per_user ON seats (match_id, user_id) WHERE user_id IS NOT NULL;
CREATE INDEX ix_seats_user ON seats (user_id) WHERE user_id IS NOT NULL;
-- A 'Neutral' seat never attacks and never fortifies; the server skips its
-- turn (DR-15). It is inserted ONLY in a 2-player match, which is what makes
-- the 3-player starting-army row of 35 apply with no special case (D-07, D-62).
-- ai_agent lists four bots. PassiveBot and MarsBot are [P1]; ChaoticBot and
-- AggressiveBot are [P2] (D-56). The ONNX agent is [P3] and is deliberately
-- absent from this CHECK: adding it is a one-line migration if RL ever ships.

-- Now that seats exists, "whose turn" and "who won" can point at a real seat.
ALTER TABLE matches
    ADD FOREIGN KEY (match_id, current_seat_no) REFERENCES seats (match_id, seat_no),
    ADD FOREIGN KEY (match_id, winner_seat_no)  REFERENCES seats (match_id, seat_no);

-- Who owns each territory and how many armies are on it. This is the ONLY
-- mutable part of the board. A row is added when a territory is first claimed;
-- after the claim phase every territory of the map has exactly one row.
CREATE TABLE match_territories (
    match_id      uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    territory_id  integer  NOT NULL REFERENCES territories(territory_id),
    owner_seat_no smallint NOT NULL,
    armies        integer  NOT NULL CHECK (armies >= 1),   -- a territory is never empty (DR-04)
    PRIMARY KEY (match_id, territory_id),
    FOREIGN KEY (match_id, owner_seat_no) REFERENCES seats (match_id, seat_no)
);
CREATE INDEX ix_match_territories_owner ON match_territories (match_id, owner_seat_no);
-- Replaces the old territory_state table. Nothing immutable about a territory
-- is copied here: its name, continent, neighbours, coastal flag and card
-- symbol are reached through territory_id.

-- The deck: one card per territory, plus the wild cards. 44 cards on the
-- classic board (42 + 2). The symbol is NOT stored (D-51): it is the
-- territory's card_symbol, or 'Wild' when territory_id is NULL.
CREATE TABLE match_cards (
    match_id       uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    card_no        smallint NOT NULL CHECK (card_no >= 1),
    territory_id   integer  REFERENCES territories(territory_id),   -- NULL = wild card
    location       text     NOT NULL CHECK (location IN ('deck','hand','discard')),
    holder_seat_no smallint,
    deck_order     integer,
    PRIMARY KEY (match_id, card_no),
    UNIQUE (match_id, territory_id),                                -- one card per territory
    CHECK ((location = 'hand') = (holder_seat_no IS NOT NULL)),
    CHECK ((location = 'deck') = (deck_order     IS NOT NULL)),
    FOREIGN KEY (match_id, holder_seat_no) REFERENCES seats (match_id, seat_no)
);
CREATE INDEX ix_match_cards_hand ON match_cards (match_id, holder_seat_no) WHERE location = 'hand';
-- The two CHECKs are BICONDITIONAL on purpose. They forbid the half-consistent
-- row in both directions — a card in a hand with no holder, and a holder on a
-- card that is not in a hand — which is the state that produces the bug nobody
-- can reproduce.
-- The deck keeps its AirForce and NavalForce symbols even while the extensions
-- are off (D-63): a symbol is a set-matching token, and air_force_enabled only
-- removes the ACTION.

-- Append-only history of every action. Lets the server resume, replay and
-- audit a game.
-- action/events are JSON on purpose, and this is one of the two deliberate
-- exceptions to strict normalisation (docs/06 section 6.5): the log is only
-- ever read back whole, and each action type has a different shape.
CREATE TABLE moves (
    match_id            uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    seq                 bigint   NOT NULL CHECK (seq >= 1),
    seat_no             smallint NOT NULL,
    round_no            integer  NOT NULL,
    phase               text     NOT NULL,
    action_type         text     NOT NULL,           -- 'Attack', 'ClaimTerritory', 'EndPhase' ...
    action              jsonb    NOT NULL,
    events              jsonb    NOT NULL,           -- what happened, including every die face
    version_after       bigint   NOT NULL CHECK (version_after >= 1),
    rng_position_after  bigint   NOT NULL CHECK (rng_position_after >= 0),
    created_at          timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (match_id, seq),
    FOREIGN KEY (match_id, seat_no) REFERENCES seats (match_id, seat_no)
);
-- created_at is AUDIT ONLY and must never be a rule input. A timestamp that
-- influenced a rule would make the match non-reproducible.

-- Append-only is a CONVENTION in the prototype (D-64): nothing in the server
-- issues an UPDATE or a DELETE against this table, and TC-DB-11 asserts the
-- log never shrinks. To enforce it at the database instead, uncomment the two
-- lines below once the application role exists. [P3]
--
--   REVOKE UPDATE, DELETE ON moves FROM app_user;
--   GRANT  INSERT, SELECT ON moves TO   app_user;
--
-- Worth doing if your supervisor asks how an append-only log is guaranteed: a
-- privilege is a guarantee, application discipline is a promise.

-- =====================================================================
-- VALIDATION
-- =====================================================================
-- Load this file, then B2, then run:
--
--     psql -d order_and_conquest -f tools/verify_db.sql
--
-- It prints every count the documents assert (13 tables, 42 territories,
-- 6 continents, 83 land borders, 36 coastal, 1,330 ordered pairs within 5
-- land steps) and runs the three map validation queries, each of which must
-- return zero rows:
--
--   1. both ends of every sea route are coastal
--   2. no sea route duplicates a land border
--   3. every territory has at least one land neighbour
--
-- STATUS AS SHIPPED: not verified on this machine. PostgreSQL was not
-- installed where this appendix was written, so the load has not been run
-- here. The counts above are derived from shared/maps/world_classic.json by
-- tools/generate_map_seed.py --stats, which does agree with them. Step 6 of
-- docs/15-lan-demo-runbook.md is where the team runs the load itself.
-- =====================================================================
