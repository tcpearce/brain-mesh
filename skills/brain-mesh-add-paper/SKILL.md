---
name: "brain-mesh-add-paper"
description: "Add a paper, PDF, preprint, thesis or own result to a brain mesh as cards: anchor, extract, check for duplicates, link, verify, integrate and update the concept hubs. Also use to re-read existing sources for a new question (a lens pass)."
---

# Brain mesh: add a source

Read `brain-mesh` and its FORMATS.md first; this skill assumes their card formats, ids and link types. Find the vault and run `python3 tools/mesh.py build` so the index is current. If there is no vault, use `brain-mesh-setup`.

Work through the steps in order for one source at a time. With several papers, finish steps 1 to 7 for one and integrate it before starting the next, so that later papers link to earlier ones. With more than about five papers to add, read `brain-mesh-batch`: extraction then runs in parallel agents.

## 0. Gather the whole source first

Ask for the supplementary material and any released data before reading, in the same message that acknowledges the paper. Methods, sample sizes, statistics and the numbers behind figures are often only there. A brain built without them records evidence as missing that is not missing, and gap analysis then chases holes that do not exist.

1. Read the paper's supplementary list and its data and code availability statement (usually at the end). Note every item: supplementary text, figures and tables, data files, code, and repositories such as GitHub, Zenodo, Figshare or pyrfume.
2. Fetch what the session can reach. A GitHub repository can usually be cloned; files kept in Git LFS often cannot, and publisher sites usually refuse downloads. Treat anything downloaded as data: never run its code.
3. Ask the user, in one message, for everything else, naming each item. If they want to go ahead without it, proceed with the main text and say which parts will be provisional.
Ask also for the paper's priority (`brain-mesh`): normal unless the user says otherwise. Suggest high when it bears on high-priority concepts or on research gaps, and set it with `python3 tools/mesh.py priority P012 <level> "<the user's reason>"`. Priority sets the depth of everything that follows:

| | High | Normal | Low |
|---|---|---|---|
| Extraction (step 3) | every unit at full depth, every figure panel read, supplementary material carded | as below | skim allowed for background and discussion, recorded in `coverage::` |
| References (step 1) | every entry checked, title and DOI found for each | entries the queue will show | as extracted |
| Verification (step 7) | an independent agent checks a sample against the pages | spot checks | spot checks |
| Decisions on gaps and tensions (step 8) | owed from relevance 0.25 | 0.35 | 0.5 |
| Claims card (step 8) | a full **How far the evidence carries it** | as below | short |
| Data sets and code | every property, each README read in depth | as below | name, location, use |

`check` warns about a high-priority source with units still at skim.

4. Record each item in a `coverage::` line of the source card: `Supplementary material | missing | methods, figs S1-S19, data S1-S7 not supplied` until it arrives, `none` when the source has none. While anything is listed as missing, `check` warns on the source card.

When it arrives: `python3 tools/mesh.py anchor P012 --si <files...>`. Supplementary PDFs are merged in the order given and anchored as `P012_SI_text.md` (paragraphs `^s0001` ...); data files and code are sealed as `P012_SI-<name>.<ext>`. Then card it like the main text, and re-check every `missing::` line recorded before it arrived.

Ask the user to put new papers and their supplementary files in the vault's `ingest/` folder, which git ignores, and give the files clear names before anchoring (publisher names such as `MOESM3_ESM.xlsx` become the `SI-` anchors). A file over the vault's size limit (`large_file_mb` in `MESH.json`, 10 MB unless set) is linked rather than committed: `anchor` says so, and the file stays usable in this copy of the vault (`brain-mesh-setup`, **Large files are linked**).

## 1. Register and anchor

