---
name: "brain-mesh"
description: "Map of a brain mesh: a Zettelkasten vault of interlinked markdown cards that Claude builds from science papers for browsing in Obsidian. Card families, ids, grades, links and navigation; the card formats are in FORMATS.md beside it. Read first for any brain mesh, second brain or research vault task, and before any other brain-mesh-* skill."
---

# Brain mesh

**Every time a vault is opened, by any agent, read `brain-mesh-access` first and follow it**: sync with GitHub before working and after, navigate and change the brain only through the tooling, and leave nothing uncommitted. A vault's own `CLAUDE.md` says the same to an agent that starts inside it.

A brain mesh is a second brain for one research topic. Claude builds it from papers and the user's own results; the user reads and steers it in Obsidian. Its job is to support new science: proposing experiments, designing them and judging their outcomes. Nobody knows in advance which detail of which paper will matter, so the vault is built to lose nothing and to keep every statement traceable to the place on the page it came from.

This document is the map. **Before writing or changing any card, read `FORMATS.md`** beside it (`skills/brain-mesh/FORMATS.md`; in a vault `.brain-mesh/skills/brain-mesh/FORMATS.md`): the parts of a card, each family's sections and Codes, the evidence types, the link keys, citations, priority and the PDF rules. A session that only reads the brain does not need it.

## The ideas that hold it together

1. **Cards.** Every note is one card with a permanent id and a meaningful file name. Evidence cards hold one statement each, so they can be cited, checked and linked individually.
2. **Human first, codes second.** Each card opens with the science in plain prose that a person can read on its own. A `## Codes` section underneath repeats it in structured form: the id, typed links, values, conditions and provenance. People read the top; Claude and the tooling read Codes. The two must always agree.
3. **Concept cards are the hubs.** Every card links the concepts it involves. Concept cards are the one exception to one statement per card: they are living articles that grow with every paper, and they are the main surface the user browses.
4. **Links are typed, reasoned and two-way.** A link names the relation and, across papers, says why. It is written once; the tooling mirrors it onto the target card.
5. **Layers cite only downward.** Sources, then evidence, then findings, tensions and gaps, then hypotheses and experiments, then the discovery cards (theories, analogies, seeds). This keeps methods, results, authors' claims, the brain's own conclusions and its speculation separate.
6. **Importance is never judged at extraction.** Everything of each type is carded. What matters emerges later from what gets linked and used.
7. **The source PDF is the ground truth.** Every evidence card points to an exact place on the page, and every other card reaches the PDF through the evidence it cites. The original file is never changed and its checksum is recorded. The tooling keeps a marked copy in which each card appears as a highlight on the page.

## Where this lives

These instructions and the tooling live in the GitHub repository `tcpearce/brain-mesh`: the documents under `skills/`, the tooling at `tools/mesh.py`, a demo vault and tests. The small `brain-mesh` skill synced to Claude is only a loader that fetches the current version. Wherever a document names a `brain-mesh-...` skill, read `skills/<that name>/SKILL.md` in the repository; where it names `brain-mesh` FORMATS.md, read `skills/brain-mesh/FORMATS.md`. To change anything, change it in the repository (see its README); never patch a copy.

## Which document does what

| Task | Document |
|---|---|
| **Every session: syncing, navigating, answering, adding your own material, editing and deleting cards** | `brain-mesh-access` |
| **Writing or changing any card:** its parts, sections, Codes and links | `brain-mesh` FORMATS.md |
| Start a vault, install or upgrade its tooling, open it in Obsidian | `brain-mesh-setup` |
| Add a paper or an own result; re-read existing papers for a new question | `brain-mesh-add-paper` |
| Add many papers at once, with agents working in parallel | `brain-mesh-batch` |
| Look for every concept across some or all sources and card each new fact with the works the paper cites for it; backfill after a new concept | `brain-mesh-concept-scan` |
| Find knowledge gaps, hunt papers that fill them, maintain the research-gaps document | `brain-mesh-gaps` |
| Hypotheses, experiment design, registered predictions, judging outcomes | `brain-mesh-experiment` |
| Mine the brain for new hypotheses and links with the user; theory, analogy and seed cards; recheck them as sources arrive | `brain-mesh-discover` |
| Write from the brain (a literature review, a background or related-work section) or audit a draft against it, claim by claim | `brain-mesh-write` |
| Dated reports for deciding what to do next: frontier map, contradiction dossier, theory scorecard, causal map, robustness audit, methods and data landscape, novelty check, what-changed digest | `brain-mesh-report` |
| Health checks, merges, corrections, retractions, periodic audits | `brain-mesh-housekeeping` |

