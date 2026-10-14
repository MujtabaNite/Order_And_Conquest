#!/usr/bin/env python3
"""Regenerate the map seed SQL from the authored JSON map.

    python tools/generate_map_seed.py                      # writes appendices/B2-seed-world-classic.sql
    python tools/generate_map_seed.py --check              # verify only, write nothing
    python tools/generate_map_seed.py --stats              # print the derived counts and exit

WHY THIS EXISTS (D-50, PROMPT A section 6.6)
--------------------------------------------
Two things now describe the same board:

    shared/maps/world_classic.json   the HUMAN-EDITED source. A person adds a
                                     territory or a border here.
    appendices/B2-...sql             the RUNTIME source. The server reads the
                                     map from PostgreSQL, not from the file.

If a person edits the JSON and forgets the SQL, the database and the design
document disagree and nobody notices until a match behaves oddly. This script
is the one-command answer: edit the JSON, run this, commit both.

It is a tool, not game code. It contains no rule and makes no decision: it
reads the JSON, checks it, and prints SQL. The capability profile is NOT
emitted, because capability is derived and never stored (D-10).

Standard library only. No pip install, which matters on demo day.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAP_JSON = REPO / "shared" / "maps" / "world_classic.json"
SEED_SQL = REPO / "appendices" / "B2-seed-world-classic.sql"

# What the repository asserts about this board. The script fails if the JSON
# stops matching, so a silent map edit cannot quietly invalidate the documents.
# Every one of these numbers appears in docs/06-database-design.md section 6.9.
EXPECTED = {
    "continents": 6,
    "territories": 42,
    "land_borders": 83,
    "coastal": 36,
    "crosses_water": 10,
    "pairs_within_5": 1330,
    "diameter": 10,
}


# ----------------------------------------------------------------------
# load and check
# ----------------------------------------------------------------------

def load_map(path: Path) -> dict:
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def build_graph(territories: list[dict]) -> dict[str, set[str]]:
    """The land adjacency graph, as an undirected symmetric dictionary."""
    graph: dict[str, set[str]] = {t["key"]: set() for t in territories}
    for t in territories:
        for n in t["neighbours"]:
            graph[t["key"]].add(n)
    return graph


def check(m: dict) -> list[str]:
    """Return a list of problems. An empty list means the map is usable.

    These are the same rules as the V-01..V-12 map validations of
    appendices/C-map-specification.md, expressed in Python so the seed can
    never be generated from a map the engine would reject.
    """
    problems: list[str] = []
    territories = m["territories"]
    keys = [t["key"] for t in territories]
    continent_keys = {c["key"] for c in m["continents"]}

    # unique keys
    if len(keys) != len(set(keys)):
        dupes = sorted({k for k in keys if keys.count(k) > 1})
        problems.append(f"duplicate territory keys: {', '.join(dupes)}")

    key_set = set(keys)
    graph = build_graph(territories)

    for t in territories:
        k = t["key"]
        if t["continent"] not in continent_keys:
            problems.append(f"{k}: unknown continent {t['continent']!r}")
        if t["cardSymbol"] == "Wild":
            problems.append(f"{k}: a territory may never carry the Wild symbol")
        # neighbours exist, are not self, and are symmetric
        for n in t["neighbours"]:
            if n not in key_set:
                problems.append(f"{k}: neighbour {n!r} does not exist")
            elif n == k:
                problems.append(f"{k}: is its own neighbour")
            elif k not in graph.get(n, set()):
                problems.append(f"{k} -> {n} is not mirrored by {n} -> {k}")
        # the authored capability profile must equal rule CAP-1
        derived = {"Infantry", t["cardSymbol"]}
        if t["coastal"]:
            derived.add("NavalForce")
        if set(t.get("capabilities", [])) != derived:
            problems.append(
                f"{k}: capabilities {sorted(t.get('capabilities', []))} "
                f"!= CAP-1 derivation {sorted(derived)}"
            )

    # crossesWater must be a subset of the adjacency graph (it is a render hint)
    for a, b in m.get("crossesWater", []):
        if b not in graph.get(a, set()):
            problems.append(f"crossesWater {a}-{b} is not a land border")

    # the graph must be connected, or some territory is unreachable
    if keys:
        seen = {keys[0]}
        queue = deque([keys[0]])
        while queue:
            for n in graph[queue.popleft()]:
                if n not in seen:
                    seen.add(n)
                    queue.append(n)
        if len(seen) != len(keys):
            missing = sorted(key_set - seen)
            problems.append(f"graph is not connected; unreachable: {', '.join(missing)}")

    # sea routes, when the team adds them: both ends coastal, not a land border
    coastal = {t["key"] for t in territories if t["coastal"]}
    seen_routes: set[tuple[str, str]] = set()
    for route in m.get("seaRoutes", []):
        a, b = route[0], route[1]
        if a not in key_set or b not in key_set:
            problems.append(f"seaRoute {a}-{b}: unknown territory")
            continue
        if a not in coastal or b not in coastal:
            problems.append(f"seaRoute {a}-{b}: both ends must be coastal")
        if b in graph.get(a, set()):
            problems.append(f"seaRoute {a}-{b}: already a land border")
        pair = tuple(sorted((a, b)))
        if pair in seen_routes:
            problems.append(f"seaRoute {a}-{b}: duplicate")
        seen_routes.add(pair)

    return problems


# ----------------------------------------------------------------------
# derived counts
# ----------------------------------------------------------------------

def border_pairs(territories: list[dict]) -> list[tuple[str, str]]:
    """Each land border once, smaller key first, sorted. Matches the
    territory_a < territory_b constraint of territory_adjacency."""
    pairs = set()
    for t in territories:
        for n in t["neighbours"]:
            pairs.add(tuple(sorted((t["key"], n))))
    return sorted(pairs)


def all_distances(graph: dict[str, set[str]]) -> dict[str, dict[str, int]]:
    """Breadth-first search from every territory over LAND edges only.

    Land edges only is not a detail: Air Force range is defined over the land
    graph and sea routes are excluded (D-11, C-08). This function is handed
    `graph`, which is built from `neighbours`, and has no access to seaRoutes.
    """
    out: dict[str, dict[str, int]] = {}
    for start in graph:
        dist = {start: 0}
        queue = deque([start])
        while queue:
            cur = queue.popleft()
            for n in graph[cur]:
                if n not in dist:
                    dist[n] = dist[cur] + 1
                    queue.append(n)
        out[start] = dist
    return out


def stats(m: dict) -> dict:
    territories = m["territories"]
    graph = build_graph(territories)
    dists = all_distances(graph)

    reach5 = sum(
        1
        for start, dist in dists.items()
        for target, d in dist.items()
        if target != start and d <= 5
    )
    diameter = max(d for dist in dists.values() for d in dist.values())
    n = len(territories)

    # per-territory reach, for the O-04 question (is the air-capable SET right?)
    reach_each = {
        k: sum(1 for t, d in dist.items() if t != k and d <= 5)
        for k, dist in dists.items()
    }

    return {
        "continents": len(m["continents"]),
        "territories": n,
        "land_borders": len(border_pairs(territories)),
        "coastal": sum(1 for t in territories if t["coastal"]),
        "landlocked": sum(1 for t in territories if not t["coastal"]),
        "crosses_water": len(m.get("crossesWater", [])),
        "sea_routes": len(m.get("seaRoutes", [])),
        "ordered_pairs": n * (n - 1),
        "pairs_within_5": reach5,
        "diameter": diameter,
        "symbol_counts": _symbol_counts(territories),
        "reach_min": min(reach_each.items(), key=lambda kv: kv[1]),
        "reach_max": max(reach_each.items(), key=lambda kv: kv[1]),
        "reach_mean": sum(reach_each.values()) / n,
    }


def _symbol_counts(territories: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for t in territories:
        counts[t["cardSymbol"]] = counts.get(t["cardSymbol"], 0) + 1
    return dict(sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])))


# ----------------------------------------------------------------------
# SQL emission
# ----------------------------------------------------------------------

def q(text: str) -> str:
    """Single-quote a SQL string literal."""
    return "'" + text.replace("'", "''") + "'"


def sql_bool(value: bool) -> str:
    return "true" if value else "false"


def emit(m: dict) -> str:
    """Build the whole seed script.

    Every INSERT looks up its parents by KEY rather than by a hard-coded id,
    because `map_id` and `territory_id` are GENERATED ALWAYS AS IDENTITY and
    their values depend on insertion order. A seed that assumed id 1 would
    break the second time anyone loaded it.
    """
    map_key = m["key"]
    mid = f"(SELECT map_id FROM maps WHERE map_key={q(map_key)})"

    def cid(code: str) -> str:
        return (
            f"(SELECT continent_id FROM continents "
            f"WHERE map_id={mid} AND code={q(code)})"
        )

    def tid(key: str) -> str:
        return (
            f"(SELECT territory_id FROM territories "
            f"WHERE map_id={mid} AND key={q(key)})"
        )

    s = stats(m)
    water = {tuple(sorted(pair)) for pair in m.get("crossesWater", [])}
    out: list[str] = []
    w = out.append

    w("-- =====================================================================")
    w("-- Appendix B2 — Seed: the classic world map")
    w("-- =====================================================================")
    w("-- GENERATED FILE. Do not edit by hand.")
    w("--   source:    shared/maps/world_classic.json")
    w("--   generator: tools/generate_map_seed.py")
    w("--   regenerate: python tools/generate_map_seed.py")
    w("--")
    w("-- Run AFTER appendices/B-database-schema.sql, on an empty database.")
    w("--")
    w("-- What this file loads, all derived from the JSON by the generator:")
    w(f"--   {s['continents']} continents")
    w(f"--   {s['territories']} territories ({s['coastal']} coastal, {s['landlocked']} landlocked)")
    w(f"--   {s['land_borders']} land borders, each stored once ({s['crosses_water']} marked crosses_water)")
    w(f"--   {s['sea_routes']} sea routes")
    w("--")
    w("-- The capability profile is deliberately NOT loaded. It is computed from")
    w("-- is_coastal and card_symbol by rule CAP-1 (D-10): storing it would let it")
    w("-- disagree with ownership.")
    w("-- =====================================================================")
    w("")
    w("BEGIN;")
    w("")
    w("-- ---------------------------------------------------------------------")
    w("-- The board itself")
    w("-- ---------------------------------------------------------------------")
    w(
        "INSERT INTO maps (map_key, name, canvas_width, canvas_height) VALUES "
        f"({q(map_key)}, {q(m['name'])}, "
        f"{m['canvas']['width']}, {m['canvas']['height']});"
    )
    w("")
    w(f"-- ---------------------------------------------------------------------")
    w(f"-- {s['continents']} continents")
    w("-- ---------------------------------------------------------------------")
    for c in m["continents"]:
        w(
            "INSERT INTO continents (map_id, code, name, bonus_armies, colour) VALUES "
            f"({mid}, {q(c['key'])}, {q(c['name'])}, {c['bonus']}, {q(c['colour'])});"
        )
    w("")
    w(f"-- ---------------------------------------------------------------------")
    w(f"-- {s['territories']} territories")
    w("-- ---------------------------------------------------------------------")
    for t in m["territories"]:
        w(
            "INSERT INTO territories "
            "(map_id, continent_id, key, name, is_coastal, card_symbol, label_x, label_y) VALUES "
            f"({mid}, {cid(t['continent'])}, {q(t['key'])}, {q(t['name'])}, "
            f"{sql_bool(t['coastal'])}, {q(t['cardSymbol'])}, "
            f"{t['label'][0]}, {t['label'][1]});"
        )
    w("")
    w(f"-- ---------------------------------------------------------------------")
    w(f"-- {s['land_borders']} land borders")
    w("-- ---------------------------------------------------------------------")
    w("-- LEAST/GREATEST satisfies the CHECK (territory_a < territory_b) constraint")
    w("-- whatever order the ids came out in, so a border can never be stored twice.")
    for a, b in border_pairs(m["territories"]):
        crosses = sql_bool(tuple(sorted((a, b))) in water)
        w(
            "INSERT INTO territory_adjacency (map_id, territory_a, territory_b, crosses_water) "
            f"SELECT {mid}, LEAST(a.id, b.id), GREATEST(a.id, b.id), {crosses} "
            f"FROM (SELECT {tid(a)} AS id) a, (SELECT {tid(b)} AS id) b;"
            f"  -- {a} | {b}"
        )
    w("")
    w("-- ---------------------------------------------------------------------")
    w(f"-- {s['sea_routes']} sea routes")
    w("-- ---------------------------------------------------------------------")
    routes = m.get("seaRoutes", [])
    if routes:
        for route in routes:
            a, b = route[0], route[1]
            w(
                "INSERT INTO sea_routes (map_id, territory_a, territory_b) "
                f"SELECT {mid}, LEAST(a.id, b.id), GREATEST(a.id, b.id) "
                f"FROM (SELECT {tid(a)} AS id) a, (SELECT {tid(b)} AS id) b;"
                f"  -- {a} | {b}"
            )
    else:
        w("-- EMPTY ON PURPOSE (C-7 / D-37). The fixed list is a game-design choice")
        w("-- the team has not made yet, and Naval Force is off by default (D-54), so")
        w("-- classic RISK does not need a single row here.")
        w("--")
        w("-- To add one: put the pair in the seaRoutes array of")
        w("-- shared/maps/world_classic.json and re-run the generator. It checks that")
        w("-- both ends are coastal and that the pair is not already a land border")
        w("-- before it will emit anything. Appendices C has a proposed list of 8.")
        w("--")
        w("-- The generated statement looks like this:")
        w("--   INSERT INTO sea_routes (map_id, territory_a, territory_b)")
        w("--   SELECT <map>, LEAST(a.id, b.id), GREATEST(a.id, b.id)")
        w("--     FROM (SELECT <territory 'brazil'>   AS id) a,")
        w("--          (SELECT <territory 'congo'> AS id) b;")
    w("")
    w("COMMIT;")
    w("")
    w("-- ---------------------------------------------------------------------")
    w("-- After loading, check it: \\i tools/verify_db.sql")
    w("-- ---------------------------------------------------------------------")
    return "\n".join(out) + "\n"


# ----------------------------------------------------------------------
# entry point
# ----------------------------------------------------------------------

def print_stats(s: dict) -> None:
    print("Derived from shared/maps/world_classic.json")
    print("-" * 56)
    for label, key in [
        ("continents", "continents"),
        ("territories", "territories"),
        ("  coastal", "coastal"),
        ("  landlocked", "landlocked"),
        ("land borders", "land_borders"),
        ("  marked crosses_water", "crosses_water"),
        ("sea routes", "sea_routes"),
    ]:
        print(f"{label:<28}{s[key]:>6}")
    print("-" * 56)
    print(f"{'ordered pairs':<28}{s['ordered_pairs']:>6}")
    print(
        f"{'  within 5 land steps':<28}{s['pairs_within_5']:>6}"
        f"   ({100 * s['pairs_within_5'] / s['ordered_pairs']:.1f}%)"
    )
    print(f"{'land graph diameter':<28}{s['diameter']:>6}")
    print("-" * 56)
    print("card symbols on territories")
    for sym, n in s["symbol_counts"].items():
        print(f"  {sym:<26}{n:>6}")
    print(f"  {'+ Wild cards (not a territory)':<26}{2:>6}")
    print(f"  {'= deck':<26}{sum(s['symbol_counts'].values()) + 2:>6}")
    print("-" * 56)
    print("reach at range 5, per territory (open question O-04)")
    print(f"  worst  {s['reach_min'][0]:<22}{s['reach_min'][1]:>6} of {s['territories'] - 1}")
    print(f"  best   {s['reach_max'][0]:<22}{s['reach_max'][1]:>6} of {s['territories'] - 1}")
    print(f"  mean   {'':<22}{s['reach_mean']:>6.1f}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true",
                    help="validate and compare counts; write nothing")
    ap.add_argument("--stats", action="store_true",
                    help="print the derived counts and exit")
    ap.add_argument("--map", type=Path, default=MAP_JSON)
    ap.add_argument("--out", type=Path, default=SEED_SQL)
    args = ap.parse_args()

    if not args.map.exists():
        print(f"ERROR: map not found: {args.map}", file=sys.stderr)
        return 2

    m = load_map(args.map)

    problems = check(m)
    if problems:
        print(f"REFUSING: {args.map.name} has {len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    s = stats(m)

    mismatches = [
        (k, v, s[k]) for k, v in EXPECTED.items() if s.get(k) != v
    ]
    if mismatches:
        print("REFUSING: the map no longer matches what the documents assert.",
              file=sys.stderr)
        for key, want, got in mismatches:
            print(f"  - {key}: documents say {want}, map gives {got}", file=sys.stderr)
        print("\nIf the map change was intended, update EXPECTED in this script AND",
              file=sys.stderr)
        print("every number in docs/06 section 6.9 and REWORK-PLAN.md section 11.3.",
              file=sys.stderr)
        return 1

    if args.stats:
        print_stats(s)
        return 0

    text = emit(m)

    if args.check:
        if not args.out.exists():
            print(f"{args.out.name} does not exist yet; run without --check")
            return 1
        current = args.out.read_text(encoding="utf-8")
        if current == text:
            print(f"OK: {args.out.name} is up to date with {args.map.name}")
            return 0
        print(f"STALE: {args.out.name} differs from what {args.map.name} generates.",
              file=sys.stderr)
        print("Run: python tools/generate_map_seed.py", file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(text, encoding="utf-8")
    print(f"wrote {args.out.relative_to(REPO)}  "
          f"({len(text.splitlines())} lines, "
          f"{s['territories']} territories, {s['land_borders']} borders, "
          f"{s['sea_routes']} sea routes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
