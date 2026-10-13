# REWORK-PLAN — Phase 0 (plan only, no edits yet)

**Branch:** `prototype-edition` · **Written:** 13 October 2026 · **Author:** rework agent

> **In plain words.** This file is the survey before the building work. It lists everything in the
> repository that contradicts the team's new decisions, everything that is simply wrong today, the ten
> questions worth answering before the rewriting starts, and the order the work will be done in.
> No document has been edited yet. The only changes so far are: a new branch, and the team's new
> database pack copied into `_incoming/`.

## 0. What was read

`README.md` · `docs/00`, `docs/14`, `docs/06` (header + schema sections) · `PLATFORM-SCOPE-PROPOSAL.md`
header · `_incoming/*` (all five files) · the new and old SQL schemas, compared table by table · plus a
repository-wide search for each of the twenty stale terms listed in PROMPT A §11.2. The remaining
chapters are read in full at the start of the batch that edits them, not before — reading 913 KB up
front and then editing from memory is how numbers get mangled.

**Measured footprint of the job:** 39 Markdown/SQL/JSON files, 15,987 lines, 913 KB. The twenty stale
terms produce **≈ 400 hits across ~30 files** (table in §2).

---

## 1. Conflicts between the repository and PROMPT A §3–§7

Each row is a place where the repository asserts something the new decisions contradict. "Where" names
the authority that has to change, not every hit.

### 1.1 Architecture and platform

| # | Repository says | New decision | Where it is written |
|---|---|---|---|
| X-01 | Three thin clients, but the engine may be "compiled in via FFI" for Flutter (O-02 open) | **C-3**: laptop hosts engine + API + DB; clients never contain the engine; O-02 is answered | `docs/00` O-02, `README.md`, `docs/05` |
| X-02 | Desktop **and** mobile UI, 20 screens each, iPhone frames 844×390 / 932×430 | **C-2**: Android landscape only, 915×412 / 800×360 | `design/07`, `design/08`, `design/10`, `design/11`, `design/03` |
| X-03 | `SignalR` for live push (13 files, 32 hits) | **P-1**: polling `GET /matches/{id}/state?since=` | `docs/05`, `docs/14`, `appendices/A`, `README.md` |
| X-04 | Internet-capable deployment assumed; no LAN story anywhere | **C-4**: hotspot only, no internet on task day | nowhere yet — new material |
| X-05 | `PLATFORM-SCOPE-PROPOSAL.md` is withdrawn, but `README.md` still says "Awaiting decision" | Withdrawn, closed by **C-2** | `README.md` line 39 |

### 1.2 Modes, seats and accounts

| # | Repository says | New decision | Where |
|---|---|---|---|
| X-06 | Three modes: Pass & Play, Player vs AI, Room. Hand-over screen S-17 | **P-2**: one mode, Room. S-17 removed | `design/00` §75, `design/02`, `design/08`, `design/09` §207, `docs/04` §4.9.3 |
| X-07 | **D-24: guest play permitted without an account**; the API contract has a "guest play needs neither route" section; UC-03 is a guest use case | **C-8**: login required, guest removed | `docs/00` D-24, `appendices/A` §152, `design/02` §176, `docs/04` actors |
| X-08 | Seat kinds `LocalHuman` / `RemoteHuman` (51 hits across 13 files); D-07 composes a 2-player match as `[LocalHuman, Ai-or-Human, Neutral]` | Seat kind is `Human` / `Ai` / `Neutral` (incoming design) | `docs/00` D-07, `appendices/B`, `docs/06`, `appendices/A`, `design/*` |
| X-09 | Client pulls AI turns with an `ai-step` call (7 files, 11 hits) | **P-3**: the server runs AI turns itself | `appendices/A`, `docs/05`, `design/02` |
| X-10 | Bot roster of four heuristic bots + ONNX, exposed as difficulties (D-21: Easy/Normal/Hard/Brutal) | **P-5** defers "extra bots beyond Passive + one scorer bot"; PROMPT B's lobby names four bots | `docs/00` D-21, `docs/05`, `appendices/E` — **see Q-1, this is a prompt-vs-prompt conflict** |

### 1.3 Database

