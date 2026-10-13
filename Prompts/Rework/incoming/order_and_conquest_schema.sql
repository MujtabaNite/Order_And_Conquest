-- =====================================================================
-- Order & Conquest — normalised database schema (PostgreSQL 13+)
-- 13 tables in 3 groups:
--   A. MAP DATA   (static, loaded once from a seed file, never edited during play)
--   B. ACCOUNTS   (sign-up / login)
--   C. MATCH DATA (changes every turn)
--
-- Rules of thumb used everywhere:
--   * every fact is stored once (no copies that can disagree)
--   * anything that can be worked out is NOT stored (e.g. a player's
--     capabilities are computed from the territories/cards they own)
--   * constraints live in the database so a bug in a client or the server
--     can never save an impossible state
-- =====================================================================

-- ---------------------------------------------------------------------
-- A. MAP DATA
-- ---------------------------------------------------------------------

-- Lookup table: the six card symbols. Territories and cards point here.
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
-- RULE: a map that has been used by a match is never edited. To change a
-- map, insert a NEW row (e.g. 'world_classic_v2') and seed it again.

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
-- Capability profile is NOT a column. It is computed:
--   {Infantry} + {NavalForce if is_coastal} + {card_symbol}

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

-- Sea routes used only by Naval Force. A fixed list per map (not random).
-- Kept separate from land borders on purpose: Air Force range counts land
-- borders only and must never accidentally use these rows.
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
-- Rules a seed must satisfy (see validation queries at the bottom):
--   both ends coastal, not already a land border.

-- ---------------------------------------------------------------------
-- B. ACCOUNTS
-- ---------------------------------------------------------------------

CREATE TABLE users (
    user_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username       text NOT NULL,
    password_hash  text NOT NULL,                    -- Argon2id/bcrypt hash, NEVER the password
    display_name   text NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    last_login_at  timestamptz
);
CREATE UNIQUE INDEX ux_users_username ON users (lower(username));

-- ---------------------------------------------------------------------
-- C. MATCH DATA
-- ---------------------------------------------------------------------

CREATE TABLE matches (
    match_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    map_id           integer NOT NULL REFERENCES maps(map_id),
    created_by       uuid    NOT NULL REFERENCES users(user_id),
    room_code        text    NOT NULL,               -- what players type to join, e.g. 'K7QF'
    status           text    NOT NULL DEFAULT 'lobby'
                     CHECK (status IN ('lobby','in_progress','finished','abandoned')),
    phase            text    NOT NULL DEFAULT 'claim'
                     CHECK (phase IN ('claim','draft','attack','occupy','fortify','end_turn','game_over')),
    current_seat_no  smallint,                       -- whose turn (NULL while in lobby)
    round_no         integer  NOT NULL DEFAULT 0 CHECK (round_no >= 0),
    trade_index      integer  NOT NULL DEFAULT 0 CHECK (trade_index >= 0),  -- how many card sets traded so far
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
-- A room code must be unique among games that are still running.
CREATE UNIQUE INDEX ux_matches_active_room_code
    ON matches (room_code) WHERE status IN ('lobby','in_progress');

-- Rule settings FROZEN for this match. 1 row per match (1:1).
-- Copied from defaults when the match is created; never read live afterwards,
-- so editing a default can never change a game in progress.
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
    -- Extensions: OFF by default so the first version is exactly classic RISK.
    air_force_enabled      boolean  NOT NULL DEFAULT false,
    air_max_range          smallint NOT NULL DEFAULT 5   CHECK (air_max_range BETWEEN 1 AND 10),
    air_attacks_per_turn   smallint NOT NULL DEFAULT 1   CHECK (air_attacks_per_turn >= 1),
    naval_force_enabled    boolean  NOT NULL DEFAULT false
);

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
    -- Which columns must be filled depends on the kind of seat:
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

-- Now that seats exists, "whose turn" and "who won" can point at a real seat.
ALTER TABLE matches
    ADD FOREIGN KEY (match_id, current_seat_no) REFERENCES seats (match_id, seat_no),
    ADD FOREIGN KEY (match_id, winner_seat_no)  REFERENCES seats (match_id, seat_no);

-- Who owns each territory and how many armies are on it.
-- A row is added when a territory is first claimed. After the claim phase
-- every territory of the map has exactly one row.
CREATE TABLE match_territories (
    match_id      uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    territory_id  integer  NOT NULL REFERENCES territories(territory_id),
    owner_seat_no smallint NOT NULL,
    armies        integer  NOT NULL CHECK (armies >= 1),   -- a territory is never empty
    PRIMARY KEY (match_id, territory_id),
    FOREIGN KEY (match_id, owner_seat_no) REFERENCES seats (match_id, seat_no)
);
CREATE INDEX ix_match_territories_owner ON match_territories (match_id, owner_seat_no);

-- The deck: one card per territory + the wild cards.
-- The symbol is NOT stored: it is the territory's card_symbol (or 'Wild' if territory_id is NULL).
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

-- Append-only history of every action. Lets us resume, replay and audit a game.
-- action/events are JSON on purpose: this is a log, it is only ever read back
-- whole, and each action type has a different shape.
CREATE TABLE moves (
    match_id            uuid     NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    seq                 bigint   NOT NULL CHECK (seq >= 1),
    seat_no             smallint NOT NULL,
    round_no            integer  NOT NULL,
    phase               text     NOT NULL,
    action_type         text     NOT NULL,           -- 'Attack', 'ClaimTerritory', 'EndPhase' ...
    action              jsonb    NOT NULL,
    events              jsonb    NOT NULL,           -- what happened, including dice rolled
    version_after       bigint   NOT NULL CHECK (version_after >= 1),
    rng_position_after  bigint   NOT NULL CHECK (rng_position_after >= 0),
    created_at          timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (match_id, seq),
    FOREIGN KEY (match_id, seat_no) REFERENCES seats (match_id, seat_no)
);

-- =====================================================================
-- VALIDATION QUERIES — run after seeding a map. Every query should
-- return ZERO rows (or the number stated in the comment).
-- =====================================================================
-- 1. Sea route ends must both be coastal:
--    SELECT sr.* FROM sea_routes sr
--      JOIN territories a ON a.territory_id = sr.territory_a
--      JOIN territories b ON b.territory_id = sr.territory_b
--     WHERE NOT a.is_coastal OR NOT b.is_coastal;
-- 2. A sea route must not duplicate a land border:
--    SELECT sr.* FROM sea_routes sr
--      JOIN territory_adjacency ad
--        ON ad.territory_a = sr.territory_a AND ad.territory_b = sr.territory_b;
-- 3. Every territory has at least one land neighbour:
--    SELECT t.key FROM territories t
--     WHERE NOT EXISTS (SELECT 1 FROM territory_adjacency a
--                        WHERE t.territory_id IN (a.territory_a, a.territory_b));
