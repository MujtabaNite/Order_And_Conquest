# Order & Conquest — UI/UX Design Pack

**Status:** implementation-ready. **Audience:** whoever opens Figma, Unity, Godot or Flutter next.

This pack exists so that screen design can begin **without re-deriving anything from the
documentation**. Every number in it is either copied from a file under `../shared/`, cited to a
requirement in `../docs/03-requirements.md`, or recorded as a design decision with a `UX-nn` ID in
§0.4 below. Nothing is invented silently.

---

## 0.1 The documents

| # | File | Covers | Binding name? |
|---|---|---|---|
| 00 | [`00-index.md`](00-index.md) | This file — scope, the UX decision register, what is deferred | |
| 01 | [`01-design-system.md`](01-design-system.md) | Colour (seat, continent, semantic), type scale, spacing, elevation, iconography, motion | |
| 02 | [`02-screen-inventory-and-flows.md`](02-screen-inventory-and-flows.md) | S-01…S-20 against the 13 endpoints and 9 action types; navigation graph; per-phase screen map | |
| 03 | [`03-map-ui-ux.md`](03-map-ui-ux.md) | The board. Landmass rule, layer stack, edge styles, range highlighting, army badges, debug renderer, desktop + mobile | **Yes** |
| 04 | [`04-dice-ui-ux.md`](04-dice-ui-ux.md) | The dice. Configurable face count (D-29), pip vs numeral, roll choreography, odds display | **Yes** |
| 05 | [`05-card-ui-ux.md`](05-card-ui-ux.md) | The cards. Six symbols, 44-card deck, set highlighting, escalation, forced trade, redaction | |
| 06 | [`06-interaction-and-affordances.md`](06-interaction-and-affordances.md) | The FR-66 rule made concrete; input grammar; every error, empty and loading state; the 409 conflict; preset messages | |
| 07 | [`07-responsive-and-accessibility.md`](07-responsive-and-accessibility.md) | Breakpoints, touch targets, colour-blind safety, reduced motion, text scaling | |
| 08 | [`08-wireframes.md`](08-wireframes.md) | Every screen, desktop and mobile, as annotated ASCII wireframes with the data each region binds to | |

Two filenames are **binding**: `03-map-ui-ux.md` and `04-dice-ui-ux.md` are already cited from
`../docs/00-decisions-and-assumptions.md`, `../docs/07-game-design.md` and
`../appendices/E-pseudocode.md`. They may not be renamed without updating those citations....     

---

## 0.2 What this pack is allowed to decide

| | |
|---|---|
| **In scope** | Layout, hierarchy, colour, type, spacing, motion, copy, input grammar, which control appears where, what each state looks like, what the artist must and must not draw |
| **Out of scope** | Any rule. This pack never decides what is legal, what a die shows, what a set is worth, or how far an attack reaches |

That boundary is not a stylistic preference — it is **FR-67**: *no client shall implement combat,
reinforcement, card, capability, range or victory logic.* So wherever a reader expects this pack to
state a game number, it instead states **which field of which server response carries it**. The
odds display in §04.6 is the clearest example: the attack panel shows `winChance` from
`GET /legal`, and because of that a d7 match needs no client change at all.

### The one rule this pack does encode

**FR-66** — *each client shall make interactive only those territories and actions named in the
server's legal-action response.* This is a UI rule, it is the backbone of the whole pack, and
§06.1 reduces it to a single expression every client implements the same way.

---

## 0.3 How a screen designer should read it

1. **[01](01-design-system.md)** once, for the tokens.
2. **[02](02-screen-inventory-and-flows.md)** to find the screen you are designing and what it owes.
3. **[08](08-wireframes.md)** for its desktop and mobile frame.
4. **[03](03-map-ui-ux.md)**, **[04](04-dice-ui-ux.md)** or **[05](05-card-ui-ux.md)** if it contains the board, the dice or the hand.
5. **[06](06-interaction-and-affordances.md)** before declaring it finished — it lists the states that are always forgotten.
6. **[07](07-responsive-and-accessibility.md)** as the acceptance checklist.

---

## 0.4 UX decision register

These are **design** decisions. They are numbered `UX-nn` and kept separate from the `D-nn` engine
decisions in `../docs/00-decisions-and-assumptions.md` for one reason: changing any of them changes
**no** observable game behaviour, so they can be revised during Phase 8–12 without re-opening a
locked rule. Every one of them is a decision a screen designer would otherwise have to guess at.

