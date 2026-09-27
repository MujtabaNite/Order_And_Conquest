-- =====================================================================
--  Order & Conquest — Appendix B — Database Schema (PostgreSQL)
-- =====================================================================
--  Deliverable M. This file is the executable form of docs/06-database-design.md.
--  It is a transcription of §6.5 (constraints CK-01…CK-16) and §6.6 (the data
--  dictionary), not an independent design. Where the two could disagree, §6.6
--  is authoritative and this file is the defect.
--
--  Six tables, exactly as locked by the master specification §32 and §40:
--      users, matches, seats, territory_state, cards, moves
--  No seventh table is added. Per-territory immutable facts live inside
--  matches.effective_map (jsonb), which is why there is no `territories`
--  table and no `maps` table — see §6.4 "Why the effective map is frozen".
--
--  Target: PostgreSQL 13 or later (for gen_random_uuid()).
--  On PostgreSQL 12 or earlier, run:  CREATE EXTENSION pgcrypto;
--  For the SQLite substitution table, see §6.8.
--
--  Traceability: D-03 (six card symbols), FR-56…FR-59 (persistence),
--  FR-61 (optimistic concurrency), NFR-09 (password hashing),
--  NFR-12…NFR-14 (durability, atomicity, resume fidelity),
--  NFR-19 (portability).
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
--  1 · users
-- ---------------------------------------------------------------------
--  Registered accounts only. Guest play creates NO row here: an offline
--  match has seats with user_id IS NULL and a display_name typed at the
--  lobby. That is what lets Phases 1–5 run with no authentication at all
--  (FR-03), and it is why seats.user_id is nullable.
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    username      text        NOT NULL,
    password_hash text        NOT NULL,   -- Argon2id PHC string. NEVER a plaintext
                                          -- password and never a bare hash (NFR-09).
    display_name  text        NOT NULL,
    colour        text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    last_login_at timestamptz
);

-- Case-insensitive uniqueness (§6.6): 'Player' and 'player' are one account.
CREATE UNIQUE INDEX ux_users_username_lower ON users (lower(username));

COMMENT ON COLUMN users.password_hash IS
    'Argon2id PHC string. Correcting the 2022 report''s plaintext storage (§6.9, NFR-09).';

