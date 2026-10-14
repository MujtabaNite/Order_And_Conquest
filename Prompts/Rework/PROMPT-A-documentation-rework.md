# PROMPT A — Rework the whole repo to the new prototype decisions

**Use this with Claude Code (or any coding agent) opened at the root of `Order_And_Conquest`.**
Copy everything below the line into the agent as one message.

**Before you paste it, do these 3 things:**
1. Copy these into the repo: `order_and_conquest_schema.sql`, `seed_world_classic.sql`, `erd_overview.png`, `erd_full.png`, `database-design.md` → put them in a new folder `_incoming/` at the repo root. The prompt tells the agent to merge them in.
2. Create a git branch (`git checkout -b prototype-edition`) so you can review and undo.
3. Read section 4 ("Proposed decisions") and delete or change any line you disagree with **before** pasting.

**How it runs:** the agent first only *plans* (no edits) and asks you questions. You answer. Then it works in 6 batches and commits after each one. Review each commit.

---

ROLE
You are a senior engineer and technical writer. You are reworking the documentation and design pack of a final-year university project so that it matches new decisions made by the team. You are NOT writing game code. You edit Markdown, SQL, JSON and diagrams only.

THE READER
Three undergraduate students (beginners to intermediate) who must build, demo and defend this project. Every document must be understandable by them without prior knowledge of networking, databases or game AI. Plain English first, precise detail second.

---

## 1. PROJECT SNAPSHOT

- **Project:** Order & Conquest — a digital RISK-style game (42 territories, 6 continents, 2–6 seats, dice combat) with two extensions: **Air Force** (attack within a land-distance range) and **Naval Force** (move/attack along fixed sea routes).
- **What it is:** a **PROTOTYPE** for a final-year project (two semesters, about 5–6 months left). It must be **feasible for three students with other coursework** to finish, demo and defend. It is not a commercial game.
- **Team:** three people, one client each — Unity (Mujtaba), Godot (Abdullah), Flutter + Flame (Jarrar). All three clients are **Android phones, landscape only**.
- **Weekly supervisor meetings.** The next one needs: a proper ERD and screen mockups.
- **Task day (the final demo):** **no internet allowed.** The three phones and one laptop are connected over a **phone hotspot** (a local network). One game is played together across the three different apps, with human players and AI bots in the same match.
- **Deliverables the team needs from the docs:** complete design documentation, a proper normalised database design, screen mockups, and a runbook for the demo.

## 2. WHAT YOU MUST READ FIRST (in this order, do not skip)

1. `README.md`
2. `docs/00-decisions-and-assumptions.md` (the decisions register — your source of truth for IDs)
3. `docs/14-implementation-safety-checklist.md`
4. `docs/05-system-design.md`, `docs/06-database-design.md`, `docs/08-implementation-plan.md`
5. `appendices/A-api-contract.md`, `appendices/B-database-schema.sql`, `appendices/C-*`, `appendices/D-*`, `appendices/G-*`
6. `design/00-index.md`, `design/02-screen-inventory-and-flows.md`, `design/11-figma-prompt-mobile-landscape.md`
7. `shared/rules.json`, `shared/maps/world_classic.json`
8. `PLATFORM-SCOPE-PROPOSAL.md` (it is marked WITHDRAWN; the README still says "awaiting decision" — that is a known stale line)
9. Everything in `_incoming/` (the new database design: schema, seed, ERD images, explanation)

Then skim the rest. Do not rely on memory of how a project like this "usually" works. Use only what is in the files and in this prompt.

## 3. DECISIONS ALREADY MADE BY THE TEAM (treat as fixed)

Record each in `docs/00-decisions-and-assumptions.md` with the next free IDs (the register currently ends at D-30; continue D-31, D-32 …). Mark status **Confirmed — team, Oct 2026**.

