# 12 — References

> **Sourcing note (prompt §39).** Every entry below records what the source was actually used for. Where a
> source was consulted only in part, or could not be retrieved in full, that is stated in the entry rather
> than left for a reader to assume. Nothing is listed here that is not cited somewhere in this package.

## 12.1 Citation conventions used in this package

| Convention | Rule |
|---|---|
| **Style** | Author–year, inline, in parentheses or in running prose — e.g. "Carr (2020) reports…". No numbered markers |
| **Entries with no personal author** | Cited by publisher or site name — "(Wikipedia; UltraBoardGames)" |
| **Project design decisions** | **Not cited.** They carry a `D-nn` register identifier instead (`00-decisions-and-assumptions.md`) |
| **Measured findings** | **Not cited.** They name the data file and the computation, so a reader can recompute them (§7.8, §11.3) |
| **Secondary citations** | A work cited *inside* a source, and not read directly, is marked "cited within" and grouped in §12.6 |

The third and fourth rows are the ones that matter. A design decision dressed as a citation is the most
common way a document acquires false authority, and §2's authority order only works if the reader can see
at a glance which tier a statement came from.

## 12.2 Project source documents

These are the supplied inputs. They are **unpublished internal documents**, they sit at tier 2 of the
authority order (`00-decisions-and-assumptions.md` §A), and they are the reason most of this package needed
no external research at all.

**Order & Conquest design documents.** `docs/00-research.md`, `docs/01-architecture.md`,
`docs/02-map-system.md`, `docs/03-ai-and-rl.md`, `docs/04-database.md`. Project working documents,
unpublished. Located one directory above this package, at `../docs/`.

> *Used for:* the locked feature set, the classic board data, the capability model, the MARS coefficient
> table, the RL curriculum, the six-table schema shape, and the eight-entry source table that §12.3–§12.5
> below are drawn from. These are the primary authority for everything not fixed by the master prompt
> itself.

**Ahmad, H., Akbar, Z., Saqib, M., Ali, M. and Urooj, S. (2022).** *Game: Conquest (Risk).* Report
submitted in partial fulfilment of the requirements for the degree of Bachelor of Science in Computer
Science. Barani Institute of Information Technology, PMAS Arid Agriculture University Rawalpindi. Spring
2022. Supplied as `Risk Conquest -2022text.pdf`.

> *Used for:* the use-case specification template adopted in §4.3, the three AI personalities (Passive,
> Chaotic, Aggressive) adopted in §5.6, the screen inventory that §5.3 extends, the phase naming, and the
> pseudocode conventions of appendix E.
>
> *Authority:* **tier 3 — historical reference only** (§2 of the master prompt). Where it conflicts with
> this specification, this specification wins, and each such conflict is recorded rather than blended:
> D-06 (the 38-vs-30 starting-army contradiction), D-23 (plaintext passwords), D-25 (chat), and the four
> rows of §2.4's "not carried forward" table.
>
> Student registration numbers appear on the report's title page. They are omitted here because the
> supplied text layer does not transcribe them reliably, and an approximate identifier is worse than none.

## 12.3 Published works

**Johansson, S. J. and Olsson, F. (2006).** *Using Multi-Agent System Technologies in Risk Bots.* School of
Engineering, Blekinge Institute of Technology, Ronneby, Sweden; and Progressive Media ApS, Aalborg,
Denmark. Published under the copyright of the American Association for Artificial Intelligence, 2006.
Supplied as `Research/Using_Multi-Agent_System_Technology_in_Risk_Bots.pdf`.

> *Used for:* the branching-factor figure of ≈3.3 × 10²⁴ opening positions (§2.5); the territory evaluation
> function and its tuned coefficients, implemented directly as `MarsBot` (§5.6, appendix G); the `W_p`
> minimum-win-probability parameter used as the project's difficulty dial (§5.6, §8.8); the per-continent
> static values quoted in §2.3; and the 100-round match cap (§7.12, D-19).
>
> *Reported result, as stated by the authors:* MARS placed first or second in 507 of 792 matches, out of
> six participants, in a tournament of 13 bots. This project makes no claim about that figure beyond
> reporting it.
>
> *Bibliographic limit:* the supplied PDF's page footers read 42–47, so the paper appears in a paginated
> proceedings, but the volume and the full citation string are not present in the file. The project source
> table records it as AAAI 2006. **The team should complete this citation from the published record before
> submission** rather than inferring the remainder.

**Carr, J. (2020).** *Using Graph Convolutional Networks and TD(λ) to play the game of Risk.* arXiv preprint
arXiv:2009.06355. <https://arxiv.org/abs/2009.06355>

> *Used for:* the single clearly positive published result for machine-learned RISK play — a 35% win rate
> against the five strongest Lux Delux AIs, against a 16.7% uniform-chance baseline at six players (§2.6);
> and the architectural hint that the network is most effective as a **position evaluator inside a search**
> rather than as a policy selecting moves directly, which is why §5.6 treats the value head as
> load-bearing.
>
> ⚠️ **Abstract only. The full text was not retrievable during this project's research phase.** Layer
> sizes, search depth and training budget are therefore *not* taken from this paper; the network described
> in §5.6 and §8.9 is informed by the reported approach, not reproduced from it. §2.7 states explicitly
> that no claim is made to replicate the 35% result.

