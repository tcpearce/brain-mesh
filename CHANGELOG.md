# Changelog

Newest first. Raise `VERSION` here, in the `VERSION` file and in `tools/mesh.py` together.

## 1.5.0 (2026-11-21)

Citations: every source's reference list becomes reference cards, and the reading queue suggests what to read next.

- **`refs P012`** finds a source's numbered reference list and writes `P012_refs.md`, one entry per reference with authors, year, title, journal or book, volume, pages, DOI, arXiv id or link, kind, and `cited_at::`, the paragraphs that cite it. Both the Nature and Cell style (`Surname, I.`, superscript citations) and the Science style (`I. Surname`, italic bracketed citations, no titles) are parsed. Citation places come from the PDF's fonts, so a count in brackets is not mistaken for a citation; without a PDF every bracketed number counts. The file is checked by hand, and missing titles and DOIs filled from PubMed or another record, before the next step. Author-year lists are not parsed yet.
- **`cite P012`** turns the checked list into reference cards, `references/R0001-<surname>-<year>-<words>.md`, one per cited work and shared by every source that cites it, matched by DOI, PubMed id, arXiv id, first author with year, volume and first page, or first author with year and title. Each card has a `cited_by::` line per citing source with its reference number and paragraphs, and status `not-held`, `queued`, `held` or `skip`. A work that is already a source in the brain is marked `held`, at once or at the next `build`.
- **BibTeX.** Each reference card shows its BibTeX; `build` writes `P012_refs.bib` per source and `references/library.bib` with every source in the brain and every work it cites. Source cards list their references by number. Reference cards show each citing passage with the evidence cards anchored there.
- **Reading queue.** `build` writes a generated section in `ledger/reading-queue.md`: works cited where a research gap rests (★, read first), works cited where open gaps and tensions rest, works cited near cards sharing concepts with a gap or tension, and works cited by more than one source; each with its DOI link and how often it is cited. The hand-kept table above it stays.
- **Checks.** Reference cards are checked for type, status, year, DOI form and a citing source; `check` warns when a reference list is extracted but not carded, and when two reference cards look like the same work. `merge` moves the dropped card's citations to the survivor. `health` lists works cited by several sources, and the frontier (MAP and health) now includes them.
- Docs: add-paper step 1 gains the references step; batch agents run `refs` and the orchestrator runs `cite` in turn; gaps rung 2 starts from the works cited where a gap rests; housekeeping item 10.

## 1.4.1 (2026-11-21)

