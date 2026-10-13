-- =====================================================================
-- tools/verify_db.sql — prove the database is what the documents claim
-- =====================================================================
--
-- WHAT THIS IS FOR
--   Every count in docs/06-database-design.md section 6.9 is printed by this
--   script. Run it and you can say the design was verified instead of
--   asserted. It is also step 6 of docs/15-lan-demo-runbook.md, and it is the
--   fastest way to prove the database is healthy before a demo.
--
-- HOW TO RUN IT
--   createdb order_and_conquest
--   psql -d order_and_conquest -f appendices/B-database-schema.sql
--   psql -d order_and_conquest -f appendices/B2-seed-world-classic.sql
--   psql -d order_and_conquest -f tools/verify_db.sql
--
--   Expected: every line of Part 1 reads PASS, every query in Part 2 returns
--   "0 rows", and Part 3 reads "10 of 10 rejected".
--
-- READ THIS BEFORE QUOTING THE RESULT
--   This script has NOT been executed by the author of this commit.
--   PostgreSQL was not installed on the machine where the rework was done, so
--   nothing here is a verified claim yet. The numbers it tests against were
--   derived independently by `python tools/generate_map_seed.py --stats`,
--   which DID run and which does agree with them. Until one of you runs this,
--   write "not verified" in the report, not "passed".
--
-- It changes nothing: Part 3 wraps its writes in a transaction and rolls back.
-- =====================================================================

\set ON_ERROR_STOP off
\timing off
\pset pager off

\echo ''
\echo '====================================================================='
\echo ' PART 1 - the counts the documents assert'
\echo '====================================================================='

SELECT 'tables'            AS what,  13 AS expected, count(*) AS actual,
       CASE WHEN count(*) =   13 THEN 'PASS' ELSE 'FAIL' END AS result
  FROM information_schema.tables
 WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'card symbols',              6, count(*),
       CASE WHEN count(*) =    6 THEN 'PASS' ELSE 'FAIL' END FROM card_symbols
UNION ALL
SELECT 'maps',                      1, count(*),
       CASE WHEN count(*) =    1 THEN 'PASS' ELSE 'FAIL' END FROM maps
UNION ALL
SELECT 'continents',                6, count(*),
       CASE WHEN count(*) =    6 THEN 'PASS' ELSE 'FAIL' END FROM continents
UNION ALL
SELECT 'territories',              42, count(*),
       CASE WHEN count(*) =   42 THEN 'PASS' ELSE 'FAIL' END FROM territories
UNION ALL
SELECT 'coastal territories',      36, count(*),
       CASE WHEN count(*) =   36 THEN 'PASS' ELSE 'FAIL' END
  FROM territories WHERE is_coastal
UNION ALL
SELECT 'landlocked territories',    6, count(*),
       CASE WHEN count(*) =    6 THEN 'PASS' ELSE 'FAIL' END
  FROM territories WHERE NOT is_coastal
UNION ALL
SELECT 'land borders',             83, count(*),
       CASE WHEN count(*) =   83 THEN 'PASS' ELSE 'FAIL' END FROM territory_adjacency
UNION ALL
SELECT 'borders crossing water',   10, count(*),
       CASE WHEN count(*) =   10 THEN 'PASS' ELSE 'FAIL' END
  FROM territory_adjacency WHERE crosses_water
UNION ALL
SELECT 'sea routes (empty, D-37)',  0, count(*),
       CASE WHEN count(*) =    0 THEN 'PASS' ELSE 'see note' END FROM sea_routes;

\echo ''
\echo '-- card symbols on territories: expect 12 / 10 / 8 / 7 / 5, and never Wild'
SELECT card_symbol,
       count(*) AS territories,
       CASE card_symbol
            WHEN 'Infantry'   THEN 12 WHEN 'Cavalry'    THEN 10
            WHEN 'Artillery'  THEN  8 WHEN 'AirForce'   THEN  7
            WHEN 'NavalForce' THEN  5 ELSE 0 END AS expected,
       CASE WHEN count(*) = CASE card_symbol
            WHEN 'Infantry'   THEN 12 WHEN 'Cavalry'    THEN 10
            WHEN 'Artillery'  THEN  8 WHEN 'AirForce'   THEN  7
            WHEN 'NavalForce' THEN  5 ELSE 0 END
            THEN 'PASS' ELSE 'FAIL' END AS result
  FROM territories
 GROUP BY card_symbol
 ORDER BY territories DESC, card_symbol;

\echo ''
\echo '-- continent sizes: expect NA 9 / SA 4 / EU 7 / AF 6 / AS 12 / AU 4'
SELECT c.code, c.name, c.bonus_armies, count(t.territory_id) AS territories
  FROM continents c
  LEFT JOIN territories t ON t.continent_id = c.continent_id
 GROUP BY c.code, c.name, c.bonus_armies, c.continent_id
 ORDER BY c.continent_id;

