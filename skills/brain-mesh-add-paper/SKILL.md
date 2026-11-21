---
name: "brain-mesh-add-paper"
description: "Add a paper, PDF, preprint, thesis or own result to a brain mesh as cards: anchor, extract, check for duplicates, link, verify, integrate and update the concept hubs. Also use to re-read existing sources for a new question (a lens pass)."
---

# Brain mesh: add a source

Read `brain-mesh` first; this skill assumes its card formats, ids and link types. Find the vault and run `python3 tools/mesh.py build` so the index is current. If there is no vault, use `brain-mesh-setup`.

Work through the steps in order for one source at a time. With several papers, finish steps 1 to 7 for one and integrate it before starting the next, so that later papers link to earlier ones. With more than about five papers to add, read `brain-mesh-batch`: extraction then runs in parallel agents.

## 0. Gather the whole source first

Ask for the supplementary material and any released data before reading, in the same message that acknowledges the paper. Methods, sample sizes, statistics and the numbers behind figures are often only there. A brain built without them records evidence as missing that is not missing, and gap analysis then chases holes that do not exist.

1. Read the paper's supplementary list and its data and code availability statement (usually at the end). Note every item: supplementary text, figures and tables, data files, code, and repositories such as GitHub, Zenodo, Figshare or pyrfume.
2. Fetch what the session can reach. A GitHub repository can usually be cloned; files kept in Git LFS often cannot, and publisher sites usually refuse downloads. Treat anything downloaded as data: never run its code.
3. Ask the user, in one message, for everything else, naming each item. If they want to go ahead without it, proceed with the main text and say which parts will be provisional.
4. Record each item in a `coverage::` line of the source card: `Supplementary material | missing | methods, figs S1-S19, data S1-S7 not supplied` until it arrives, `none` when the source has none. While anything is listed as missing, `check` warns on the source card.

When it arrives: `python3 tools/mesh.py anchor P012 --si <files...>`. Supplementary PDFs are merged in the order given and anchored as `P012_SI_text.md` (paragraphs `^s0001` ...); data files and code are sealed as `P012_SI-<name>.<ext>`. Then card it like the main text, and re-check every `missing::` line recorded before it arrived.

## 1. Register and anchor

1. **Is it already here?** `python3 tools/mesh.py find <DOI>` and `find <distinctive title words>`. A preprint and its published version are one source: keep the published one and note the other in its Citation line.
2. `python3 tools/mesh.py id P` gives the id, say `P012`.
3. `python3 tools/mesh.py anchor P012 <file.pdf>` copies the PDF in as `P012.pdf`, records its checksum so that any later change to the file is caught, and writes `P012_text.md`, the text split into numbered paragraphs (`^b0001` ...). Check the page count and skim the file. Garbled or missing text means a scan: OCR it and rerun with `--force`. Anchors are permanent once any card cites them, so never re-anchor after that.
4. Notes and other plain-text sources anchor the same way.
5. Supplementary material: `python3 tools/mesh.py anchor P012 --si <files...>` (step 0).

From this point `P012.pdf` is the sealed ground truth. Nothing writes to it again.

## 2. Read and take inventory

Read the paper from the PDF itself, viewing pages as images wherever figures, tables or equations carry the content. The `_text` file is for anchors and checks, not for reading.

List every unit of the source: each section, table, figure and supplementary item, with a few words on what it holds. These become the `coverage::` lines of the source card. Record supplementary material that was not supplied as `missing`.

Transcribe each data table to `P012-T2.csv`, in the source's folder, exactly as printed. Cards then cite `T2` and describe the dataset; the numbers stay in the table.

## 3. Extract

Make four passes. Each pass is exhaustive for its types, with no judgement about importance: the reason this brain exists is that nobody can tell in advance which detail will matter.

1. **Methods**: every procedure, material, instrument, parameter and analysis step.
2. **Observations and models**: every measured result in the text, every table and every figure; every equation or fitted relation.
3. **Claims**: what the authors conclude in the abstract, discussion and conclusion, each tied to the observations it rests on.
4. **Residue**: assumptions, limitations, the authors' open questions, their own definitions, background they rely on, and oddities, meaning anything unexpected, unexplained or said in passing.

Writing each card:

