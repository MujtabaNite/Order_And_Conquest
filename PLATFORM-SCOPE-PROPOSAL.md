# Platform Scope Proposal — Request to Amend Constraint C-04

**Project:** Order & Conquest · **Date:** 8 October 2026 · **Status:** awaiting committee decision
· **Revision 2** — see §2

> **The request in one sentence.** We ask the committee to amend locked constraint **C-04** so that
> the **mobile (Flutter + Flame) client is designed in full but not implemented**, and the delivered
> build is desktop. The mobile design is complete and is submitted as evidence; what we are asking
> to drop is the *implementation*, not the *design work*.

---

## 1. The constraint we are asking to amend

From [`docs/03-requirements.md`](docs/03-requirements.md) §3.5, verbatim:

| ID | Constraint | Origin |
|---|---|---|
| **C-04** | **Three clients must all ship: Unity, Godot, Flutter + Flame. None may be dropped.** | **Locked** |

This is a formal amendment request, not a discretionary cut, and we are raising it **before Phase 8
begins** rather than at the deadline.

### What we are *not* asking for

| Not requested | Still delivered in full |
|---|---|
| Any reduction in game rules | 42 territories, 6 continents, cards, capabilities, Air Force, Naval Force |
| Any reduction in the engine, API or database | C-01, C-02, C-03 untouched |
| Any reduction in testing | 119 test cases, 85 functional requirements |
| Any reduction in **design** deliverables | All 20 screens specified for desktop **and** mobile landscape |
| Removal of mobile from the documentation | The mobile design is a submitted artefact, not a deleted section |

---

## 2. What changed in this revision, and why we are telling you

**Revision 1 of this document argued that the mobile client was not technically viable.** It measured
the board at fit-to-screen, found that all 42 territories fall below a 48 px touch target on any
phone, and concluded that mobile could not meet touch guidance.

**That argument was wrong, and we withdraw it.** It assumed a board fitted to the viewport. The board
zooms and pans — as every mobile game in this genre does, and as our own design already specified —
so "the target size at fit-to-screen" describes the *overview*, not how the game is played. Measured
correctly, **mobile is feasible**, and §3 gives the figures.

We are stating this plainly for two reasons. A committee member familiar with mobile strategy games
would have punctured the original claim with a single question. And the corrected finding makes this
a cleaner request: we are no longer claiming we *cannot* build the mobile client. We are saying we
*can*, we have measured what it costs, and we recommend spending that budget elsewhere.

The recommendation is unchanged. The reasoning is now honest.

---

## 3. Finding 1 — mobile is feasible, and here are the numbers

The board is a zoomable canvas. The question is therefore not "does the whole board fit" but **"at
the zoom where every territory is tappable, how much of the board can I see?"**

The tactical scale is **0.537** — the scale at which the two closest territory anchors (89.4 px apart
on the 1600 × 900 canvas) reach a 48 px touch target. Measured at that scale, in landscape:

| Device | Board visible at tactical zoom | Pinch from overview |
|---|---|---|
| Small Android 640 × 360 | 75 % × 66 % | 1.51 × |
| iPhone SE 667 × 375 | 78 % × 69 % | 1.44 × |
| iPhone 15 844 × 390 | **98 % × 72 %** | 1.38 × |
| Pixel 8 892 × 412 | **100 % × 77 %** | 1.30 × |
| iPhone 15 Pro Max 932 × 430 | **100 % × 81 %** | 1.24 × |
| iPad mini 1024 × 768 | **100 % × 100 %** | **none — already compliant at fit** |
| iPad Pro 11 1194 × 834 | **100 % × 100 %** | **none** |

A landscape phone holds nearly the whole board on screen *while every territory is tappable*, after a
pinch of under 1.4 ×. Tablets need no zoom at all. Our design auto-frames to tactical when the player
selects a territory, so the player reaches a compliant target without deliberately pinching.

**Conclusion: the mobile client is buildable and would be usable.** Any case for not building it has
to be made on cost, not capability.

### One measurement from the original draft does survive

Landscape is not a preference. At tactical zoom a **portrait** phone shows only **42–50 %** of the
board width against landscape's 75–100 %. The board is 16 : 9; a portrait viewport discards half the
width exactly where the territories are. The mobile design is therefore landscape-only, and that is
measured rather than assumed.

---

## 4. Finding 2 — what the third client actually costs

Mobile is not the desktop build at a smaller size. It is a **second interaction model**, and the
difference is structural:

