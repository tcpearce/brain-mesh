# Changelog

Newest first. Raise `VERSION` here, in the `VERSION` file and in `tools/mesh.py` together.

## 1.24.1 — 2026-11-23

Figure and equation crops are WebP. In a twelve-source vault 264 crops took 48.7 MB as PNG, a quarter of the working tree and about 4 MB for every paper added; as WebP at the same pixel size they take 10.3 MB.

- **`figure` writes WebP** (`P012-F2c.webp`, `P012-eq4.webp`) at 300 dpi as before, at quality 80 (MESH.json `"crop_quality"`: 1 to 100, or `"lossless"`). It needs Pillow; without it the crop is a PNG as before. A panel the vault already holds as PNG is cut again as PNG, so the cards that embed it stay right.
- **Thin coloured lines are protected.** Lossy WebP halves the colour resolution, which fades one-pixel coloured lines. Each crop is compared with its rendering over the inked pixels, and one that would differ by more than a set amount (28 dB) is written lossless, every pixel kept. In the vault above that is 22 crops of 264.
- **`crops`** reports the room the crops take and what converting would save, and changes nothing. **`crops --convert`** (optionally for named sources, with `--quality N` or `--lossless`) writes each PNG crop as WebP, rewrites every embed and mention of it in cards, hubs, scan files and the user's notes, removes the PNG and logs the change. Then `build`. Git keeps the PNG in history, and `figure` can cut any crop again from the PDF.
- `scan` matches a figure or equation to its hub embed and its `not_key::` line by name without the extension, so decisions recorded under the PNG name still stand. `latex` reads a crop in either format. `*.webp binary` joins `.gitattributes`, in new vaults and at `upgrade`.

## 1.24.0 (2026-11-23)

Lists that grow with the vault are capped, and nothing is lost. An LLM reading the vault no longer pays for them at every build.

- **A hub's long list moves to its own page.** A concept card lists the first cards of each kind by title, as before. The rest used to follow on one line of links by id, and on a concept most cards name (`species`, `preparation`) that line had reached 15,000 tokens. Up to twenty are still linked on the hub; more go to a generated page, `index/hubs/<concept>--all.md`, which lists every card that names the concept by source and type. The hub links it with a count for each source. Every card is still one link from its hub, the cards' own links are untouched, and the page is removed when the list fits the hub again. On a nine-paper vault the largest hub falls from 62,000 to 19,000 characters. `"hub_inline"` in `MESH.json` sets the twenty.
- **`check` and `build` count warnings by kind once there are more than forty**, with an example of each kind. Every error is still printed. Every line is in `index/check.txt` after a build and under `check --all`; `"check_show"` in `MESH.json` sets the forty. Build output on the same vault: 13,400 characters to 3,600.
- **`gaps` prints the first eight rows of each section**; `gaps --all` prints every row.
- **`discover` with no miner named is an overview**: the top three signals of each miner on one line each. A named miner prints its details as before, and `discover --full` prints every miner in full. 85,000 characters to 15,000.
- `check --all` no longer takes the flag for a source id.

## 1.23.7 (2026-11-23)

Found while measuring how the tooling scales on a vault grown to four times its size.

- **A miner's scores no longer depend on which miners ran before it.** The rarity weighting every miner shares read a variable that the `links` miner reassigned, so every miner after it (`unify`, `recognised`, `limits` and the others added in 1.21.0) was scored with counts taken over another set of cards whenever `links` had run first. `discover links unify` and `discover unify` now rank `unify` the same way, and `zoom` and `routes` rest on the intended weights. Expect some scores in `discover` to move.
- **Scoring pairs of cards is about twice as fast on a large vault.** A card's own part of the comparison (its concepts, their summed weight, its title words) is worked out once for each weighting. `zoom` on 4,400 evidence cards: 14 s to 6 s, with the same output.
- **`routes` prints the same lines on every run.** The three techniques named in "obtained by" were picked in an order that varied between runs when counts tied.

## 1.23.6 (2026-11-23)

What the review of pull requests #41 and #43 found, each seen on real papers.

- **`check` is no slower for reading data files.** Reading workbooks and deposited CSV files had taken `check` on a twenty-source vault from 15 to 23 seconds: every workbook was opened a second time whenever a value was not found, whether or not the card had a `computed::` line, and every value was compared with every number of the file. A workbook is now opened once for both uses, its rows are read only for a card that has a `computed::` line, and a number is looked up in a sorted list. Back to 15 seconds, with the same warnings.
- **A work cited only by a supplement's list is read back as cited.** `ref_cites` did not read `ref S1`, so such a reference card dropped out of its paper's reference list, of the reading queue's counts and of every other reader of `cited_by::`.
- **A numbered protocol in a supplement is not taken for references.** A supplement's numbered list is kept only when at least half of its entries carry a year; otherwise `refs` leaves it out and says so. (A numbered algorithm in one supplement had become five reference entries.) A supplement's list is also parsed in its own style when that differs from the main list's.
- **Author-year entries.** A publisher's place (`Montclair, NJ: Author.`) no longer starts an entry, and APA's `Journal, 30(5), 342–361` gives journal, volume and pages.
- Known limits: an author-year list with no comma between surname and initials and no brackets round the year (`Buck L, Axel R. 1991.`) is read only in the PLOS and eLife forms; book entries give no publisher field.

## 1.23.5 (2026-11-23)

- **A trailing `DOI: https://…` no longer swallows the journal.** eLife ends each entry with a `DOI:` label before the link; the reader stripped the link but left the label, so the volume and pages stayed inside the title and 68 of one paper's 75 entries came out wrong. The label is stripped with the link, and the match is case-insensitive.
- **An entry whose year is followed by no punctuation is found.** `Abraham NM, Spors H … (2004) Maintaining accuracy …` (the Journal of Neuroscience style) has no stop after the closing parenthesis, so an unnumbered list in that style split into nothing. One paper went from no list found to 45 entries, 41 traced.

## 1.23.4 (2026-11-23)