## Finding the vault

A vault is a folder containing `MESH.json`. Look, in order, in: a path the user names; a folder on their computer or a repository connected to this session; an uploaded archive. If there is none, use `brain-mesh-setup`.

The vault must outlive the session. If it lives in a connected folder or a repository, work there. If this session's files are temporary, say so at the start and hand back an archive of the whole vault at the end; otherwise the work is lost.

Keep the vault's tooling current: from the repository clone run `python3 tools/mesh.py upgrade <vault folder>`, which copies the tooling and these instructions into the vault, then `build` in the vault. One writer at a time: if the user may have edited cards in Obsidian since the last session, run `build` before anything else so the index matches the files.

## Layout

```
MAP.md  CLAUDE.md  MESH.json  SCHEMA.md   home note; agent instructions; marker file; cheat sheet
concepts/<slug>.md                         concept cards (the hubs)
sources/P012-<first author>-<year>-<words>/  one folder per source:
  P012-<slug>.md  P012-007-<slug>.md  P012-claims.md     source card, evidence cards, claims card
  P012.pdf  P012_marked.pdf  P012_text.md                the original (never changed), the marked copy, the anchored text
  P012_SI*, P012_correction*, P012-T2.csv, P012-F5c.png/.csv   supplementary material, corrections, tables, figure panels and their values
  P012_refs.md  P012_refs.bib  P012_scan.md  P012_concepts.md  P012_progress.md   reference list, concept scan, proposals, an agent's notes
references/R0042-<slug>.md  library.bib    the works the sources cite
findings/K###  tensions/X###  contradictions/V###  gaps/G###   the brain's own conclusions and unknowns
hypotheses/H###  experiments/E###          the workbench
theories/T###  analogies/A###  seeds/S###  discovery cards
data-sets/D###  code/C###                  what the studies use
reports/<date>-<kind>.md                   dated snapshots, never sources
ledger/                                    changelog, reading queue, contradictions register, checksums, removed ids, rejected signals and concepts
index/                                     generated tables: cards.tsv, edges.tsv, coverage.tsv, priority.tsv, marks.json
tools/mesh.py  .brain-mesh/                the tooling (a copy) and an offline copy of these instructions
notes/                                     the user's own notes, ignored by the tooling
```

## Ids and names

- The id is the code at the start of the file name: `P012` (a source), `P012-007` (its seventh evidence card), `P012-claims`, `K003`, `X001`, `V001`, `G004`, `H002`, `E001`, `T001`, `A001`, `S001`, `D003`, `C002`, `R0042`. A concept card's id is its slug: `binding-capacity`.
- File name = id plus a short meaningful slug, frozen when the card is created. Ids are never changed or reused; a wrong or merged card is retired (`- retired:: <why>`), never deleted.
- Get the next free id from `python3 tools/mesh.py id <kind>`, or `id P012` for that source's next card. In a link a bare id is enough (`[[P012-007|readable text]]`); `build` expands it.

## The card families

| Family | Id | What it holds |
|---|---|---|
| Concept | slug | A hub: a short living article on one shared term (`entity`, `variable`, `count`, `technique` or `concept`), with a generated list of every card that uses it |
| Source | `P012` | One per paper, preprint, thesis, report, data set or own result: citation, what they did and found, weaknesses, the study profile, and coverage lines saying what was not read in full |
| Evidence | `P012-007` | One statement from one source, anchored to its place on the page: a `method`, `observation`, `model`, `claim`, `assumption`, `limitation`, `question`, `definition`, `cited` background or `oddity` |
| Claims card | `P012-claims` | The paper's main claim and up to five sub-claims, in its authors' voice. Never a finding |
| Finding | `K` | The brain's own proposition with its scope, built from every source that bears on it, graded |
| Tension | `X` | A disagreement worked up into a question, with its sides and possible explanations |
| Contradiction | `V` | Two or more cards that cannot both hold as stated: the contradictions register |
| Gap | `G` | Something the brain does not know, on a ladder from "not in the brain" to a research gap |
| Hypothesis, experiment | `H`, `E` | The workbench: proposed explanations, and designs with registered predictions |
| Theory, analogy, seed | `T`, `A`, `S` | Discovery cards: rival accounts, mappings between systems, ideas the user judged worth a card |
| Data set, code | `D`, `C` | What the studies use, with access |
| Reference | `R0042` | A work the sources cite, shared by every source that cites it |