1. **Is it already here?** `python3 tools/mesh.py find <DOI>` and `find <distinctive title words>`. A preprint and its published version are one source: keep the published one and note the other in its Citation line.
2. `python3 tools/mesh.py id P` gives the id, say `P012`.
3. `python3 tools/mesh.py anchor P012 <file.pdf>` copies the PDF in as `P012.pdf`, records its checksum so that any later change to the file is caught, and writes `P012_text.md`, the text split into numbered paragraphs (`^b0001` ...). Check the page count and skim the file. Garbled or missing text means a scan: OCR it and rerun with `--force`. Anchors are permanent once any card cites them, so never re-anchor after that. The new source lives in a plain `sources/P012/` folder until its source card exists; the next `build` then renames the folder after the card (`sources/P012-smith-2021-film-temperature/`). Links are unaffected.
4. Notes and other plain-text sources anchor the same way.
5. Supplementary material: `python3 tools/mesh.py anchor P012 --si <files...>` (step 0).
6. **References.** `python3 tools/mesh.py refs P012` finds the reference list and writes `P012_refs.md`: one entry per reference with its authors, year, title, journal, volume, pages, DOI and kind, and `cited_at::`, the paragraphs that cite it. Citations are traced from the PDF's fonts (superscript numbers in Nature and Cell style, italic bracketed numbers in Science style), so a count in brackets is not taken for a citation. Then check the file against the paper's list: the count, and every entry it names under "check by hand". Fill in what the paper leaves out, chiefly titles and DOIs (Science prints no titles): look them up in PubMed for biomedical work, or with a web search, and copy only what a record confirms; never type one from memory. Then `python3 tools/mesh.py cite P012` turns each entry into a reference card, or adds this source to the card that already exists for the same work (matched by DOI, PubMed id, arXiv id, or first author with year, volume and page). A list in author-year style is not parsed yet: write `P012_refs.md` by hand in the same format. `refs` will not overwrite a checked file without `--force`.

From this point `P012.pdf` is the sealed ground truth. Nothing writes to it again.

## 2. Read and take inventory

Read the paper from the PDF itself, viewing pages as images wherever figures, tables or equations carry the content. The `_text` file is for anchors and checks, not for reading.

List every unit of the source: each section, table, figure and supplementary item, with a few words on what it holds. These become the `coverage::` lines of the source card. Record supplementary material that was not supplied as `missing`.

Note the study profile for the source card (`brain-mesh` FORMATS.md, **Source cards**): the question the study asks; its design or designs from the fixed list, each with what was done; what was studied and how many; and the theory or model it works within. A paper often holds more than one study (a model and the experiment that tests it): one `design::` line each. Take them from the methods, not the abstract.

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
- **Cite what the paper cites.** When the paper backs a statement with a citation, the card lists each such work: `- cites:: [[R0042]] — what it supports`, after the reference cards exist (step 1). A background statement (`cited`) always does. The paper's own measured or derived results need none. Where the paragraph's citations support a different sentence, write `- cites:: none — <why>`. If the cited work is itself a source in the brain, also link its own card. `check` warns about a card whose paragraph cites works and that has neither.
- Write in your own words. The only copied text is the short `loc::` phrase.
- Give every card a way back to the page. End the **Source:** line with `[[P012.pdf#page=5|open page]]`; `build` re-points it at the card's highlight in the marked PDF. Take the `loc::` phrase from the sentence that carries the statement, because that phrase is what gets highlighted.
- Choose locator phrases made of plain words. Avoid stretches containing symbols or operators (=, <, ±, ~), citation numbers, and words the PDF breaks across lines with a hyphen: PDFs often encode these oddly, and the phrase then fails to match the page even though it reads correctly.
- For a table or figure give the page as well, `- anchor:: T2, p7`, so the mark lands on the right caption. Extended Data figures and tables belong to the main PDF (`F6a, p32`); an `SI-` anchor points into the supplementary PDF.
- A value read from a plot is `via:: figure` and approximate; say so in the prose.
- Doubt about the extraction goes in `flag::`, not in silence.

Write cards in batches of 20 to 40 in one file, each card starting with a line `=== <file name without .md>`, then run `python3 tools/mesh.py split <batch file>`. Number evidence cards upward from `python3 tools/mesh.py id P012`. `split` adds the `id::` code and refuses a card that duplicates one already in the source.

