# Order & Conquest

**Order & Conquest** is a digital territory-conquest game built on classic RISK rules, designed as a comprehensive software engineering project. It introduces three controlled extensions to the classic gameplay: an **Air Force** capability that attacks beyond adjacency, a **Naval Force** capability operating over sea routes, and a per-territory **capability profile** system.

## 🎯 Project Overview

This project tackles the common pitfalls of digital board game implementations (e.g., duplicated logic across platforms, unreliable match persistence, tied-down AI) by adopting a strict architectural separation:

- **One Authoritative Rules Engine (Server):** A pure C# library (`OrderAndConquest.Engine`) without any I/O or framework dependencies. It handles all game logic, combat resolution, random number generation, and state transitions deterministically.
- **Three Thin Clients:** The game features clients built in **Unity**, **Godot**, and **Flutter + Flame**. These clients contain *no rules logic whatsoever*. They communicate with the server to receive the current state and a list of legal actions (`GET /legal`), simply rendering what the server dictates.
- **Advanced AI & Optional RL:** Includes heuristic AI opponents (like MarsBot) and an optional setup for training a reinforcement-learning agent using self-play.

## 🏗️ Structure

- **`docs/`**: Comprehensive project documentation, including requirement definitions, system design, database design, and implementation plans (chapters 00–14).
- **`appendices/`**: Reference material — API contract (A), database schema (B), map specification (C), capability decision table (D), engine pseudocode (E), the 119 test cases (F), configuration tables (G), and additional diagrams and screenshots (H).
- **`design/`**: The UI/UX design pack (00–09) — design system, screen inventory and flows, map, dice, card, interaction, accessibility, wireframes, and the **art direction sampled from reference frames** in `design/References/`. Written so screen design can start without re-deriving anything from the documentation.
- **`diagrams.html`**: **Zoomable viewer for all 34 diagrams** in the package. Self-contained — open it in any browser, no network needed. Click a diagram to open it, scroll to zoom, drag to pan.
- **`server/`**: The ASP.NET Core backend containing the C# rules engine, REST + SignalR APIs, and PostgreSQL persistence logic.
- **`clients/`**: Subdirectories for the different thin clients (Unity, Godot, Flutter).
- **`shared/`**: Shared contracts and OpenAPI specifications, plus `rules.json` (every tunable number) and `maps/world_classic.json`.
- **`rl/`**: Python/PyTorch environment for reinforcement learning training and ONNX exports.
- **`assets/`**: Shared static assets like 2D maps, icons, and audio.

## 🚀 Key Features

1. **Deterministic Rules Engine:** Every action sequence produces a predictable state, making match resumption, replayability, and testing seamless.
2. **Controlled Extensions:** Air Force and Naval Force capabilities are elegantly integrated into the classic map graph without requiring an entirely new combat system.
3. **Procedural Map Generation:** Alongside a classic 42-territory board, the game can generate balanced procedural maps using clustering algorithms.
4. **Multiple AI Personalities:** Different bot profiles ranging from Passive and Chaotic to a well-tuned heuristic bot.
5. **Configurable Combat Parameters:** The dice face count (`diceSides`, default 6, settable 2–20) and the land attack range (`attackRange`, default 1 — which *is* adjacency, settable 1–10) are both match-level settings rather than hard-coded constants. At their defaults the game is exactly classic RISK; both are frozen into the match at creation so a configuration edit can never alter a match in progress.

## 🛠️ Setup & Development

*(Detailed instructions for running the server, database, and specific clients will be added here as the implementation progresses. See `docs/08-implementation-plan.md` for the development roadmap.)*

## 📋 Open Scope Decision

[`PLATFORM-SCOPE-PROPOSAL.md`](PLATFORM-SCOPE-PROPOSAL.md) is a formal request to the FYP committee to amend locked constraint **C-04** (*"Three clients must all ship… None may be dropped"*) so that the Flutter mobile client is **designed in full but not implemented**. The case is cost, not capability: the mobile client would work — in landscape at the tactical zoom scale of 0.537 an iPhone 15 still shows 98% of the board width — but it is a second interaction model, restructuring 12 of the 20 screens, and Room mode has since made Phase 6 mandatory. Awaiting decision.

## 📝 Git & Version Control

- **Git LFS** is configured for handling large binaries (images, 3D models, audio, machine learning models like `.onnx`, etc.). Make sure to run `git lfs install` on your local machine before working with assets.
- A standard **.gitignore** is set up covering Unity, Godot, Flutter, .NET, and Python environments.