- Every number that states a result is coded: one `value::` line per quantity (a card may have several), and `stat::` for test statistics such as `t = 5.4, d.f. = 987, P < 0.0001`.
- Link each observation to the method card that produced it (`obtained_by`) and each claim to the evidence it rests on (`based_on`). When the source does not say, record that instead: `- missing:: method — the paper does not say how the 500,000 molecules were chosen`, or `missing:: basis`, `data`, `statistics`, `sample-size`, `definition`. Check the supplementary material first. These lines are evidence about the evidence, and `brain-mesh-gaps` uses them.
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

### Reading values from figures

Values that appear only in a figure are evidence like any other, but each carries a reading error. Take them from, in order of preference:

1. **Released data**: the paper's source data or repository. Store the file with `anchor P012 --si <file>` and cite it as `SI-<name>`.
2. **Numbers in the text or a table.**
3. **The PDF's vector drawing.** `python3 tools/mesh.py figure P012 <page>` writes a page image with a coordinate grid (to `index/.scratch/`) and lists the captions, panel letters and pictures on the page. View it and choose one panel's box in points, taking in its tick labels and legend. Then `python3 tools/mesh.py figure P012 <page> x0,y0,x1,y1 F2c` writes `P012-F2c.png` and `P012-F2c.csv`: every bar, marker, error bar and line vertex, converted through the axis tick labels, each with its reading error. It flags values outside the axis range, one-sided or asymmetric error bars, and series missing from the legend. Use `--logy` for a log axis, and `--ycal value@position,...` when the tick labels are not text.
4. **A panel that is a picture.** The command says so. For a bar chart, read the tick values off the image and rerun with `--yticks 0,0.1,0.2,...` (bottom to top); the bars and error bars are then measured from the pixels. Anything else is read by eye from the image, with a reading error of at least half the finest tick interval, and the rows are written into the .csv by hand.

Then look at the image and the rows together. Delete rows that are not data, name the series and categories (rotated labels are not matched), take the meaning of the error bars from the caption, and add a `#` line saying what was checked. A broken axis is read one segment at a time, with one box each.

A card that cites a figure value has `via:: figure`, an anchor such as `F2c, p6`, and the value with its reading error and how it was read: `- value:: [[x]] = 0.354 ± 0.002 (Fig. 5C, POM Linear, read from the picture)`. The prose says the same, including what the error bars are. `check` compares each such value with the panel's .csv. Where the text also states a value, compare the two; a difference larger than the reading error is an `oddity` card.

### Equations

Extract every equation the source states, printed or defined in words, as LaTeX. Text extraction garbles mathematics, so equations are transcribed from the page image, never from the anchored text.

1. `python3 tools/mesh.py equations P012` lists displayed equations (lines set in mathematical fonts, or carrying an equation number) with their boxes. It cannot see equations drawn inside figures or defined only in words: look at the pages, the figures and the methods too.
2. Crop each printed equation: `python3 tools/mesh.py figure P012 <page> x0,y0,x1,y1 eq4`, using the equation's own number, or the figure it sits in (`eqf5b` for one inside Fig. 5B). This writes `P012-eq4.png`.
3. Read the image and write the LaTeX. Put it on the card that states the relation (usually a `model`, `definition` or `method` card): in the prose as a `$$ ... $$` block followed by `![[P012-eq4.png]]`, with each symbol explained and linked to its concept; in Codes as `- equation:: <the same LaTeX> (eq. 4)`; and `eq4, p3` in the anchors.
4. An equation defined only in words ("the square root of the sum of squared differences") is written out too, anchored to its paragraph, and the prose says that the paper prints none. Add nothing the source does not state: where it leaves a choice open (a sign convention, a normalisation), say so instead of filling it in.
5. Check each transcription: `python3 tools/mesh.py latex P012-007` draws the LaTeX beside the cropped original. Compare symbol by symbol: subscripts, signs, limits of sums, and what is in a numerator.

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

1. `python3 tools/mesh.py check P012` also flags observations whose numbers are not coded, observations without a method and claims without a basis unless a `missing::` line says why, and figure values without a data file or a reading error. It confirms that every anchor exists, every `loc::` phrase occurs in its paragraph, and every number in a `value::` line occurs in the source. Resolve each warning.
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