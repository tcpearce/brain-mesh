# Changelog

Newest first. Raise `VERSION` here, in the `VERSION` file and in `tools/mesh.py` together.

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