| | Desktop | Mobile landscape |
|---|---|---|
| Board | a column between two persistent panels | **full-bleed, never resized by a panel** |
| Panels | persistent side panels | **overlay drawers** plus one bottom card strip |
| Target minimum | 24 px (WCAG 2.5.8, pointer) | **48 px** (Material / Apple HIG / WCAG 2.5.5, touch) |
| Zoom | available, rarely used | **structural** — two named states, auto-framed on selection |

Why a panel cannot simply be docked on touch: a persistent 280 px rail takes an iPad mini from a
compliant **57.2 px** target down to **41.6 px**, putting 16 of 42 territories under the minimum. The
overlay model exists to protect the touch guarantee, and it has to be built and tested as its own
thing.

Countable consequences:

| | |
|---|---|
| Screens whose touch form **changes structure** | **12 of 20** |
| Screen implementations, three clients | **60** · two clients: **40** |
| Client-level test runs (TC-UI-01…03, per client) | **9** · two clients: **6** |
| Touch-only machinery to build and verify | overlay drawers, two zoom states, auto-framing, disambiguation popover, declutter levels, orientation lock |

---

## 5. Finding 3 — the project's own rationale already supports this

This is the strongest argument, because it is from the locked documentation rather than from us.
[`docs/08-implementation-plan.md`](docs/08-implementation-plan.md) §8.5 already concedes a
desktop-only client, and gives the reason:

> *"Godot's C# builds do not target the web. The Godot client is therefore **desktop only**, and that
> is acceptable because the three clients exist to demonstrate one backend serving different runtimes
> — not to cover every platform."*

The project has **already accepted a desktop-only client on the grounds that platform coverage is not
the objective.** If the objective is demonstrating that one authoritative engine serves different
runtimes, two different runtimes demonstrate it. Flutter's distinct contribution is *platform* —
mobile, and later web — which that rationale explicitly says is not what the three clients are for.

---

## 6. Finding 4 — the total scope has grown since C-04 was written

The three shipped modes are **Pass & Play**, **Player vs AI** and **Room** (remote players and AI
together). Room requires `RemoteHuman` seats, room codes, join authorisation and the realtime push to
all work.

`docs/01-introduction.md` previously recorded online play as *"prepared, not delivered — Phase 6+"*.
That is inconsistent with Room being a shipped mode, and has been corrected: **Phase 6 is now
mandatory rather than optional.**

So the budget this amendment is spent against is **larger** than when C-04 was set, not smaller. That
is an argument for the amendment, and we would rather state it than have it found.

---

## 7. Two options, with their real costs

### Option A — **two desktop clients: Unity + Godot** *(recommended)*

| | |
|---|---|
| Functional requirements lost | **0 of 85.** FR-65…FR-70 read *"**Each** client shall…"*, so each shipped client satisfies them |
| Non-functional requirements lost | **0 of 24** |
| Test cases lost | **0 of 119.** TC-UI-01…03 run per client (6 runs instead of 9); **TC-UI-04** still runs, its text amended from *"all three clients"* to *"both clients"* |
| Architecture claim | **Preserved and still demonstrated** — two independent runtimes, one engine, one contract |
| Dropped | Mobile platform; web delivery route |

### Option B — one desktop client: Unity only

| | |
|---|---|
| Functional requirements lost | 0 of 85 |
| Test cases lost | **1 of 119** — TC-UI-04 compares clients, so it becomes unrunnable |
| Architecture claim | Becomes an **argument** rather than a **demonstration**. Nothing would prove the API is not Unity-shaped |
| Dropped | Mobile, web, and the cross-runtime evidence |

**We recommend Option A.** Option B saves one desktop client — the cheapest kind, since it needs no
new interaction model — at the cost of the project's main architectural claim.

---

## 8. What this honestly costs us

| Cost | Severity | Detail |
|---|---|---|
| **NFR-18 loses its hardest consumer** | **Real** | Unity and Godot both reference the C# contract types directly; Flutter was the only client needing **generated** Dart DTOs. The CI check still runs, but the end-to-end proof weakens |
| **A buildable client is going unbuilt** | **Real** | §3 establishes mobile would work. We are choosing not to spend the budget, which is a different and weaker claim than "it cannot be done" |
| Web delivery is foreclosed | Moderate | §8.5 names Flutter as the route to web |
| No mobile demonstration | Moderate | The mobile design is evidenced on paper, not in a running build |