| # | Repository says | New decision | Where |
|---|---|---|---|
| X-11 | **Exactly six tables**, and a tripwire that "a seventh needs a recorded reason" | **C-10**: 13 tables, fully normalised | `docs/06`, `docs/14` §14.4, `docs/00` Part E, `README.md`, `appendices/B` |
| X-12 | `territory_state` table (9 files, 32 hits) | `match_territories` | `appendices/B`, `docs/06`, `appendices/A`, `appendices/F` |
| X-13 | `matches.effective_map` — the map is frozen into the match as a blob (17 files, 46 hits) | Maps are rows and are **immutable once used**; a changed map is a new `maps` row | `docs/00` D-04, `docs/06`, `appendices/C`, `docs/05` |
| X-14 | `matches.options` jsonb carries dice sides, attack range, sea-route count, turn timer | `match_rules` — one row per match, real typed columns | `docs/06` §287, `docs/00` D-29/D-30 consequence 1, `appendices/G` |
| X-15 | `cards.symbol` is a stored column with a 6-value CHECK (D-03) | A card's symbol is **derived** from its territory, or Wild when it has none | `docs/00` D-03, `appendices/B`, `docs/06` |
| X-16 | The map lives in `world_classic.json` and is loaded from the file at runtime | JSON is the human-edited source; the **database** is the runtime source; a generator keeps them in step | `appendices/C`, `docs/05` §5.7 |
| X-17 | Room code is 6 characters (`K4P9TQ`) | New schema comments and PROMPT B both say **4** (`K7QF`, `7F3K`) | `appendices/A` §233/§272, `appendices/H` |

### 1.4 Sea routes, rules and UI exposure

| # | Repository says | New decision | Where |
|---|---|---|---|
| X-18 | **D-13 (SEA-1)**: the host picks a sea-route count at setup, min 2 / max 10 / default 4; the system picks endpoints; routes are generated per match and frozen | **C-7**: a fixed list per map, chosen by the team, stored in `sea_routes`. The count control is removed | `docs/00` D-13, `docs/03` FR-15/16, `docs/07` §7.10, `appendices/C`, `appendices/E`, `appendices/G`, `design/*` S-05 |
| X-19 | Dice-face and attack-range **steppers appear in the UI** (setup screen and Settings) | **C-9**: both stay configurable in the engine, neither is shown in the UI | `design/04`, `design/08` S-20, `design/10`, `design/11`, `appendices/G` |
| X-20 | Air Force / Naval Force are built alongside classic RISK | **C-6**: classic RISK first; both extensions **off by default** | `docs/08`, `docs/07`, `docs/03` |
| X-21 | 119 hand-run test cases, untiered | **P-6**: tiered `[P1]`/`[P2]`/`[P3]`, ~25 `[P1]`, plus database tests | `appendices/F`, `docs/09`, `docs/13` |
| X-22 | 13 endpoints and 9 action types | **P-4**: about **10** endpoints | `appendices/A`, `design/00`, `design/02`, `docs/14` §42 |
| X-23 | Procedural map generation, RL, replay viewer S-19, tournament runner are live requirements | **P-5**: all deferred `[P3]`, text kept | `docs/02`, `docs/08`, `docs/11`, `appendices/E`, `rl/` |
| X-24 | `O-05` turn timer field exists and may be enforced later | PROMPT B forbids turn timers outright; `design/07` already says nothing expires | `docs/00` O-05, `docs/06` |

### 1.5 Stale-term footprint (measured 13 Oct 2026)

| Term | Files | Hits | | Term | Files | Hits |
|---|---|---|---|---|---|---|
| `hand-over` | 19 | 43 | | `SignalR` | 13 | 32 |
| `effective_map` | 17 | 46 | | `territory_state` | 9 | 32 |
| `guest` | 15 | 64 | | `LocalHuman` | 13 | 31 |
| `pass-and-play` | 15 | 30 | | `RemoteHuman` | 11 | 20 |
| `iPhone` | 6 | 19 | | `HandOverDevice` | 11 | 18 |
| `844` / `932` | 6 / 4 | 14 / 10 | | `iPad` | 6 | 14 |
| `ai-step` | 7 | 11 | | `six tables` | 5 | 6 |
| `Pass & Play` | 6 | 8 | | `Unity only` | 1 | 2 |

---

## 2. Statements that are simply wrong today (independent of the new decisions)

These are already false in the repository as it stands, before any new decision is applied.

