---
name: "brain-mesh-concept-scan"
description: "Scan chosen sources of a brain mesh, or all of them, for every concept in the brain and card each new fact with the works the paper cites for it; add missing citations to existing cards; update the concept hubs. Use when the user asks to scan sources for concepts, facts or citations, after a concept is adopted or made by hand, and to backfill papers added before the scan existed."
---

# Brain mesh: concept scan

Read `brain-mesh` first for the card formats, and `brain-mesh-access` for syncing. This skill goes back over sources already in the brain. For a new paper the same work is part of `brain-mesh-add-paper` step 4.

The aim: for every source in scope, everything the paper says about any concept in the brain is either on a card or recorded as nothing new, and every fact the paper backs with a citation carries that citation, on its evidence card and in the concept hub.

## 1. Scope

1. `python3 tools/mesh.py sync`, then `python3 tools/mesh.py scan`. With no arguments, `scan` lists every source with what is left to do: concepts named in passages no card of that source covers, and how many passages.
2. Take the sources the user named, or all of them if they said all. Work high-priority sources first, then those with most to do.
3. One source at a time, start to finish. With more than about five sources, the sources can be split between agents as in `brain-mesh-batch`: each agent writes only in its own source's folder (new evidence cards, `cites::` lines on that source's cards, `P012_scan.md`, proposals with `propose --from P012`), and the launching session does steps 5 to 7.

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

## 4. Close the source

1. `python3 tools/mesh.py scan P012` again, until **To do** and **Citations to add** are empty.
2. `python3 tools/mesh.py check P012`: fix every error, clear every warning or record why it stands.
3. Add a pass line to the source card: `- pass:: <date> | concept scan | <n> new cards, <m> citations added | <k> concepts decided`.

## 5. Link and place the new cards

For each source done: `python3 tools/mesh.py neighbours P012` and `python3 tools/mesh.py place P012`, then add-paper steps 6 and 8 for the new cards only: typed links with reasons to other sources' cards, support or against on the findings within scope, and decisions on any gap, tension or hypothesis the new facts bear on.

## 6. Update the concept hubs

For every concept that gained a fact, add-paper step 9: a line under **What is known** (or **Relationships**, **How it is measured**, **Open questions**) citing the evidence card and the works it cites, as `[[R0042-…|Keller et al. 2017]]`, with the matching `- cites::` line in Codes. `check` flags a hub line that states a fact from a citing card without its works. Revise lines the new facts overtake, and set `updated`.

## 7. Finish

1. `python3 tools/mesh.py build` until it shows 0 errors.
2. `python3 tools/mesh.py log "concept scan P001-P003: <n> new cards, <m> citations added, hubs <list>"` and `python3 tools/mesh.py sync "concept scan <sources>"`.
3. Report in a few lines: per source, the new facts by concept and the citations added; the hubs updated; findings, gaps or tensions affected; the concepts proposed, one line each with its definition, for the user to adopt (`adopt <slug>`, or `adopt --all`), fold (`adopt <slug> into <concept>`) or reject (`reject <slug> "<why>"`).