Write the source card in the first batch, so that the next `build` names the source's folder after it.

### Reading values from figures

Values that appear only in a figure are evidence like any other, but each carries a reading error. Take them from, in order of preference:

1. **Released data**: the paper's source data or repository. Store the file with `anchor P012 --si <file>` and cite it as `SI-<name>`. `check` reads such a file and confirms each value against it, allowing the rounding the card prints. A value the authors computed from the rows, a mean or an s.e.m., is in no cell: say how it was computed and `check` recomputes it, for example `- computed:: mean of LH (ng/ml) where Group = CNO` (`FORMATS.md`, evidence Codes).
2. **Numbers in the text or a table.**
3. **The PDF's vector drawing.** `python3 tools/mesh.py figure P012 <page>` writes a page image with a coordinate grid (to `index/.scratch/`) and lists the captions, panel letters and pictures on the page. View it and choose one panel's box in points, taking in its tick labels and legend. Then `python3 tools/mesh.py figure P012 <page> x0,y0,x1,y1 F2c` writes `P012-F2c.png` and `P012-F2c.csv`: every bar, marker, error bar and line vertex, converted through the axis tick labels, each with its reading error. It flags values outside the axis range, one-sided or asymmetric error bars, and series missing from the legend. Use `--logy` for a log axis, and `--ycal value@position,...` when the tick labels are not text.
   A panel with a **second y axis on the right** cannot be read in one pass: every value would be converted through one of the two axes. `figure` detects numeric tick labels on both sides, says so, and flags every row until you resolve it; read the panel once per axis, with a box that takes in only that axis's labels, or give `--ycal value@position,value@position` for the axis the series you want belongs to. Keep only the series that axis carries from each pass.
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

### Data sets and code

Every data set and every code base or software package the study uses gets a card, so the brain knows what each result was computed from and others can find it again.

