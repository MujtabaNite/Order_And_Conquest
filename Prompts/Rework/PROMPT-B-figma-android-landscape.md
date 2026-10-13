# PROMPT B — Figma prompts for the Android landscape screens

**What this replaces:** `design/11-figma-prompt-mobile-landscape.md`. That prompt was one giant message for an iPhone layout with features you no longer have (Pass & Play, dice/attack-range steppers, sea-route count, hand-over screen, guest login). This version is split into **small stages** because AI design tools handle short, focused prompts far better than one 24 KB message.

## How to use it (read once)

1. Create **one new Figma file** called `Order & Conquest — Mobile`. All three clients (Unity, Godot, Flutter) copy from this single file.
2. For each stage, open a **new generation** and paste: **HEADER + that stage's block** in one message. Do not paste two stages together.
3. Run the stages in order: **0 → 1 → 2 → 3**. After each stage, run the stage's **check list** and fix by hand before moving on.
4. **Do not ask the AI to draw the real 42-territory map.** It cannot do it accurately. Every board frame uses a *board placeholder* (an ocean-blue rectangle with simple territory circles). If you have `board_placeholder.svg` from the team, drop it into every board frame; otherwise let the AI draw 12–15 rounded land blobs. The real artwork is a later task.
5. If the AI ignores a rule (it will sometimes), do not re-argue. Fix that frame by hand using the check list. The prompts are also a plain specification you can build from manually.
6. Expect about **2–3 hours per stage** including fix-ups. Stage 1 and 2 are what your next meeting needs; Stage 3 is for later.

**Scope tags:** `[P1]` classic RISK, needed for the demo · `[P2]` Air Force / Naval Force screens, designed now, built later.

---

## HEADER — paste this at the top of every stage

```text
PRODUCT
Order & Conquest — a turn-based, RISK-style world-conquest game for 2–6 players
(humans and AI bots) with dice combat. ANDROID PHONE, LANDSCAPE ONLY.
The ONLY portrait frame in the whole project is one "rotate your phone" screen.

FRAME SIZES — build every screen at BOTH:
  915 × 412   primary  (modern Android phone, landscape)
  800 × 360   compact  (smaller / older phone, landscape)
Name frames like:  "S-08 Main board · 915"  and  "S-08 Main board · 800".
SAFE AREAS: keep all controls 24px away from the left and right edges (camera
cut-out) and 12px above the bottom edge (gesture bar).
ONE THEME ONLY (dark). No light mode, no theme switch.

COLOURS — use exactly these hex values, invent no others
  Board    ocean #1897C8 · ocean-highlight #53B7E5 · ocean-deep #2D5E74 ·
           land-unowned #383E48 · outline #120400 · banner-panel #D3E9F3
  Chrome   deep #081A24 · base #0A2433 · panel #123A50 · panel-raised #20658A ·
           line #1D4E68 · list-ground #102032 · panel-charcoal #333333 ·
           instruction-overlay #008CD4
  Text     primary #FFFFFF · on-panel #E8F2F7 · secondary #9FC0D2 ·
           disabled #5E7788 · ink #000000 (only on banner-panel)
  State    gold #FBBA2D · legal #5FD13A · danger #FF5457 · info #45A4EE
  Seats (fill / accent — never swap them)
    seat-0 #FF0103 / #FF2E30    seat-3 #6D9423 / #8FD13A
    seat-1 #96843C / #FBBA2D    seat-4 #8A3FA8 / #B97BE8
    seat-2 #2F6E92 / #45A4EE    seat-5 #B4532A / #F2863A
    seat-neutral #4E5765 / #8A94A2

TYPE — Inter. Tabular figures on every number. Minimum 12px anywhere.
  h1 24/32 Bold · h2 20/28 SemiBold · h3 16/24 SemiBold · body 15/22 ·
  body-sm 13/18 · label 12/16 SemiBold UPPERCASE · num 15/20 SemiBold tabular
  White text drawn ON THE BOARD always has a 2px #120400 outline.

SHAPE & SIZE — spacing 4 8 12 16 24 32 · corner radius 4 / 8 / 16 / pill.
  EVERY tappable control is at least 48 × 48. Buttons are GLOSSY PILLS
  (vertical gradient, lighter top edge, darker bottom edge), never flat.
  Lists are built from glossy pill rows, never ruled table rows.

LOOK IN ONE LINE
  Bright cyan ocean, dark slate land, deep teal-navy chrome, gold accents —
  glossy, physical, a polished board-game app. Do NOT copy the RISK logo,
  Hasbro artwork or any character portrait.

NEVER ADD: chat, text messaging, emoji, friends list, shop, currency, ads,
battle pass, daily rewards, lives/energy, leaderboards, turn timers,
guest login, lorem ipsum.
```

---

## STAGE 0 — Styles and components `[P1]`