\echo ''
\echo '-- AIR FORCE REACH. Ordered territory pairs within 5 LAND steps.'
\echo '-- Expect 1330 of 1722 (77.2%). Land borders only - sea_routes is not'
\echo '-- joined anywhere in this query, which is the point (C-08, D-53).'
WITH RECURSIVE edges AS (
        SELECT territory_a AS a, territory_b AS b FROM territory_adjacency
        UNION ALL
        SELECT territory_b AS a, territory_a AS b FROM territory_adjacency
     ),
     reach AS (
        SELECT a AS src, b AS dst, 1 AS steps FROM edges
        UNION
        SELECT r.src, e.b, r.steps + 1
          FROM reach r
          JOIN edges e ON e.a = r.dst
         WHERE r.steps < 5
     )
SELECT count(*)                                   AS pairs_within_5,
       (SELECT count(*) * (count(*) - 1) FROM territories) AS ordered_pairs,
       round(100.0 * count(*)
             / (SELECT count(*) * (count(*) - 1) FROM territories), 1) AS percent,
       CASE WHEN count(*) = 1330 THEN 'PASS' ELSE 'FAIL' END AS result
  FROM (SELECT DISTINCT src, dst FROM reach WHERE src <> dst) p;

\echo ''
\echo '====================================================================='
\echo ' PART 2 - map validation. EVERY query must return 0 rows.'
\echo '====================================================================='

\echo ''
\echo '-- V1: both ends of a sea route must be coastal'
SELECT a.key AS from_key, b.key AS to_key
  FROM sea_routes sr
  JOIN territories a ON a.territory_id = sr.territory_a
  JOIN territories b ON b.territory_id = sr.territory_b
 WHERE NOT a.is_coastal OR NOT b.is_coastal;

\echo ''
\echo '-- V2: a sea route must not duplicate a land border'
SELECT a.key AS from_key, b.key AS to_key
  FROM sea_routes sr
  JOIN territory_adjacency ad
    ON ad.territory_a = sr.territory_a AND ad.territory_b = sr.territory_b
  JOIN territories a ON a.territory_id = sr.territory_a
  JOIN territories b ON b.territory_id = sr.territory_b;

\echo ''
\echo '-- V3: every territory has at least one land neighbour'
SELECT t.key
  FROM territories t
 WHERE NOT EXISTS (SELECT 1 FROM territory_adjacency a
                    WHERE t.territory_id IN (a.territory_a, a.territory_b));

\echo ''
\echo '-- V4: every border joins two territories of the SAME map'
SELECT ad.territory_a, ad.territory_b
  FROM territory_adjacency ad
  JOIN territories a ON a.territory_id = ad.territory_a
  JOIN territories b ON b.territory_id = ad.territory_b
 WHERE a.map_id <> b.map_id OR a.map_id <> ad.map_id;

\echo ''
\echo '-- V5: no territory is its own neighbour'
SELECT * FROM territory_adjacency WHERE territory_a = territory_b;

\echo ''
\echo '-- V6: no territory carries the Wild symbol'
SELECT key FROM territories WHERE card_symbol = 'Wild';

\echo ''
\echo '====================================================================='
\echo ' PART 3 - the database must REFUSE impossible data'
\echo '====================================================================='
\echo ' Ten deliberate attempts to save something that must never exist.'
\echo ' Each is expected to be REJECTED by a constraint. This whole part is'
\echo ' rolled back, so the database is unchanged afterwards.'
\echo ' These are test cases TC-DB-01 .. TC-DB-10 of appendices/F-test-cases.md.'
\echo ''

BEGIN;

-- Scratch fixtures: two accounts, one match, two seats, one owned territory.
INSERT INTO users (username, password_hash, display_name)
     VALUES ('_verify_one', 'not-a-real-hash', 'Verify One'),
            ('_verify_two', 'not-a-real-hash', 'Verify Two');

INSERT INTO matches (map_id, created_by, room_code, rng_seed)
     VALUES ((SELECT map_id  FROM maps  WHERE map_key = 'world_classic'),
             (SELECT user_id FROM users WHERE username = '_verify_one'),
             'VFY1', 20261013);

INSERT INTO match_rules (match_id)
     VALUES ((SELECT match_id FROM matches WHERE room_code = 'VFY1'));

INSERT INTO seats (match_id, seat_no, kind, user_id, colour)
     VALUES ((SELECT match_id FROM matches WHERE room_code = 'VFY1'),
             0, 'Human', (SELECT user_id FROM users WHERE username = '_verify_one'),
             '#FF0103');

INSERT INTO seats (match_id, seat_no, kind, ai_agent, colour)
     VALUES ((SELECT match_id FROM matches WHERE room_code = 'VFY1'),
             1, 'Ai', 'MarsBot', '#96843C');