## 12.4 Rule references for classic RISK

The numeric rule baseline — starting armies, the reinforcement formula, continent bonuses, the tie rule,
card sets, trade escalation, the two-player neutral variant — is taken from published rule descriptions
rather than from the physical rulebook. Two reasons, and both are deliberate:

1. §39 forbids copying long passages from copyrighted sources. Only **parameter values** are taken, and
   they are recorded as data in [`shared/rules.json`](../shared/rules.json), not reproduced as rules text.
2. Published descriptions differ between editions. Where they differ, the choice is recorded as a decision
   (D-06 starting armies, D-15 card escalation, D-26 mission cards) rather than presented as *the* rule.

**Wikipedia.** *Risk (game).* <https://en.wikipedia.org/wiki/Risk_(game)>

> *Used for:* board structure (42 territories, 6 continents), continent bonus values, the
> defender-wins-ties rule, and the two-player neutral-army variant adopted as D-07.

**UltraBoardGames.** *Risk Game Rules.* <https://www.ultraboardgames.com/risk/game-rules.php>

> *Used for:* the starting-army table (35/30/25/20 for 3/4/5/6 players), the `max(3, ⌊t/3⌋)` reinforcement
> formula, territory-card rules, trade-in escalation anchors, and the fortification rule.

## 12.5 Technical sources

**Gambetta, G.** *Client-Server Game Architecture.*
<https://www.gabrielgambetta.com/client-server-game-architecture.html>

> *Used for:* the authoritative-server model, the intents-not-state principle, and — decisively for this
> project's scope — the explicit statement that the naive authoritative model is *"fine for slow turn based
> games"*. That one sentence is why §5.1 contains no client-side prediction, rollback or interpolation
> layer, and it removed an entire subsystem from the plan.

**Mapbox.** *Delaunator guide.* <https://mapbox.github.io/delaunator/>

> *Used for:* Delaunay/Voronoi duality, deriving territory adjacency from half-edges in a single pass
> (§8.10), and the convex-hull edge cases a naive implementation gets wrong. The C# port `DelaunatorSharp`
> is used in the implementation; this guide documents the algorithm and data layout it ports.

**Patel, A. (Red Blob Games).** *Polygon map generation (mapgen2).*
<https://www.redblobgames.com/maps/mapgen2/>

> *Used for:* generator design goals — that a procedural map should be validated against playability
> constraints rather than merely generated (§8.10, V-01…V-12).
>
> ⚠️ **The detailed algorithm write-up was not retrievable** (TLS and archive access both failed). Only
> the landing page's stated design goals were available. The nine-step pipeline of §8.10 is this project's
> own composition of Bridson sampling, Lloyd relaxation and Delaunay adjacency — it is not that article's
> pipeline, and is not presented as such.

## 12.6 Works cited within the sources, not consulted directly

Marked so that no reader mistakes a second-hand citation for a source this project read. Each is cited in
this package only through the source that cites it.

| Work | Cited within | What this package takes from it |
|---|---|---|
| **Keppler, D. and Choi, E. (2000).** *An intelligent agent for risk.* Technical Report CS 473, Computer Science Department, Cornell University | Johansson & Olsson (2006) | The single most important negative result for this project: a TD-learning RISK agent trained *"without significant success."* It is the reason RL is optional and gated here rather than central (§2.6, O8) |
| **SillySoft (2005).** *Lux v4.3.* <https://sillysoft.net/> | Johansson & Olsson (2006); and the opposition Carr (2020) measures against | Identification of the Lux Delux bots that both the MARS tournament and Carr's 35% figure are measured against. ⚠️ The Lux bot API documentation was **not retrievable** (404) |
| **Lemke, K. (1999).** *Risk board game dice odds.* | Johansson & Olsson (2006) | Corroboration only. The five combat probabilities in §7.5 are stated as exact fractions computed from first principles, not quoted from this source |
| **Lyne, O., Atkinson, L., George, P. and Woods, D. (2005).** *Risk — frequently asked questions v5.61.* | Johansson & Olsson (2006) | Corroboration of rule details also available from §12.4 |

Both URLs above were recorded in the MARS paper as last visited in January 2006 and are cited here as the
paper cites them, not as pages this project retrieved.

The remainder of the MARS paper's reference list — works on multi-agent systems, Diplomacy, chess programs
and alpha-beta pruning — is not reproduced. This project draws nothing from those works, and listing them
would inflate this chapter without adding a single supported statement.

## 12.7 Algorithm and method references

Named so that a reader can identify the methods this package specifies by name. **These were not retrieved
or read during this project**; they are given from established engineering knowledge, which is tier 4 of the
authority order. Venue names are given without volume or page numbers, deliberately — inventing
bibliographic precision would be the same defect as inventing a result.

> **Before submission, complete and verify each entry below against the published record.** They are
> identification, not verified citation, and this note should be deleted only once that has been done.