| # | File | Line | Wrong statement | Correct today |
|---|---|---|---|---|
| S-01 | `README.md` | 39 | Platform proposal "Awaiting decision" | It was **withdrawn on 13 October 2026** with no committee decision needed (`PLATFORM-SCOPE-PROPOSAL.md` line 3) |
| S-02 | `README.md` | 17 | Design pack is "(00–09)" | It is **00–11** — `10-figma-prompt-desktop.md` and `11-figma-prompt-mobile-landscape.md` exist |
| S-03 | `README.md` | 17 | Lists art direction but omits chapter 10 and 11 from the range | Same as S-02 |
| S-04 | `README.md` | 19 | "`server/`: the ASP.NET Core backend containing…" | `server/` contains **six empty project folders**; there is no code yet. Likewise `clients/`, `rl/`, `assets/` |
| S-05 | `README.md` | 21 | "`shared/`: shared contracts and OpenAPI specifications" | `shared/` holds **only** `rules.json` and `maps/world_classic.json`; no OpenAPI file exists |
| S-06 | `README.md` | 3 | "three controlled extensions" then lists Air Force, Naval Force and capability profiles | Capability profiles are the *mechanism* of the other two, and **D-09** says the capability system has exactly two mechanical members. "Three extensions" overstates it |
| S-07 | `README.md` | 29 | "Procedural Map Generation" as a **key feature** | Already optional in `docs/00`; now `[P3]` |
| S-08 | `README.md` | 18 | "all 34 diagrams" | Not re-counted since the design pack landed; `diagrams.html` has not been regenerated and is a 3.6 MB generated artefact. **Unverified number** |
| S-09 | `docs/14` | 20–21 | Minimum path step 5 is "one client board, **pass-and-play**… no server, no database" and step 6 is "Persistence, API, SignalR" | Contradicts **C-3** and **P-2**: there is no single-device mode and the server is where the engine lives. The walking skeleton replaces it |
| S-10 | `docs/14` | 42 | "all 20 screens against the 13 endpoints and 9 action types" | Screen count, endpoint count and the desktop/mobile split all change |
| S-11 | `docs/14` | 81 | Tripwire: "Adds a database table. There are six" | Now 13 by decision |
| S-12 | `docs/00` | 316 | Part E: "no dozens of database tables (there are six)" | Same |
| S-13 | `docs/00` | 289 | O-02 "whether the Flutter client ships offline… Both are open" | **Answered** by C-3 |
| S-14 | `docs/06` | 287 | `matches.options` carries "sea-route count" | The feature is removed entirely (C-7) |
| S-15 | `appendices/F` | 3, 598, 613 | "119 test cases" in three places | Count changes once database tests are added and deferred tests are tagged |
| S-16 | `design/02` | 333 | "Not additions to the 119-case catalogue" | Same |
| S-17 | `appendices/A` | 152 | "Guest play needs neither route" | Guest play is removed (C-8) |
| S-18 | `design/03` | 408, 415 | Responsive table rows for "Small Android 640×360" and "iPad Pro 11" | 640×360 is not a target frame (800×360 is); iPad is out of scope |

---

## 3. Ten questions for the team, each with a recommended answer

> Answer "all recommended" and the work proceeds exactly as written below. Each answer becomes a
> register entry, so none of them is silently assumed.

### Q-1 — Bot roster: the two prompts disagree. **(blocking)**

PROMPT A P-5 defers "extra bots beyond Passive + one scorer bot" to `[P3]`. PROMPT B Stage 1 requires
the lobby to offer "exactly Passive, Chaotic, Aggressive, Mars". Both cannot be `[P1]`.

**Recommended:** design all four in Figma (a bot menu with four rows costs nothing to draw), but tier
them in the documentation: **Passive and Mars `[P1]`**, **Chaotic and Aggressive `[P2]`**, the ONNX/RL
agent `[P3]`. The lobby shows bot **names**, not difficulties — so **D-21** (Easy/Normal/Hard/Brutal →
agent mapping) is retired, because difficulty is no longer a user-facing concept.

### Q-2 — Documentation size: the budget conflicts with the new files. **(blocking)**

C-12 says the documentation must not grow. §8 asks for four new documents (`PROTOTYPE-EDITION`,
`GLOSSARY`, `15-lan-demo-runbook`, `16-task-day-change-guide`) plus an appendix `B3`.

**Recommended:** accept a **net growth of at most 5 %** of the current 913 KB, and pay for the new
pages by compressing, not deleting: the RL sections of `docs/02`, the deferred phases of `docs/08`, and
the desktop material in `design/07`/`design/08` move under "Deferred — future work" headings and are
cut to summaries, with the full text retained in those sections. Nothing is lost; the beginner path
gets shorter.