| # | Decision |
|---|---|
| C-1 | **Prototype scope.** Optimise for "three students can finish this", not completeness. |
| C-2 | **All three clients are Android, landscape only.** Unity, Godot and Flutter + Flame. The portrait-only artwork is a single "rotate your phone" screen. Desktop and iPad layouts are out of scope. |
| C-3 | **The laptop is the host.** The game engine (one C# library, the single source of rules) and the API server run on the laptop. The three phone apps are **thin clients**: they hold no rules; they show what the server says is legal. The engine is **not** compiled into the phone apps. |
| C-4 | **Local network only on task day.** Phone hotspot, no internet. The system must never require a cloud service, an external API, a CDN or a font download at runtime. |
| C-5 | **Humans and AI bots play in the same match.** Every demo match is a "room": remote human seats plus AI seats. |
| C-6 | **Build order: classic RISK first.** Only after classic RISK works end to end do Air Force and Naval Force cards and actions get added. In the first version both extensions are switched off by default. |
| C-7 | **Sea routes are a fixed list per map, not generated per match.** The team wants **more** sea routes than classic RISK has. The exact list is chosen later by the team; the schema supports any number. The old "choose 2–10 routes when creating a match" feature is **removed**. |
| C-8 | **Sign-up and login are required.** Guest play is removed. |
| C-9 | **Dice sides and attack range stay configurable in the engine, but are not shown in the UI.** They are per-match settings frozen at creation. The team must be able to change them on request on task day, so the docs must contain a clear "how to change it" guide. |
| C-10 | **The database is fully normalised, in PostgreSQL on the laptop.** The map is stored as tables, not as a JSON blob. The 13-table design in `_incoming/` is the starting point (see §6). The old "exactly six tables" constraint (C-03) is replaced. |
| C-11 | **Locked decisions may change** where this prompt says so. Record every change; never change silently. |
| C-12 | **Documentation must stay beginner-friendly** and must not grow larger than it is now. Prefer rewriting and tagging over adding. |

## 4. PROPOSED DECISIONS (adopt as defaults, but flag them for the team to confirm)

Record each with status **Proposed — needs team confirmation**. Where the old text conflicts, update it to the proposed behaviour and mark the paragraph with the decision ID.

| # | Proposal | Reason |
|---|---|---|
| P-1 | **Polling instead of SignalR/WebSockets.** Clients call `GET /matches/{id}/state?since={version}` about once per second. The server returns `304`/empty if nothing changed. | Real-time sockets are a known risk in Unity (IL2CPP) and Flutter; a turn-based game does not need them. |
| P-2 | **One mode: Room.** "Pass & Play" and "Player vs AI" are removed as separate modes; Player vs AI is simply a room with one human and bots. The hand-over screen (S-17) is removed. | No single-device play is needed for the demo. |
| P-3 | **The server runs AI turns itself** when it is an AI seat's turn. Remove the pull-style `ai-step` client call. | Fewer endpoints; clients stay simple. |
| P-4 | **API target is about ten endpoints:** register, login, get map, create room, join room, add AI seat, start match, get state (poll), get legal actions, submit action. Rewrite `appendices/A-api-contract.md` to exactly this set (re-number, keep error codes, keep the `409` stale-version rule and per-seat hiding of other players' cards). | Smaller surface for three clients. |
| P-5 | **Deferred (kept in the docs, not built):** procedural map generation, the reinforcement-learning agent, replay viewer (S-19), tournament runner, extra bots beyond Passive + one scorer bot, SignalR, desktop/iPad layouts. Do **not delete** their text; move it under a clearly marked "Deferred — future work" heading or tag it `[P3]`. | Keeps the work, cuts the workload. |
| P-6 | **Test plan is tiered.** Tag every test case `[P1]` (about 25 core tests, must pass for the demo), `[P2]` (extensions), `[P3]` (deferred). Add database tests (see §6). | 119 tests is too many to run by hand. |
| P-7 | **Android networking rules go into the safety checklist:** plain HTTP needs "cleartext traffic" enabled in all three apps; hotspots can isolate clients from each other; the laptop firewall must allow the server port; the host's IP address must be shown on the laptop and typed (or scanned) into each phone. | These are the things that break first on demo day. |

## 5. SCOPE TIERS (use these tags everywhere)

- **[P1] Demo-critical:** classic RISK across three Android clients over the local network, with accounts, rooms, humans + AI, database persistence.
- **[P2] Extensions:** Air Force, Naval Force, fixed sea routes, the Air/Naval card symbols, capability panel.
- **[P3] Deferred:** everything in P-5.

Every requirement (FR/NFR), use case (UC), test case (TC), screen (S-xx), diagram and appendix section gets exactly one tier tag. Where the old text covered several tiers in one block, split the text or tag each paragraph.

## 6. THE NEW DATABASE DESIGN (merge from `_incoming/`)

1. Replace `appendices/B-database-schema.sql` with `_incoming/order_and_conquest_schema.sql`.
2. Add `appendices/B2-seed-world-classic.sql` from `_incoming/seed_world_classic.sql`.
3. Put the ERD images in `docs/images/` (`erd_overview.png`, `erd_full.png`) and embed them in chapter 6.
4. **Rewrite `docs/06-database-design.md`** using `_incoming/database-design.md` as the base text. It must contain: the one-minute explanation, the "JSON vs tables" comparison and decision, the 13-table list with one line each, the two deliberate normalisation exceptions (repeated `map_id` guarded by composite foreign keys; JSON in the `moves` log), a **conceptual ERD** drawn in Mermaid (Player, Match, Seat, Territory, Card, Move — plain English), the physical ERD, a table-by-table data dictionary (every column: type, meaning, example), the constraints list, the "how to change things on task day" table, and the test results.
5. Add a **data dictionary appendix** (`appendices/B3-data-dictionary.md`) listing every table and column.
6. Add `tools/generate_map_seed.py` that regenerates the seed SQL from `shared/maps/world_classic.json` (so JSON stays the human-edited source and the database is the runtime source). If you cannot test it, say so.
7. Make `shared/maps/world_classic.json` consistent: add a `seaRoutes` array (empty for now) and a comment that the list is chosen by the team; remove nothing else.
8. **Run it.** If PostgreSQL is available, load schema + seed into a scratch database and confirm: 13 tables; 42 territories; 6 continents; 83 land borders; 36 coastal territories; a recursive query finds 1,330 ordered territory pairs within 5 land steps. If PostgreSQL is not available, say so in the final report; do not claim the check passed.
9. Update everything that referred to the old design: `territory_state`, `matches.effective_map`, `matches.options`, the `cards.symbol` column, the seat kinds `LocalHuman`/`RemoteHuman`, "six tables", constraint C-03, and the "freeze the map into the match" wording (replace with: maps are immutable once used; a changed map is a new map row).

## 7. FILE-BY-FILE WORK ORDER

Legend: **REWRITE** = substantial change · **UPDATE** = targeted edits · **TAG** = add tier tags and fix references only · **KEEP** = do not touch.

| File | Action | What to change |
|---|---|---|
| `README.md` | REWRITE | New one-page overview, the three-device demo picture, reading order for beginners, correct folder list (remove folders that do not exist yet: mark them "planned"), fix "awaiting decision" for the platform proposal (it is withdrawn), fix design pack range (00–11). |
| `docs/00-decisions-and-assumptions.md` | UPDATE | Add C-1…C-12 and P-1…P-7 as D-31 onwards with status; mark superseded decisions (sea-route count D-13, platform/clients, six tables C-03, SignalR, guest play, pass-and-play, the engine-in-client wording) as **Superseded by D-xx**. Resolve open item O-02 (host) and note O-04 stays open. |
| `docs/01-introduction.md` | UPDATE | Objectives, scope, constraints, limitations: prototype framing, laptop host, local network, Android landscape, build order. |
| `docs/02-literature-review.md` | TAG | Keep. Tag RL sections `[P3]`. |
| `docs/03-requirements.md` | UPDATE | Re-tag all 85 FRs and 24 NFRs. Remove/modify requirements for guest play, pass-and-play, generated sea routes, SignalR. Add requirements for: LAN host discovery by typed IP, polling, login, Android cleartext, demo-day offline operation, per-match rule frozen settings change guide. Keep numbering; never reuse a retired ID — mark it "Retired". |
| `docs/04-system-analysis.md` | UPDATE | Actors (remove "device handed over"), use cases (remove UC-03 guest, UC-05 configure sea routes, UC-16 hand-over; mark UC-18/20/21 `[P3]`; add "Connect to host", "Add AI seat", "Start match"), redraw the flowcharts, DFDs and sequence diagrams (replace 4.9.3 pass-and-play with "remote player waits for their turn"), update state diagrams. |
| `docs/05-system-design.md` | REWRITE (§5.1–5.8) | Architecture: laptop host (engine + API + PostgreSQL) and three thin Android clients on a hotspot; deployment diagram; polling flow; screen list (see design pack); API summary; remove the engine-in-client and SignalR text (move to "Deferred"). |
| `docs/06-database-design.md` | REWRITE | See §6. |
| `docs/07-game-design.md` | UPDATE | Keep classic rules intact. Mark Air Force / Naval Force as `[P2]`. Replace "sea routes generated per match" with "fixed per map". State clearly that dice sides and attack range are engine settings not shown in the UI, with the allowed ranges. Do not change any probability table. |
| `docs/08-implementation-plan.md` | REWRITE | A realistic plan for 3 people over about 22–24 weeks with two review points. Phase order: (1) walking skeleton — three phones join one room and see one shared value change; (2) database + engine core (classic); (3) API + AI bots; (4) first client end to end; (5) the other two clients; (6) hardening + demo rehearsal; (7) extensions `[P2]`. Add a risk table (hotspot, cleartext HTTP, firewall, clock/IP changes). For each phase: goal, deliverable, who, definition of done. Keep the cut order, but update it. |
| `docs/09-testing.md` | UPDATE | Tiered test strategy, add DB tests and a **three-device demo rehearsal checklist**. |
| `docs/10-results-template.md` | TAG | Keep; remove references to deferred experiments or tag them. |
| `docs/11-conclusion-and-future-work.md` | UPDATE | Future work = all `[P3]` items. |
| `docs/12-references.md` | KEEP | |
| `docs/13-traceability-matrix.md` | REWRITE | Regenerate: FR → UC → screen → API endpoint → table → test, with tier. Every row must resolve; list any orphan as a defect. |
| `docs/14-implementation-safety-checklist.md` | UPDATE | Keep the existing traps; add the networking traps from P-7 and: polling with stale `since`, AI turn running on the server, login token expiry on a long demo. |
| `appendices/A-api-contract.md` | REWRITE | See P-4. Give every endpoint: method, path, auth, request, response, errors, example. |
| `appendices/B-*` | REPLACE | See §6. |
| `appendices/C-*` | UPDATE | Map spec: fixed sea routes, normalised storage, validation rules for sea routes (both ends coastal, not a land neighbour). |
| `appendices/D-*` | KEEP | Capability table is unchanged (check it still matches the schema: capability is derived, never stored). |
| `appendices/E-pseudocode.md` | UPDATE | Replace sea-route generation with "load the fixed routes"; tag procedural map generation `[P3]`; keep combat, cards, legality and AI. |
| `appendices/F-test-cases.md` | UPDATE | Tag every TC with a tier; list the 25 `[P1]` tests at the top; add database tests: the 10 rejection cases listed in `_incoming/database-design.md` §6, plus seed counts. |
| `appendices/G-*` | UPDATE | Config tables: remove sea-route count settings; keep dice sides and attack range with allowed ranges; add server port, poll interval, token lifetime. |
| `appendices/H-*`, `diagrams.html` | UPDATE | List every diagram that is now wrong. Redraw Mermaid sources. If `diagrams.html` is generated and you cannot regenerate it, say so and leave a note at the top of the file listing stale diagrams. |
| `design/00-index.md` | UPDATE | New index, new screen count, mobile-only. |
| `design/01…09` | UPDATE / TAG | Mobile landscape Android only (frame sizes **915×412** and **800×360**). Desktop and iPad material → tag `[P3]` or move under "Deferred". Remove from the UI: dice-face and attack-range controls, sea-route count stepper, guest link, mode cards for Pass & Play and Player vs AI, hand-over screen. Add screens: **Connect to host**, **Join room**, **Waiting for other players**, **Connection lost / reconnecting**. Keep the art direction (colours, type, components) as is. |
| `design/02-screen-inventory-and-flows.md` | REWRITE | New screen list and navigation graph; bind each screen to the new endpoints. |
| `design/10-figma-prompt-desktop.md` | KEEP | Mark at the top: "Not used — desktop is out of scope (D-xx)." |
| `design/11-figma-prompt-mobile-landscape.md` | REPLACE | Replace with the staged Figma prompt supplied separately by the team (`PROMPT-B`). If it is not in `_incoming/`, leave a placeholder and tell the team. |
| `PLATFORM-SCOPE-PROPOSAL.md` | KEEP | Already withdrawn; add a one-line pointer to the decision that closed it. |
| `Prompts/*` | KEEP | Historical authority; add a README noting which decisions it no longer governs. |
| `shared/rules.json` | UPDATE | Remove sea-route count keys; keep everything else; keep dice sides and attack range with ranges. |
| `shared/maps/world_classic.json` | UPDATE | See §6.7. |

## 8. NEW FILES TO CREATE

1. `docs/PROTOTYPE-EDITION.md` — **max 3 pages.** What we are building / not building (a table), the three scope tiers, the architecture picture, who builds what, the reading order, and the 10 most important rules in plain English.
2. `docs/GLOSSARY.md` — one or two plain sentences each: authoritative server, deterministic, seed, thin client, polling, REST, JSON, ERD, primary key, foreign key, normalisation, composite key, constraint, hash, token, hotspot, cleartext HTTP, firewall, IPv4 address, landscape, tick/turn, redaction, optimistic concurrency (the `version` field), idempotent, etc. Use only the terms the docs actually use.
3. `docs/15-lan-demo-runbook.md` — step by step, with checkboxes: hotspot setup, finding the laptop's IP, starting the database and server, firewall rule, entering the host address on each phone, a 10-minute pre-demo test, and a fallback plan (what to do if the hotspot blocks device-to-device traffic, if one client crashes, if the database will not start).
4. `docs/16-task-day-change-guide.md` — "The committee asks X → you do Y": dice sides, attack range, enabling Air Force / Naval Force, adding a sea route, adding an AI bot, changing the starting armies, resetting a match, changing the map. Each with the exact file/column/endpoint and a verification step.
5. `docs/images/` and `design/tokens.json` — colour and type tokens in one JSON file (copy values from the existing art direction; invent none), so all three clients use the same numbers.

## 9. STYLE RULES

- Plain English. Define a term the first time it appears, and link to the glossary.
- Every chapter starts with a 3–5 line box: **"In plain words"**.
- Prefer a table or a diagram to a long paragraph. Mermaid for diagrams.
- Keep the existing numbering and IDs. If something is removed, mark it **Retired**, do not renumber.
- Keep the repo's spelling convention (British: "normalised").
- Label every number as **sourced**, **derived** or **assumed** where the old docs did; do the same for new numbers.
- Never invent a fact, a statistic, a library version or a citation. If you do not know it, write "TBD — team to decide" and list it in the final report.
- Do not make the documentation longer overall. If you add a page, remove or shorten another.

## 10. WORKFLOW

**Phase 0 — Plan only (no edits).** Read everything in §2. Produce `REWORK-PLAN.md` containing: (a) a list of every conflict you found between the repo and sections 3–7, (b) a list of every stale statement in the README/docs that is already wrong today, (c) up to **10 questions** for the team, each with your recommended answer, (d) the batch plan below with estimated files per batch. **Stop and wait for the team's answers.**

**Batch 1 — Decisions and database.** `00`, §6 (everything), appendix B/B2/B3, `shared/`.
**Batch 2 — Requirements, analysis, game design.** `01`, `03`, `04`, `07`, appendix C/D/E/G.
**Batch 3 — System design, API, plan.** `05`, appendix A, `08`, `14`.
**Batch 4 — Testing and traceability.** `09`, `10`, `11`, appendix F, `13`.
**Batch 5 — Design pack.** `design/*`, `diagrams`, appendix H.
**Batch 6 — Beginner layer.** `README.md`, `docs/PROTOTYPE-EDITION.md`, `GLOSSARY.md`, `15`, `16`, `design/tokens.json`.

After each batch: run the checks in §11, commit with a message `Batch N: …`, and print a short summary. Do not start the next batch until the previous commit exists.

## 11. VERIFICATION (run after every batch, fix before moving on)

1. **Dangling references:** every `D-xx`, `FR-xx`, `NFR-xx`, `UC-xx`, `TC-xx`, `S-xx` and every Markdown link points to something that exists.
2. **Stale terms:** search the whole repo for each of these and justify or fix every hit outside "Deferred"/"Superseded" sections: `SignalR`, `Pass & Play`, `Pass and Play`, `hand-over`, `HandOverDevice`, `guest`, `six tables`, `effective_map`, `territory_state`, `LocalHuman`, `RemoteHuman`, `ai-step`, `sea-route count`, `seaRoutes min`, `iPhone`, `iPad`, `844`, `Unity only`.
3. **Numbers:** 42 territories, 6 continents, 83 land borders, 36 coastal, 44 cards (12/10/8/7/5 + 2 wild), 1,330 reachable pairs at range 5, 13 tables. Any file that states a different number is wrong.
4. **Tier tags:** no requirement, use case, test, screen or diagram lacks a tier tag.
5. **Mermaid:** every diagram parses (use a Mermaid parser if available; otherwise review by eye and say so).
6. **Database:** schema and seed load on an empty PostgreSQL database (if available).
7. **Traceability:** the regenerated matrix has no orphan rows.

## 12. HARD RULES

1. Do not write or modify game, server or client code. This is a documentation and design task.
2. Do not delete content. Move it to a "Deferred" or "Superseded" section, or tag it.
3. Do not change the classic RISK rules, the combat probability tables, the map data (other than §6.7), or the AI scoring coefficients.
4. Do not touch `design/References/`, `Prompts/`, `docs/12-references.md`.
5. Do not claim something was verified unless you ran the check. Say "not verified" instead.
6. If two instructions conflict, stop and ask. Do not guess.
7. Never silently change a decision. Every change is recorded in the decisions register with its ID and reason.

## 13. FINAL REPORT (print at the end)

1. Files changed, by batch (counts).
2. The final decisions list, grouped Confirmed / Proposed / Superseded / Retired.
3. Open questions and every "TBD — team to decide".
4. Checks run and their results (pass / fail / not verified).
5. Anything you were unsure about.
6. A "what to read first" list of 5 files for the three team members.