We are not claiming the amendment is free. We are claiming it is cheap relative to what it buys, and
that the alternative — three clients plus a now-mandatory Phase 6, to one deadline — risks delivering
**three incomplete clients instead of two complete ones**.

---

## 9. What we deliver either way

The mobile work is **done as design** and is submitted as part of the package:

| Deliverable | Status |
|---|---|
| UI/UX design pack, 12 documents | **Complete** — [`design/`](design/) |
| All 20 screens, **desktop** wireframes with data bindings | **Complete** — [`design/08`](design/08-wireframes.md) |
| All 20 screens, **mobile-landscape** forms, per-screen audit table | **Complete** — [`design/08` §8.18](design/08-wireframes.md) |
| **Art direction sampled from reference**, every value traced to a frame | **Complete** — [`design/09`](design/09-art-direction.md) |
| **Build-ready Figma prompt, mobile landscape** — 21 frames at two sizes | **Complete** — [`design/11`](design/11-figma-prompt-mobile-landscape.md) |
| Build-ready Figma prompt, desktop | **Complete** — [`design/10`](design/10-figma-prompt-desktop.md) |
| 83 design acceptance checks (DA-01…DA-83) | **Complete** |
| 34 diagrams, all render-validated, with a zoomable viewer | **Complete** — [`diagrams.html`](diagrams.html) |
| 119 test cases · 85 requirements · 21 use cases, fully traced | **Complete** |

The mobile client is specified to the point where **a third party could build it from the documents
alone**. That is the evidence that this is an engineering decision and not an avoidance of work.

---

## 10. Proposed amendment text

> | **C-04** | **Two clients ship: Unity and Godot. The Flutter + Flame mobile client is specified and designed in full (all 20 screens, `design/08` §8.18, with a build-ready prompt at `design/11`) but is not implemented in v1. Amended by committee decision of [date]; original text required all three.** | **Locked (amended)** |

Consequential edits, made on approval:

| File | Change |
|---|---|
| `docs/03-requirements.md` §3.5 | C-04 replaced as above |
| `appendices/F-test-cases.md` | TC-UI-04 *"all three clients"* → *"both clients"*; TC-UI family runs 9 → 6 |
| `docs/09-testing.md` §9.3 | Client level: 3 runs → 2 |
| `docs/08-implementation-plan.md` §8.11 | Phase 10 marked **Not implemented — committee decision**, with the date |
| `docs/10-results-template.md` §10.5 | Screenshot 24 *"three clients"* → *"both clients"* |
| `docs/00-decisions-and-assumptions.md` | A dated decision entry recording the amendment |

Recording the amendment as a dated decision rather than editing the constraint silently is the point:
§14.5 requires that *"a cut that is reported is a scope decision; a cut that is not reported is a gap
in the evidence."*

---

## 11. Decision

| | |
|---|---|
| **Requested** | Amend C-04 per §10, Option A (Unity + Godot) |
| **Alternative** | Option B (Unity only) |
| **If declined** | We build all three clients plus the mandatory Phase 6. Per `docs/11` §11.4 this is the constraint most likely to compress everything else |
| **Decision** | ☐ Option A ☐ Option B ☐ Declined |
| **Committee member** | ______________________ |
| **Date** | ______________________ |

---

### Sources for every number

| Claim | Source |
|---|---|
| Tactical scale, visible-board percentages, pinch ratios, rail cost | Computed from [`shared/maps/world_classic.json`](shared/maps/world_classic.json); reproduced in [`design/07` §7.2](design/07-responsive-and-accessibility.md) |
| 48 px touch / 24 px pointer minimums | Material Design · Apple HIG · WCAG 2.1 SC 2.5.5 and SC 2.5.8 |
| Screen counts and per-platform forms | [`design/08` §8.18](design/08-wireframes.md) |
| FR / NFR / test counts and wording | [`docs/03-requirements.md`](docs/03-requirements.md), [`appendices/F-test-cases.md`](appendices/F-test-cases.md), [`docs/13-traceability-matrix.md`](docs/13-traceability-matrix.md) |
| The three-clients rationale | [`docs/08-implementation-plan.md`](docs/08-implementation-plan.md) §8.5 |
| Three shipped modes; Phase 6 mandatory | [`docs/01-introduction.md`](docs/01-introduction.md) §1.6, [`design/09` §9.6](design/09-art-direction.md) |
