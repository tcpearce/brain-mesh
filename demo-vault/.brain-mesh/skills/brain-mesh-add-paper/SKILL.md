---
name: "brain-mesh-add-paper"
description: "Add a paper, PDF, preprint, thesis or own result to a brain mesh as cards: anchor, extract, check for duplicates, link, verify, integrate and update the concept hubs. Also use to re-read existing sources for a new question (a lens pass)."
---

# Brain mesh: add a source

Read `brain-mesh` first; this skill assumes its card formats, ids and link types. Find the vault and run `python3 tools/mesh.py build` so the index is current. If there is no vault, use `brain-mesh-setup`.

Work through the steps in order for one source at a time. With several papers, finish steps 1 to 7 for one and integrate it before starting the next, so that later papers link to earlier ones.

## 1. Register and anchor

1. **Is it already here?** `python3 tools/mesh.py find <DOI>` and `find <distinctive title words>`. A preprint and its published version are one source: keep the published one and note the other in its Citation line.
2. `python3 tools/mesh.py id P` gives the id, say `P012`.
3. `python3 tools/mesh.py anchor P012 <file.pdf>` copies the PDF in as `P012.pdf`, records its checksum so that any later change to the file is caught, and writes `P012_text.md`, the text split into numbered paragraphs (`^b0001` ...). Check the page count and skim the file. Garbled or missing text means a scan: OCR it and rerun with `--force`. Anchors are permanent once any card cites them, so never re-anchor after that.
4. Notes and other plain-text sources anchor the same way.

From this point `P012.pdf` is the sealed ground truth. Nothing writes to it again.

## 2. Read and take inventory

Read the paper from the PDF itself, viewing pages as images wherever figures, tables or equations carry the content. The `_text` file is for anchors and checks, not for reading.

List every unit of the source: each section, table, figure and supplementary item, with a few words on what it holds. These become the `coverage::` lines of the source card. Record supplementary material that was not supplied as `missing`.

Transcribe each data table to `sources/P012/P012-T2.csv` exactly as printed. Cards then cite `T2` and describe the dataset; the numbers stay in the table.

## 3. Extract

Make four passes. Each pass is exhaustive for its types, with no judgement about importance: the reason this brain exists is that nobody can tell in advance which detail will matter.

1. **Methods**: every procedure, material, instrument, parameter and analysis step.
2. **Observations and models**: every measured result in the text, every table and every figure; every equation or fitted relation.
3. **Claims**: what the authors conclude in the abstract, discussion and conclusion, each tied to the observations it rests on.
4. **Residue**: assumptions, limitations, the authors' open questions, their own definitions, background they rely on, and oddities, meaning anything unexpected, unexplained or said in passing.

Writing each card:

- One statement per card, readable alone. Name the system, the conditions and the direction of the effect. Put conditions on every card even when the paper gives them once.
- One card per finding-bearing statement or comparison, not one per table cell. Expect roughly 40 to 150 cards for a paper.
- Keep the authors' strength of claim in `status`. A hedge is `speculated`; an interpretation is `inferred`; only what was measured is `measured`.
- Say what the paper leaves out: no n, an unspecified uncertainty, a missing control. Absences are information for experiment design.
- Write in your own words. The only copied text is the short `loc::` phrase.
- Give every card a way back to the page. End the **Source:** line with `[[P012.pdf#page=5|open page]]`; `build` re-points it at the card's highlight in the marked PDF. Take the `loc::` phrase from the sentence that carries the statement, because that phrase is what gets highlighted.
- Choose locator phrases made of plain words. Avoid stretches containing symbols or operators (=, <, ±, ~), citation numbers, and words the PDF breaks across lines with a hyphen: PDFs often encode these oddly, and the phrase then fails to match the page even though it reads correctly.
- For a table or figure give the page as well, `- anchor:: T2, p7`, so the mark lands on the right caption.
- A value read from a plot is `via:: figure` and approximate; say so in the prose.
- Doubt about the extraction goes in `flag::`, not in silence.

Write cards in batches of 20 to 40 in one file, each card starting with a line `=== <file name without .md>`, then run `python3 tools/mesh.py split <batch file>`. Number evidence cards upward from `python3 tools/mesh.py id P012`. `split` adds the `id::` code and refuses a card that duplicates one already in the source.

Write the source card in the first batch.

## 4. Concepts

For every material, variable, technique and mechanism a card mentions, run `python3 tools/mesh.py concept "<name>"`.

- An existing concept covers it: link that card. If the paper uses a new name for it, add the name to the concept's `aliases`.
- Nothing covers it: create the concept card with a definition, kind and unit.
- A variable whose values are things (solvent, strain, polymer) is `categorical`, and each value is its own concept card.

Use the concept's canonical unit in `value::` and `when::` lines where the conversion is exact; otherwise keep the paper's unit and say so on the concept card.

## 5. The new-card checker: no pointless duplication

The test every new card must pass: it adds a new statement, a new source for a statement, new conditions, or a new relationship. Otherwise it is an edit to an existing card.

1. **Same source, same statement: one card.** Papers repeat themselves across abstract, results and discussion. Card it once, anchored where it is most specific, and add the other places as extra anchors.
2. **Different source, same statement: never merged.** That is independent evidence. Give it its own card and link it to the existing one (`replicates`, `contradicts`, `extends`) with a reason.
3. **Concepts: match before create** (step 4). A synonym becomes an alias.
4. **Findings, tensions and gaps: search first.** New support for an existing finding is added to that finding. A new card is justified only when the scope differs, and its title must say how.
5. **Background claims repeated across papers.** One `cited` card per reference and claim. When another source cites the same thing, add `- also_cited_by:: [[P013]]` to the existing card. If the cited paper is itself in the brain, link its own card instead of carding the hearsay.
6. **Definitions.** Card a definition only when the source defines or operationalises the term differently from the concept card.
7. **Later discoveries.** Merge with `brain-mesh-housekeeping`: the older id survives and the other is retired with a pointer.