| ID | Decision | Rationale | Where |
|---|---|---|---|
| **UX-01** | **One territory is exactly one closed polygon. Every drawn landmass is a territory; every territory is a drawn landmass.** No island that is not a territory appears on the map at any zoom level | A tappable-looking landmass that is not a legal target is a lie the interface tells. It also makes hit-testing a single point-in-polygon test, and makes the artwork verifiable by counting shapes | [03 §3.3](03-map-ui-ux.md) |
| **UX-02** | Seven-entry ownership palette: six seats plus `Neutral`. Seats 0–2 keep the colours already published in the API examples | Those three appear in `../appendices/A-api-contract.md` §A.6/§A.7 as literal values; changing them would invalidate a published contract example | [01 §1.2](01-design-system.md) |
| **UX-03** | **Ownership is encoded twice — seat colour *and* a per-seat pattern.** Colour alone is never the only carrier of owner identity | A seven-way categorical palette cannot be made distinguishable for every form of colour vision. Measured: deuteranopia collapses `seat-5` Teal against `seat-neutral` Slate (ΔE 3.8) and `seat-1` Cobalt against `seat-4` Violet (ΔE 5.4); tritanopia collapses `seat-2` Jade against `seat-5` Teal (ΔE 5.4). Luminance does not rescue it either — `seat-4` and `seat-0` are 1.4 apart. The second channel is the fix, not a nicety | [07 §7.4](07-responsive-and-accessibility.md) |
| **UX-04** | **Continent colour never fills a territory.** It appears only on the continent grouping band, the bonus chip and the continent outline | Territory fill is reserved for seat identity. Europe's `#5b8fb9` and seat 1's `#2980b9` are both blue — if both could appear as a fill, a glance could not tell ownership from geography | [01 §1.3](01-design-system.md), [03 §3.4](03-map-ui-ux.md) |
| **UX-05** | Minimum supported viewport is **360 × 640 CSS px**. The board remains playable, not merely visible, at that size | It is the practical floor for shipping phones. It is a design target here and deliberately *not* promoted to an NFR, because no NFR in `../docs/03-requirements.md` fixes a viewport and this pack does not get to add one | [07 §7.1](07-responsive-and-accessibility.md) |
| **UX-06** | **Dice presentation mode is a property of the match, not of the die.** `faces ≤ 6` → pips on every die; `faces > 6` → numerals on every die | Mixing pips for 1–6 with a numeral for 7 would make the seventh face look like a special event. It is not special; it is one face of a d7 | [04 §4.3](04-dice-ui-ux.md) |
| **UX-07** | **Range display is one component, shared by land attack and Air Force.** It renders "every reachable target, with its distance", parameterised by the bound it is handed | Post-D-30 both callers ask the same question of the same land graph. Two components would drift, and S-12 would eventually disagree with the board about what range 3 means | [03 §3.8](03-map-ui-ux.md) |
| **UX-08** | The ten `crossesWater` edges are drawn **dashed**, and a dashed edge is labelled in the legend as *"land border across water"* — never as a sea route | `crossesWater` is a render hint with **no mechanical meaning** (`../shared/maps/world_classic.json` `_comment`). It is a subset of `neighbours`. A player who reads it as naval-only would mis-plan every turn | [03 §3.6](03-map-ui-ux.md) |
| **UX-09** | Until Phase 12, the board ships as the **debug renderer**: labelled circles at each territory's `label` anchor, with real edges and real interaction | `shape` is deliberately absent from the map file — *"adjacency ships first, artwork in Phase 12"*. The debug renderer is therefore the **real** board for Phases 1–11, and is specified, not improvised | [03 §3.9](03-map-ui-ux.md) |
| **UX-10** | Army counts render as a **badge pinned to the `label` anchor**, not as free text inside the polygon | `label` is documented as *"an approximate anchor for the debug board view and for the army-count badge"*. Pinning the badge there means the artwork can change in Phase 12 without moving any number | [03 §3.5](03-map-ui-ux.md) |
| **UX-11** | **No client holds a random source at all.** The dice tumble is a deterministic sweep of `1 … diceSides`, not a local random draw | FR-69 says dice animate *from the event*. Making the decorative tumble deterministic too means there is no RNG in a client for a later refactor to accidentally promote into a game outcome — FR-69 becomes verifiable by the absence of an import rather than by reading an animation | [04 §4.5](04-dice-ui-ux.md) |
| **UX-12** | A hidden card is drawn **face-down with a visible count**, never as a blank gap or a guessed back-count | Card *counts* are public in RISK and are sent for every seat; card *identities* are redacted server-side to `null`. Drawing the count from the redacted field keeps the interface truthful in both directions at once | [05 §5.6](05-card-ui-ux.md) |