- **eLife-style lists** (issue #45, same code path). `Alvarez-Melis D, Fusi N. 2020. Title. Journal 7:20.` has the initials against the surname like PLOS but a bare year with no parentheses, and the heading runs straight on into the first entry. All three now read: the run-on heading is recognised for an author-year list as well as a numbered one, and the entry parser takes the year in parentheses or bare.
- **Soft hyphens and zero-width spaces are ignored when reading references.** A PDF leaves them inside words (`Alvarez-­Melis`) and URLs, which stopped a surname, a DOI or the heading itself from matching. They are removed from the text the reference reader works on; the anchored text is untouched.
- On the three papers added to a vault today, `refs` went from unusable to 58 of 58, 15 and 75 entries, with 58, 3 and 56 traced to the paragraphs that cite them.

## 1.23.3 (2026-11-23)

- **Square-bracket citations are traced** (issue #44). The fallback that reads citation numbers from the text matched round brackets only, and one stray superscript was enough to stop it running at all, so a paper citing `[1]`, `[2,3]` traced almost nothing: Snitz et al. 2013 gave 1 of 58 references a paragraph. Square brackets are read too, and the font-based pass is trusted only when it found citations for a fair share of the list. The same paper now traces 58 of 58.
- **PLOS and BMC style entries are parsed** (issue #45). `Amoore JE (1977) Specific anosmia and the concept of primary odors. Chemical Senses and Flavor 2: 267-281.` has the initials against the surname, the year after the authors and a colon before the pages, and 14 of Snitz's 58 entries came out with no authors or no year. The authors are rewritten as `Amoore, J. E.` (with `; others` for et al.) and the colon as a comma, and the entry then goes through the author-year reader added for #5. An `In: … editors.` entry is an incollection. A classic numbered entry, whose year sits at the end, is untouched.

## 1.23.2 (2026-11-23)

Three reference lists `refs` could not read.

- **A numbered list run together in one paragraph** (issue #23). Some two-column PDFs come out as a few long blocks, `References 1. Dulac, C. & Torello, A. T. … 2. Belluscio, L. …`, and the heading sits in the same block as the first entries, so `refs` found no list at all and said, wrongly, that the list was author-year. A heading with the list run on after it now starts the region at that paragraph, and a list broken in two by the Methods is picked up in both places so its numbering continues. The paragraphs between the two parts count as text, so citations in the Methods are traced too.
- **Author-year lists** (issue #5), common in chemical senses, psychophysics and food science, are parsed: entries are split at a surname followed by initials and a year, the fields are read by moving the year to the end and reusing the same field parser (so journal, volume, pages and DOI come out as before), and the citing paragraphs are found by surname and year, `(Snitz et al. 2013)`, `(Haddad and Sobel, 2008)`, `Laska et al. (1999a)`, with the letter of `1999a` kept. Entries are numbered in the order printed, so `cite` and `cites:: ref N` work unchanged.
- **A supplement's own reference list** (issue #28). Its numbers mean its own works, not the main text's, so cards anchored in the supplement were told to cite the wrong papers. `refs` now writes it as entries `S1` onwards, traces the supplement's paragraphs against it (through `P012_SI.pdf` where there is one), and `cite` makes cards from `S` entries like any other. Reference numbers are carried as written throughout, and `S` entries sort after the main list.

## 1.23.1 (2026-11-23)

- **A panel with a second y axis is no longer read silently through the first** (issue #15). `figure` calibrates one y axis per box, taking whichever side carries more tick labels, so in a panel with a left and a right axis every series was converted through one of them and the other came out wrong, with nothing to show it. It now detects numeric tick labels on both sides of the plot area, prints both ranges, says in the CSV header which axis the values went through, and flags every row with a y value ("second y axis: verify this series' scaling"). Read the panel once per axis, with a box that takes in only that axis's labels, or pass `--ycal value@position,...` for the axis you want: a calibration given by hand is trusted and the flag goes.

## 1.23.0 (2026-11-23)

- **A summary the authors computed from a data file is recomputed from its rows** (issue #30, the part left open). A mean or an s.e.m. the paper prints sits in no cell of its deposited source data, so `check` could only report "value not found". A card may now say how the number was made, `- computed:: <op> of <column> [where <column> = <value>] [in <sheet or file>]`, with `mean`, `median`, `sum`, `count`, `min`, `max`, `sd` or `sem`. `check` reads the file (`.csv` and `.tsv` directly, a workbook through openpyxl), recomputes the number and compares it with the value: the paper's own summary is now checked against the rows it rests on, and when they disagree the warning names both numbers. A line `check` cannot read leaves the value unchecked and says why. Columns and sheets are matched ignoring case and punctuation; anything after ` — ` is a note.
- **A deposited `.csv` or `.tsv` is read at full precision**, like a workbook since 1.22.1: a value the card rounds from it is confirmed within half a unit in its last decimal place. A number printed in the running text still has to match as printed.

## 1.22.2 (2026-11-23)

Three false alarms cleared and a title that keeps its capitals (issues #31, #36, #39, #40).

- **`check` reads a value's number before its note** (issue #31). The value of a `value::` line is now the first number that stands on its own before the note in brackets. A digit inside a label or name (`pEC50`, `OR1A1`, `GCaMP6f`, `TM5`, `C6–C25`) is not a value, so `= unchanged (pEC50 of R-carvone at OR1A1)` and `= pEC50 −6.29` no longer warn "value 50 not found in the anchored source". The same reading is used when the value is compared with the card's prose. A unit may still follow the number (`5 nM`, `5nM`, `25%`).
- **`propose` keeps the capitals an alias spells** (issue #36). Without `--title`, the title is made from the slug with each word cased as an alias spells it: `propose gnrh-neuron … --alias "GnRH neuron"` gives "GnRH neuron", `class-i-film` with "class I films" gives "Class I film", and "cAMP reporter assay" keeps its small first letter. Nothing is lowered. A concept note made by hand in `concepts/` is titled the same way.
- **A dismissed pair no longer warns as unlinked parallel results** (issue #39). A `values:<card>~<card>` key dismissed on the contradictions register, in either order, settles `check`'s parallel-results warning for the pair, and the dismissal says so. `contradictions dismiss values:<card>~<card> "<why>"` now also takes two results with the same variable and conditions in different sources whose values do not clash, which could not be dismissed before and could only be cleared by a link.
- **A lookup resource does not group its users** (issue #40). A data-set card with `- role:: lookup` (a chemical database, a supplier's catalogue, a compendium) is left out of the independence grouping, directly and as the parent of a derived data set. `independence` names the lookup resources two or more of the sources use as not counted, and `check` questions a role other than `data` or `lookup`.
- Open: #5, #15, #23 and #28 are untouched. Of #30, CSV, TSV and workbook files are now read (1.22.1); a `computed::` line for a mean or other summary taken from a data file is not done.

## 1.22.1 (2026-11-23)

`check` reads the source-data workbooks a card is anchored to (pull request #38).

- **`check` reads source-data workbooks** (issue #37). An `SI-…` anchor to an `.xlsx` or `.xlsm` file was never read, so every value anchored to a paper's source data warned "not found in the anchored source" (77 in the odour-coding vault). With openpyxl installed (an optional dependency, like PyMuPDF), its text cells join the anchored text, so `loc::` phrases and labels are found, and its numeric cells are matched exactly or, since a cell holds full precision, within half a unit in the last decimal place the card prints (a cell of 0.8230456 confirms 0.82). Rounding is accepted only for workbook cells; text sources still need the printed number. A mean or other summary the authors computed from the rows is in no cell and still warns: anchor the passage or legend that prints it, or mark the value derived. Without openpyxl nothing changes. In the odour-coding vault the warnings fell from 77 to 45.

## 1.22.0 (2026-11-23)

What the ontology cannot name: found by comparing the brain with something outside it.

- **`beyond terms`** (no network): phrases and acronyms that two or more independent groups of sources use in their anchored text, and phrases in the titles of the works they cite, that no concept names. Each comes with its count, its sources, the concepts beside it and a paragraph to read. A piece of a longer concept name, a paper's furniture (competing interests, funding, repeated page headers) and stock statistics phrases are not raised; `"beyond_stop"` in `MESH.json` adds a vault's own. A concept or `topic:<slug>` narrows it to the paragraphs that name it.
- **`beyond pointers`** (no network): paragraphs where a source itself points outside the brain, to another field ("by analogy with", "as in vision", "originally developed for", "has transformed") or to what a question would take ("future work could use", "would require").
- **`beyond probe`**: any list of names from outside (Claude's own map of a topic, MeSH headings, a review's headings, a web page) sorted by where each stands in the brain: a concept already; in the sources' text with no concept; only in the titles of cited works; nowhere in the brain. Names are matched across case, plurals, British and American spelling, hyphens and joined words, and inverted headings ("Receptors, Odorant").
- **`beyond wiki`**: the same for the Wikipedia articles of some concepts or of a topic's leading concepts, the links of each article's opening section first; plus the links Wikipedia makes between two concepts the brain has and does not connect, the ties the brain makes that neither article does, and with `--family` the other members of an article's categories. The article is the one named by `- wikipedia::` on the concept card, else found by title, slug, alias or search; a name several articles share is said. Pages are cached in `ledger/beyond/wiki/`, which syncs, so a copy with no network uses what another fetched; with neither, the command says how to go round. Only titles are sent.
- **`beyond works`**: a list of works from outside (a review's reference list, related or citing articles), by DOI, PMID or title, sorted into sources already, cited and held, cited and not held, and unknown to the brain.
- **`beyond judge`** and `ledger/beyond.md`: a verdict on a term, a pair, a paragraph or a work (`skip`, `concept`, `alias`, `lead`, `tool`), recorded with where it stood that day, so it is not raised again. **`beyond`** alone lists the comparisons made, the topics never compared, and what was added since has moved: a lead or tool a new source now names, a term set aside that twice as many sources now use, a proposal not yet adopted. `discover --recheck` prints the same.
- **Tools from other fields.** `outside <need>` now ends with the cross-field question (the problem said without this field's words; which fields have it; what they use) and lists the outside tools kept for that need; `routes` names the tools kept for the import pass; `routes --readiness` counts the topics compared with an outside map.
- New skill `brain-mesh-beyond`: the frames, a session, what each class means and what to do, the import pass by the form of the problem, Wikipedia, and the recheck. `brain-mesh-discover`, `brain-mesh-access`, the map, the loader and the README point to it.
- Not done: the tooling fetches Wikipedia only. MeSH headings, related and citing articles come through the session's literature connectors or web tools and are compared with `probe` and `works`. A name is matched as written, so a synonym the brain files under another name reads as absent until it is an alias.

## 1.21.0 (2026-11-23)

Discovery matched to the ways a paper makes a contribution, focused by what the user can do, checked outside the brain, and kept current as sources arrive.

- **Fix: `discover` and `zoom` crashed** (`TypeError: 'str' object is not callable`) in any vault holding a contradiction candidate not yet on the register. A loop variable in the contradictions miner overwrote a helper the later miners call (since 1.13.0; the demo vault has no unlogged candidate, so no test met it). Tested now.
- **The lens.** One index of the ontology, built once per run and read by every new miner, route and verdict: the techniques each result was obtained by (through `obtained_by::` and the method card's technique concept), which techniques measure each variable, the systems (species, preparation) each card was observed in, the data it uses, the limitation cards against each technique, the independent group of each source, what rests on each card, and which sources cite which works.
- **`routes`.** Twenty routes to a contribution, each a checklist of ingredients read from the lens: resolve-contradiction, unification, joining-literatures, pooling, framework, fill-gap, decisive-test, mechanism, extension, replication, scale, tool-transfer, concept-transfer, new-phenomenon, overturn-assumption, existence-proof, new-method, new-model, new-resource, translation. `routes [topic:<slug> | <concept> | <id>] [--route r] [--reach in|partner|unclear|out|all] [--budget n]` lists the opportunities, best first: each open need under the route it feeds, with the ingredients present, missing and not coded, its reach, the next step and the proof the route needs. `routes --list` describes the routes. `zoom` shows the routes in reach per topic.
- **Nine miners** feed the routes that had none: `unify` (one driver of several outcomes; one form fitted to several quantities), `tools` (a technique that measures a variable elsewhere and that an open question's evidence never used), `mechanism` (relations never tested by intervention), `recognised` (open questions two or more independent groups state themselves), `cornerstones` (much built on, thinly supported), `bottlenecks` (techniques carrying limitations; variables never measured), `ceilings` (one score across methods), `data` (open data only its source has used; data that questions turn on and that is closed), `limits` (stated impossibilities). Three reading passes: import, limits, application.
- **The research profile.** `PROFILE.md` and `mesh.py profile`: the techniques, organisms and preparations the user has, can reach through a partner, or cannot use; the designs they run; the data they can access; what they bring; where they could apply a finding. A mark on a broader concept covers the techniques under it. Every opportunity gets a verdict (in reach, with a partner, unclear, out of reach), the best of three ways of doing the work: from the published record, by reanalysing data its cards use, or by measuring again. The profile is the user's statement, like priority; nothing out of reach is dropped.
- **Outside the brain.** `outside <need>` prints the brief for checking one need against Claude's own knowledge of the field and then the literature: the sources with their DOIs, search terms from the concepts and aliases, and a question for each ingredient the ontology lacks. `outside add <need> nothing|answered|partly|lead ...` records what came back in `ledger/outside.md`; a `lead` is what Claude believes without a source. `routes` counts a need checked and found open as having the ingredient `outside`, and asks again when the check is stale. Nothing from outside goes onto a card until its source is carded.
- **Contingent on the brain, and updateable.** Nothing discovery shows is stored as a result. `routes --record` keeps what the routes showed; `routes --changes`, also printed by `discover --recheck` after new sources, says what moved: opportunities a new source or card brought, ingredients that arrived or went, reach that changed, signals set aside that a source added since reopens, and what is gone. A rejected signal now comes back into `routes`, `zoom` and the frontier report when a source added since bears on it, as `discover` already showed it.
- **`routes --readiness`**: how much of each dimension discovery reads is coded, and which routes each limits.
- Signals mostly about low-priority concepts are never raised as opportunities.
- `brain-mesh-discover` is rewritten around the session loop (zoom, routes, verify, supply the missing ingredient, check outside, propose, record), with what discovery reads from the ontology, the research profile, the routes, the outside check and the changes after new sources. The other skills, the README and the vault's `CLAUDE.md` point to it.
- Not done: the tooling cannot tell whether a technique can set a variable (only whether it measures it), so `mechanism` cannot say whether the intervention is within the profile.

## 1.20.2 (2026-11-22)

Three false alarms of `check` met in a six-paper batch (issue #34).

- **Duplicates read the value's number, not a digit inside a name** (issue #34). The duplicate test compared the first number in each card's value; in `= unchanged relative to consOR1` that was the `1` of `consOR1`, and two values with no number at all compared equal. A number must now stand on its own (not inside `consOR1`, `TM3` or `6x55`), and two values with no number are the same only when their words are. `split` uses the same test when it skips a card that duplicates one already written.
- **A reanalysis is not a duplicate of the card it bears out.** A card of Claude's own recomputation from a source's data (`origin:: claude`) that `supports::` or `replicates::` a card of the same source repeats that card's number on purpose: a trial file reproducing a paper's d′ of 2.02, for example. `check` no longer calls it a duplicate. The same card in the authors' voice still is.
- **Near-identical concept names can be told apart.** The warning asked to "say in each definition how they differ" but never read the definitions, so `class-i-odorant-receptor` and `class-ii-odorant-receptor` were warned of forever. When each definition links the other concept, the pair is taken as told apart; the warning now says so.

## 1.20.1 (2026-11-22)

Lessons from a six-paper batch with parallel agents (`brain-mesh-batch`, `brain-mesh-add-paper`).

- **The verifying agent's brief** is written out: every observation and model card and a sample of 20 others against the pages and data; an independent recomputation of everything the extractor derived. It may also correct the paper's `P012_refs.md` and figure data files, which a verifier needed and was not allowed to fix.
- **While the agents run** the launching session runs no `build`, `mark`, `sync` or `upgrade`, commits shared files by path if it must, and asks the user to pause Obsidian Git.
- **Registration lists every unit**, including Extended Data, the reporting summary, a peer-review file and source data. An agent found a reporting summary that contradicted the Methods and that registration had not listed.
- **`species` and `preparation`** are seeded as the categorical condition variables every card's `when::` lines need. Agents had each proposed their own.
- **Propose sparingly.** About 100 concepts were proposed for six papers, many of them method detail; more than about 15 for one paper means the bar is too low.
- **Extended Data anchors** use the main PDF (`F6a, p32`): eleven cards had pointed them into the supplementary PDF, a peer-review file.
- **References.** Agents may cite by number (`cites:: ref 12`) where they write a reference list by hand, and the merge runs `cite P012 --update` (1.20.0).

## 1.20.0 (2026-11-22)

- **`cite --update` applies a checked reference list to the cards made before it was checked** (issue #27). In a batch, `cite` runs at registration, before the extraction agents correct each `P012_refs.md`, and `cite` never overwrites a field. With `--update` the checked list becomes the truth for the cards only this source cites, and is not applied to works held in the brain:
  - their fields and heading are rewritten from it;
  - a card that turns out to be another card's work is merged into that card, which keeps its citations and links (`merge`);
  - a citation that has moved to another card is taken off the old one.
- **A reference carrying the citing paper's own identifiers is refused** (issue #26). This covers its own DOI, or the reference card of the paper itself. `refs` also strips the page furniture that put them there: page counters ("6 of 6"), publisher download stamps (with the reader's IP address), author-manuscript running heads, and the paper's own DOI.
- **`cite` links `- cites:: ref 12 — …` lines** in the source's cards, cited cards included, to the card of reference 12. A card written before the reference cards existed can cite by number, for example in a paper whose reference list is written by hand (issue #23).

## 1.19.0 (2026-11-22)

Discovery by progressive disclosure: the brain as a hierarchy, revealed on a need-to-know basis.

- **`zoom [topic:<slug> | <concept> | <id>] [--budget n] [--explored "<note>"]`.** Each level fits in about n tokens (1,000):
  - `zoom`: the topics, hottest first, with their size, findings, open contradictions and gaps, signals and when each was last explored; where topics meet and where no card joins them; the strongest signals.
  - `zoom topic:<slug>`: its concepts ranked by need to know, its findings and open questions, the signals inside it, and its joins to other topics with the concept pairs that make them.
  - `zoom <concept>`: hub facts, relations with their basis, broader and narrower concepts and what it appears with, the conclusions that hold it, its signals, its evidence and the parts of sources not read in full.
  - `zoom <K | X | V | G | H | T | S | E id>`: what it says, its sides or support with values, ways out and what would settle it, what works on it, its history.
  - `zoom <evidence id>`: the card, its codes and the passage on the page. `zoom <P012>`: the study profile, claims, the topics its evidence falls in and what was not read.
- **Topics** are computed: concepts tied by the cards that hold them together (each card weighted 1/(k-1) for k concepts) and grouped by the Louvain method, in a fixed order so the same brain gives the same topics. A `broader::` or `part_of::` link ties a concept to its parent as strongly as the strongest pair, so a curated hierarchy wins. Low-priority and count concepts are left out, so a vault's generic vocabulary never organises it.
- **Heat** is need to know: the open contradictions, tensions, gaps, hypotheses, seeds and unfinished experiments holding a concept, plus each miner's ten best fresh signals by rank; doubled for a high-priority concept (1.5 elevated); halved when it was explored and nothing holding it has changed since.
- **`--explored "<note>"`** records a branch worked in `ledger/explored.md`. `discover --focus topic:<slug>` mines a whole topic.
- `brain-mesh-discover` now works top-down (**Working top-down**): the hottest branch, the miners inside it, down only where a signal survives, a shortlist, the branch recorded; one subagent per branch where the session can start them. The access skill, the map, the README and the vault's `CLAUDE.md` point to `zoom` for exploring and `ask` for answering.

## 1.18.1 (2026-11-22)

- `split` gives each new card's duplicate check its own temporary file (`index/.new-<card id>-<process>.md`, removed even on error), so extraction agents can split their batches at the same moment. Before, every process used `index/.new.md`: two agents splitting together could read each other's card, or crash (on Windows, "file in use") with a batch left unwritten. `init` and `upgrade` ignore `index/.new*.md` (issue #25).

## 1.18.0 (2026-11-22)

A small context: a session can navigate, extract from and mine a large brain without filling its context with cards it does not need.

- **`ask "<question>" [--budget n] [--concepts a b] [--source P012]`**: what the brain holds on a question, best first, in about n tokens (2,500 unless set). It finds the question's concepts by name or alias (British or American spelling, plurals) and any card ids it names, then gives: those cards with their opening lines; the brain's conclusions (findings, tensions, contradictions, gaps, hypotheses, theories) with their grades; the definition and facts of the concept hubs the best evidence holds; the relations among the concepts with their basis; the most relevant evidence cards; and the parts of the sources holding them that were not read in full. A named card's own sides and support come first. Ranking weighs rare shared concepts, holding all of them, words in title and prose, the kind and status of each card, how much synthesis cites it, and priority.
- **`find` ranks by relevance**: the concept named first, then cards with the words in their title or linking the concept, findings and observations before background; 25 shown.
- **Short views.** `show` cuts a long generated list or `## Linked from` section to its first lines with a count; for a concept it gives the prose and Codes and the 15 cards that use it most. `--all` prints everything. `table` shows the 25 most relevant rows, taken from each source in turn (`--limit 0` for every row; `--out` saves them all). `place P012` groups a source's evidence by the finding, tension, gap or hypothesis it bears on (`--by-card` for the old layout). `facts` lists the 30 most relevant evidence cards. On the odour-coding vault: `show odour-intensity` 6,500 tokens to 2,200, `show P001` 9,700 to 2,300, `place P003` 11,400 to 2,500.
- **The main skill is split.** `skills/brain-mesh/SKILL.md` is now a 3,700-token map (card families, ids, grades, links, navigation, rules) that every session reads; the card formats, word for word, are in `skills/brain-mesh/FORMATS.md` (9,900 tokens), read before writing or changing a card. A session that only reads the brain saves about 9,000 tokens.
- **Context rules** in `brain-mesh-access` (section 2, **Keeping the context small**) and in the vault's `CLAUDE.md`: query through the tooling, never read a hub or `index/` whole, go down the layers only as far as needed, and hand wide sweeps to subagents that return only their conclusions. `brain-mesh-discover`, `brain-mesh-concept-scan`, `brain-mesh-write` (long drafts) and `brain-mesh-housekeeping` (audits) say how.

## 1.17.1 (2026-11-22)

Review fixes for 1.17.0 (linked files).

- **Other copies of the vault get linked files back.** Stopping tracking a committed file makes git delete it from every other copy at its next pull. `sync` now restores, after the pull, each linked file still in the history, checking an original against its recorded checksum; `linked --restore` does the same by hand. Without this, `linked --all` on one computer took the large PDFs out of every other copy, cloud sessions included.
- **An absent linked file is a note, not a warning.** It is true of one copy only, so counting it made `MAP.md` and `index/stats.json` differ between copies and each sync commit them back and forth. `check` prints it as a `note` line, uncounted.
- A marked copy's checksum is no longer recorded in `ledger/linked-files.md` (it changed with every rebuild, rewriting the ledger each time).
- `build` makes the standard folders when they are missing. Git keeps no empty folders, so a fresh clone could lack `data-sets/` or `code/`, and the test suite failed on a fresh checkout of this repository.

## 1.17.0 (2026-11-22)

- **Large files are linked, not committed.** A source file over the vault's size limit (`large_file_mb` in `MESH.json`, 10 MB unless set), whether an original PDF, a supplementary PDF or data file, or a marked copy, is kept out of git: it stays in its source folder, so every command and Obsidian work as before; it is listed in a managed block of `.gitignore`; and `ledger/linked-files.md` records its size, checksum and where to get it again (the DOI page, or "rebuilt by build" for a marked copy). `anchor` and `build` link such files as they write them, and `sync` links any it finds before committing. Large marked copies, rewritten whenever a source's cards change, no longer add a full copy to the history each time.
- New command `linked`: list the linked files; `linked --all` links the large files of a vault that had them before; `linked <file> --from <url>` links one by hand or records where it can be had; `linked --verify` checks that every linked original is present and unchanged. `check` names a linked original absent from this copy of the vault and where to get it.
- `sync` refuses to commit a binary file over the limit outside the source folders, naming it (text files are always committed), and `init` and `upgrade` add `ingest/` to `.gitignore` as the drop folder for papers and supplementary files waiting to be anchored (issue #22).

## 1.16.2 (2026-11-22)

From the first run of the reports on a real vault.

- `report methods`, **What existing data might answer**: each open question now lists first the data sets its own card points to (named on it, or used by the evidence cards it links through `uses_data::`), whatever their access, and only then the accessible data sets that share two or more concepts with it. Matching by concepts alone missed the data a gap card itself cites when each data set shared one concept with it.
- `report causal` and `table relations`: a contradiction or tension that holds both concepts of a relation is listed as "both concepts appear in V001", not "contested in V001". Holding both concepts does not make the card a dispute about that relation.
- A command whose output is piped to a reader that stops early (`... | head`, `... | grep -q`) now ends quietly with exit code 0 instead of a `BrokenPipeError` traceback. One test failed now and then for this reason.

## 1.16.1 (2026-11-22)

- `sync` with nothing new to commit now pushes any local commits the branch holds, such as the one made by finishing a rebase after a conflict, as sync's own message asks. Before, it reported "up to date" and left them unpushed (issue #21).

## 1.16.0 (2026-11-22)

Reports: eight dated documents assembled from the cards, for deciding what to do next.

- **`report <kind>`** writes `reports/<date>-<kind>.md`, every line linked to the cards it rests on, with a **Reading** section for Claude's judgement that a rerun on the same day keeps. `report all` writes the seven that need no argument; `report` lists the kinds and what has been written; `MAP.md` links the latest of each kind.
  - `frontier [--focus concept] [--top n]`: open contradictions, tensions, gaps by rung, hypotheses with no experiment, experiments not yet run, seeds and the strongest discovery signals, ranked, each with what would settle it and what works on it.
  - `contradictions [V001 X001 ...]`: a dossier for each open or explained contradiction and tension: the sides as an evidence table, what differs between them (conditions, methods, designs, samples, definitions, independence), what the miners point at, ways out, what works on it, decisions so far.
  - `theories`: each theory against each finding, what separates them, pairs nothing separates, findings none explains, discriminating predictions; with no theories, the claims a theory pass would start from.
  - `causal [--focus concept]`: every relation by basis, drawn as a graph; relations that carry weight without a test; chains with an untested link; effects looked for and not found.
  - `robustness`: each finding's sources, independent groups, designs and weak points; replication priorities; second-hand claims by what rests on them; load-bearing assumptions; each source's unread parts.
  - `methods`: designs and samples, techniques and who uses them, quantities not measured alike, methods untried elsewhere, data sets and code, and the accessible data sets that share concepts with each open question.
  - `novelty "<idea>" | <S001> [--concepts a b]`: the cards that already hold the idea's concepts together, whether it has been asked, what it must respect, then the three rungs: uncarded passages in held papers, unread works cited on its concepts, a starting query.
  - `changes [--since date|P012]`: new cards, status changes with reasons, decisions, priority changes, the discovery recheck, the log, and what waits for the user.
- New skill `brain-mesh-report`: what each report holds, the rules (a snapshot, never a source), what the Reading of each says, and which skill acts on what a report shows. The main skill, access, discover, experiment, gaps, housekeeping, write, the loader and the README point to it.

## 1.15.2 (2026-11-22)

- `cite` run again no longer makes a second reference card for a work it cannot key (no DOI, volume or title of three long words, as for a conference paper printed without its title). It now also matches the card whose `cited_by::` line already records the same source and reference number (issue #20).

## 1.15.1 (2026-11-22)

- README: a guide to using the tools well: the loop from adding papers to writing, what to ask for at each stage, the order to work the discovery miners in, how often to run each thing, what to expect at each vault size, and habits that pay.
- `brain-mesh-discover`: the order to work the miners in (check the ground, explain disagreements, extend what holds, stress the structure).

## 1.15.0 (2026-11-22)

What kind of study each source is, whether sources are independent, how far a relation is causal, and writing from the brain.

- **Study profile on every source card:** `question::`, `design::` (experiment, observational, reanalysis, computational-model, simulation, theory, review, method, case, other; one line per study, with what was done), `sample::`, `framework::`. `check` asks every extracted paper and own result for them; `schema` lists the designs and what each can establish.
- **Independence.** Sources that share a data-set card, two or more authors, or an author who is first or last on both, count once. `independence [K001 | P001 P003 ...]` shows the groups. `check` warns when a `probable` or `established` finding rests on one group and questions a `replicates::` link between sources on the same data; `health` and the gap scan count groups, not papers. `- independent:: [[P001]], [[P003]] — <why>` on a finding declares two sources independent for it.
- **Basis of relations.** Every `affects::` line starts its reason with `tested`, `correlational`, `proposed` or `inferred`. `check` warns about a line with none, and about `tested` where no cited source is an experiment. `facts`, the miners and the tables show the basis. Causal wording only for `tested` relations.
- **`definitions` miner:** one term defined or operationalised differently by several sources, one quantity measured by different techniques, two concepts that may be one thing, and open contradictions and tensions whose sides do not define or measure the quantity alike.
- **`table <concept ...|K001|X001|V001|G001> [evidence|relations|definitions]`:** the evidence, one row per card (study, design, sample, result, conditions, how obtained, limits, page) with the independent groups and what each design can establish; the relations a concept has, with direction, basis, evidence and what is unresolved; how each source defines and measures a concept. `--out` saves one with links.
- **`draft <file>`:** a worklist for auditing a draft against the brain. Per sentence: the works cited and whether the brain holds them (author-year, numbers against the draft's reference list, citation keys), the concepts, each number and the card that holds it, the likeliest cards, and what to check: a number on no card, causal wording beyond the recorded basis, a work known only second-hand, a logged contradiction that bears on it.
- **New skill `brain-mesh-write`:** writing a literature review or background section from the brain with every claim traced to a card and page, and auditing a draft claim by claim (supported, overstated, contradicted, not in the brain) with a corrected draft. The main skill, add-paper, batch, discover, access, gaps and housekeeping follow.

## 1.14.8 (2026-11-21)

- `contradictions add` writes the `sides::` lines of a new V card with the sides' card names, as every other typed link in Codes is written. Before, it wrote the bare ids (`[[P002-033]]`), which Obsidian cannot open (issue #19).

## 1.14.7 (2026-11-21)

- A card with no loc phrase, such as a table card, is no longer told its loc phrase could not be found when it is marked at its anchored paragraph (a regression in 1.14.6; issue #18).

## 1.14.6 (2026-11-21)

- Marking a supplement finds labels as many supplements print them: "Supplementary Figure 2" and "Supplementary Table 1", as well as "Figure S2" and "Table S1".
- A card's link and recorded mark are now its best spot: its loc highlight first, then its anchored paragraph, then a label, then the page. Before, they were its first spot, so a failed label search could hide a highlight on the same page. A page marker is no longer added where the card is already highlighted.
- A card anchored in both the main text and the supplement has one loc phrase, which is in one of the two PDFs. In the other PDF it now highlights the opening words of its anchored paragraph, not just the page. `check` warns only when no PDF of the source has the loc phrase highlighted (issue #18).

## 1.14.5 (2026-11-21)

- Supplementary material that arrives in parts (data files, but not the supplementary PDF) is reported as what is still missing, by coverage unit. Before, `check` said a coverage line was out of date and should be updated (issue #8).

## 1.14.4 (2026-11-21)

- Concept matching lets the longer of two overlapping names win. "Olfactory receptor" (the GPCR) is no longer counted inside "olfactory receptor neuron" (the cell), so `scan` and `check` stop asking for cards on false mentions (issue #17).

## 1.14.3 (2026-11-21)

- When a locator still cannot be found, `mark` matches it word by word against the page, joining a word hyphenated at a line end ("pre-" + "dicted"), and highlights those words (issue #16).

## 1.14.2 (2026-11-21)

- A locator broken by a hyphenated line end ("…DREAM Ol-" / "faction…") still gets a highlight on its page. When the phrase and its six-word ends are not found, `mark` tries each four-word window on the anchor's page (issue #16).

## 1.14.1 (2026-11-21)

- `find` no longer crashes when its hits include reference, data-set or code cards (issue #13).
- An isotope label such as "[¹⁴C]" is no longer read as a superscript citation; on Haddad et al. 2008 this removes two false citations of reference 14 (issue #14).

## 1.14.0 (2026-11-21)

- The concept scan puts each concept's key equations and figures on its hub (issue #12).
  - `scan P012` lists every equation and figure panel of the source, for each concept its card names: a crop (`P012-eq4.png`), a card id for an equation with no crop, or a panel image (`P012-F2c.png`, flagged when not yet cropped).
  - An item stays listed until the hub embeds it, or links its card under `## Key equations and figures`, or `P012_scan.md` records `- not_key:: [[concept]] <item> — why`. These decisions survive re-scans.
  - `brain-mesh-concept-scan` step 7 says how to judge, crop, embed and cite them: the evidence card, the works it cites, and the original source of a borrowed equation.
  - The hub template in `brain-mesh` has the section, and `brain-mesh-add-paper` step 9 fills it for new papers.

## 1.13.0 (2026-11-21)

The contradictions register; discovery respects the evidence.

- **Contradiction cards `V###`** in `contradictions/`: two or more cards (evidence, findings, concepts) that cannot both hold as stated, with the clash, why both cannot hold, the ways out, the kind (values, direction, null, against, link, mechanism, definition, scope, other) and who found it. Status open, explained, resolved or dissolved, with a graded history. Hypotheses and theories `explains::` them, seeds come `from::` them, experiments `addresses::` them, tensions gather them (`tension::`).
- **`contradictions [P###|<concept>]`** lists the logged ones and the possible contradictions in the Codes not yet logged: `contradicts::` links, values that clash under the same conditions, a recorded effect the data reverse, opposite directions in different sources, null results against effects, evidence against findings. `contradictions add <key>` (or `<card> <card> "<clash>" --by ...`) logs one; `contradictions dismiss <key> "<why>"` records one that is not. `check` warns about candidates neither logged nor dismissed, and an integrated paper owes each open contradiction it bears on a decision.
- **The register,** `ledger/contradictions.md`, rebuilt by `build`: open contradictions and what works on them (marked when nothing does), the explained, resolved and dissolved, tensions, candidates not yet logged, and the dismissed. MAP lists open contradictions.
- **Discovery respects the evidence.** New miner `contradictions`: candidates to log (housekeeping, once judged real) and open contradictions nothing works on (theory, hypothesis and experiment prompts). `implied` and `analogies` withhold predictions that evidence in the brain looked for and did not find, unless a logged contradiction frees that evidence; `theories` flags theories in conflict with findings no contradiction frees; `moderators` works on contradictions as on tensions. Each signal names its `facts` call.
- **`facts <concept> ...`** lists what a proposal must respect: hub facts and relations, effects and null results, findings, evidence, and the logged contradictions that free a side.
- Skills: discover (constraint rule, contradiction pass and hunt), add-paper and concept-scan (scan for contradictions and log them; decisions on open ones), batch, experiment, access, housekeeping, main skill.
- A test parses the tooling with Python 3.11 where it is installed (beside the 1.12.1 check for backslashes in f-string expressions).

## 1.12.1 (2026-11-21)

- The tooling starts again on Python 3.10 and 3.11. 1.11.0 put a backslash inside an f-string expression, which only Python 3.12 accepts. A test now flags any such expression, and the test suite runs on Windows (UTF-8 mode, paths from glob) (issue #10).
- `sync` finishes with the tooling a pull brings. Before, it built, committed and pushed with the old code still loaded in memory, so generated sections went out in the old format (issue #11).

## 1.12.0 (2026-11-21)

Every link can be followed both ways.

- `build` gives every card, of every kind (sources, claims, concepts and references too, not only evidence and synthesis cards), a generated `## Linked from` section: each card that links to it and that it does not already link back to. Prose links come back as `mentioned_in`; evidence and claims cards link their source card (`in_source`); data and code cards the source lists, `used_in_source`; reference cards, the concepts listing them as key references (`key_reference_for`); evidence cards, the works cited in their paragraph (`cited_in_its_paragraph`).
- Concept hubs no longer stop at 30 evidence cards or 40 synthesis, discovery, data or code cards: the rest are linked by id. "Appears alongside" is symmetric.
- `check` warns about any link with no link back; `build` writes it. In the odour-coding vault this closed 1,007 one-way links of 16 kinds.
- A `- key::` line written below `## Linked from` (an append to the end of the file) is read as Codes and moved up by `build`, instead of being dropped.
- The reference card's "Cited in the brain's cards" list counts only hand-written links.

## 1.11.0 (2026-11-21)

Every concept looked for in every paper; facts carry the citations the paper gives; new concepts are the user's call.

- **`scan P012`** looks for every concept in the brain across a source's text (names and aliases, British or American spelling, plurals; word stems for high-priority concepts and sources; reference lists and the title block left out). It lists the passages no card of the source covers, with the sentence and the works the paper cites in it, numbered or author-year, and the source's cards whose passage cites works but which carry no `cites::` line. Writes `P012_scan.md`, where `decided::` lines record why a concept's remaining passages add nothing. `scan <concept>` does one concept across every source; `scan` alone summarises. `check` warns about a source with passages neither carded nor decided, so a new concept is flagged in every paper that names it.
- **Citations behind facts.** `check` warns about an evidence card, other than a measured or derived result, whose anchored paragraph cites works and that has no `cites::` line; `cites:: none — <why>` answers it. A concept-hub line stating a fact from such a card must cite the works too. The hub's generated evidence list shows the works each card cites.
- **Proposals.** `propose <slug> "<definition>" [--from P012]` writes a proposal (in the paper's `P012_concepts.md`, or `ledger/concept-proposals.md`). Cards may link proposed names: `check` warns, never refuses, so a vault with proposals waiting for the user still syncs. `adopt --all` makes cards of proposals that match nothing; `adopt <name> into <proposal>` folds without making a card; `reject <name> "<why>"` turns one down, turns its links into plain words and records the name so it is not proposed again. `concept` shows rejected names.
- **Concepts made by hand.** A note the user makes in `concepts/` ("Mixture suppression.md", a sentence or more) becomes a concept card at the next `build`: front matter, definition, generated block, id, kind, `origin:: made by the user`, file renamed to the slug and links repointed.
- New skill `brain-mesh-concept-scan`: scan chosen or all sources and card every fact with its citations. add-paper, batch, access, the main skill and the vault's `CLAUDE.md`: agents propose concepts and the user adopts them; extraction cites what the paper cites; every paper gets a concept scan.

## 1.10.0 (2026-11-21)

- The reading queue puts recent work first (issue #7). Within each list a work's score halves with every 8 years of age (`queue_half_life` in `MESH.json`), unless the work is foundational. Foundational means cited by two or more sources in the brain, cited in two or more paragraphs where one source's methods, models or results rest, marked high, or carrying `foundational::` or a `cited_count::` of at least 500 (`queue_foundational_citations`). Foundational works keep full weight and, once older than the half-life, are marked ⌛. Each queue line now shows the work's year.
- Reference cards take two optional Codes lines: `foundational:: <why>` and `cited_count:: <n> (<source>, <date>)`. Counts are copied by hand from a record for now; `build` stays offline.
- `brain-mesh-gaps` rung 2 searches recent work first, then reviews, then the classics they cite. `brain-mesh-add-paper` step 10 reports queue entries with their years.
- `build` no longer crashes when two reference cards claim the same reference number of one source; the duplicate check reports it instead (issue #9).

## 1.9.0 (2026-11-21)

Parallel extraction without a mess of concepts.

- **Agents see each other's proposals.** `concept "<name>"` also searches every paper's `P###_concepts.md` and marks matches PROPOSED, so the second agent links to the first agent's name instead of inventing a twin.
- **`adopt <name> [into <concept>]`** settles a proposal in one command. Alone, it creates the concept from the fullest proposal, with every proposing paper's names as aliases. With `into`, it folds the proposal into an existing concept, or into another proposal adopted first, adds its names as aliases, and rewrites every link to it in every card (plain in Codes, the reader's words kept in the prose). Proposals leave their files, and an emptied file goes. A proposal with `priority: low` keeps it. `staged` now pairs likely twins by shared content words.
- **Sync rule and agents.** The vault's `CLAUDE.md` and `brain-mesh-access` now exempt extraction agents in a batch from the sync rule. Vault rules that ask for a shared change (a new concept, a priority) are met by proposing it in the paper's own files.
- Batch skill: concept search before every proposal, vault rules within the agent's limits, merge by `adopt` with twins first and before `neighbours`, batch size set by the merge, Obsidian Git paused during a batch.

## 1.8.2 (2026-11-21)

- `id P` counts source folders named after their source cards. Before, once `build` had renamed the folders it found none and offered P001 again (issue #2).
- `upgrade` completes when a sync client such as OneDrive leaves the emptied `.brain-mesh/` folders behind. Before, it stopped with `FileExistsError` and left the vault without its offline instructions (issue #3).
- Empty source folders are ignored. A sync client can keep the old, emptied folder when a renamed source folder is pulled, and `build` then reported every source as two folders, one without a source card (issue #6).
- `brain-mesh-add-paper` says that a new source sits in a plain `sources/P012/` folder until its source card exists, and that the next `build` renames the folder after the card (issue #4).
- `brain-mesh-access` gains section 8, **Tooling bugs**: record every tooling or instruction fault as an issue on `tcpearce/brain-mesh` (or, without GitHub access, in the vault's `ledger/tooling-bugs.md`) before working around it, and fix only in the repository.

## 1.8.1 (2026-11-21)

- `sync` no longer stops on local changes. Generated files (`index/`, `*.bib`) changed locally are discarded before the pull, since the build regenerates them. A local edit that clashes with a newer version on GitHub is set aside in the git stash, the GitHub version is kept, and `sync` says which files and how to see the edit. Before, a plain pull refused to run, or left conflict markers.

## 1.8.0 (2026-11-21)

Merges the discovery work (built in parallel from 1.5.0 as "1.6.0", pull request #1) with 1.6.0 and 1.7.0.

- Everything in the discovery release below is now on main alongside claims, data-set and code cards, citations, decisions on gaps and tensions, `brain-mesh-access`, `sync` and priority.
- Id prefixes now cover both lines of work: `D` data sets, `C` code, `T` theories, `A` analogies, `S` seeds, `R` references, and `P012-claims`.
- Discovery cards (`T`, `A`, `S`) take part in priority like any other card: a high theory lifts the findings it explains.

## 1.7.0 (2026-11-21)

Priority across the ontology, as planned in the doc "Brain mesh: priority across the ontology".

- **Priority on every card:** `priority: high | normal | low` in front matter (absent means normal) and a `prioritised:: <date> <level> — <why>` line per change. New command `priority <id> <level> "<why>" [--sync]`; bare, it lists high and low cards and what each lifts. `build` records a priority set by hand (in Obsidian) and `check` asks for its reason; unknown values are errors.
- **Effective priority:** a normal card one link from a high card is elevated. A high paper lifts its own cards, the references it cites and the data and code it uses; a high concept lifts every card naming it; any high card lifts the cards linked to it either way. Explicit levels win; low never spreads. `index/priority.tsv`; a **Focus** line opens `MAP.md`.
- **Reading queue:** one score per work, from the pages it bears on (weighted by their priority), the sources citing it (weighted by theirs and by paragraphs), multi-source citation, the data sets citing it, and its own priority. New lists: **Marked high by you** and **◆ From high-priority sources** (works a high paper cites in two or more paragraphs or in its methods or results). ◆ names the high cards lifting a work; low references bearing on nothing high leave the queue.
- **Thresholds:** review decisions on gaps and tensions owed from relevance 0.25 (high), 0.3 (elevated), 0.35, 0.5 (low); the neighbour floor drops to 0.15 for high and elevated cards; high concepts weigh 1.5 times in ranking; high hubs list 12 key references; gap searches go stale after 90, 180 or 365 days.
- **Concepts:** `gaps` lists, for high concepts, every untested combination of their variable, and hub relationships and open questions with no card behind them. `health` lists disagreements on high concepts (tension candidates) and lens passes worth making.
- **Checks:** a high source with units at skim; a high hub citing nothing; a high gap unsearched or stale; a claim on a high concept feeding nothing; a high card unchanged for 90 days; a priority without a reason.
- **Order:** `health` opens with the focus and orders its queues by priority; `gaps` and `gapsdoc` list high first.
- **Migration:** gap priorities 1, 2, 3 in Codes become high, normal, low, each with a `prioritised::` line.
- Skills: priority in the main skill; who sets it in `brain-mesh-access`; the depth table in add-paper; order and verifiers in batch; the wider scan and staleness in gaps; high first in experiment; focus and hygiene in housekeeping; the Obsidian property, colour group and Git auto-sync in setup.

## 1.6.0 (2026-11-21)

Claims, data sets, code, citations in cards, decisions on gaps and tensions after each paper, and rules for any agent working in a vault.

- **Claims cards.** Each paper gets `P012-claims.md`: one main claim and at most five sub-claims, each linking the paper's own evidence (the claim card stating it, the observations or models it rests on) and the findings, tensions, gaps or hypotheses it feeds. Mirrored onto those cards as `main_claim_of` and `sub_claim_of`; tabulated by evidence type and status in the card's generated block; listed on the source card. `check` enforces the limits, own-source evidence, and that a linked finding cites the claim's evidence, and asks for a claims card on every integrated paper. New command `claims P012` lists the candidates and writes a skeleton. The main skill sets out how claims (per paper, authors' voice, ungraded) differ from findings (cross-source, scoped, graded).
- **Data-set cards** (`data-sets/D###`) and **code cards** (`code/C###`): key properties in Codes, `used_by:: [[P012]] — how` per study, `uses_data::`, `uses_code::`, `derived_from::`, `depends_on::`; status is availability (open, on-request, restricted, unavailable, unknown). Source cards list their data sets and code; data-set and code cards list what uses them. Code cards must summarise the code as a README would. New commands `mentions P012` (paragraphs naming data and code, links, accessions, matching cards) and `repoinfo <github URL>` (description, language, licence, README). `check` flags missing studies, locations, thin summaries and duplicates.
- **Citations in cards.** Any card may carry `cites:: [[R0042]] — why` (a reference card or a source in the brain) and `see_also::`; a reference linked in the prose must also be in Codes. Concept hubs get **Key references**: the works cited in the paragraphs where their evidence cards are anchored. Reference cards list the cards that cite them.
- **Decisions on gaps, tensions and hypotheses.** After a paper is integrated, every open gap, tension or hypothesis it bears on needs a decision: a status change with a `graded::` line naming the paper, or `- reviewed:: <date> P012 — untouched: <why>`. `place P012` lists them under **Decisions to record**; `check` warns until each is made. Tensions gain `resolved_by::` and `explained_by::`; a closed gap must name `closed_by::`. Knock-on warnings: experiments still planned against a closed gap, hypotheses explaining a resolved tension.
- **Any agent, every session.** New skill `brain-mesh-access`, read every time a vault is opened: sync first and last, navigating and answering by layer, where bespoke material goes, editing, retiring and deleting cards, working alongside others. Vaults get a `CLAUDE.md` (written by `init` and refreshed by `upgrade`, keeping the user's own text) that sends local agents such as Claude Code there. New commands `sync ["message"]` (pull with rebase, build, refuse on errors, commit, push, retry once) and `remove <id> [--force] [--why]` (delete for good; refuses while linked unless --force unlinks; a source goes with its folder; ids recorded in `ledger/removed.md` and never reused).
- Links in table cells (`[[card\|label]]`) now resolve. Batch agents draft claims cards and list data sets and code; the orchestrator makes the shared cards.

## Discovery (built as 1.6.0 on its own branch; merged in 1.8.0)

Discovery: mining the brain, with the user, for new hypotheses and links, and following every mined card as sources arrive.

- **New document `brain-mesh-discover`.** Interactive by rule: the miners print signals, Claude judges them and proposes cards with the case for each (where it comes from, why it is worth a card, whether it is already known, the fastest way to kill it), and writes only what the user accepts. Housekeeping signals (`links`, `implied:data`, `genealogy:held`) are done and reported. Reading passes (theory, analogy, inversion, levels, red-team) produce proposals the same way. Unattended runs write proposals to `ledger/proposals.md` and no cards.
- **`discover [miner ...] [--focus concept] [--top n] [--all]`** runs eleven miners over the Codes: `bridges` (Swanson's ABC across sources), `moderators` (what differs between the sides of tensions, contested findings and disagreeing parallel results), `transfer` (outcomes, methods and findings never tried at another value of a categorical variable), `implied` (chained effects with their signs, direct and indirect effects that disagree, loops, effects in the data no hub records), `constraints` (each quantity pooled across sources by conditions, with unit checks), `genealogy` (cited works several sources lean on; held works with no card for what they are cited for), `assumptions` (load-bearing, untested, shared), `oddities`, `theories` (the theory × finding matrix), `analogies` (relations that carry across a mapping) and `links`. Each signal has a stable key, the sources it rests on, the cards that already touch it, and a ready stamp line.
- **New cards.** `theories/T###` (status active, strained, abandoned; `explains::`, `conflicts_with::`, `includes::`, `rivals::`), `analogies/A###` (proposed, productive, failed; `maps:: [[base]] = [[target]] — role`) and `seeds/S###` (new, developing, promoted, answered, dropped; `miner::`, `from::`, `promoted_to::`, `answered_by::`). Theories and analogies keep a grading history. MAP and the concept hubs list them; `theories` prints the matrix.
- **Lifecycle.** A card made from a signal carries `- mined:: <key> | <date> | <score> | <sources>`. `discover --recheck` re-runs the miners behind every live stamped card and every rejection, and sorts them into dissolved (naming the new cards that now hold the signal's concepts), strengthened, weakened, changed, re-opened and standing. `dismiss <key> <reason>` records a rejection in `ledger/signals.md`; `discover` hides it until a new source bears on it. A closed card's stamp counts as a judgement in the same way. `health` lists mined cards with evidence newer than their stamp. The add-paper integrate step, the batch merge phase and housekeeping now run the recheck.
- **Axes for mining.** add-paper asks for species, preparation, level of organisation and stimulus class as categorical `when::` conditions, so the miners can look across them.
- Miner scores use the rarity of concepts in evidence and findings only, so writing discovery cards never moves a score. `check` validates the new cards (mapping lines, stamps, promotion and answer links, dropped reasons).

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
