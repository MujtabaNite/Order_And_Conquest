# 10 · Figma AI Prompt — Desktop

**Copy everything inside the rule below into Figma AI as one prompt.** It is written to be
un-improvisable: every colour, size and string is given exactly, and §D names what must never be
invented. Nothing in it needs the rest of this pack to be read first.

Companion prompt for touch: [`11-figma-prompt-mobile-landscape.md`](11-figma-prompt-mobile-landscape.md).

> **Why it is this long.** A short prompt makes a design tool guess, and a guess produces a different
> palette, a different layout and a different set of screens every run. Every section below removes
> one class of guess.

---

```text
═══════════════════════════════════════════════════════════════════════════
ORDER & CONQUEST — DESKTOP UI  ·  FIGMA BUILD PROMPT
═══════════════════════════════════════════════════════════════════════════

ROLE
You are producing a complete, production-ready desktop UI kit for a turn-based
strategy board game called Order & Conquest. It is a RISK-style world-conquest
game: 42 territories, 6 continents, 2–6 players, dice combat.

Work in the exact order of sections A → B → C → E. Do not skip ahead, do not
merge steps, and do not begin a screen until every component it uses exists.

ART DIRECTION IN ONE LINE
A bright cyan ocean with dark slate landmasses, saturated territory fills with
heavy near-black outlines, and deep teal-navy chrome with gold accents. Glossy
and physical, not flat. Think a polished commercial board-game app, not a
dashboard and not a corporate web page.

───────────────────────────────────────────────────────────────────────────
A · STYLES — build these first, as named Figma styles
───────────────────────────────────────────────────────────────────────────

A1 · COLOUR STYLES — use these exact hex values. Do not substitute, tint,
     "harmonise" or generate additional colours.

  Board
    board/ocean              #1897C8
    board/ocean-highlight    #53B7E5
    board/ocean-deep         #2D5E74
    board/land-unowned       #383E48
    board/outline            #120400
    board/banner-panel       #D3E9F3

  Chrome
    chrome/deep              #081A24
    chrome/base              #0A2433
    chrome/panel             #123A50
    chrome/panel-raised      #20658A
    chrome/line              #1D4E68

  Text
    text/primary             #FFFFFF
    text/on-panel            #E8F2F7
    text/secondary           #9FC0D2
    text/disabled            #5E7788
    text/ink                 #000000      (only on board/banner-panel)

  Semantic
    accent/gold              #FBBA2D
    state/legal              #5FD13A
    state/legal-wash         #5FD13A  at 20% opacity
    state/danger             #FF5457
    state/warning            #FBBA2D
    state/info               #45A4EE
    state/focus              #8FD13A

  Seats — EVERY seat has TWO values. They are not interchangeable.
  "fill" paints the territory body. "accent" paints the army badge, the seat
  ring, and anything in the UI that names that seat.

    seat-0/fill #FF0103    seat-0/accent #FF2E30    (Red)
    seat-1/fill #96843C    seat-1/accent #FBBA2D    (Gold)
    seat-2/fill #2F6E92    seat-2/accent #45A4EE    (Blue)
    seat-3/fill #6D9423    seat-3/accent #8FD13A    (Green)
    seat-4/fill #8A3FA8    seat-4/accent #B97BE8    (Violet)
    seat-5/fill #B4532A    seat-5/accent #F2863A    (Orange)
    seat-neutral/fill #4E5765  seat-neutral/accent #8A94A2  (Slate)

  THERE IS NO LIGHT MODE. Build one theme only. Do not create light variants.

A2 · TEXT STYLES
  Family: Inter (fallback: system sans). Numerals MUST use tabular figures
  everywhere a number appears.

    display   32/40  Bold
    h1        24/32  Bold
    h2        20/28  SemiBold
    h3        16/24  SemiBold
    body      15/22  Regular
    body-sm   13/18  Regular
    label     12/16  SemiBold, letter-spacing +0.04em, UPPERCASE
    num-lg    28/32  Bold, tabular
    num       15/20  SemiBold, tabular

  BOARD TYPE RULE — any white text sitting on the board carries a 2px dark
  outline (#120400). This is mandatory: white on the ocean measures only
  3.33:1 contrast, and the outline is what makes it legible. It applies to
  army numerals, territory names and the phase label.

A3 · SPACING, RADIUS, ELEVATION
    space: 4, 8, 12, 16, 24, 32, 48, 64
    radius: sm 4 · md 8 · lg 16 · full 9999
    control heights: sm 32 · md 40 · lg 48
    elev-1  0 1px 2px rgba(0,0,0,.30)
    elev-2  0 4px 12px rgba(0,0,0,.40)
    elev-3  0 12px 32px rgba(0,0,0,.55)

───────────────────────────────────────────────────────────────────────────
B · COMPONENTS — build every one, with the variants listed
───────────────────────────────────────────────────────────────────────────

B1 · TerritoryShape
  Three concentric layers, always, in this order:
    1. Fill         — seat-n/fill, or board/land-unowned when unowned
    2. Inner rim    — 4px, the fill lightened ~45% (e.g. #FF0103 → #FF7975)
    3. Outline      — 3px, board/outline #120400
  Variants: unowned · owned · legal-target · selected-origin · in-range · inert
    legal-target   = add a 3px state/legal stroke outside the outline
    selected-origin= add a 3px #FFFFFF stroke outside the outline
    in-range       = state/legal-wash overlay on the fill
    inert          = fill at 55% opacity
  Ownership is ALSO encoded by a pattern at 18% opacity over the fill:
    seat-0 solid · seat-1 diagonal-45 · seat-2 horizontal · seat-3 dotted
    seat-4 diagonal-135 · seat-5 cross-hatch · neutral 30% stipple
  This second channel is required: seat-0 and seat-1 fills are indistinguishable
  under deuteranopia without it.

B2 · ArmyBadge
  Circle Ø 44. Fill = seat-n/accent. Beneath it, offset +3px down, a ring of the
  same hue at 60% brightness, so it reads as a physical token. Numeral centred,
  num-lg, #FFFFFF, 2px #120400 outline.
  Directly BELOW the badge: the territory name, body-sm Bold, #FFFFFF, 2px
  #120400 outline.
  Variants: default · changed (one pulse ring in accent/gold)

B3 · EdgeLine
  land             — invisible (a shared border implies it)
  across-water     — 2px dashed #FFFFFF at 70%
  sea-route        — 3px dotted #FFFFFF with 5px round dots, plus a small
                     anchor glyph at each end
  These three must be visually distinct. A sea route and an across-water border
  are different things and a player must never confuse them.

B4 · Die
  Rounded square 44×44, radius md, fill #FFFFFF, 1px #120400, elev-1.
  Pips: #120400, Ø7, standard western die layout.
  Variants: pips-1 … pips-6 · numeral (for face counts above 6) · rolling ·
            winning (2px state/legal) · losing (2px state/danger, 55% opacity)

B5 · Button
  Glossy pill, radius full, height 48, horizontal padding 24, label h3.
  A vertical gradient from the fill lightened 18% to the fill, a 1px darker
  bottom edge, and elev-1. NOT flat.
  Variants: primary (state/legal fill, #FFFFFF label) ·
            secondary (chrome/panel-raised fill) ·
            danger (state/danger fill) ·
            ghost (transparent, 1px chrome/line) ·
            disabled (chrome/panel fill, text/disabled label)

B6 · Also build, in the same language
  Stepper (− value +, min/max, a marked default) · Chip · SeatChip (colour +
  pattern + glyph + name + territory and army counts) · GameCard 132×184 ·
  CardHand · PhaseBar · OddsReadout (percentage + bar) · RangeReadout ·
  CapabilityPanel · Drawer · Dialogue · Toast · EmptyState · Skeleton

───────────────────────────────────────────────────────────────────────────
C · SCREENS — 20 frames at 1920×1080, named exactly "S-01 Splash" etc.
───────────────────────────────────────────────────────────────────────────

Build in this order. Use the real content given; invent no other copy.

  S-01 Splash          logo, version "v0.1.0", a thin progress bar
  S-02 Sign in         tabs Sign in / Register; Username + Password; a
                       "Continue as guest" link; error text
                       "Username or password is incorrect."
  S-03 Main menu       primary "New match"; an IN PROGRESS list with two rows
                       ("World Classic · 4 seats · round 7"); Replay, Settings
  S-04 Match setup     STEP 1 is three MODE CARDS, side by side, equal size:
                         "Pass & Play"   — 2–6 players, one device
                         "Player vs AI"  — you against 1–5 bots
                         "Room"          — invite players, add AI
                       then: map choice, seat list, and these four controls —
                         Dice faces   stepper 2–20, default 6, marked "classic"
                         Attack range stepper 1–10, default 1, marked "classic"
                         Sea routes   stepper 2–10, default 4
                         Allocation   Random | Claim
  S-05 Sea routes      the count stepper with its permitted range visible
  S-06 Lobby           room code "7F3K", seat rows, a greyed Neutral row
                       labelled "never acts", a Start button
  S-07 Claim           board + a top banner "Tap any grey territory to claim it"
  S-08 Main board      THE KEY SCREEN — see C1
  S-09 Draft           army total 14, a breakdown (territories 4, Africa 3,
                       Australia 2, card set 5), placement rows with steppers
  S-10 Cards           hand of 3, the escalation ladder 4 6 8 10 [12] 15 20 25,
                       "1 valid set", a Trade button, opponent rows showing
                       face-down backs with counts
  S-11 Attack          Kamchatka → Alaska, 12 vs 3 armies, dice stepper 1–3,
                       "win chance 66%" with a bar, the dice tray (see C2)
  S-12 Air Force       same, plus a range column; targets listed with distances
  S-13 Naval Force     same, plus the sea route being crossed
  S-14 Occupy          BLOCKING modal, no close button of any kind, a stepper
                       from 3 to 11, text "You rolled 3 dice, so at least 3
                       armies must move in."
  S-15 Fortify         from/to/amount, a note "one per turn"
  S-16 Capabilities    rows: Infantry held, Cavalry held, Artillery —,
                       AirForce held (from a card), NavalForce held (Brazil).
                       NO Wild row. Never add one.
  S-17 Hand-over       BLOCKING full screen, seat glyph, "Pass the device to
                       MARS", "The previous player's cards have been cleared.",
                       one Continue button
  S-18 Game over       "YOU WIN", "world domination", a standings table
  S-19 Replay          the board again plus an action log and a transport bar
  S-20 Settings        Music, Effects, Animation speed, Reduced motion, Text
                       size; then a THIS MATCH block showing Dice faces, Attack
                       range and Sea routes as READ-ONLY with the note
                       "Fixed when the match was created."
                       Do NOT add a theme switch. There is one theme.

C1 · S-08 MAIN BOARD — exact layout at 1920×1080
  ┌──────────────────────────────────────────────────────────────┐
  │ PhaseBar  56px   Round 12 · ATTACK · Seat 0      [⚙][Caps]   │
  ├────────────┬──────────────────────────────┬──────────────────┤
  │ SEAT LIST  │        BOARD                 │   CARD HAND      │
  │  240px     │   16:9, letterboxed,         │     300px        │
  │            │   never stretched            │                  │
  │ SeatChip×n │                              │  GameCard×n      │
  │            │   ocean #1897C8 with a faint │  escalation      │
  │ continent  │   triangulated line texture  │  ladder          │
  │ bonuses    │   at 8% white                │  ───────────     │
  │            │   legend bottom-left         │  EVENT LOG       │
  ├────────────┴──────────────────────────────┴──────────────────┤
  │ ACTION BAR 72px   origin → target · dice · odds   [End phase ▸]│
  └──────────────────────────────────────────────────────────────┘
  Side panels sit over the ocean margins so no landmass is covered.
  "End phase" is ALWAYS the rightmost control in the action bar.

C2 · THE DICE TRAY (inside S-11)
  Three regions, stacked, in this order — the order the rule is applied:
    1. ROLLED    attacker row then defender row, in the order drawn
    2. COMPARED  both rows re-sorted high→low, paired highest-with-highest,
                 each pair joined by a connector
    3. OUTCOME   "Attacker −1 army    Defender −1 army"
  A TIED PAIR is labelled, in words, "TIE → defender holds", with the connector
  in state/danger. The defender wins ties. This is the single most
  misremembered rule in the game and it must be unmissable.
  Unpaired attacker dice are shown greyed and labelled "discarded" — never
  hidden.

───────────────────────────────────────────────────────────────────────────
D · HARD CONSTRAINTS — do not violate any of these
───────────────────────────────────────────────────────────────────────────

  1.  Do NOT invent colours. Use only §A1.
  2.  Do NOT build a light theme or a theme switch.
  3.  Do NOT use a continent colour as a territory fill. Continent colour
      appears only as an outline, a bonus chip, or a list grouping band.
  4.  Do NOT put a Wild row in the capability panel. A Wild grants nothing.
  5.  Do NOT give S-14 Occupy or S-17 Hand-over a close button, an X, a back
      arrow or any dismissal. They are blocking by requirement.
  6.  Do NOT show another player's card faces anywhere. Opponent hands are
      face-down backs plus a visible count.
  7.  Do NOT invent screens, tabs, menus or features. Exactly the 20 in §C.
  8.  Do NOT add chat, a text input, an emoji picker or a friends list. There
      is no free-text input anywhere in this product.
  9.  Do NOT add leaderboards, shops, currencies, battle passes, daily rewards,
      lives, energy or any monetisation surface.
  10. Do NOT use lorem ipsum. Use the real strings in §C.
  11. Do NOT use flat Material-style buttons. Buttons are glossy pills (§B5).
  12. Do NOT render white board text without its 2px dark outline.
  13. Do NOT swap a seat fill for a seat accent. Territory bodies take fill;
      badges take accent.
  14. Do NOT add a turn timer or any countdown. Nothing in this game expires.
  15. Do NOT copy the RISK wordmark, Hasbro or SMG artwork, or any character
      portrait. The art direction is the reference; the assets are not.

───────────────────────────────────────────────────────────────────────────
E · SELF-CHECK — verify before returning, and state the result of each
───────────────────────────────────────────────────────────────────────────

  [ ] 20 frames exist, named S-01 … S-20
  [ ] Every colour in the file is a style from §A1
  [ ] Every territory has fill + 4px inner rim + 3px #120400 outline
  [ ] Every army badge uses seat accent, every territory body uses seat fill
  [ ] Every white board label has a 2px dark outline
  [ ] Ownership is encoded by colour AND pattern
  [ ] S-14 and S-17 have no dismissal control of any kind
  [ ] The capability panel has no Wild row
  [ ] S-20 shows dice faces, attack range and sea routes read-only, and has no
      theme switch
  [ ] S-04 opens with exactly three mode cards
  [ ] The dice tray labels a tie in words and shows discarded dice
  [ ] No chat, shop, leaderboard, timer or monetisation element exists
  [ ] Every number uses tabular figures

═══════════════════════════════════════════════════════════════════════════
```

---

## How to use this

| Step | |
|---|---|
| 1 | Paste the whole block. If the tool truncates, split at the section rules and paste A, then B, then C, then D+E — in that order |
| 2 | If it returns fewer than 20 frames, reply with: *"Continue from S-nn. Same styles and components, no new colours."* |
| 3 | If it invents a colour, reply with the exact token name and value from §A1 rather than describing the colour |
| 4 | Run §E as the review. Anything unticked is a defect, not a variation |

**Keep §D intact.** Each line in it exists because it is a mistake a design tool reliably makes, or a
rule in this project that an outsider cannot infer: the blocking screens, the Wild row, the absence
of a text input and the absence of monetisation are all correctness requirements, not preferences.

---

[← 09 Art direction](09-art-direction.md) · [11 Figma prompt — mobile landscape →](11-figma-prompt-mobile-landscape.md)
