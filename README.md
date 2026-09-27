# Order & Conquest

**Order & Conquest** is a digital territory-conquest game built on classic RISK rules, designed as a comprehensive software engineering project. It introduces three controlled extensions to the classic gameplay: an **Air Force** capability that attacks beyond adjacency, a **Naval Force** capability operating over sea routes, and a per-territory **capability profile** system.

## 🎯 Project Overview

This project tackles the common pitfalls of digital board game implementations (e.g., duplicated logic across platforms, unreliable match persistence, tied-down AI) by adopting a strict architectural separation:

- **One Authoritative Rules Engine (Server):** A pure C# library (`OrderAndConquest.Engine`) without any I/O or framework dependencies. It handles all game logic, combat resolution, random number generation, and state transitions deterministically.
- **Three Thin Clients:** The game features clients built in **Unity**, **Godot**, and **Flutter + Flame**. These clients contain *no rules logic whatsoever*. They communicate with the server to receive the current state and a list of legal actions (`GET /legal`), simply rendering what the server dictates.
- **Advanced AI & Optional RL:** Includes heuristic AI opponents (like MarsBot) and an optional setup for training a reinforcement-learning agent using self-play.

## 🏗️ Structure

- **`docs/`**: Comprehensive project documentation, including requirement definitions, system design, database design, and implementation plans.
- **`server/`**: The ASP.NET Core backend containing the C# rules engine, REST + SignalR APIs, and PostgreSQL persistence logic.
- **`clients/`**: Subdirectories for the different thin clients (Unity, Godot, Flutter).
- **`shared/`**: Shared contracts and OpenAPI specifications.
- **`rl/`**: Python/PyTorch environment for reinforcement learning training and ONNX exports.
- **`assets/`**: Shared static assets like 2D maps, icons, and audio.

## 🚀 Key Features

1. **Deterministic Rules Engine:** Every action sequence produces a predictable state, making match resumption, replayability, and testing seamless.
2. **Controlled Extensions:** Air Force and Naval Force capabilities are elegantly integrated into the classic map graph without requiring an entirely new combat system.
3. **Procedural Map Generation:** Alongside a classic 42-territory board, the game can generate balanced procedural maps using clustering algorithms.
4. **Multiple AI Personalities:** Different bot profiles ranging from Passive and Chaotic to a well-tuned heuristic bot.

## 🛠️ Setup & Development

*(Detailed instructions for running the server, database, and specific clients will be added here as the implementation progresses. See `docs/08-implementation-plan.md` for the development roadmap.)*

## 📝 Git & Version Control

- **Git LFS** is configured for handling large binaries (images, 3D models, audio, machine learning models like `.onnx`, etc.). Make sure to run `git lfs install` on your local machine before working with assets.
- A standard **.gitignore** is set up covering Unity, Godot, Flutter, .NET, and Python environments.