Every card has properties, a title stating its point as a sentence, plain prose, then `## Codes` (`- key:: value` lines), then a generated `## Linked from`.

## Reading the grades

- **Findings:** `single-source`, `tentative`, `probable`, `established`, or `contested` (a tension says why). Graded on independent sources, directness and replication; sources that share data or authors count once (`independence K001`).
- **Evidence status:** `measured`, `derived` (computed from measurements), `reported` (a description), `inferred` (the authors' interpretation), `asserted` (stated without evidence here), `speculated`, `cited` (taken from other work).
- **Study design** (`design::` on a source card): `experiment`, `observational`, `reanalysis`, `computational-model`, `simulation`, `theory`, `review`, `method`, `case`. It sets what the source's results can establish.
- **Relation basis** (on `affects::` lines): `tested`, `correlational`, `proposed`, `inferred`. Causal wording ("causes", "raises", "lowers") only for `tested`; "is associated with" or "predicts" for `correlational`; "is proposed to" for `proposed`; "the evidence suggests" for `inferred`.
- **Coverage** (on a source card): what was read in full, skimmed or not read. "Not in the brain" is never "not in the paper", and never "not known".

## Priority

Every card is `high`, `normal` (the default) or `low`. Priority is the user's statement of interest: attention, never evidence. Only the user sets it (`priority <id> <level> "<why>"`); it spreads one link as *elevated*; `MAP.md` opens with the **Focus**. Details in FORMATS.md.

## Links

Links live in Codes as `- relation:: [[target]] — reason`; a link to another source's card must give the reason. Each is written once, on the newer card, and `build` mirrors it onto the target under `## Linked from`, so every link can be followed both ways. Layers cite only downward. The keys are in FORMATS.md, and `mesh.py schema` prints them.

## The PDF as ground truth

Every evidence card's **open page** link lands on its highlight in the marked copy of the PDF. The original and the supplementary files are sealed with checksums and never changed. For anything a decision will rest on, read the passage on the page.

## Navigating and answering

Work from the top down, read only what the question needs, and keep the context small (`brain-mesh-access`, section 2):

1. **`python3 tools/mesh.py ask "<the question>"`** first. Within about 2,500 tokens it returns the brain's conclusions on the question with their grades, the hub facts, the relations with their basis, the most relevant evidence cards and what was not read in full, each with an id to open.
2. `show <id>` for a card, its source paragraph and what links to it; `find <words>` to search, most relevant first; `table <concept>` to lay the evidence side by side; `facts <concepts>` before proposing anything.
3. `MAP.md` for the overview and the hubs; `index/*.tsv` for bulk work, searched with grep, never read whole.
4. When a detail matters, open the PDF page the card points to.

When answering: cite card ids, and the source in words (authors, year, page) for anything the user may repeat; say what kind of statement each point is (measured, the authors' interpretation, the brain's synthesis); check coverage before saying the brain has nothing on a point, and where the answer may sit in a part not read in full, run a lens pass (`brain-mesh-add-paper`) instead of reporting an absence.

Without code execution the same route works by reading `MAP.md`, then the concept card's prose, then only the cards it cites for the point in question.

## Rules that keep it sound

- Read FORMATS.md before writing or changing any card.
- Never edit a source PDF, its anchored text or an id. If `build` reports that a source file has changed, restore the original before doing anything else.
- After any change run `python3 tools/mesh.py build`. It expands links, mirrors them, refreshes the hub lists and `MAP.md`, re-marks the PDFs whose cards changed, rebuilds `index/` and runs every check. Fix all errors before finishing; treat each warning as work to do or to explain.
- Record each completed operation with `python3 tools/mesh.py log "<what changed>"`.
- Before creating any card, apply the duplicate rules in `brain-mesh-add-paper`.
- Propose concepts; do not create them: new concepts are the user's call (FORMATS.md, **Concept cards**).
- Log every contradiction you find on the register (FORMATS.md, **Contradiction**); never resolve one by quietly dropping or rewording a side.
- Keep prose and Codes in agreement on every card touched, and set its `updated` date.
- If the vault is a git repository, every change ends up on GitHub: `python3 tools/mesh.py sync "<what changed>"` at the end of each completed operation, as `brain-mesh-access` says.
