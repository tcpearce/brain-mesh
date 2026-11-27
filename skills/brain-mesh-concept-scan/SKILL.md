---
name: "brain-mesh-concept-scan"
description: "Scan chosen sources of a brain mesh, or all of them, for every concept in the brain and card each new fact with the works the paper cites for it; log every contradiction with what the brain holds on the contradictions register; add missing citations to existing cards; update the concept hubs. Use when the user asks to scan sources for concepts, facts or citations, after a concept is adopted or made by hand, and to backfill papers added before the scan existed."
---

# Brain mesh: concept scan

Read `brain-mesh` first, its FORMATS.md before writing or changing a card, and `brain-mesh-access` for syncing. This skill goes back over sources already in the brain. For a new paper the same work is part of `brain-mesh-add-paper` step 4.

The aim: for every source in scope, everything the paper says about any concept in the brain is either on a card or recorded as nothing new; every fact the paper backs with a citation carries that citation, on its evidence card and in the concept hub; and every contradiction between what the paper says and what the brain holds is logged on the contradictions register. Each hub also shows its key equations and figures, with the cards and works they come from (step 7).

## 1. Scope

1. `python3 tools/mesh.py sync`, then `python3 tools/mesh.py scan`. With no arguments, `scan` lists every source with what is left to do: concepts named in passages no card of that source covers, and how many passages.
2. Take the sources the user named, or all of them if they said all. Work high-priority sources first, then those with most to do.
3. One source at a time, start to finish. With more than about five sources, split them between agents as in `brain-mesh-batch`, which also keeps each source's reading out of the main conversation: each agent writes only in its own source's folder (new evidence cards, `cites::` lines on that source's cards, `P012_scan.md`, proposals with `propose --from P012`) and returns a short summary: cards added, citations added, hub lines it proposes, contradictions it found, with card ids. The launching session does steps 5 to 8 from those summaries.

### After a batch of adoptions

Adopting many concepts at once — as happens when a batch of papers is merged and the user judges their proposals together — leaves every one of them on the cards of the paper that proposed it and nowhere else. The other sources may discuss the same thing with no link, because the word did not exist when they were carded. A concept in that state is half a concept: its hub shows one source, every miner sees one source, and `literature` reports the brain as having read one paper on it.

So a sweep follows an adoption batch, and it is divided **by source, never by concept**. One agent takes whole sources and works every new concept within them, which keeps it inside its own folder; dividing the other way would have several agents writing into every paper's folder at once, which the batch rules forbid for good reason.

Two things make such a sweep cheaper than it looks. Most newly adopted concepts are specific and will be found in one or two sources beyond their own, where the answer is usually a `decided::` line rather than a card. A handful are load-bearing and will be found nearly everywhere — those deserve the careful pass, and are worth naming in each agent's brief so they are not skimmed.

**`scan` finds names, not ideas.** It matches each concept's slug, title and aliases (and word stems for high-priority concepts and sources), against brackets, dashes, slashes and commas as well as spaces. A paper that states a concept in other words is invisible to it: a role given only as a residue number (`W254(6.48)` for a toggle switch), a procedure described but never named, a product name used throughout for a general method (GloSensor for a cAMP reporter assay). So "nothing to do" means no unlinked passage *names* the concept, not that none is *about* it, and after an adoption batch the second is the common case. Each sweep agent, besides working the worklist, reads the source's own section headings, methods list and figure titles for the concepts in its brief, and cards or decides what it finds there as in step 2.

## 2. Work one source: `python3 tools/mesh.py scan P012`

`scan` prints, for each concept, every passage that names it and that no card of the source covers, with the sentence and the works the paper cites in that sentence (numbered and author-year styles). It writes the same worklist, without the paper's text, to `P012_scan.md`. A passage counts as covered when a card of P012 anchored there links the concept.

For each concept under **To do**, read every passage, opening the page where a figure, table or equation carries it. Each passage gets one of three outcomes:

| The passage | Do |
|---|---|
| States something about the concept that no card holds | A new evidence card, following add-paper step 3: one statement, the right type and status (`cited` when the paper takes it from other work; `claim`, `method`, `observation`, `definition`, `limitation` and so on otherwise), anchored to the passage with a `loc::` phrase, linking the concept in Codes, and `- cites:: [[R0042]] — what it supports` for each work the paper cites for it (the "cited here" list). Apply add-paper step 5 first: a background claim another source already carries gets `also_cited_by::` instead of a new card, and a cited work that is itself in the brain gets its own card linked. |
| Restates a fact a card of this source already holds (the abstract, the discussion) | Add the passage to that card's `anchor::` line. |
| Names the concept and says nothing new about it: a passing mention, a heading, a figure label, an equation fragment | Write why on the concept's `decided::` line in `P012_scan.md`, for example `- decided:: nothing new — named in figure labels and in passing`. |

Number new cards from `python3 tools/mesh.py id P012` and add them with `split`. Mark them `- lens:: L###` if the scan was started for a question (`brain-mesh-add-paper`, **Lens pass**).

Concepts the paper needs that the brain lacks: propose them (`propose <slug> "<definition>" --from P012`) and link the proposed name. Never make the concept card; that is the user's call.

High-priority concepts and sources are matched by word stem too, so expect more passages; each still needs an outcome. Low-priority concepts are listed and need nothing.

## 3. Citations on the source's existing cards

The end of the `scan` output, and **Citations to add** in `P012_scan.md`, list the source's cards whose passage cites works but which carry no `cites::` line. For each, read the sentence: add `- cites:: [[R0042]] — what it supports` for every work the statement rests on (the works cited in its own sentence are listed first), or `- cites:: none — <why>` when the citations in that paragraph support another sentence. The paper's own measured or derived results are not listed and need none.

If the source has no reference cards yet, make them first: `refs P012`, check the file, `cite P012` (add-paper step 1).

## 3a. Contradictions

The facts a concept scan adds are the ones most likely to clash with the brain: statements made in passing, in introductions and discussions, that nobody has yet set against the other papers.

1. As you card each new fact, read it against the concept's hub facts and evidence (`python3 tools/mesh.py facts <concept>`). Does it deny a fact on the hub, contradict another source's card, or exclude a mechanism the brain holds?
2. `python3 tools/mesh.py contradictions P012` lists what the tooling sees in the Codes, including any `contradicts::` link you made.
3. Log every real one: `contradictions add <key>`, or `contradictions add <card> <card> "<the clash>" --by "concept scan P012"`, and write **Why both cannot hold** and **Ways out**. Dismiss a candidate that is not one with its reason. Never edit a hub fact or another source's card to make a clash go away: the register keeps it until evidence explains or resolves it.

## 4. Close the source

1. `python3 tools/mesh.py scan P012` again, until **To do**, **Citations to add** and **Equations and figures for the hubs** are empty (step 7), and `python3 tools/mesh.py contradictions P012` shows nothing unlogged.
2. `python3 tools/mesh.py check P012`: fix every error, clear every warning or record why it stands.
3. Add a pass line to the source card: `- pass:: <date> | concept scan | <n> new cards, <m> citations added | <k> concepts decided, <c> contradictions logged`.

## 5. Link and place the new cards

For each source done: `python3 tools/mesh.py neighbours P012` and `python3 tools/mesh.py place P012`, then add-paper steps 6 and 8 for the new cards only: typed links with reasons to other sources' cards, support or against on the findings within scope, and decisions on any gap, tension or hypothesis the new facts bear on.

## 6. Update the concept hubs

For every concept that gained a fact, add-paper step 9 (a fact on a logged contradiction is stated with it: "against [[P001-014]], see [[V002]]"): a line under **What is known** (or **Relationships**, **How it is measured**, **Open questions**) citing the evidence card and the works it cites, as `[[R0042-…|Keller et al. 2017]]`, with the matching `- cites::` line in Codes. `check` flags a hub line that states a fact from a citing card without its works. Revise lines the new facts overtake, and set `updated`.

## 7. Key equations and figures on the hubs

Do this as you go, source by source: a hub should show the equations and figures that define or measure its concept, not just name the cards that hold them. **Equations and figures for the hubs** in the `scan` output, and in `P012_scan.md`, lists every equation and figure panel of the source for each concept its card names in `concepts::`, until each is on that hub or decided.

1. **Get the image.** A printed equation is cropped as `P012-eq4.webp`, and a figure panel as `P012-F2c.webp` (`P012-SF3.webp` in the supplementary material), with `mesh.py figure`; the scan lists each item under the name its file has, which is `.png` in a vault whose crops were made before 1.24.1 (add-paper, **Reading values from figures** and **Equations**). An item listed "no image yet" whose figure is key: crop it now, choosing a box that takes in the panel, its axes and legend.
2. **Judge it for this concept.** Key means it defines the concept, gives its functional form, or shows its principal measurement or result. A figure that only touches the concept is not key for it, though it may be for another.
3. **Put a key one on the hub**, under `## Key equations and figures` (after **Open questions**, before **Where it appears**), one entry each:
   - a bold name and one sentence on what it shows, with the conditions;
   - for an equation, the LaTeX as a `$$ … $$` block with its symbols linked to their concepts, then `![[P012-eq4.webp]]`; for a figure, `![[P012-F2c.webp|400]]`;
   - the evidence card it comes from (`[[P012-028|Pellegrino et al. 2025, Fig. 1D]]`), which carries the link to the page;
   - every work that card cites for it, as `[[R0042-…|Keller et al. 2017]]`, with the matching `- cites:: [[R0042]] — <what it supports>` in the hub's Codes. An equation the paper takes from earlier work is credited to that work as well as to the paper.
4. **Or decide.** For one that is not key to that concept, write `- not_key:: [[concept]] P012-F2c.webp — why` in `P012_scan.md`. The line is kept when the scan runs again.

When two sources give the same equation, keep one entry and cite both. Where they differ (another form, other parameters), show both and say how they differ.

## 8. Finish

1. `python3 tools/mesh.py build` until it shows 0 errors.
2. `python3 tools/mesh.py log "concept scan P001-P003: <n> new cards, <m> citations added, <c> contradictions logged, <k> equations and figures on hubs, hubs <list>"` and `python3 tools/mesh.py sync "concept scan <sources>"`.
3. Report in a few lines:
   - per source, the new facts by concept and the citations added;
   - the contradictions logged, each in one line, and those that suggest a theory or an experiment;
   - the hubs updated, and the equations and figures put on them;
   - findings, gaps or tensions affected;
   - the concepts proposed, one line each with its definition, for the user to adopt (`adopt <slug>`, or `adopt --all`), fold (`adopt <slug> into <concept>`) or reject (`reject <slug> "<why>"`).