-- ---------------------------------------------------------------------
--  2 · matches
-- ---------------------------------------------------------------------
--  The snapshot root. One row per match, carrying the authoritative
--  phase/round/seat cursor, the optimistic-concurrency version, the
--  frozen effective map, and the random-source position.
--
--  effective_map is FROZEN at creation (FR-10). It contains the
--  normalised territories, adjacency, continents, capability profiles and
--  the GENERATED SEA ROUTES for this match. Editing shared/maps/*.json
--  afterwards cannot alter a match in progress — which is what makes a
--  procedural map resumable at all.
-- ---------------------------------------------------------------------
CREATE TABLE matches (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),

    status          text        NOT NULL DEFAULT 'lobby',
    phase           text        NOT NULL DEFAULT 'claim',
    round           int         NOT NULL DEFAULT 0,
    current_seat    int         NOT NULL DEFAULT 0,
    version         bigint      NOT NULL DEFAULT 1,

    map_key         text        NOT NULL,   -- 'world_classic' or 'generated:<seed>'.
                                            -- Display and audit only; never a rule input.
    map_format_ver  int         NOT NULL,
    effective_map   jsonb       NOT NULL,   -- FROZEN. See above.
    mask            jsonb,                  -- Submersion mask. Optional feature (D-05);
                                            -- null in v1. Column kept: it is free.

    rng_seed        bigint      NOT NULL,
    rng_position    bigint      NOT NULL DEFAULT 0,   -- Draws consumed. WITH rng_seed this
                                                      -- reconstructs the exact stream (FR-58).

    options         jsonb       NOT NULL DEFAULT '{}'::jsonb,
    trade_index     int         NOT NULL DEFAULT 0,   -- Position in the escalation table.
                                                      -- Match-wide, monotonic, never resets (DR-13).
    room_code       text,                             -- Built now, used in Phase 6.
    winner_seat     int,

    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ck_matches_status   -- CK-01
        CHECK (status IN ('lobby','setup','in_progress','finished','abandoned')),
    CONSTRAINT ck_matches_phase    -- CK-02
        CHECK (phase IN ('claim','draft','attack','occupy','fortify','end_turn','game_over')),
    CONSTRAINT ck_matches_version      CHECK (version      >= 1),  -- CK-03
    CONSTRAINT ck_matches_rng_position CHECK (rng_position >= 0),  -- CK-04
    CONSTRAINT ck_matches_trade_index  CHECK (trade_index  >= 0),  -- CK-05
    CONSTRAINT ck_matches_round        CHECK (round        >= 0),  -- CK-06

    -- A winner exists only on a finished match, and a match finished by
    -- domination must name one. Round-cap endings set status='finished'
    -- with winner_seat from the tiebreak, so this stays an equivalence.
    CONSTRAINT ck_matches_winner
        CHECK ((winner_seat IS NOT NULL) <= (status = 'finished'))
);

-- FR-04: the resumable-match list. Partial, because finished matches are the
-- majority after a month and never appear in that list.
CREATE INDEX ix_matches_status ON matches (updated_at DESC)
    WHERE status = 'in_progress';

CREATE UNIQUE INDEX ux_matches_room ON matches (room_code)
    WHERE room_code IS NOT NULL;

COMMENT ON COLUMN matches.effective_map IS
    'Frozen normalised map including generated sea routes (FR-10). Never re-read from disk.';
COMMENT ON COLUMN matches.rng_position IS
    'The RNG stream is STATE. Seed alone cannot resume a match (§6.4, TC-DET-03).';

-- ---------------------------------------------------------------------
--  3 · seats
-- ---------------------------------------------------------------------
--  The unified seat model. Single-player, pass-and-play and online differ
--  by NOTHING except the `kind` column across these rows. Going online in
--  Phase 6 is an UPDATE of kind to 'RemoteHuman'; there is no other schema
--  change and no second match model.
--
--  A 2-player match inserts a THIRD seat of kind 'Neutral' (FR-14, D-07)
--  and uses the 3-player starting-army count of 35.
-- ---------------------------------------------------------------------
CREATE TABLE seats (
    match_id         uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    seat_index       int  NOT NULL,
    kind             text NOT NULL,
    user_id          uuid REFERENCES users(id) ON DELETE SET NULL,
    display_name     text NOT NULL,
    colour           text NOT NULL,
    agent            text,               -- 'passive'|'chaotic'|'aggressive'|'mars'|'onnx:v7'
    status           text NOT NULL DEFAULT 'active',
    eliminated_by    int,                -- Seat that eliminated this one; drives FR-38.
    eliminated_round int,
    final_rank       int,

    PRIMARY KEY (match_id, seat_index),

    CONSTRAINT ck_seats_index  CHECK (seat_index BETWEEN 0 AND 5),          -- CK-07
    CONSTRAINT ck_seats_kind                                                -- CK-08
        CHECK (kind IN ('LocalHuman','RemoteHuman','Ai','Neutral')),
    CONSTRAINT ck_seats_agent                                               -- CK-09
        CHECK ((kind = 'Ai') = (agent IS NOT NULL)),
    CONSTRAINT ck_seats_status                                              -- CK-10
        CHECK (status IN ('active','eliminated','left')),

    -- A remote human is, by definition, an authenticated account.
    CONSTRAINT ck_seats_remote_has_user
        CHECK (kind <> 'RemoteHuman' OR user_id IS NOT NULL),
    -- A neutral seat is never a person and never an agent: it does not take turns.
    CONSTRAINT ck_seats_neutral_anonymous
        CHECK (kind <> 'Neutral' OR (user_id IS NULL AND agent IS NULL)),
    -- Elimination bookkeeping is consistent with status.
    CONSTRAINT ck_seats_eliminated
        CHECK ((status = 'eliminated') OR (eliminated_by IS NULL AND eliminated_round IS NULL)),
    CONSTRAINT ck_seats_not_self_eliminated
        CHECK (eliminated_by IS NULL OR eliminated_by <> seat_index)
);

CREATE INDEX ix_seats_user ON seats (user_id) WHERE user_id IS NOT NULL;

COMMENT ON COLUMN seats.agent IS
    'Agent name as a string, deliberately not a FK: ''onnx:v7'' names a versioned '
    'policy file on disk, not a database row. A finished match therefore records '
    'WHICH network won, which is what makes checkpoint comparison possible.';

-- ---------------------------------------------------------------------
--  4 · territory_state
-- ---------------------------------------------------------------------
--  The MUTABLE half of a territory: who owns it and how many armies sit
--  on it. Everything immutable — name, continent, neighbours, coastal
--  flag, card symbol, capability profile — lives in effective_map and is
--  NOT duplicated here. That split is the correction to the 2022 report's
--  denormalised Map table (§6.9).
--
--  Rows are inserted ONCE, at match creation, from the effective map:
--  42 rows for the classic board, fewer if a mask submerged territories.
--  Never 42 by assumption (TC-PER-02).
-- ---------------------------------------------------------------------
CREATE TABLE territory_state (
    match_id      uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    territory_key text NOT NULL,
    owner_seat    int  NOT NULL,
    armies        int  NOT NULL DEFAULT 1,

    PRIMARY KEY (match_id, territory_key),
    FOREIGN KEY (match_id, owner_seat) REFERENCES seats(match_id, seat_index),

    CONSTRAINT ck_territory_armies CHECK (armies >= 1)   -- CK-11, DR-04
);

-- Territory count per seat, recomputed every Draft phase (FR-23).
CREATE INDEX ix_territory_owner ON territory_state (match_id, owner_seat);

COMMENT ON CONSTRAINT ck_territory_armies ON territory_state IS
    'DR-04: a territory is never empty. This is why occupation moves at least as '
    'many armies as dice rolled and fortification always leaves one behind.';

-- ---------------------------------------------------------------------
--  5 · cards
-- ---------------------------------------------------------------------
--  44 rows per match on the classic board: 42 territory cards + 2 wilds
--  (D-14). Fewer when territories are submerged — a card naming a drowned
--  territory would make the +2 territory bonus unclaimable, so the mask
--  resolver drops those cards with the territories.
--
--  D-03: the symbol domain carries SIX values, extended from the source
--  report's four. Six symbols do NOT imply five-card sets. A set is
--  exactly THREE cards (DR-12, C-05) — this is an explicit §40 prohibition.
-- ---------------------------------------------------------------------
CREATE TABLE cards (
    match_id    uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    card_key    text NOT NULL,           -- territory key, or 'wild_1' / 'wild_2'
    symbol      text NOT NULL,
    location    text NOT NULL DEFAULT 'deck',
    holder_seat int,
    deck_order  int,

    PRIMARY KEY (match_id, card_key),
    FOREIGN KEY (match_id, holder_seat) REFERENCES seats(match_id, seat_index),

    CONSTRAINT ck_cards_symbol                                              -- CK-12
        CHECK (symbol IN ('infantry','cavalry','artillery','airforce','naval','wild')),
    CONSTRAINT ck_cards_location                                            -- CK-13
        CHECK (location IN ('deck','hand','discard')),
    CONSTRAINT ck_cards_holder                                              -- CK-14
        CHECK ((location = 'hand') = (holder_seat IS NOT NULL)),
    -- Only the two wilds carry the 'wild' symbol, and they carry nothing else.
    CONSTRAINT ck_cards_wild_keys
        CHECK ((symbol = 'wild') = (card_key LIKE 'wild\_%'))
);

CREATE INDEX ix_cards_holder ON cards (match_id, holder_seat)
    WHERE holder_seat IS NOT NULL;

COMMENT ON COLUMN cards.deck_order IS
    'Written once at shuffle time. Storing the shuffled order explicitly — rather '
    'than re-deriving it from rng_seed — means resuming a match cannot possibly '
    'deal a different card, and keeps dealing independent of rng_position.';

-- ---------------------------------------------------------------------
--  6 · moves — the append-only log
-- ---------------------------------------------------------------------
--  One row per applied action, in order, forever. Three jobs from one
--  table (§6.3): replay, audit, and RL trajectory export.
--
--  `action` and `events` are stored VERBATIM as the API saw them, not
--  normalised into columns. A future action type needs no migration. The
--  events blob includes EVERY DIE FACE, which is what makes a replay
--  visually identical rather than merely outcome-identical.
-- ---------------------------------------------------------------------
CREATE TABLE moves (
    match_id           uuid        NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    seq                bigint      NOT NULL,
    seat_index         int         NOT NULL,
    round              int         NOT NULL,
    phase              text        NOT NULL,
    action             jsonb       NOT NULL,   -- exactly what the client POSTed
    events             jsonb       NOT NULL,   -- exactly what the engine returned
    version_after      bigint      NOT NULL,
    rng_position_after bigint      NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),  -- AUDIT ONLY. Never a rule input.

    PRIMARY KEY (match_id, seq),                            -- also ix_moves_match_seq
    FOREIGN KEY (match_id, seat_index) REFERENCES seats(match_id, seat_index),

    CONSTRAINT ck_moves_seq           CHECK (seq           >= 1),  -- CK-15
    CONSTRAINT ck_moves_version_after CHECK (version_after >= 1),  -- CK-16
    CONSTRAINT ck_moves_rng_after     CHECK (rng_position_after >= 0)
);

COMMENT ON COLUMN moves.created_at IS
    'Wall-clock time, audit only. A timestamp that influenced a rule would make the '
    'match non-reproducible, so the column is documented as audit-only to stop it '
    'becoming a temptation (§6.6).';

COMMIT;

-- =====================================================================
--  Append-only enforcement
-- =====================================================================
--  This REVOKE is the whole enforcement mechanism, and it is worth more
--  than a trigger: it makes a violation a permission error at the exact
--  call site, instead of a silent correctness loss discovered weeks later
--  in a replay that no longer matches its snapshot.
--
--  Run as the schema owner, after the application role exists. Substitute
--  the real role name for app_user.
-- =====================================================================

-- CREATE ROLE app_user LOGIN PASSWORD '<set-outside-source-control>';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON users, matches, seats,
--       territory_state, cards TO app_user;
-- GRANT SELECT, INSERT                 ON moves TO app_user;
-- REVOKE UPDATE, DELETE                ON moves FROM app_user;

-- For a SQLite build (NFR-19), the same guarantee comes from triggers,
-- because SQLite has no per-table privileges:
--
--   CREATE TRIGGER moves_no_update BEFORE UPDATE ON moves
--   BEGIN SELECT RAISE(ABORT, 'moves is append-only'); END;
--   CREATE TRIGGER moves_no_delete BEFORE DELETE ON moves
--   BEGIN SELECT RAISE(ABORT, 'moves is append-only'); END;

-- =====================================================================
--  The action transaction (§6.7)
-- =====================================================================
--  Every applied action is ONE transaction containing the snapshot update
--  and the log insert. The version predicate is the entire concurrency
--  design: if it matches no row, the transaction affects nothing, the
--  client receives 409 with the current state, and no partial write ever
--  existed (FR-61, NFR-13, TC-API-03, TC-PER-05).
--
--  BEGIN;
--    UPDATE matches
--       SET version      = version + 1,
--           rng_position = @newPosition,
--           phase        = @phase,
--           current_seat = @currentSeat,
--           round        = @round,
--           trade_index  = @tradeIndex,
--           updated_at   = now()
--     WHERE id = @matchId
--       AND version = @expectedVersion;   -- 0 rows => 409, nothing applied
--
--    -- territory_state, cards, seats updated from the new state
--
--    INSERT INTO moves (match_id, seq, seat_index, round, phase, action,
--                       events, version_after, rng_position_after)
--    VALUES (@matchId, @seq, @seat, @round, @phase, @action, @events,
--            @newVersion, @newPosition);
--  COMMIT;
--
--  There are no row locks, no SELECT ... FOR UPDATE, and no lock held
--  across a client round trip. A turn-based game has one writer at a time;
--  the only real contention is a double-tap, and a version check is the
--  cheapest correct answer to it. On localhost a double-tap is genuinely
--  faster than a round trip, so this is not deferred to Phase 6.
-- =====================================================================

-- =====================================================================
--  Invariants NOT expressible in SQL (§6.5)
-- =====================================================================
--  Enforced by the engine, each with a test:
--
--    Territory keys in territory_state match exactly the keys
--      in effective_map ............................................ TC-PER-02
--    Card keys match exactly the territory keys plus the wilds ..... TC-PER-03
--    Exactly one seat is 'active' and holds every territory when a
--      match is finished by domination ............................. TC-VIC-01
--    matches.rng_position equals rng_position_after of the highest
--      seq in moves ................................................ TC-DET-03
--
--  The last is the schema-level statement of determinism: if the snapshot
--  and the log disagree about the random-source position, the match is not
--  reproducible — and that is detectable without playing it.
-- =====================================================================