### Q-3 — PostgreSQL is **not installed** on this machine. **(affects what I can claim)**

`psql` is absent, so §6.8's load test and §11.6 cannot be run here. Python 3.13 **is** available, so
`tools/generate_map_seed.py` can be written and tested properly.

**Recommended:** I write `tools/verify_db.sql` — one script that prints every count in §6.8 (13 tables,
42 territories, 6 continents, 83 borders, 36 coastal, 1,330 pairs at range 5) — and step 6 of the LAN
runbook tells you to run it. Every database claim in the docs is labelled **"not verified on this
machine"** until one of you runs it. I will not write that the check passed.

### Q-4 — The sea-route list is empty and someone has to choose it.

`sea_routes` ships empty by design (C-7 leaves the list to the team).

**Recommended:** I add a **proposed** list of 8 routes to `appendices/C` as a table for the team to
accept or edit — each one validated against the three rules (both ends coastal, not already land
neighbours, no duplicate) — but I **do not** put them in the seed. The seed stays empty until you say
so, and the extension is off by default anyway (D-54).

### Q-5 — Room code length: 4 or 6 characters?

The old API contract uses 6 (`K4P9TQ`). The new schema comment and PROMPT B both use 4 (`K7QF`,
`7F3K`).

**Recommended:** **4 characters**, uppercase, from a 32-character alphabet that excludes `I`, `O`, `0`
and `1` — about a million combinations, which is ample for one hotspot, and four characters is far
faster to read aloud across a room on demo day. Recorded as superseding the 6-character examples.

### Q-6 — Login token lifetime on a long demo day.

Not currently specified anywhere.

**Recommended:** **12 hours**, no refresh token, no session table. A token issued at the start of task
day cannot expire during it. This goes in `appendices/G` and in the safety checklist as a named trap.

### Q-7 — Poll interval and the stale-`since` rule.

P-1 says "about once per second".

**Recommended:** **1,000 ms** default, configurable in `appendices/G`; the server answers `304 Not
Modified` when `since` equals the current version, and `409` when a submitted action carries a stale
version (the existing rule, kept). A client that has fallen far behind re-reads full state rather than
replaying a gap.

### Q-8 — Does the 44-card deck keep Air Force and Naval Force symbols in the classic-only build?

The deck is 12 Infantry / 10 Cavalry / 8 Artillery / 7 Air Force / 5 Naval Force + 2 Wild = 44.

**Recommended:** **yes, unchanged.** Card symbols are inert while the extensions are off: a card is a
set-matching token, and `air_force_enabled = false` only removes the *action*. Changing the deck for
the first version would change every card-family test oracle twice. The card art still shows the
symbols (PROMPT B Stage 3 S-10b).

### Q-9 — Is the Neutral seat always present, or only in 2-player matches?

PROMPT B's lobby shows a greyed "Neutral — never acts" row.

**Recommended:** **2-player matches only**, exactly as D-07 already decided — it is what makes the
3-player starting-army row (35) apply without a special case. In a 3–6 player lobby the Neutral row is
not drawn. The Figma frame keeps it because the frame illustrates a 2-player room.

### Q-10 — Is the `moves` log enforced append-only?

The incoming design notes this is a convention, not enforced; the older design blocked `UPDATE` and
`DELETE` with database permissions.

**Recommended:** document it as a **convention `[P1]`** (nothing in the server issues an update), and
put the `REVOKE UPDATE, DELETE` grant in `appendices/B` as a commented-out block tagged `[P3]` with one
line explaining when to switch it on ("if your supervisor asks"). It costs one paragraph and it is a
good viva answer.

---

## 4. The batch plan

Every batch ends with the §11 verification run, a commit named `Batch N: …`, and a printed summary.
No batch starts before the previous commit exists.