The tooling enforces these at three points: `split` refuses a same-source duplicate; `python3 tools/mesh.py neighbours P012` lists, for each new card, the most similar existing cards and what each calls for; `build` reports same-source near-duplicates, unlinked parallel results from different sources, repeated background claims, near-identical concept names and overlapping findings. Clear every one, or state why it stands.

## 6. Link

The web grows from the bottom up, card to card.

- **Within the source.** Each observation gets `obtained_by` its method. Each claim and model gets `based_on` its observations. Each limitation `qualifies`, and each assumption `underlies`, the statements it affects.
- **Across sources.** Run `python3 tools/mesh.py neighbours P012`. For every candidate ask: where does this card fit, and does it replicate, contradict, support, extend or qualify that one? Add the link with a reason, or decide the two are unrelated.

A link should tell a reader something they would want to follow. Do not link cards merely because they share a concept; the concept hub already does that.

## 7. Verify against the PDF

1. `python3 tools/mesh.py check P012` confirms that every anchor exists, every `loc::` phrase occurs in its paragraph, and every number in a `value::` line occurs in the source. Resolve each warning.
2. `python3 tools/mesh.py sample P012 10` prints ten random cards beside their source paragraphs. Read each pair: is the statement right, are the conditions complete, is the status fair? For a source that a decision will rest on, check every observation.
3. Run `python3 tools/mesh.py build` and look at `P012_marked.pdf` page by page, as images. Every card should sit on the passage it describes. A card that `build` reports as having only a page-level marker has a wrong `loc` or anchor; fix it. Then read what is not highlighted: any unmarked sentence that states a method, a result, a claim or a caveat is a missed card. `python3 tools/mesh.py unread P012` lists every paragraph that no card is anchored to; go through the whole list, since a paragraph can be covered by a card anchored next door, or not covered at all. End matter counts: data and code availability, and summaries not written by the authors, can hold facts or discrepancies worth a card. Card what was missed, or record in the coverage lines why that part was left.
4. Record the result in a `pass::` line on the source card, for example `2026-11-20 | full | 84 cards | verified 10 of 10 sampled, marked pages reviewed`, and set its status to `extracted`.

## 8. Integrate upward

`python3 tools/mesh.py related P012` lists the findings, tensions, gaps, hypotheses and experiments that share concepts with the new source. Then:

- For each main result and claim: add it to an existing finding as `support` or `against` and re-grade the finding; or open a tension if it disagrees with existing evidence; or write a new finding if nothing covers it.
- Turn the authors' open questions and limitations into gap candidates (`brain-mesh-gaps`), searching existing gaps first.
- **Check the workbench.** Does the source support or undermine an open hypothesis, or already answer a planned or registered experiment? Say so on that card, under `## Amendments` for a registered experiment, and tell the user at once.
- If the source was in `ledger/reading-queue.md`, mark it ingested and revisit the gap it was meant to fill.

## 9. Update the concept hubs

This is what the user reads, so it is not optional. For every concept the source says something material about:

- add to **What is known**, one line per point, citing the finding or evidence card;
- add or revise lines under **Relationships**, and the matching relation in Codes (`affects`, `measured_by`, `part_of`, `broader`, `related`);
- add to **Open questions**; extend **How it is measured** when the source uses a new method;
- revise a line that the new source has overtaken, and do not leave contradictory lines standing;
- set `updated` to today.

## 10. Close

Set the source card's status to `integrated`. Rewrite the Overview in `MAP.md` if the picture has changed. Run `python3 tools/mesh.py build` until there are no errors, then `python3 tools/mesh.py log "add P012 <authors year> (<n> cards); <findings, tensions and gaps changed>"`.

Report to the user in a few lines: cards by type; findings added or re-graded; new tensions and gaps; hubs updated; anything bearing on their hypotheses or experiments; what was not extracted and why; and the most-cited references not yet in the brain (`index/frontier.tsv`). If the session's files are temporary, hand back the vault archive.

## Lens pass: re-reading sources for a new question

Use this when a question needs a detail the cards do not hold but the papers may.

1. `python3 tools/mesh.py id L`, then add `## L003 — <the question>` to `ledger/lenses.md` with the date.
2. Use `index/coverage.tsv` to see which sources and units could hold the answer. Search the `_text` files for the terms, including every alias of the concepts involved, then read the pages. The marked PDFs show at a glance which passages already have cards.
3. Add cards with `- lens:: L003`. Apply the duplicate rules; a lens pass is where re-extraction duplicates creep in.
4. Under the lens heading record every source examined and what was found, including "nothing". A negative result is what later allows a gap to be called a gap.
5. Update the coverage lines of sources read more deeply, then run steps 6 to 10.

## Own results

The user's own experimental results enter exactly like a paper, with `kind:: own-result` on the source card and `- experiment:: [[E001]]` when they come from a registered experiment. Anchor the lab note or results file. When it is not a PDF, cards link to the paragraph with `[[P003_text#^b0002|open passage]]` in the Source line. Card every measured value, including nulls and failed runs, and card protocol deviations as limitations. Link the cards to the literature cards they replicate, contradict or extend. Own results get no special weight: a conflict with a paper is a tension. Then use `brain-mesh-experiment` to assess the outcome.