Paste HEADER, then:

```text
TASK
Build the style library and the reusable components. Do NOT build any full
screens yet. Put everything on one page called "Kit".

1. COLOUR STYLES — one per colour in the header, named exactly (e.g.
   "ocean", "seat-0 fill", "seat-0 accent").
2. TEXT STYLES — the seven in the header.
3. COMPONENTS (with the listed variants):
   Button        glossy pill, height 48. Variants: primary (gold), secondary
                 (blue), danger, disabled. Label bold white with dark outline.
   TextField     height 48, panel-charcoal fill, white text, 1px line border.
                 Variants: empty (with placeholder), filled, focused, error
                 (danger border + one line of error text under it).
   Tabs          two pill tabs, one active (blue gradient) one inactive (grey).
   ListRow       glossy pill, full width, height 50, on list-ground, 8px gaps.
                 Active = blue gradient #3199E5→#2C87C9. Inactive = grey
                 gradient. Parts: ordinal prefix, label, trailing value,
                 trailing icon buttons (48×48), circular status dot.
   StatusDot     12px circle. Variants: ok (legal green), waiting (gold),
                 error (danger red), offline (disabled grey).
   TitlePlaque   wide gold pill, 3px #ECECEC border, gradient
                 #F1E659 → #F9D85B → #FFFC72, white display label with heavy
                 dark outline. At most ONE per screen.
   Banner        top-centre, rounded, #D3E9F3 fill, BLACK text, one line.
                 Variants: info, warning (gold edge), error (danger edge).
   Stepper       [−] value [+] with 48×48 buttons.
   SeatAvatar    circle with the seat accent ring, small army/territory count,
                 and a "YOU" tag variant. Variants: human, AI (robot glyph),
                 empty (dashed ring), neutral (grey, "never acts").
   ArmyBadge     48px circle, seat accent fill, darker ring offset 3px, white
                 numeral with 2px dark outline, territory name beneath.
   Die           48×48 white die, tabular numeral. Variants 1–6, plus
                 "discarded" (greyed) and "rolling".
   TerritoryShape  a rounded blob, fill = seat fill, 4px lighter inner rim,
                 3px #120400 outline, plus an 18%-opacity PATTERN per seat
                 (stripes, dots, crosses, waves, checks, diamonds) so seats are
                 distinguishable without colour.
   BoardPlaceholder  915×412 and 800×360 variants: ocean rectangle with 12–15
                 territory shapes. (If board_placeholder.svg is available, use it.)
   TopBar        height 40: "r7 · ATTACK · Seat 0 ●", zoom chip, settings
                 glyph, "Caps" and "Cards 3" tab buttons.
   Drawer        right-edge panel, width min(320, 45% of frame), strong drop
                 shadow, NO dim over the board. Variants: closed, open.
   ActionCluster floating bottom-RIGHT group of 1–3 pills. "End phase" is
                 always rightmost. NOT a full-width bar.
   SeatRail      vertical stack of SeatAvatars on the right edge.
   ZoomChip      reads OVERVIEW or TACTICAL.
   RotatePrompt  the entire portrait layout: one phone icon, one line.

CHECK
[ ] every colour/text style exists and is named
[ ] every interactive component is ≥ 48×48
[ ] Button, ListRow and TitlePlaque are glossy, not flat
[ ] SeatAvatar has human, AI, empty and neutral variants
[ ] TerritoryShape has 6 seat patterns
```

---

## STAGE 1 — Connection, accounts, rooms `[P1]`

Paste HEADER, then:

```text
TASK
Using the Kit components, build these screens. 10 frames × 2 sizes
(S-00 is portrait and has one size).

FLOW:  Splash → Connect to host → Sign in / Register → Main menu →
       Create room  OR  Join room → Lobby → (game)

S-00 Rotate        PORTRAIT 412×915. Phone-rotate icon and "Rotate your phone
                   to play". Nothing else.
S-01 Splash        game logo (plain wordmark "ORDER & CONQUEST"), version
                   "v0.1 prototype", thin progress bar.
S-02a Connect to host
                   The phones talk to a laptop on the same hotspot, so the
                   player must tell the app where the laptop is.
                   Centred panel. TextField "Host address" with example text
                   "192.168.43.10 : 5000". Primary button "Connect". Under it
                   a list "Recent hosts" (ListRow, one entry with a status dot).
                   Three state frames: idle · connecting (spinner, button
                   disabled) · "Cannot reach the host. Check that your phone
                   is on the demo hotspot." (error Banner, red dot).
S-02 Sign in / Register
                   Centred card. Tabs "Sign in" | "Register".
                   Sign in: Username, Password, button "Sign in".
                   Register: Username, Display name, Password, Confirm
                   password, button "Create account".
                   Show one error state ("Username already taken").
                   NO guest option, NO social login.
S-03 Main menu     TitlePlaque "ORDER & CONQUEST". Primary "Create room",
                   secondary "Join room". Below: "In progress" list with two
                   ListRows ("Room 7F3K · Round 7 · your turn" with green dot;
                   "Room 2QD9 · waiting" with gold dot) and a "Resume" icon
                   button on each. Top-right: player name "Mujtaba" and a
                   Settings glyph. "Sign out" as a small text button.
S-04 Create room   ONE screen, not a stepper. Left half: map card "Classic
                   world · 42 territories · 6 continents" (selected, single
                   option). Right half: "Seats" with a Stepper 2–6 and a list of
                   seat rows: Seat 1 "You (host)", Seat 2 "Open — waiting for a
                   player", Seat 3 "Add AI bot" (opens a menu with four
                   bot types: Passive, Chaotic, Aggressive, Mars). Primary
                   "Create room". NO rule settings, NO dice controls.
S-04b Join room    Large 4-character room-code field, on-screen keypad area
                   hint, primary "Join". Error state: "Room not found".
                   Full-room state: "This room is full."
S-06a Lobby (host) Big room code "7F3K" in a plaque. Seat rows (ListRow):
                   1 "Mujtaba (you)" ready · 2 "Abdullah" ready · 3 "Mars (AI)"
                   · 4 "Open" dashed · a greyed "Neutral — never acts" row.
                   Buttons: "Add AI bot", "Start match" (enabled when ≥ 2
                   seats filled), "Close room".
S-06b Lobby (guest) same list, no Start button, banner "Waiting for the host
                   to start the match…".

CHECK
[ ] only S-00 is portrait; all others exist at 915×412 and 800×360
[ ] S-02a has idle, connecting and error frames
[ ] no guest login, no social login anywhere
[ ] S-04 has no dice, attack-range, sea-route or mode-card controls
[ ] bot types are exactly Passive, Chaotic, Aggressive, Mars
[ ] every control ≥ 48×48 and inside the safe area
```

---

## STAGE 2 — The board and the classic turn `[P1]`

Paste HEADER, then:

```text
TASK
Build the in-game screens for CLASSIC RISK (no Air Force, no Naval Force yet).
Every frame is built on the BoardPlaceholder, full-bleed under a 40px TopBar.

THREE LAYOUT RULES (these are the heart of the design)
R1  The board is full-bleed. Panels FLOAT over it. A panel NEVER resizes,
    squeezes or shifts the board.
R2  Panels are RIGHT-EDGE DRAWERS (Drawer component). No bottom sheets.
    Exceptions: the card hand is a BOTTOM STRIP (168px tall); Occupy is a
    CENTRED BLOCKING MODAL.
R3  The board has two zoom states: OVERVIEW (whole board visible) and
    TACTICAL (zoomed, every territory has a 48px touch target). The ZoomChip
    always shows which. A [⊕] button bottom-right switches between them.
    Selecting a territory auto-zooms to TACTICAL.

SCREENS (each at both sizes)
S-07 Claim         board + Banner "Tap an unowned territory to claim it." +
                   ActionCluster. Show which seat is claiming (SeatRail).
S-08 Main board    TWO frames: "overview" and "tactical + drawer".
                   Overview: TopBar "r7 · ATTACK · Seat 0 ●", chip OVERVIEW,
                   SeatRail on the right, ActionCluster [Attack][End phase ▸].
                   Tactical: chip TACTICAL; Drawer open on the right showing
                   "KAMCHATKA → ALASKA", "12 armies vs 3", dice stepper 1–3,
                   "win chance 66 %" with a bar, button "ATTACK". The board
                   behind has the SAME scale and centre as overview.
S-09 Draft         Drawer: "Armies to place: 14" with a breakdown (territories
                   9 · Asia bonus 7 · card set −2 → shown as lines that add up
                   to 14), and placement Steppers per selected territory.
S-10 Cards         BOTTOM STRIP 168px. "YOUR HAND 3 · next set 12 · 1 valid
                   set". Three cards 88×124 (Infantry, Cavalry, Artillery).
                   Tap-to-select hint. Button "TRADE" to the RIGHT of the
                   cards. A hand never wraps onto a second row (max 5).
S-11 Attack        Drawer with the DICE TRAY, three stacked regions:
                   1 ROLLED   attacker dice row then defender dice row
                   2 COMPARED both rows sorted high→low, paired, connected
                   3 OUTCOME  "Attacker −1 army   Defender −1 army"
                   A tie reads "TIE → defender holds" (connector in danger
                   red). Unpaired attacker dice are greyed, labelled
                   "discarded". Do NOT show a dice-sides setting anywhere.
S-14 Occupy        CENTRED BLOCKING MODAL. No close, no X, no back arrow.
                   Stepper 3–11. Text "You rolled 3 dice, so at least 3
                   armies must move in."  One button "Move armies".
S-15 Fortify       Drawer: "Move armies once per turn", from → to, Stepper,
                   buttons "Fortify" and "Skip".
S-18 Game over     TitlePlaque "YOU WIN" (variant "MARS WINS"), standings list
                   (ListRows with rank, name, territories, armies), button
                   "Back to menu".
S-21 Waiting       NOT a full screen. The normal board with a Banner:
                   "Waiting for Abdullah…" (human) or "Mars is thinking…" (AI).
                   Board stays visible; controls are disabled (greyed).
S-22 Connection lost
                   Normal board with a warning Banner: "Connection lost —
                   reconnecting…" and a small "Retry now" pill. A second
                   frame: "Reconnected" (green dot, banner fades).

CHECK
[ ] S-08 exists in BOTH overview and tactical; the board is not narrower in
    tactical
[ ] every panel is a right drawer, except the card strip and the Occupy modal
[ ] Occupy has no dismissal control
[ ] the card hand is a single row
[ ] other players' cards are never shown face-up (backs + a count only)
[ ] a tie is written out in words
[ ] white board text has the 2px dark outline
[ ] ownership uses colour AND pattern
[ ] S-21 and S-22 keep the board visible
```