| Method | Reference as understood | Where this package uses it |
|---|---|---|
| Poisson-disc sampling | **Bridson, R. (2007).** *Fast Poisson Disk Sampling in Arbitrary Dimensions.* ACM SIGGRAPH sketches | Step 1 of map generation (§8.10) |
| Centroidal relaxation | **Lloyd, S. P. (1982).** *Least squares quantization in PCM.* IEEE Transactions on Information Theory | Step 2 of map generation (§8.10) |
| Graph convolutional networks | **Kipf, T. N. and Welling, M. (2017).** *Semi-Supervised Classification with Graph Convolutional Networks.* arXiv:1609.02907 | The state encoder, chosen because its parameter count is independent of territory count (§5.6, §8.9) |
| Proximal Policy Optimization | **Schulman, J., Wolski, F., Dhariwal, P., Radford, A. and Klimov, O. (2017).** *Proximal Policy Optimization Algorithms.* arXiv:1707.06347 | The training algorithm (§8.9, FR-79) |
| Temporal-difference learning | **Sutton, R. S. (1988).** *Learning to Predict by the Methods of Temporal Differences.* Machine Learning | The method used by Carr (2020) and by Keppler & Choi (2000); **not** used by this project, which uses PPO |
| Argon2id password hashing | **RFC 9106.** *Argon2 Memory-Hard Function for Password Hashing and Proof-of-Work Applications.* IETF, 2021 | Credential storage (§5.9, D-23) |

Sutton (1988) is listed although this project does not use TD learning, because §2.6 describes two
published RISK results that do, and a reader tracing "TD(λ)" needs the pointer.

## 12.8 Software platforms and libraries

Listed by name and project homepage only. **No version numbers appear here** — versions are pinned in the
repository, which is the only place they can be kept true (§8.1).

| Component | Project |
|---|---|
| .NET and ASP.NET Core | <https://dotnet.microsoft.com/> |
| PostgreSQL | <https://www.postgresql.org/> |
| Dapper | <https://github.com/DapperLib/Dapper> |
| Unity | <https://unity.com/> |
| Godot Engine | <https://godotengine.org/> |
| Flutter | <https://flutter.dev/> |
| Flame | <https://flame-engine.org/> |
| PyTorch | <https://pytorch.org/> |
| ONNX | <https://onnx.ai/> |

`DelaunatorSharp` is a C# port of Mapbox's Delaunator (§12.5). `signalr_netcore` is the third-party Dart
SignalR client whose suitability is the open question of §8.6; neither is given a URL here, because both
are decisions a developer should make against the package registry at the time of implementation rather
than against a link in a document.

## 12.9 Retrieval gaps

Carried forward verbatim from the research record (`../docs/00-research.md`) rather than quietly dropped,
because a gap that disappears from the documentation reappears as an unsupported claim later:

> **Retrieval gaps, restated so they are not forgotten:** Carr full text (blocked), Amit Patel's
> polygon-map-generation article (TLS/archive blocked), Lux Delux bot API docs (404). Web search was
> unavailable in this session; all of the above was fetched by direct URL.

What each gap cost, and what was done instead:

| Gap | Consequence | Mitigation |
|---|---|---|
| Carr (2020) full text | No layer sizes, search depth or training budget from the one successful published result | §8.9 specifies its own network (3 GCN layers, hidden 128) as an **assumption**, and §2.6 states the gap in place |
| Red Blob Games algorithm write-up | No reference pipeline for polygon map generation | §8.10's nine steps are composed from the individually documented algorithms of §12.7 |
| Lux Delux bot API | No reference for an established RISK bot interface | `IAgent.ChooseAction` is designed from this project's own `Legal` list (§5.6), which is a better fit anyway |

None of the three gaps blocks implementation. All three are recorded because each one is a place where a
reader might otherwise assume a design was derived from a source when it was in fact decided here.

## 12.10 What is deliberately not cited

| Not cited | Why |
|---|---|
| The physical RISK rulebook | Copyrighted. §39 forbids reproducing long passages; §12.4's parameter values are sufficient and are stored as data |
| Trademarks and brand names | *Risk* is a trademark of its publisher. This project is an independent implementation, cites the rules as published descriptions, and makes no claim of affiliation |
| Any source for the three extensions | The capability system, Air Force and Naval Force are **this project's design**, locked by the master prompt. They have no external source, and inventing one would be the exact fabrication §39 prohibits |
| Any source for a performance or win-rate figure | There are none in this package. §10.3 and §10.4 are templates (§11.1) |

The third row is worth stating plainly. The capability mapping in appendix D, the range-5 limit, the
one-attack-per-turn constraint and the sea-route generation rule are **decisions**, recorded as `D-nn`
entries and open questions `O-01`…`O-06`. None of them is a finding about real air or naval forces, and
none of them should ever acquire a citation.

---

**Previous:** [11 — Conclusion and Future Work](11-conclusion-and-future-work.md) · **Next:**
[13 — Traceability Matrix](13-traceability-matrix.md)