| Batch | Scope | Files touched | New files | Heaviest item |
|---|---|---|---|---|
| **1** | Decisions and database | `docs/00`, `docs/06`, `appendices/B`, `shared/rules.json`, `shared/maps/world_classic.json` | `appendices/B2-seed-world-classic.sql`, `appendices/B3-data-dictionary.md`, `tools/generate_map_seed.py`, `tools/verify_db.sql`, `docs/images/erd_*.png` | `docs/06` is a full rewrite (398 lines → data dictionary for 13 tables) |
| **2** | Requirements, analysis, game design | `docs/01`, `docs/03`, `docs/04`, `docs/07`, `appendices/C`, `appendices/D`, `appendices/E`, `appendices/G` | — | `docs/04` (912 lines, every diagram) and `appendices/E` (1,280 lines) |
| **3** | System design, API, plan | `docs/05`, `docs/08`, `docs/14`, `appendices/A` | — | `appendices/A` rewritten to 10 endpoints; `docs/08` replanned for 22–24 weeks |
| **4** | Testing and traceability | `docs/09`, `docs/10`, `docs/11`, `docs/13`, `appendices/F` | — | `appendices/F` (631 lines, every TC tiered + 10 new DB tests); `docs/13` regenerated |
| **5** | Design pack | `design/00`–`design/09`, `design/10` (header note), `design/11` (replaced by PROMPT B), `appendices/H`, `diagrams.html` (banner only) | `design/screens/README.md` | `design/08` wireframes (678 lines) re-framed to 915×412 / 800×360 |
| **6** | Beginner layer | `README.md`, `PLATFORM-SCOPE-PROPOSAL.md` (pointer line), `Prompts/README.md` | `docs/PROTOTYPE-EDITION.md`, `docs/GLOSSARY.md`, `docs/15-lan-demo-runbook.md`, `docs/16-task-day-change-guide.md`, `design/tokens.json` | `docs/16` — needs the exact column and endpoint for every change |

**Estimate:** 39 files edited, 14 created, 0 deleted.

### Decision IDs this rework will add

The register ends at **D-30**. New entries, fixed now so every batch cites the same number:

| Range | Source | Status |
|---|---|---|
| **D-31…D-42** | PROMPT A C-1…C-12 | Confirmed — team, Oct 2026 |
| **D-43…D-49** | PROMPT A P-1…P-7 | Proposed — needs team confirmation |
| **D-50…D-55** | `_incoming/database-design.md` §4 (renumbered — it proposed D-31…D-38, which collide) | Confirmed — team, Oct 2026 |
| **D-56…D-66** | The answers to Q-1…Q-10 above, plus D-65 (turn timer retired) | Proposed — needs team confirmation |

Two of the incoming document's eight entries get **no new ID** because they restate existing
decisions: "capability is not stored" is already **D-10**, and "six tables → 13" is **D-40** (C-10).
Its proposed D-31…D-38 numbering is recorded as superseded by this mapping so the two documents cannot
be read as disagreeing.

**Superseded by this rework:** D-03 (stored card symbol), D-04 (sea routes generated and frozen into
`effective_map` — the `crossesWater` rename survives), D-07 (seat-kind half only; the Neutral-seat rule
survives), D-13 (sea-route count bounds), D-21 (difficulty→agent mapping), D-24 (guest play), the
storage half of D-29/D-30 (`matches.options` → `match_rules`; configurability itself stands), C-03 (six
tables). **Resolved:** O-02. **Retired:** O-05 (turn timer). **Still open:** O-01, O-03 (as `[P3]`),
O-04, O-06.

---

## 5. What I will not do

Per PROMPT A §12: no game, server or client code is written or modified (`tools/*.py` and `*.sql`
scripts are tooling, and §6.6 asks for them explicitly). Nothing is deleted — superseded text moves
under a "Deferred" or "Superseded" heading. The classic RISK rules, the five combat probability
fractions, the map data beyond §6.7, and the AI scoring coefficients are untouched.
`design/References/`, `Prompts/*` and `docs/12-references.md` are not edited, except for the one new
`Prompts/README.md` that §7 asks for.

---

## 6. Answers received — 13 October 2026

| Q | Answer | Effect |
|---|---|---|
| Q-1 | **Draw four, tier them.** | Figma draws Passive, Chaotic, Aggressive, Mars. Docs: Passive + Mars `[P1]`, Chaotic + Aggressive `[P2]`, ONNX/RL `[P3]`. **D-21 retired** — difficulty is no longer user-facing. |
| Q-2 | **≤ 5 % growth, compress to pay.** | Budget: 913 KB → **≤ 959 KB**. RL sections of `docs/02`, deferred phases of `docs/08`, desktop material in `design/07`/`design/08` compress to summaries under "Deferred" headings. |
| Q-3…Q-10 | **All recommendations accepted.** | Recorded as **Proposed — needs team confirmation** (D-56…D-66), so any one of them is still reversible as a data edit. |

Phase 0 is closed. Batch 1 begins.
