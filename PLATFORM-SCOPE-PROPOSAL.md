# Platform Scope Proposal — Request to Amend Constraint C-04

**Project:** Order & Conquest · **Date:** 5 October 2026 · **Status:** awaiting committee decision

> **The request in one sentence.** We ask the committee to amend locked constraint **C-04** so that the
> **mobile (Flutter + Flame) client is designed in full but not implemented**, and the delivered build is
> desktop. The design for mobile is complete and is submitted as evidence; what we are asking to drop is
> the *implementation*, not the *design work*.

---

## 1. The constraint we are asking to amend

From [`docs/03-requirements.md`](docs/03-requirements.md) §3.5, verbatim:

| ID | Constraint | Origin |
|---|---|---|
| **C-04** | **Three clients must all ship: Unity, Godot, Flutter + Flame. None may be dropped.** | **Locked** |

We are treating this as a locked constraint requiring formal amendment, not as a discretionary cut. We
are raising it **now**, before Phase 8 begins, rather than discovering it at the deadline.

### What we are *not* asking for

Bounding the request matters as much as making it:

| Not requested | Still delivered in full |
|---|---|
| Any reduction in game rules | All 42 territories, 6 continents, cards, capabilities, Air Force, Naval Force |
| Any reduction in the engine, API or database | C-01, C-02, C-03 untouched |
| Any reduction in testing | 119 test cases, 85 functional requirements |
| Any reduction in **design** deliverables | All 20 screens specified for **both** desktop and mobile |
| Removal of mobile from the documentation | The mobile design is a submitted artefact, not a deleted section |

---

## 2. Finding 1 — the board cannot meet touch-target guidance on any phone

This is the central evidence, and it is arithmetic rather than opinion. It was computed directly from
the shipped map data file, [`shared/maps/world_classic.json`](shared/maps/world_classic.json).

The 42 territory anchors sit on a 1600 × 900 canvas. Measured separations:

| Measure | Value |
|---|---|
| Closest two anchors | **89.4 px** (`irkutsk` ↔ `mongolia`) |
| Median nearest-neighbour | 110.0 px |
| **Loosest** nearest-neighbour | **145.6 px** (`japan`) |

The last row is decisive: **every territory has a neighbour within 145.6 px**, so the board is uniformly
dense. There is no sparse region where larger targets would fit.

Two adjacent touch targets of diameter *d* need their centres at least *d* apart. Scaling the board to
fit a viewport therefore gives:

| Viewport (fit-to-width) | Scale | Smallest gap | Territories failing a **48 px** target | Failing **44 px** |
|---|---|---|---|---|
| 360 px — small phone | 0.225 | 20.1 px | **42 / 42** | **42 / 42** |
| 390 px — iPhone 15 | 0.244 | 21.8 px | **42 / 42** | **42 / 42** |
| 414 px — large phone | 0.259 | 23.1 px | **42 / 42** | **42 / 42** |
| 430 px — iPhone 15 Pro Max | 0.269 | 24.0 px | **42 / 42** | **42 / 42** |
| 768 px — iPad portrait | 0.480 | 42.9 px | 10 / 42 | 3 / 42 |
| 834 px — iPad Air | 0.521 | 46.6 px | 3 / 42 | 0 / 42 |
| **859 px — threshold** | **0.537** | **48.0 px** | **0 / 42** | **0 / 42** |
| 1024 px — iPad landscape | 0.640 | 57.2 px | 0 / 42 | 0 / 42 |
| 1280 px — laptop | 0.800 | 71.6 px | 0 / 42 | 0 / 42 |
| 1366 px — laptop | 0.854 | 76.4 px | 0 / 42 | 0 / 42 |
| 1920 px — desktop FHD | 1.200 | 107.3 px | 0 / 42 | 0 / 42 |

**Not "some territories in the crowded part of Asia" — all forty-two, on every phone made.**

The guidance thresholds are not ours: 48 dp is Material Design's minimum touch target, 44 pt is Apple's
Human Interface Guidelines minimum, and 44 CSS px is WCAG 2.1 success criterion 2.5.5.

### The zoom workaround does not rescue it

A phone can zoom past fit-to-width. The cost is that it stops being a board:

| Viewport | Zoom needed to comply | Board then visible |
|---|---|---|
| 360 px | **2.39 ×** | **42 %** of board width |
| 390 px | 2.20 × | 45 % |
| 414 px | 2.07 × | 48 % |
| 430 px | 2.00 × | 50 % |

> **"See the whole board and be able to touch any territory" is simultaneously true at ≥ 859 px and
> false below it.** A phone player must choose between seeing the board and being able to act on it.
> This is a property of putting 42 territories on one screen, not a layout problem we failed to solve.

Desktop clears the threshold with ~60 % margin at a standard 1366 px laptop.

---

## 3. Finding 2 — mobile is a different interaction model, not a smaller layout

Because of Finding 1, the mobile design cannot be the desktop design reflowed. Below 859 px the design
([`design/03`](design/03-map-ui-ux.md) §3.11, [`design/07`](design/07-responsive-and-accessibility.md) §7.2)
makes the **territory list the primary selection path**, with direct touch demoted to a secondary path
carrying a 22 px hit radius and a disambiguation popover.

That is a second interaction design, and it propagates:

| | Count |
|---|---|
| Screens specified for both platforms | **20 / 20** |
| Screens whose mobile form **changes structure**, not just width | **13** |
| Screens identical on both platforms | **2** (S-01 Splash, S-17 Hand-over) |
| Mobile-only interaction machinery | `BottomSheet` peek/half/full, disambiguation popover, tactical-zoom threshold, four-level declutter, one-handed reach rules, territory-list selection |

Implementing the mobile client is therefore **not** "the same screens on a smaller canvas". It is a
distinct interaction model that must be built, tested and evidenced separately — which is precisely why
we are asking to scope it as design-only rather than quietly shipping a poor version of it.

---

## 4. Finding 3 — the project's own rationale for three clients is runtime diversity, not platform coverage

This is the argument we consider strongest, because it comes from the locked documentation rather than
from us. [`docs/08-implementation-plan.md`](docs/08-implementation-plan.md) §8.5 already concedes a
desktop-only client, and gives the reason:

> *"Godot's C# builds do not target the web. The Godot client is therefore **desktop only**, and that is
> acceptable because the three clients exist to demonstrate one backend serving different runtimes — not
> to cover every platform."*

The project has therefore **already accepted a desktop-only client on the grounds that platform coverage
is not the objective.** If the objective is demonstrating that one authoritative engine serves different
runtimes, then two different runtimes demonstrate it. Flutter's distinct contribution is *platform*
(mobile, and later web) — which the stated rationale explicitly says is not what the three clients are
for.

---

## 5. Two options, with their real costs

We present two rather than one, because the choice is the committee's.

### Option A — **two desktop clients: Unity + Godot** *(recommended)*

| | |
|---|---|
| Functional requirements lost | **0 of 85.** FR-65…FR-70 read *"**Each** client shall…"*, so they are satisfied by each client that ships |
| Non-functional requirements lost | **0 of 24** |
| Test cases lost | **0 of 119.** TC-UI-01…03 run per client (6 runs instead of 9); **TC-UI-04** still runs, with its text amended from *"all three clients"* to *"both clients"* |
| Architecture claim | **Fully preserved and still demonstrated** — two independent runtimes, one engine, one contract |
| Dropped | Mobile platform; web delivery route |

### Option B — one desktop client: Unity only

| | |
|---|---|
| Functional requirements lost | 0 of 85 |
| Test cases lost | **1 of 119** — TC-UI-04 becomes unrunnable, as it compares clients |
| Architecture claim | Becomes an **argument** rather than a **demonstration**. Nothing would have proved the API is not Unity-shaped |
| Dropped | Mobile, web, and the cross-runtime evidence |

**We recommend Option A.** Option B saves one desktop client — the cheapest kind, since it needs no new
interaction model — at the cost of the project's main architectural claim.

---

## 6. What this honestly costs us

A proposal that lists only benefits is advocacy. These are the real losses, stated so the committee can
weigh them:

| Cost | Severity | Detail |
|---|---|---|
| **NFR-18 loses its hardest consumer** | **Real** | Unity and Godot can both reference the C# contract types directly; Flutter was the only client needing **generated** Dart DTOs. Dropping it means the generation pipeline has no consumer that genuinely depends on it. The CI check (*`shared/contracts/` regenerated with no diff*) still runs, but the end-to-end proof weakens |
| Web delivery is foreclosed | Moderate | §8.5 names Flutter as the route to web. Without it there is no web path |
| No mobile demonstration | Moderate | The mobile design is evidenced on paper, not in a build |
| Reduced platform breadth in the report | Minor | Offset by a deeper, measured treatment of why |