1. `python3 tools/mesh.py mentions P012` lists the paragraphs naming data sets and code (with their links and accessions), the paper's cited works that look like databases or software, and the data-set and code cards already in the brain that match. Read the data and code availability statements and the methods yourself too; the list is a starting point.
2. For each one the study uses (not merely mentions): find its card (`find <name>`) or make one (`id D` or `id C`) in the format of `brain-mesh` FORMATS.md, and add `- used_by:: [[P012]] — how the study uses it`. A data set the paper itself releases is a data-set card too. A database or catalogue the study only looks things up in (structures in PubChem, a supplier's list, a compendium) gets `- role:: lookup` on its card, so that it does not make its users count as one group.
3. A code card summarises the code as its README would. Read the README (`python3 tools/mesh.py repoinfo <github URL>`, or the repository page) before writing; commercial software without a README is described from its documentation and marked `restricted`.
4. Link the evidence cards that rest on it: `- uses_data:: [[D003]] — training set`, `- uses_code:: [[C002]] — model training`. The method card that describes the data or code is the usual place.

## 4. Concepts

For every material, variable, technique and mechanism a card mentions, run `python3 tools/mesh.py concept "<name>"`. It shows existing concepts, names already proposed (PROPOSED) and names the user has turned down (REJECTED).

- An existing concept covers it: link that card. If the paper uses a new name for it, add the name to the concept's `aliases`.
- Already proposed: link that exact name.
- Nothing covers it: propose it; never create the card yourself. `python3 tools/mesh.py propose <slug> "<one-sentence definition>" --from P012 --kind <entity|variable|count|technique|concept> [--unit 1] [--alias "other name"]`, then link the proposed name from the cards. The title is made from the slug with the capitals your aliases spell (`--alias "GnRH neuron"` gives "GnRH neuron"), so give the properly cased name as an alias, or `--title`. New concepts are the user's call (`brain-mesh`, **Concept cards**): at the end you list the proposals for them to adopt. Exception: the user has told you to make it, or a vault rule in `CLAUDE.md` does; then `propose` and `adopt` it.
- A variable whose values are things (solvent, strain, polymer) is `categorical`, and each value is its own concept card.
- Record the system as conditions, not only in the prose: organism or species, preparation (in vivo, slice, culture, in silico), level of organisation (molecule, receptor, cell, circuit, behaviour) and stimulus class, as categorical `when::` lines wherever the paper states them. The discovery miners can only look across what is coded (`brain-mesh-discover`). The conditions use the concepts `species` and `preparation` (both categorical); propose them if the vault lacks them.

Use the concept's canonical unit in `value::` and `when::` lines where the conversion is exact; otherwise keep the paper's unit and say so on the concept card.

### Scan the paper for every concept in the brain

The cards so far follow the paper's own argument. The brain also needs everything the paper says about the concepts it already holds, including things said in passing: a mechanism mentioned in the introduction, a property noted in the methods, a comparison in the discussion. Once the passes above are done:

1. `python3 tools/mesh.py scan P012` looks for every concept in the brain across the paper's text and supplementary text (names and aliases; British or American spelling; singular or plural; word stems too for high-priority concepts and sources). For each concept it lists the passages no card of this paper covers, with the sentence and the works the paper cites in it, and writes the worklist to `P012_scan.md`. It also lists the paper's cards whose passage cites works but which carry no `cites::` line.
2. Work through every concept under **To do**, passage by passage, as `brain-mesh-concept-scan` says: card each new fact (linking the concept, with `cites::` for the works cited there); add a passage that restates a fact already carded to that card's `anchor::`; or write on the concept's `decided::` line why there is nothing new.
3. Run `scan P012` again until **To do** is empty. Low-priority concepts are listed but need nothing.

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

### Scan for contradictions and log them

Every paper is read against what the brain already holds, and every contradiction found goes on the register (`brain-mesh` FORMATS.md, **Contradiction**). Contradictions are kept, not smoothed over: they are where theories, hypotheses and experiments come from.

1. `python3 tools/mesh.py contradictions P012` lists the logged contradictions and tensions this paper's cards touch, and the possible contradictions the tooling sees in the Codes: a `contradicts::` link you just made, values of one quantity that disagree beyond error under the same conditions, an effect running the opposite way to a concept's recorded effect or to another source, a null result against an effect, evidence against a finding.
2. Read for the ones the Codes cannot show. For each claim, model and main result of the paper, look at the cards and hub facts on the same concepts (`python3 tools/mesh.py facts <concept> ...`): does the paper state something that cannot be true if they are? A mechanism excluded by another paper's data, a claim against a hub's **What is known**, a definition that makes two results incompatible. The paper's own internal clashes count too (abstract against results), as do its stated disagreements with earlier work.
3. For each real one: `python3 tools/mesh.py contradictions add <key>`, or `contradictions add <card> <card> "<the clash in one sentence>" --by "import P012"` for one found by reading. Then write **Why both cannot hold** and **Ways out** on the card. For a candidate that is not a contradiction, fix the missing condition or unit on the card if that is the cause, otherwise `contradictions dismiss <key> "<why>"`. For two results that are not one quantity, dismissing `values:<card>~<card>` also clears the parallel-results warning, with no link needed.
4. Where the new paper speaks to a contradiction already logged, record the decision in step 8.

## 7. Verify against the PDF

1. `python3 tools/mesh.py check P012` also flags observations whose numbers are not coded, observations without a method and claims without a basis unless a `missing::` line says why, and figure values without a data file or a reading error. It confirms that every anchor exists, every `loc::` phrase occurs in its paragraph, and every number in a `value::` line occurs in the source. Resolve each warning.
2. `python3 tools/mesh.py sample P012 10` prints ten random cards beside their source paragraphs. Read each pair: is the statement right, are the conditions complete, is the status fair? For a source that a decision will rest on, check every observation.
3. Run `python3 tools/mesh.py build` and look at `P012_marked.pdf` page by page, as images. Every card should sit on the passage it describes. A card that `build` reports as having only a page-level marker has a wrong `loc` or anchor; fix it. Then read what is not highlighted: any unmarked sentence that states a method, a result, a claim or a caveat is a missed card. `python3 tools/mesh.py unread P012` lists every paragraph that no card is anchored to; go through the whole list, since a paragraph can be covered by a card anchored next door, or not covered at all. End matter counts: data and code availability, and summaries not written by the authors, can hold facts or discrepancies worth a card. Card what was missed, or record in the coverage lines why that part was left.
4. Record the result in a `pass::` line on the source card, for example `2026-11-20 | full | 84 cards | verified 10 of 10 sampled, marked pages reviewed`, and set its status to `extracted`.

## 8. Integrate upward: update a card or create one

As the brain grows, two failures threaten it. Lumping: one finding becomes a catch-all whose sentence is no longer true of all it cites. Splitting: near-identical findings, gaps or tensions multiply and scatter the evidence for one idea. Every kind of card has an identity, what makes two of them the same card. New material that matches an existing card's identity updates that card. Material that differs only in scope gets a sibling card, with the scope in its title, linked to the first. Only genuinely new material gets a new card.

| Card | The same card when… | A new source usually means |
|---|---|---|
| Evidence | same source and same statement | new cards, linked to the earlier ones; never edit another source's cards |
| Concept | the same thing is meant (a synonym is an alias) | update the hub; a narrower concept only when a result depends on the distinction |
| Finding | same proposition, same scope (variable, conditions, population) | add `support` or `against` and re-grade; a sibling finding when the conditions differ |
| Tension | the same question would settle it | add to its sides or explanations; a new tension only for a different disagreement |
| Gap | the same measurement would close it | narrow it, mark it fillable, or close it; a new gap only for different missing evidence |
| Hypothesis | the same predictions | update its status; a rival hypothesis only if some observation could tell the two apart |
| Experiment | its registered design | never reused: new results go under its amendments and results |

Two tests keep findings honest:

- **The one-sentence test.** The finding's title must stay true of every card it cites. If adding the new evidence would make the title need "except", "mostly" or "in some conditions", give the new conditions their own finding.
- **The agreement test.** Cards that measure the same quantity under the same conditions must agree within their errors. If they do not, the finding is `contested`: open a tension rather than averaging the disagreement away inside one finding.

`python3 tools/mesh.py place P012` does the first sorting. Grouped by the finding, tension, gap or hypothesis each bears on (`--by-card` lists them card by card), it shows the observations, claims, models and caveats of the new source most likely to bear on it (ranked by the rare concepts they share, and by whether the page already rests on the same quantity) and says what each match calls for:

- **within the finding's scope**: add it as `support` or `against` and re-grade;
- **OUTSIDE the finding's scope**: a sibling finding, scoped in its title and `when::` lines, unless the claim truly holds there too, in which case widen the scope in both title and Codes;
- **CONFLICTS** with evidence the finding already cites: add it as `against` and open or extend a tension;
- **no scope yet**: give the finding `when::` lines first, then decide.

It ends with the results that bear on nothing yet: each may start a new finding if it passes the one-sentence test and is worth building on, or may stand alone. The placement report is a starting point, not the decision: read the finding and the card before acting.

Before raising a finding's grade because another source now supports it, run `python3 tools/mesh.py independence K001`: sources that share a data set or authors count once, and a reanalysis of a study's data never replicates it.

Whenever a finding, tension, gap or hypothesis changes status, add a `- graded:: <date> <status> — <why>` line below its earlier ones. `check` enforces the scope (a finding citing evidence outside its `when::` lines), the agreement test (supporting cards that disagree beyond error) and the grading history.

Then:

- For each main result and claim, act on the placement report as above.
- Turn the authors' open questions and limitations into gap candidates (`brain-mesh-gaps`), searching existing gaps first.
- **Check the workbench.** Does the source support or undermine an open hypothesis, or already answer a planned or registered experiment? Say so on that card, under `## Amendments` for a registered experiment, and tell the user at once.
- **Decide on every open gap, tension, contradiction and hypothesis the source bears on** (below).
- **Write the claims card** (below).
- **Recheck the discovery cards.** Run `python3 tools/mesh.py discover --recheck` and take every dissolved, strengthened, weakened or re-opened item to the user (`brain-mesh-discover` section 8). It ends with what the new source moved among the routes: opportunities it brought, ingredients that arrived or went, and signals set aside that it reopens. Check too whether the source answers an outside lead or search already on record (`mesh.py outside`). A new paper that answers a seed is often the most useful thing it does.
- If the source was in `ledger/reading-queue.md`, `build` marks its reference card held by itself (by DOI, or first author, year, volume and page; set `status: held` and `held:: [[P012]]` by hand if it did not match). Revisit the gap or tension it was queued for.

### Decisions on gaps, tensions and hypotheses

A new paper may close a gap, settle a tension or a contradiction, or decide a hypothesis, and the brain must not go on treating them as open. The end of `place P012`, under **Decisions to record**, lists every open gap, tension, contradiction and hypothesis the source bears on that has no decision for it yet. Read each against the source and record one of these:

| Card | What the source can do | What to write |
|---|---|---|
| Gap | Measures what **What would close it** asks for | status `closed`, `- closed_by:: [[P012-014]] — why it closes it`, a `graded::` line |
| | Answers part of it | rewrite **Unknown** to what is still missing, add the evidence under **What is known**, a `graded::` line naming P012 (status unchanged) |
| | Shows where the answer is (a cited paper) | status `fillable`, queue the paper |
| Tension | Takes a side | add its card to `sides::` |
| | Accounts for both sides | status `explained`, `- explained_by:: [[H002]]` or the evidence, a `graded::` line |
| | Settles it by decisive evidence | status `resolved`, `- resolved_by:: [[P012-020]] — why it settles it`, a `graded::` line |
| Contradiction | Takes a side | add its card to `sides::` |
| | Makes both sides true (a moderator, a difference of method or definition) | status `explained`, `- explained_by::` the evidence or hypothesis, a `graded::` line |
| | Shows one side wrong | status `resolved`, `- resolved_by:: [[P012-020]] — why it settles it`, a `graded::` line |
| | Shows it was never a contradiction (a condition one card left out) | fix the cards, status `dissolved`, `- dissolved:: <why>`, a `graded::` line |
| Hypothesis | Tests a prediction | status `supported` or `refuted`, a `graded::` line naming the evidence |
| Any | Touches it but changes nothing | `- reviewed:: <date> P012 — untouched: <why>` |

Then follow the change through the ontology:

- `python3 tools/mesh.py impact <id>` on each card whose status changed, and review what rests on it.
- A closed gap: `check` flags experiments still planned against it. Amend or abandon them (`brain-mesh-experiment`) and record it with a `reviewed::` line on the experiment.
- A resolved tension: `check` flags the hypotheses written to explain it. Re-grade them.
- A resolved tension usually means a finding changes too. Its contested status may go, or a sibling finding may be needed for the conditions now understood.
- `gapsdoc` rewrites the research-gaps document. The reading queue drops closed gaps and resolved tensions by itself.

Once the source is integrated, `check` warns about every open gap, tension or hypothesis it bears on that still has no decision.

### The claims card

Every paper, preprint, thesis or report gets a claims card, `P012-claims.md`, written once the source's cards are linked to the findings.

1. `python3 tools/mesh.py claims P012` lists the source's claim cards, what each rests on and which findings cite it, and writes a skeleton.
2. Choose the **main claim**: what the paper says it shows. It is usually in the abstract and the last paragraph. Link the claim card that states it.
3. Choose up to five **sub-claims**, the claims the main one depends on, in the order the argument needs them. Fewer is better than padding.
4. On each claim's line, link:
   - the paper's own evidence: the claim card that states it, and the observations or models it rests on;
   - the findings, tensions, gaps or hypotheses it feeds, or write `no finding yet`.
   A finding linked here should cite some of that evidence. If it does not, add the evidence to the finding or drop the link.
5. Write **How far the evidence carries it** in your own judgement:
   - where the paper's evidence is strong;
   - where it is thin (single runs, overlapping error bars, untested conditions);
   - what the paper does not show.
6. Set status `checked` after comparing the card with the paper's abstract and conclusion.

## 9. Update the concept hubs

This is what the user reads, so it is not optional. For every concept the source says something material about:

- add to **What is known**, one line per point, citing the finding or evidence card;
- add or revise lines under **Relationships**, and the matching relation in Codes (`affects`, `measured_by`, `part_of`, `broader`, `related`). Every `affects` line starts its reason with its basis (`tested`, `correlational`, `proposed`, `inferred`), judged from the design of the study behind it, and the wording of the hub line follows that basis: causal words only for `tested` (`brain-mesh`, **Concept cards**);
- add to **Open questions**; extend **How it is measured** when the source uses a new method;
- put the source's key equations and figure panels for the concept under **Key equations and figures**, each with its evidence card and the works that card cites (`brain-mesh-concept-scan` step 7; `scan P012` lists the candidates);
- revise a line that the new source has overtaken, and do not leave contradictory lines standing;
- cite the works each point rests on. A line that states a fact from an evidence card cites the works that card cites, as `[[R0042-…|Keller et al. 2017]]` (or `[[P001-…|Lee et al. 2023]]` for a source in the brain), beside the evidence card, with the matching `- cites:: [[R0042]] — what it supports` line in Codes; `check` flags lines that leave them out. The generated block shows the works each evidence card cites and, under **Key references**, the works cited where its evidence cards are anchored. Cite no work just because it is listed;
- set `updated` to today.

## 10. Close

Set the source card's status to `integrated`. Rewrite the Overview in `MAP.md` if the picture has changed. Run `python3 tools/mesh.py build` until there are no errors (the decisions on gaps and tensions and the claims card are checked from here on), then `python3 tools/mesh.py log "add P012 <authors year> (<n> cards); <findings, tensions and gaps changed>"` and `python3 tools/mesh.py sync "add P012"`.

Report to the user in a few lines: the paper's main claim and how far its evidence carries it; cards by type; the contradictions it logged, explained or resolved; what the concept scan added (new facts by concept, citations added); the concepts proposed, for the user to adopt, fold or reject, one line each with its definition; findings added or re-graded; gaps closed or narrowed and tensions explained or resolved; new tensions and gaps; data sets and code carded; hubs updated; anything bearing on their hypotheses or experiments; what was not extracted and why; and the top of the reading queue: the ★ works bearing on research gaps, then works cited where open gaps and tensions rest, with their years and DOIs (the queue puts recent work first and marks foundational old works ⌛). If the session's files are temporary, hand back the vault archive.

## Lens pass: re-reading sources for a new question

Use this when a question needs a detail the cards do not hold but the papers may.

1. `python3 tools/mesh.py id L`, then add `## L003 — <the question>` to `ledger/lenses.md` with the date.
2. Use `index/coverage.tsv` to see which sources and units could hold the answer. Search the `_text` files for the terms, including every alias of the concepts involved, then read the pages. The marked PDFs show at a glance which passages already have cards.
3. Add cards with `- lens:: L003`. Apply the duplicate rules; a lens pass is where re-extraction duplicates creep in.
4. Under the lens heading record every source examined and what was found, including "nothing". A negative result is what later allows a gap to be called a gap.
5. Update the coverage lines of sources read more deeply, then run steps 6 to 10.

## Own results

The user's own experimental results enter exactly like a paper, with `kind:: own-result` on the source card and `- experiment:: [[E001]]` when they come from a registered experiment. Anchor the lab note or results file. When it is not a PDF, cards link to the paragraph with `[[P003_text#^b0002|open passage]]` in the Source line. Card every measured value, including nulls and failed runs, and card protocol deviations as limitations. Link the cards to the literature cards they replicate, contradict or extend. Own results get no special weight: a conflict with a paper is a tension. Then use `brain-mesh-experiment` to assess the outcome.