---

## STAGE 3 — Extensions and settings `[P2]`

Paste HEADER, then:

```text
TASK
Build the screens for the Air Force and Naval Force extensions and the
Settings screen. Same rules as Stage 2 (right drawers, full-bleed board,
48×48 targets). These are designed now and built later.

S-12 Air Force     Drawer, wide. Title "AIR FORCE". Targets as ListRows with
                   the distance ("Ukraine · 3 steps", "Siam · 5 steps"). A
                   range indicator "up to 5". One attack per turn: text
                   "1 air attack per turn" and a disabled state after use.
S-13 Naval Force   Drawer. "NAVAL FORCE". The sea route being crossed (from
                   Brazil to West Africa), armies Stepper, buttons "Sail" and
                   "Cancel". Show the sea route on the board as a 3px DOTTED
                   white line with anchor glyphs at both ends.
S-16 Capabilities  Drawer, wide. Rows: Infantry — held · Cavalry — held ·
                   Artillery — not held · Air Force — held (from a card) ·
                   Naval Force — held (Brazil). NO "Wild" row.
S-10b Cards (extension variant)
                   The bottom strip again, with Air Force and Naval Force
                   card symbols alongside Infantry, Cavalry, Artillery and one
                   Wild card.
S-20 Settings      Rows (PanelRow on #333333): Music slider, Effects slider,
                   Animation speed, Reduced motion toggle, Text size.
                   Sliders have a large glossy round knob carrying a line-art
                   icon (speaker for volume). NO game-rule section, NO dice
                   or attack-range controls, NO theme switch.

EDGE LINES (show all three on one board frame so they are clearly different)
  land border     invisible
  across-water    2px dashed white
  sea route       3px dotted white with round dots and anchor glyphs

CHECK
[ ] sea routes are dotted, across-water borders are dashed, land is invisible
[ ] the capability panel has exactly five rows and no Wild row
[ ] Settings has no rule or dice controls
[ ] Air Force shows distance in steps and the one-per-turn limit
```

---

## AFTER THE STAGES — quick fix-up pass (30 minutes)

- Rename every frame `S-xx Name · 915` / `· 800`.
- Add a cover page listing every screen and its tier tag.
- Set up prototype links: S-01 → S-02a → S-02 → S-03 → S-04 / S-04b → S-06 → S-07 → S-08 → S-09 → S-10 → S-11 → S-14 → S-15 → S-18. That is the clickable flow to show at the meeting.
- Export the colour and text styles to the team (one list), so Unity, Godot and Flutter all use identical values.
- Put a screenshot of every screen in `design/screens/` in the repo.

## Why this version differs from the old one

| Old (`design/11`) | This version | Reason |
|---|---|---|
| iPhone sizes 844×390 / 932×430 | Android 915×412 / 800×360 + safe areas | All three clients are Android |
| 3 mode cards (Pass & Play, vs AI, Room) | One "Create room" screen | One mode: a room with humans and AI |
| Dice faces and attack-range steppers in setup and Settings | Not shown anywhere | Configurable in the engine, hidden in the UI |
| Sea-route count stepper (S-05) | Removed | Sea routes are a fixed list |
| Guest link on sign-in | Removed | Login is required |
| Hand-over screen (S-17) | "Waiting for…" banner (S-21) | Remote players, not one shared device |
| — | **Connect to host** (S-02a), **Join room** (S-04b), **Connection lost** (S-22) | The demo runs on a local network |
| Replay viewer (S-19) | Not built | Deferred |
| One 24 KB prompt | HEADER + 4 small stages | More reliable generation |