We are not claiming the amendment is free. We are claiming it is **cheap relative to what it buys**, and
that the alternative — three clients built to the deadline — risks delivering three incomplete clients
instead of two complete ones.

---

## 7. What we deliver either way

The mobile work is **done as design** and is submitted as part of the package. This is the evidence that
the scope reduction is an engineering decision and not an avoidance of work:

| Deliverable | Status |
|---|---|
| UI/UX design pack, 9 documents | **Complete** — [`design/`](design/) |
| All 20 screens, **desktop** wireframes with data bindings | **Complete** — [`design/08`](design/08-wireframes.md) |
| All 20 screens, **mobile** forms specified | **Complete** — [`design/08` §8.18](design/08-wireframes.md) is the per-screen audit table |
| Design system — colour, type, spacing, motion, 21 components | **Complete**, with measured WCAG contrast and colour-vision simulation |
| 75 design acceptance checks (DA-01…DA-75) | **Complete** |
| 33 diagrams, all render-validated | **Complete** |
| 119 test cases, 85 FRs, 21 use cases, full traceability | **Complete** |

---

## 8. Proposed amendment text

If approved, C-04 in [`docs/03-requirements.md`](docs/03-requirements.md) §3.5 is replaced by:

> | **C-04** | **Two clients ship: Unity and Godot. The Flutter + Flame mobile client is specified and designed in full (all 20 screens, `design/08` §8.18) but is not implemented in v1. Amended by committee decision of [date]; original text required all three.** | **Locked (amended)** |

Consequential edits, which we will make on approval:

| File | Change |
|---|---|
| `docs/03-requirements.md` §3.5 | C-04 replaced as above |
| `appendices/F-test-cases.md` | TC-UI-04 *"all three clients"* → *"both clients"*; TC-UI family run count 9 → 6 |
| `docs/09-testing.md` §9.3 | Client level: 3 runs → 2 runs |
| `docs/08-implementation-plan.md` §8.11 | Phase 10 marked **Not implemented — committee decision**, with the date |
| `docs/10-results-template.md` §10.5 | Screenshot 24 *"three clients"* → *"both clients"* |
| `docs/00-decisions-and-assumptions.md` | New decision entry recording the amendment and its date |

Recording the amendment as a dated decision rather than editing the constraint silently is the point:
§14.5 requires that *"a cut that is reported is a scope decision; a cut that is not reported is a gap in
the evidence."*

---

## 9. Decision

| | |
|---|---|
| **Requested** | Amend C-04 per §8, Option A (Unity + Godot) |
| **Alternative** | Option B (Unity only) |
| **If declined** | We build all three clients. Per `docs/11` §11.4 this is the constraint most likely to compress everything else, and the risk shifts to delivering three partial clients |
| **Decision** | ☐ Option A ☐ Option B ☐ Declined |
| **Committee member** | ______________________ |
| **Date** | ______________________ |

---

### Sources for every number in this document

| Claim | Source |
|---|---|
| Anchor separations, per-viewport failure counts, zoom ratios | Computed from [`shared/maps/world_classic.json`](shared/maps/world_classic.json); reproduced in [`design/07` §7.2](design/07-responsive-and-accessibility.md) |
| 48 dp / 44 pt / 44 px target minimums | Material Design, Apple HIG, WCAG 2.1 SC 2.5.5 |
| Screen counts and per-platform forms | [`design/08` §8.18](design/08-wireframes.md) |
| FR / NFR / test-case counts and wording | [`docs/03-requirements.md`](docs/03-requirements.md), [`appendices/F-test-cases.md`](appendices/F-test-cases.md), [`docs/13-traceability-matrix.md`](docs/13-traceability-matrix.md) |
| The three-clients rationale | [`docs/08-implementation-plan.md`](docs/08-implementation-plan.md) §8.5 |
| Cut order and reporting rule | [`docs/14-implementation-safety-checklist.md`](docs/14-implementation-safety-checklist.md) §14.5 |