- **Builds on Windows match builds elsewhere.** Files are always written with LF line endings, and every path the tooling writes into a file (the card index, the marked PDFs' links, the marking signature) uses forward slashes. Before, a build on Windows rewrote files with Windows line endings and back-slashed paths, so they no longer matched the repository and `git pull` refused to run.
- Vaults get a `.gitattributes` that keeps text files in LF and treats PDFs and images as binary.

## 1.4.0 (2026-11-21)

Deciding, as the brain grows, whether a new source updates an existing card or needs a new one.

- **Identity rules** in add-paper step 8: what makes two cards of each kind the same card (finding: same proposition and scope; tension: same settling question; gap: same closing measurement; hypothesis: same predictions), with the one-sentence test against lumping and the agreement test for conflicting evidence. Housekeeping gains rules for splitting and merging synthesis cards.
- **Scoped findings.** Findings carry `when::` lines for their scope. `check` warns when a finding cites evidence outside its scope.
- **Agreement check.** `check` warns when a finding's supporting cards from different sources measure the same quantity under the same conditions and disagree beyond their errors.
- **Placement report.** New command `place P012`: for each new card, the findings, tensions, gaps and hypotheses it bears on, and whether it fits within a finding's scope, lies outside it, or conflicts with what the finding cites; plus the results that bear on nothing yet.
- **Grading history.** `graded:: <date> <status> — <why>` lines on findings, tensions, gaps and hypotheses; `build` starts the history where there is none, and `check` warns when a status changes without a new line.

## 1.3.0 (2026-11-21)

From the user's first look at the test vault in Obsidian.

- **Source folders named after their papers.** `build` names each source folder after its source card (`sources/P001-lee-2023-principal-odor-map/`), so papers can be told apart in Obsidian's file list. A new source starts as `sources/P012/` and is renamed once its source card exists. Links are unaffected; the PDF tags are regenerated with the new paths.
- **Equations in LaTeX.** New command `equations P012` lists displayed equations with their boxes; `figure P012 <page> <box> eq4` crops one (`eqf5b` for an equation inside Fig. 5B); new code `equation::` holds the LaTeX, displayed in the prose as a `$$` block that Obsidian renders, with the cropped original embedded beneath; new command `latex <card>` draws the transcription beside the original for checking. `check` flags Codes and prose that disagree on an equation, unbalanced braces or `$` signs, and equations without an anchor. Numbers inside equations no longer count as uncoded result numbers.

## 1.2.0 (2026-11-21)

Housekeeping gaps closed.

- **Retractions.** `retracted::` on a source card (or a single card) now has effect: every card resting on the retracted evidence, directly or through other cards and including concept hubs, is a warning until `- retraction_checked:: P012 — <what changed>` records its review; `check` warns until the source card's prose states the retraction; the marked PDF gets a RETRACTED banner; hubs label retracted cards; `health` lists retracted sources with dependants still to review. `impact` and these warnings share one dependency walk.
- **Published corrections.** `anchor P012 --correction notice.pdf` appends each correction to `P012_correction.pdf` (sealed, marked) and its paragraphs to `P012_correction_text.md` as `^c####`, numbered on so earlier anchors never move. A card with `corrected::` must anchor into the correction. `health` lists corrected sources.
- **Renamed cards.** `build` restores a card's id when its file was renamed without it, from the card's `- id::` line, keeps the user's wording as the slug, adds a renamed concept's new name as an alias, and rewrites the links Obsidian had pointed at the new name.
- **Tests** for `health`, `impact`, `merge`, retractions, corrections and rename repair.

## 1.1.0 (2026-11-21)

From the user's review of the first test on real papers.

- **Supplementary material first.** Add-paper has a new step 0: before reading, list the supplementary material and released data, fetch what can be reached and ask the user for the rest. `anchor P012 --si <files...>` seals it: supplementary PDFs are merged, anchored as `P012_SI_text.md` (paragraphs `^s0001`) and marked as `P012_SI_marked.pdf`; data files and code are sealed as `P012_SI-<name>.*` and can be cited (`anchor:: SI-<name>`), with values checked against them. `check` warns while a source lists its supplementary material as missing.
- **Figure reading.** New command `figure`. `figure P012 <page>` gives a page image with a coordinate grid and an inventory of captions, panel letters and pictures. `figure P012 <page> x0,y0,x1,y1 F2c` reads one panel from the PDF's vector drawing: every bar, marker, error bar and line vertex, converted through the axis tick labels (tick marks where present), with a reading error per row that allows for the fit, the tick placement and drawings made on a coarse coordinate grid, plus plausibility checks (outside the axis range, one-sided or asymmetric error bars, series missing from the legend). For a bar chart that is a picture, `--yticks` measures bars and error bars from the pixels. Values with `via:: figure` must carry their reading error and are checked against the panel's data file.
- **Coded numbers.** `value::` may appear several times on a card; new `stat::` for test statistics. `check` flags an observation whose prose states result numbers but has neither.
- **Missing evidence, per card.** An observation without `obtained_by` and a claim without `based_on` are now warnings on the card, unless `missing:: method` or `missing:: basis` records that the source gives none (other kinds: data, statistics, sample-size, definition). `gaps` lists these lines as gap candidates, marking those recorded before the supplementary material was read.
- **Links between papers.** `neighbours` ranks candidates in other sources by the concepts they share, rare concepts weighing most, and shows the shared concepts. On the test vault it ranked four of the six links found by reading within the top two.
- **Rounded tick labels and counts.** `--yticks` also overrides the tick values of a vector panel, for labels printed rounded (-0.22 for -0.225); `figure` warns when tick labels do not lie on a straight line. New concept kind `count` (`sample-size`): counts of different things are skipped by the duplicate and parallel-result checks.
- **Batch ingest with agents.** New document `brain-mesh-batch`: prepare and seed the vocabulary in one session, extract with one agent per paper in parallel (each writing only its own folder, new concepts staged in `P012_concepts.md`), then merge. New commands `progress P012` (where a source's extraction stands, for resuming) and `staged` (proposed concepts with the existing ones they resemble). `check P012` treats links to its own staged concepts as warnings.

## 1.0.4 (2026-11-20)

Found by rebuilding the test vault from a fresh clone.

- Builds are now identical on every machine: lists ranked by count break ties by name. Before, the "Appears alongside" line of concept hubs could reorder between runs and show up as changes in git.
- The vault name that the PDF tags open is recorded in `MESH.json` (`obsidian_vault`) when a vault is created, and by `upgrade` if it is missing. Before, it was taken from the folder name at each build, so a clone in a differently named folder rewrote every marked PDF.

## 1.0.3 (2026-11-20)

Also from the first test on real papers.

- New command `unread <P###>`: lists the paragraphs of a source that no card is anchored to. On the two test papers it found six statements the first pass had missed.
- Add-paper instructions: the verification step now runs `unread` and reviews each listed paragraph, as well as viewing the marked pages.
- Marking: the legend at the top of page 1 is no longer cut off.

## 1.0.2 (2026-11-20)

Found by the first test on real papers.

- Marking: PDF search now expands typeset ligatures, so a locator phrase containing "fi" or "fl" is found on the page.
- Marking: each tag now sits immediately left of the column holding its highlight, so on a two- or three-column page a tag is beside its own passage. A page margin takes the full card id; a gutter between columns takes the card number alone.
- Marking: a card with two anchors that resolve to the same passage gets one highlight, not two.
- Checks: a value written with a thousands separator in the prose (5,000) now matches the same value in Codes (5000).
- Add-paper instructions: choose locator phrases made of plain words, avoiding symbols, operators and words split by a line-break hyphen.

## 1.0.1 (2026-11-20)

- Vaults kept in their own git repository: `init` writes a `.gitignore`; generated files no longer carry the build date, so they change only when the content does; the setup document explains what to commit, pull and push.

## 1.0.0 (2026-11-20)

First version.

- Card format: human-readable part first, then `## Codes`; one statement per evidence card; concept cards as living hubs.
- Tooling `tools/mesh.py`: anchoring, batch card writing, link expansion and mirroring, checks, duplicate rules, concept hub and source lists, search, condition matrix, gap scan, research-gaps document, health report, impact tracing, merge.
- PDF ground truth: sealed originals with checksums, marked copies with each card highlighted on the page.
- Six instruction documents under `skills/`, a loader skill under `loader/`, a demo vault and tests.