DO $$
DECLARE
    m          uuid;
    map        integer;
    rejected   integer := 0;
    notes      text    := '';
BEGIN
    SELECT match_id INTO m   FROM matches WHERE room_code = 'VFY1';
    SELECT map_id   INTO map FROM maps    WHERE map_key  = 'world_classic';

    -- TC-DB-01  a territory with 0 armies        (match_territories.armies >= 1)
    BEGIN
        INSERT INTO match_territories (match_id, territory_id, owner_seat_no, armies)
        VALUES (m, (SELECT territory_id FROM territories WHERE key = 'alaska'), 0, 0);
        notes := notes || E'\n  TC-DB-01 NOT REJECTED: a territory with 0 armies was saved';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-02  a border written backwards       (CHECK territory_a < territory_b)
    BEGIN
        INSERT INTO territory_adjacency (map_id, territory_a, territory_b)
        VALUES (map,
                (SELECT max(territory_id) FROM territories WHERE map_id = map),
                (SELECT min(territory_id) FROM territories WHERE map_id = map));
        notes := notes || E'\n  TC-DB-02 NOT REJECTED: a backwards border was saved';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-03  a human seat with no account     (seats kind/user_id CHECK)
    BEGIN
        INSERT INTO seats (match_id, seat_no, kind, colour)
        VALUES (m, 2, 'Human', '#2F6E92');
        notes := notes || E'\n  TC-DB-03 NOT REJECTED: a Human seat with no user was saved';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-04  one account in two seats         (ux_seats_one_seat_per_user)
    BEGIN
        INSERT INTO seats (match_id, seat_no, kind, user_id, colour)
        VALUES (m, 3, 'Human',
                (SELECT user_id FROM users WHERE username = '_verify_one'), '#6D9423');
        notes := notes || E'\n  TC-DB-04 NOT REJECTED: one account took two seats';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-05  a second rules row for one match (match_rules PRIMARY KEY)
    BEGIN
        INSERT INTO match_rules (match_id) VALUES (m);
        notes := notes || E'\n  TC-DB-05 NOT REJECTED: a match got two rules rows';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-06  dice outside 2..20              (match_rules.dice_sides CHECK)
    BEGIN
        UPDATE match_rules SET dice_sides = 21 WHERE match_id = m;
        notes := notes || E'\n  TC-DB-06 NOT REJECTED: dice_sides = 21 was saved';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-07  a winner while still running     (matches winner/status CHECK)
    BEGIN
        UPDATE matches SET status = 'in_progress', winner_seat_no = 0 WHERE match_id = m;
        notes := notes || E'\n  TC-DB-07 NOT REJECTED: a running match has a winner';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-08  a re-used active room code       (ux_matches_active_room_code)
    BEGIN
        INSERT INTO matches (map_id, created_by, room_code, rng_seed)
        VALUES (map, (SELECT user_id FROM users WHERE username = '_verify_two'),
                'VFY1', 7);
        notes := notes || E'\n  TC-DB-08 NOT REJECTED: an active room code was re-used';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-09  the Wild symbol on a territory   (territories.card_symbol CHECK)
    BEGIN
        INSERT INTO territories (map_id, continent_id, key, name,
                                 is_coastal, card_symbol, label_x, label_y)
        VALUES (map,
                (SELECT continent_id FROM continents
                  WHERE map_id = map AND code = 'NA'),
                '_verify_wild', 'Verify Wild', false, 'Wild', 0, 0);
        notes := notes || E'\n  TC-DB-09 NOT REJECTED: a territory carries the Wild symbol';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    -- TC-DB-10  a card in a hand with no holder  (match_cards location CHECK)
    BEGIN
        INSERT INTO match_cards (match_id, card_no, territory_id, location)
        VALUES (m, 1, (SELECT territory_id FROM territories WHERE key = 'brazil'),
                'hand');
        notes := notes || E'\n  TC-DB-10 NOT REJECTED: a held card has no holder';
    EXCEPTION WHEN others THEN rejected := rejected + 1;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '  % of 10 rejected', rejected;
    IF rejected = 10 THEN
        RAISE NOTICE '  PASS - the database refused every impossible row.';
    ELSE
        RAISE NOTICE '  FAIL - a constraint is missing:%', notes;
    END IF;
    RAISE NOTICE '';
END $$;

ROLLBACK;

\echo ''
\echo '-- rolled back. Confirm nothing was left behind (expect 0 and 0):'
SELECT (SELECT count(*) FROM users   WHERE username LIKE '\_verify\_%') AS scratch_users,
       (SELECT count(*) FROM matches WHERE room_code = 'VFY1')          AS scratch_matches;

\echo ''
\echo '====================================================================='
\echo ' Done. Part 1 all PASS, Part 2 all 0 rows, Part 3 "10 of 10 rejected"'
\echo ' means the database matches docs/06-database-design.md.'
\echo '====================================================================='
