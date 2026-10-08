# 11 · Figma AI Prompt — Mobile, Landscape

**Copy everything inside the rule below into Figma AI as one prompt.** It is the touch counterpart to
[`10-figma-prompt-desktop.md`](10-figma-prompt-desktop.md) and is deliberately **not** a
"make it responsive" instruction — the touch layout has a different interaction model, and asking a
tool to shrink the desktop build produces the wrong answer.

> **Run this as a separate prompt, in a separate file.** If you paste it into the same session as the
> desktop prompt, the tool will try to reconcile the two layouts and will usually resize the board,
> which breaks the touch guarantee in §B1.

---

```text
═══════════════════════════════════════════════════════════════════════════
ORDER & CONQUEST — MOBILE UI, LANDSCAPE ONLY  ·  FIGMA BUILD PROMPT
═══════════════════════════════════════════════════════════════════════════

ROLE
You are producing a complete, production-ready MOBILE UI kit for a turn-based
strategy board game called Order & Conquest — a RISK-style world-conquest game
with 42 territories, 6 continents, 2–6 players and dice combat.

THE APP IS LANDSCAPE-ONLY. There is no portrait layout. Build every frame
landscape. The only portrait artwork in the entire product is a single rotate
prompt (S-00 below).

Work in order A → B → C → E. Do not skip ahead.

ART DIRECTION IN ONE LINE
A bright cyan ocean with dark slate landmasses, saturated territory fills with
heavy near-black outlines, deep teal-navy chrome, gold accents. Glossy and
physical, not flat. A polished commercial board-game app.

FRAME SIZES — build every screen at BOTH
    844 × 390   (primary — iPhone 15 landscape)
    932 × 430   (large phone)
Name them "S-08 Main board · 844" and "S-08 Main board · 932".

───────────────────────────────────────────────────────────────────────────
A · STYLES — identical to the desktop kit. Build them first.
───────────────────────────────────────────────────────────────────────────

A1 · COLOUR — exact values, no substitutions, no additions.

  Board    ocean #1897C8 · ocean-highlight #53B7E5 · ocean-deep #2D5E74
           land-unowned #383E48 · outline #120400 · banner-panel #D3E9F3
  Chrome   deep #081A24 · base #0A2433 · panel #123A50 ·
           panel-raised #20658A · line #1D4E68
  Text     primary #FFFFFF · on-panel #E8F2F7 · secondary #9FC0D2 ·
           disabled #5E7788 · ink #000000 (only on banner-panel)
  State    gold #FBBA2D · legal #5FD13A · danger #FF5457 · info #45A4EE ·
           focus #8FD13A

  Seats — TWO values each, never interchangeable.
    seat-0 fill #FF0103 accent #FF2E30     seat-3 fill #6D9423 accent #8FD13A
    seat-1 fill #96843C accent #FBBA2D     seat-4 fill #8A3FA8 accent #B97BE8
    seat-2 fill #2F6E92 accent #45A4EE     seat-5 fill #B4532A accent #F2863A
    seat-neutral fill #4E5765 accent #8A94A2

  ONE THEME ONLY. No light mode, no theme switch.

A2 · TEXT — Inter. Tabular figures on every number.
    h1 24/32 Bold · h2 20/28 SemiBold · h3 16/24 SemiBold · body 15/22 ·
    body-sm 13/18 · label 12/16 SemiBold UPPERCASE +0.04em ·
    num-lg 28/32 Bold tabular · num 15/20 SemiBold tabular
    Minimum rendered size anywhere: 12px.
    BOARD TYPE RULE — white text on the board carries a 2px #120400 outline.
    Mandatory: white on the ocean is only 3.33:1 without it.

A3 · SIZING
    space 4 8 12 16 24 32 · radius sm 4 md 8 lg 16 full 9999
    EVERY interactive control is at least 48 × 48. No exceptions outside the
    board.

───────────────────────────────────────────────────────────────────────────
B · THE THREE RULES THAT DEFINE THIS LAYOUT
───────────────────────────────────────────────────────────────────────────

B1 · THE BOARD IS FULL-BLEED AND NO PANEL EVER RESIZES IT
  The board fills the whole frame beneath a 40px top bar. Panels FLOAT OVER it.
  They never push it, shrink it, or squeeze it into a column.
  Reason, and it is not stylistic: a territory is tappable only when the board
  is at or above a certain scale. Shrinking the board to make room for a panel
  drops territories below the minimum touch size. A persistent 280px side rail
  takes an iPad mini from a compliant 57px target down to 41px and puts 16 of
  42 territories under the minimum. So: overlay, never resize.

B2 · PANELS ARE RIGHT-EDGE DRAWERS, NOT BOTTOM SHEETS
  In landscape the board has only 320–390px of height. A bottom sheet would eat
  half of it. Every panel slides in from the RIGHT edge.
    width: min(320px, 45% of frame width)
    elevation: a strong drop shadow; no scrim over the board — the player is
    choosing a target on it while the drawer is open
    dismiss: tap the board, swipe right, or the ✕
  TWO EXCEPTIONS, both deliberate:
    · The card hand (S-10) is a BOTTOM STRIP, because a hand is a horizontal
      row of at most 5 cards. 168px tall, overlay, never wraps.
    · S-14 Occupy and S-17 Hand-over are CENTRED BLOCKING MODALS.

B3 · THE BOARD HAS TWO NAMED ZOOM STATES
    OVERVIEW   — the whole board fits. For reading the position.
    TACTICAL   — zoomed in. Every territory carries a 48px touch target.
  A small chip in the top bar always reads OVERVIEW or TACTICAL, so the player
  knows whether a tap will be precise.
  Selecting a territory AUTO-ZOOMS to Tactical, centred on it. The player gets
  a compliant target without having to pinch deliberately.
  A [⊕] control bottom-right snaps between the two states.
  Gestures: one-finger drag pans · two-finger pinch zooms · double-tap a
  territory goes Tactical on it · two-finger double-tap returns to Overview.

───────────────────────────────────────────────────────────────────────────
C · COMPONENTS
───────────────────────────────────────────────────────────────────────────

Build B1–B6 exactly as in the desktop kit:
  TerritoryShape (fill + 4px lightened inner rim + 3px #120400 outline, plus an
  18%-opacity per-seat pattern — the pattern is required, because seat-0 and
  seat-1 fills are indistinguishable under deuteranopia without it)
  ArmyBadge (Ø48 on touch; accent fill, darker ring offset +3px, white numeral
  with 2px dark outline, territory name below in the same treatment)
  EdgeLine (land invisible · across-water 2px dashed white · sea-route 3px
  dotted white with round dots and anchor glyphs — these three must be
  visually distinct)
  Die (48×48 on touch) · Button (glossy pill, height 48)

Then these, specific to touch:
  Drawer        closed · open
  ZoomControl   overview · tactical
  ActionCluster bottom-RIGHT, floating. NOT a full-width bar — vertical space
                is the scarce axis in landscape. "End phase" stays rightmost.
  SeatRail      right edge, a vertical stack of circular seat avatars, each
                with its accent ring, a small territory/army count, and a "YOU"
                tag on the local seat
  TopBar        40px. Round · phase · current seat · zoom-state chip · a
                settings glyph · tab buttons for Caps and Cards
  InstructionBanner  top-centre, rounded, banner-panel #D3E9F3 fill with BLACK
                text. Used for one-line guidance such as "Tap any of your
                territories to begin deploying troops."
  RotatePrompt  the entire portrait layout: one icon, one line, nothing else

───────────────────────────────────────────────────────────────────────────
D · SCREENS — 21 frames, each at 844×390 and 932×430
───────────────────────────────────────────────────────────────────────────

  S-00 Rotate        PORTRAIT 390×844. An icon and "Rotate your device to
                     play". Nothing else on this frame.
  S-01 Splash        logo, version, thin progress bar
  S-02 Sign in       centred card; Sign in / Register tabs; guest link
  S-03 Main menu     "New match" primary; an in-progress list
  S-04 Match setup   STEP 1 — three MODE CARDS in a row, equal size:
                       "Pass & Play"  — 2–6 players, one device
                       "Player vs AI" — you against 1–5 bots
                       "Room"         — invite players, add AI
                     then one step per screen, dots in the header:
                       map · seats · dice faces 2–20 (default 6 "classic") ·
                       attack range 1–10 (default 1 "classic") ·
                       sea routes 2–10 (default 4) · allocation
  S-05 Sea routes    the count stepper, permitted range visible
  S-06 Lobby         room code "7F3K", seat rows, a greyed Neutral row
                     labelled "never acts"
  S-07 Claim         board + instruction banner + action cluster
  S-08 Main board    THE KEY SCREEN — build BOTH states, see D1
  S-09 Draft         right drawer: total 14, breakdown, placement steppers
  S-10 Cards         BOTTOM STRIP, see D2
  S-11 Attack        right drawer: Kamchatka → Alaska, 12 vs 3, dice stepper
                     1–3, "win chance 66%" + bar, dice tray
  S-12 Air Force     right drawer, wide: targets with distances
  S-13 Naval Force   right drawer: the sea route being crossed
  S-14 Occupy        CENTRED BLOCKING MODAL. No close, no X, no back. Stepper
                     3–11. "You rolled 3 dice, so at least 3 armies must move
                     in."
  S-15 Fortify       right drawer; "one per turn"
  S-16 Capabilities  right drawer, wide. Infantry held · Cavalry held ·
                     Artillery — · AirForce held (from a card) · NavalForce
                     held (Brazil). NO WILD ROW.
  S-17 Hand-over     BLOCKING full screen. Seat glyph, "Pass the device to
                     MARS", "The previous player's cards have been cleared.",
                     one Continue button.
  S-18 Game over     "YOU WIN", standings
  S-19 Replay        board + right drawer log + a bottom-centre transport bar
  S-20 Settings      Music · Effects · Animation speed · Reduced motion · Text
                     size; then THIS MATCH showing dice faces, attack range and
                     sea routes READ-ONLY, noted "Fixed when the match was
                     created." No theme switch.

D1 · S-08 MAIN BOARD — build both states as separate frames

  "S-08 Main board · overview · 844"
  ┌────────────────────────────────────────────────────────────┐
  │ r7 · ATTACK · Seat 0 ●   ◉ OVERVIEW   ⚙ [Caps] [Cards 3]  │ 40
  ├────────────────────────────────────────────────────────────┤
  │                                                            │
  │              BOARD — full bleed, whole map visible          │
  │                                                            │
  │                                                     [⊕]    │
  │                              ┌─ ⚔ Attack ─┬─ End phase ▸─┐ │
  └──────────────────────────────┴────────────┴───────────────┘
                                          seat rail on the right edge

  "S-08 Main board · tactical + drawer · 844"
  ┌──────────────────────────────┬─────────────────────────────┐
  │ r7 · ATTACK ●  ◉ TACTICAL    │ KAMCHATKA → ALASKA       ✕ │ 40
  ├──────────────────────────────┤─────────────────────────────┤
  │   BOARD — zoomed in.          │ 12 armies    vs    3        │
  │   SAME scale and SAME centre  │ dice   ① ② ③                │
  │   as if the drawer were not   │ win chance        66 %      │
  │   there. The drawer FLOATS.   │ ████████████░░░░░░          │
  │   Do not shrink the board.    │ [        ATTACK        ]    │
  │                               │ ▸ Other targets (4)         │
  └──────────────────────────────┴─────────────────────────────┘
                                        drawer ≤ 320px

D2 · S-10 CARDS — bottom strip, 168px
  ┌────────────────────────────────────────────────────────────┐
  │ r7 · DRAFT · Seat 0 ●              ⚙ [Caps] [Cards 3]     │ 40
  ├────────────────────────────────────────────────────────────┤
  │                  BOARD — unchanged                          │
  ├────────────────────────────────────────────────────────────┤
  │ YOUR HAND 3      next set 12      1 valid set              │ 44
  │ ┌───┐┌───┐┌───┐                      ◆ Mars  ▨▨    2       │
  │ │ ✈ ││ 🛡 ││ ✦ │   tap to select     ▲ Chaos ▨▨▨▨  4 ⚠     │124
  │ └───┘└───┘└───┘      [    TRADE    ]                       │
  └────────────────────────────────────────────────────────────┘
  Cards are 88×124 on touch. Five cards plus gaps is about 480px, so a full
  hand fits ONE row at every supported width. It must never wrap.
  The Trade button sits to the RIGHT of the cards, never beneath them.

D3 · THE DICE TRAY (inside S-11)
  Three regions, stacked, in the order the rule is applied:
    1. ROLLED    attacker row, then defender row, in the order drawn
    2. COMPARED  both rows re-sorted high→low and paired, with connectors
    3. OUTCOME   "Attacker −1 army    Defender −1 army"
  A TIE is labelled in words — "TIE → defender holds" — with the connector in
  state/danger. The defender wins ties; it is the most misremembered rule in
  the game and must be unmissable.
  Unpaired attacker dice are shown greyed and labelled "discarded", never
  hidden.

───────────────────────────────────────────────────────────────────────────
E · HARD CONSTRAINTS
───────────────────────────────────────────────────────────────────────────

  1.  LANDSCAPE ONLY. The only portrait frame is S-00 Rotate.
  2.  Do NOT let any panel resize, squeeze or reposition the board.
  3.  Do NOT use bottom sheets. Right drawers, plus the one card strip.
  4.  Do NOT invent colours. Only §A1.
  5.  Do NOT build a light theme or a theme switch.
  6.  Do NOT make any control smaller than 48×48 outside the board.
  7.  Do NOT give S-14 or S-17 a close button, X, back arrow or any dismissal.
  8.  Do NOT show another player's card faces. Face-down backs plus a count.
  9.  Do NOT put a Wild row in the capability panel.
  10. Do NOT wrap the card hand onto a second row.
  11. Do NOT add chat, a text field, an emoji picker or a friends list.
  12. Do NOT add shops, currencies, battle passes, daily rewards, lives,
      energy, leaderboards or any monetisation surface.
  13. Do NOT add a turn timer or countdown. Nothing here expires.
  14. Do NOT use lorem ipsum. Use the strings in §D.
  15. Do NOT use flat Material buttons. Glossy pills.
  16. Do NOT render white board text without its 2px dark outline.
  17. Do NOT swap seat fill and seat accent.
  18. Do NOT copy the RISK wordmark, Hasbro or SMG artwork, or any character
      portrait.

───────────────────────────────────────────────────────────────────────────
F · SELF-CHECK — verify and report each line
───────────────────────────────────────────────────────────────────────────

  [ ] Every frame is landscape except S-00
  [ ] Each screen exists at BOTH 844×390 and 932×430
  [ ] S-08 exists in both Overview and Tactical states
  [ ] In the Tactical frame the board is NOT narrower than in Overview
  [ ] Every panel is a right drawer, except the card strip and the two modals
  [ ] The action cluster is bottom-right, not a full-width bar
  [ ] A zoom-state chip reads OVERVIEW or TACTICAL on every board frame
  [ ] Every control outside the board is ≥ 48×48
  [ ] The card hand is one row and does not wrap
  [ ] S-14 and S-17 have no dismissal control
  [ ] No Wild row in the capability panel
  [ ] Every white board label has a 2px dark outline
  [ ] Ownership is encoded by colour AND pattern
  [ ] No chat, shop, leaderboard, timer or monetisation element exists
  [ ] Every number uses tabular figures

═══════════════════════════════════════════════════════════════════════════
```

---

## How this differs from the desktop prompt, and why that matters

A design tool handed both prompts in one session will try to unify them. It must not, because three
things genuinely differ:

| | Desktop | Mobile landscape |
|---|---|---|
| Board | a column between two persistent panels | **full-bleed**, never resized |
| Panels | persistent side panels | **overlay drawers** + one bottom card strip |
| Selection | pointer, 24px minimum | **touch, 48px minimum**, reached via the Tactical zoom state |
| Zoom | available, rarely needed | **structural** — two named states, auto-framed on selection |

The zoom model is the part most likely to be dropped as "extra", so §B3 states it before any screen
is drawn and §F checks it twice. Without it the touch targets are not compliant, and with it they are
— which makes it a correctness requirement rather than a feature.

---

[← 10 Figma prompt — desktop](10-figma-prompt-desktop.md) · [00 Index](00-index.md)