---

## 0.5 Facts this pack is built on

Copied here so no document in it has to re-read a source file. Every row is verifiable.

| Fact | Value | Source |
|---|---|---|
| Board canvas | **1600 × 900** | `../shared/maps/world_classic.json` → `canvas` |
| Territories | **42**, in 6 continents, 9/4/7/6/12/4 | same → `territories` |
| Land edges | **83** undirected | `../appendices/C-map-specification.md` |
| `crossesWater` edges | **10**, render hint only, a subset of `neighbours` | same → `crossesWater` + `_comment` |
| Landlocked territories | **6** — `alberta`, `ontario`, `northern_europe`, `ukraine`, `irkutsk`, `afghanistan` | same → `coastal: false` |
| Island territories | **7** — `greenland`, `iceland`, `great_britain`, `madagascar`, `japan`, `indonesia`, `new_guinea` | geography; all are territories, so all are drawn (UX-01) |
| Territory shapes | **absent by design**; artwork is Phase 12 | same → `_comment` |
| Card symbols | Infantry 12, Cavalry 10, Artillery 8, AirForce 7, NavalForce 5, Wild 2 = **44** | `../shared/rules.json` → `cards`, map → `cardSymbol` |
| Dice faces | `6` by default, settable **2…20**, frozen per match | `../shared/rules.json` → `combat.diceSides` (D-29, FR-84) |
| Attack range | `1` by default, settable **1…10**, frozen per match | same → `combat.attackRange` (D-30, FR-85) |
| Sea routes | count chosen at setup, **2…10**, default **4**; endpoints chosen by the system | same → `seaRoutes` |
| Air Force range | **5** over land edges only; `attacksPerTurn: 1` | same → `airForce` |
| Screens | **S-01…S-20** | `../docs/05-system-design.md` §5.3 |
| Endpoints | **13**, of which **one** changes gameplay state | `../appendices/A-api-contract.md` §A.3 |
| Push events | `StateChanged`, `DiceRolled`, `TurnChanged`, `SeatEliminated`, `GameOver`, `HandOverDevice` | same → §A.9 |
| Phases | `Claim`, `Draft`, `Attack`, `Occupy`, `Fortify`, `EndTurn`, `GameOver` | `../appendices/E-pseudocode.md` |

### The two configurable parameters, in UI terms

D-29 and D-30 arrived after the rules were locked, and both are now fully specified in the engine
documents. Their entire UI consequence is small enough to state in four lines:

- **Match setup (S-04)** gains two steppers — face count and attack range — each showing its
  default and its permitted span.
- **The dice renderer (S-11, §04)** is handed a face count and a list of values and has no opinion
  about either.
- **The board (S-08, §03)** highlights whatever the legal list contains, which at range > 1 simply
  contains more territories.
- **Nothing else changes.** At the defaults — 6 and 1 — every screen in this pack is pixel-identical
  to what it would have been before those two decisions existed.

---

## 0.6 What is deliberately deferred

| Deferred | Until | Why it is safe to defer |
|---|---|---|
| Territory artwork (SVG paths) | Phase 12 | UX-09. The debug renderer is a complete, playable board; adjacency is what gameplay needs and adjacency already ships |
| Final typeface licence | Phase 8 | §01 specifies a scale and a fallback stack, not a purchase |
| Audio design | Phase 12 | S-20 already exposes the volume controls the engine needs to be told about; nothing else depends on it |
| Localisation | Post-v1 | §01 reserves 30 % string expansion in every frame so this is a translation job, not a redesign |
| Emoji/preset message artwork | Phase 12 | FR-70 is **OPT**; §06.9 specifies the slot and the no-free-text rule (D-25) so that removing it removes a panel and nothing else |

---

*Order & Conquest · UI/UX Design Pack · `design/`*
*Engine documents: [`../docs/`](../docs/) · Appendices: [`../appendices/`](../appendices/) · Data: [`../shared/`](../shared/)*
