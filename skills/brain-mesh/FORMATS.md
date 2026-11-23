# Brain mesh: card formats

Read this before writing or changing any card. The map, `SKILL.md` beside this file, says what each card family is for and how to work in a vault; this says what goes on each card: its parts, sections and Codes, the evidence types and statuses, the link keys, citations, priority and the PDF rules. `python3 tools/mesh.py schema` prints the keys and statuses the tooling enforces.

## Card anatomy

Every card has the same four parts in the same order.

```markdown
---
type: observation
status: measured
updated: 2026-11-20
---
# Binding capacity for analyte X falls to 1.3 at 45 °C in water

At 45 °C in [[water]], the [[binding-capacity|binding capacity]] of the
[[imprinted-polymer-film|imprinted polymer film]] for [[analyte-x|analyte X]]
was 1.3 ± 0.2 across three replicate films, about a third of its value at 25 °C.

**Basis:** [[P001-002|batch rebinding with UV detection]].
**Source:** Smith & Jones 2021, Results, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- id:: P001-004
- value:: [[binding-capacity]] = 1.3 ± 0.2 (± unspecified, n = 3)
- when:: [[temperature]] = 45 degC
- when:: [[solvent]] = [[water]]
- concepts:: [[imprinted-polymer-film]], [[analyte-x]]
- obtained_by:: [[P001-002]]
- anchor:: [[P001_text#^b0004]]
- loc:: "At 45 °C it decreased to 1.3"
```

1. **Properties.** Exactly `type`, `status` and `updated`, one per line. Concept cards add `aliases` and have no `status`. Put quotes round any value that contains a colon.
2. **Title.** A `#` heading that states the card's point as a full sentence.
3. **Human part.** The science in plain prose, complete enough to understand with no other card open: name the system, the conditions, the numbers with units and uncertainty, and the direction of any effect. Link concepts and other cards by readable name. Use the labelled lines and sections given for the card type below.
4. **Codes.** A list of `- key:: value` lines. Everything a query might need is here even when the prose already says it: the id, every concept, every typed link, values and conditions in fixed form, and provenance. A generated `## Linked from` section may follow it; never edit that section.

Why both halves: prose alone cannot be traversed reliably, and codes alone cannot be read. They are kept in step by hand. If the user has edited the prose in Obsidian, bring the Codes into line, and the reverse. `build` flags a value or a concept that appears in one half and not the other.

## Card types

### Concept cards: the hubs

A concept is anything the brain needs a shared word for: an `entity` (material, analyte, organism, device), a `variable` (anything measured or set), a `technique`, or a `concept` (mechanism, phenomenon, model). Concept cards are what the user navigates by. Write them as short living articles and extend them every time a source touches them.

```markdown
---
type: concept
aliases: ["Binding capacity", "rebinding capacity"]
updated: 2026-11-20
---
# Binding capacity

**Definition.** One to three sentences.

**How it is measured.** For variables and techniques: the methods the sources use and how they differ, citing method cards.

## What is known
- One line per established point, each citing a finding or evidence card.

## Relationships
- **[[temperature]]** lowers it in water but not in acetonitrile ([[X001|tension X001]]).

## Open questions
- One line each, citing a gap card where one exists.

## Key equations and figures
- **Langmuir isotherm**, how capacity saturates with analyte concentration ([[P001-009|Smith & Jones 2021, eq. 2]], after [[R0007|Langmuir 1918]]):
  $$q = \frac{q_{max} K c}{1 + K c}$$
  ![[P001-eq2.png]]

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- id:: binding-capacity
- kind:: variable
- unit:: 1
- measured_by:: [[batch-rebinding-assay]], [[quartz-crystal-microbalance]]
```

- `kind` is `entity`, `variable`, `count`, `technique` or `concept`. A `count` is a variable that only says how many items a result rests on (`sample-size`). A variable needs `unit`: a unit, `1` for dimensionless, or `categorical` when its values are themselves concept cards (solvent = water).
- Concept-to-concept relations in Codes: `broader` (is a kind of), `part_of`, `measured_by`, `affects`, `related`. Write the relation on the card of the concept that does the affecting or belonging, for example on the temperature card: `- affects:: [[binding-capacity]] — tested: in water only, [[K001]]`. An `affects` line must cite the finding or evidence card it rests on, because it is a scientific claim and not vocabulary.
- **Every `affects` line states its basis,** as the first word of its reason:

  | basis | means |
  |---|---|
  | `tested` | an experiment set the cause and measured the outcome |
  | `correlational` | the two vary together in observational data, a reanalysis or a fitted model; nothing was manipulated |
  | `proposed` | the cited authors say so (theory, mechanism, discussion) without testing it in the cited work |
  | `inferred` | the brain's own inference, from chaining relations or comparing sources |

  `check` warns about a line with no basis, and about `tested` where no cited source is recorded as an experiment. **Causal wording follows the basis:** "causes", "raises", "lowers", "leads to", "drives" only for `tested` relations; "is associated with", "predicts", "is higher where" for `correlational`; "is proposed to" for `proposed`; "the evidence suggests" for `inferred`. This holds in hubs, findings, answers and anything written from the brain.
- **Key equations and figures** (optional) shows the equations and figure panels that define or measure the concept: the LaTeX or the embedded image, a sentence on what it shows, the evidence card it comes from, and the works that card cites, each with a `cites::` line. `scan` lists the candidates (`brain-mesh-concept-scan` step 7).
- The block under **Where it appears** is generated: every finding, tension, gap, hypothesis and experiment that uses the concept, its evidence cards, relations pointing at it from other concepts, and the concepts it most often appears with. Keep the two AUTO marker lines in the card.
- Before proposing a concept run `python3 tools/mesh.py concept "<name>"`. If an existing concept covers it, add the new name to that card's `aliases` instead. If another agent has proposed it, link that name.
- **New concepts are the user's call.** They come into the brain in two ways:
  - **An agent proposes one:** `python3 tools/mesh.py propose <slug> "<one-sentence definition>" --from P012 [--kind variable --unit 1] [--alias "other name"]` writes the proposal into the paper's `P012_concepts.md` (or `ledger/concept-proposals.md` without `--from`). The cards link the proposed name meanwhile; `check` warns, it does not refuse. The user makes it a card (`adopt <slug>`, or `adopt --all` for proposals that match nothing), folds it into an existing concept (`adopt <slug> into <concept>`, which rewrites every link), or turns it down (`reject <slug> "<why>"`; links become plain words and the name cannot be proposed again). An agent folds twins and near matches itself, and makes a card only on the user's word or where a vault rule tells it to.
  - **The user makes one by hand:** a note in `concepts/`, named as they like ("Mixture suppression.md"), holding at least a sentence saying what it is. `build` turns it into a card: front matter, the first paragraph as its definition, the generated block, Codes with its id (the name as a slug, `mixture-suppression`), `kind:: concept` unless they gave one, and `origin:: made by the user`. The file is renamed to the slug and every link to the old name is pointed at it. Check its kind; a variable needs a unit.
- **Every concept is looked for in every paper.** `python3 tools/mesh.py scan P012` searches a source's text for every concept in the brain (by name and alias, British or American spelling, plural or singular; word stems too for high-priority concepts and sources) and lists the passages no card of that source covers, with the works the paper cites in each sentence. `check` warns about a source with such passages and no decision. After a new concept, `scan <concept>` finds it across all sources. `brain-mesh-concept-scan` says how to work through the lists.

### Source cards

One per paper, preprint, thesis, report, dataset or own result. Name it `P012-<first author>-<year>-<two to four title words>` (`P001-lee-2023-principal-odor-map`): `build` names the source's folder after it, so papers can be told apart in Obsidian's file list. Links are unaffected, because Obsidian resolves them by file name.

Human part: `# Authors (year) Title`, then **Citation.** (with links `[[P012.pdf|original PDF]]`, `[[P012_marked.pdf|marked PDF]]` and `[[P012_text|anchored text]]`), **What they did.**, **What they found.**, **Weaknesses.**, **Extraction.** (one sentence on what has and has not been extracted), then a `## Cards from this source` heading followed by the two AUTO marker lines.

Codes: `kind` (paper, preprint, thesis, report, dataset, own-result, other), `authors` (separated by `;`), `year`, `venue`, `doi`, one `coverage:: unit | depth | what it holds` line for every section, table, figure and supplementary item (depth is `full`, `skim`, `none` or `missing`), and one `pass:: date | kind | cards | verification` line per extraction pass. Status is `registered`, `extracted` or `integrated`.

**The study profile.** Four more Codes lines say what kind of study the source is, because that sets what its results can establish:

- `question::` the question the study asks, in one sentence.
- `design::` one line per study in the paper: a design from the list, then ` — ` and what was done. `- design:: experiment — intensity rated by a trained panel at seven concentrations of 62 odorants`.

  | design | what it can establish |
  |---|---|
  | `experiment` | the investigators set the conditions and measured the outcome: that a variable they changed changes the outcome, within the conditions tested |
  | `observational` | measured without intervening: that things vary together, not which causes which |
  | `reanalysis` | a new analysis of data others collected: as strong as those data, and not independent of the work that produced them |
  | `computational-model` | a model fitted or trained on data and tested on data: what predicts the outcome, not what causes it |
  | `simulation` | a model run from stated assumptions: what follows from them |
  | `theory` | argument or derivation with no new data: a proposal |
  | `review` | a summary of others' work: the evidence is in the original studies |
  | `method` | a technique, instrument, data set or software introduced or validated: that it works as characterised |
  | `case` | one or a few cases described: that something can happen |
  | `other` | say what after the dash |

- `sample::` what was studied and how many: molecules, animals, participants, films, data sets.
- `framework::` the theory or model the study works within, or `none stated`.

`check` asks every extracted paper, preprint, thesis, report and own result for all four. They feed the tables (`table`), the independence check, the basis of relations and the writing skill.

The coverage lines are the record of what has not been read closely. They are what stops "not in the brain" being mistaken for "not in the paper".

### Evidence cards

One statement from one source. Human part as in the example above: the statement, an optional **Basis:** line naming the method or evidence in words, a **Source:** line a person can follow (authors, year, section, figure or table, page, link to the PDF page), and an optional **Caveat:** line.

| type | what the statement must contain | usual status |
|---|---|---|
| `method` | what was done, to what, with which parameters and instruments; enough to repeat or compare | reported |
| `observation` | what was measured, the value with uncertainty and n, the conditions, the comparison | measured, derived |
| `model` | the relation in words and in LaTeX (see Equations below), fitted parameters, range of validity | derived |
| `claim` | what the authors conclude, how strongly they put it, what it rests on | inferred, speculated |
| `assumption` | what is assumed, where it enters, whether anything tests it | asserted |
| `limitation` | what limits the result and which statements it affects | reported |
| `question` | the open question as the authors pose it | reported |
| `definition` | how this source defines or operationalises a term, where that differs from the concept card | reported |
| `cited` | a background statement the source takes from other work, with the reference | cited |
| `oddity` | anything unexpected, unexplained or mentioned in passing that fits nowhere else | measured, reported |

Status says what kind of support the statement has in this source: `reported` (a description of what was done or stated), `measured`, `derived` (computed from measurements), `inferred` (the authors' interpretation), `asserted` (stated without evidence here), `speculated`, `cited`.

Codes on evidence cards:

- `value:: [[variable]] = number ± uncertainty unit (kind of uncertainty, n = N)`. One line per quantity: a card still makes one statement, but that statement may involve several numbers (a count and its total, the two arms of one comparison). A non-numeric outcome may follow the `=`. Put the number first and anything else in the note in brackets: `check` reads the first number that stands on its own before the note, so a label or name with digits in it (`pEC50`, `OR1A1`, `GCaMP6f`) is never taken for the value. A value read from a figure carries its reading error and how it was read: `= 0.354 ± 0.002 (Fig. 5C, POM Linear, read from the picture)`.
- `stat:: t = 5.4, d.f. = 987, P < 0.0001 (what was compared)` for a test statistic, which is not a quantity of any variable.
- For a count that only says how many items a result rests on (molecules, stimuli, neurons), use the `sample-size` concept, whose Codes say `kind:: count`. Counts of different things are never compared, so the duplicate and parallel-result checks skip them.
- Every number that states a result goes into a `value::` or `stat::` line, so that searches and comparisons can see it. The checker flags an observation whose prose has numbers and whose Codes have neither.
- `when:: [[variable]] = value`, one line per condition, written on every card even when the paper states it once, because cards are read alone. A categorical value is a concept link.
- `concepts::` every other concept involved.
- Typed links (next section).
- `anchor::` where it comes from: `[[P012_text#^b0042]]` for a paragraph, or `T2` (table), `F3b` (figure panel), `p7` (page), `eq4`; in the supplementary material `[[P012_SI_text#^s0042]]`, `SI-T2`, `SI-F3`, `SI-p4`, and `SI-<name>` for a supplementary data file. Give several, separated by commas, when the paper states the same thing more than once, and add the page to a table or figure anchor (`T2, p7`).
- `loc:: "..."` six to twelve consecutive words copied from the anchored paragraph. The tooling uses it to confirm the anchor and to place the card's highlight on the PDF. It is a locator, not an excerpt; keep it short.
- `missing:: <kind> — <what the source does not give>` when the source itself lacks something the card needs. Kinds: `method`, `basis`, `data`, `statistics`, `sample-size`, `definition`. An observation must link the method that produced it (`obtained_by`) and a claim the evidence it rests on (`based_on`), or say with `missing::` that the source gives none. These are genuine holes in the evidence and feed `brain-mesh-gaps`. Look in the supplementary material before recording one; while it is unread, a `missing::` is provisional and the checker says so.
- `equation:: <LaTeX> (eq. 4)` for an equation the source prints or defines in words. The same LaTeX is displayed in the prose as a `$$ ... $$` block, which Obsidian renders, with the symbols explained in words and linked to their concepts; inline symbols use `$x$`. Under a printed equation, embed the cropped image of the original (`![[P012-eq4.png]]`) so the transcription can be checked at a glance. Anchor it with `eq4, p3` for a printed equation, or with the paragraph that defines it in words (then say so in the prose). `check` warns when the Codes and the displayed equation differ, when braces or `$` signs are unbalanced, and when an equation has no anchor.
- Housekeeping codes: `retracted:: <date and reason>` on a retracted source (or a single retracted card); `retraction_checked:: P012 — <what changed>` on a card reviewed after a retraction it rests on; `corrected:: <date> — <what changed>` on a card fixed after a published correction, together with an anchor into `P012_correction_text`. See `brain-mesh-housekeeping`.
- Optional: `origin:: claude` when the statement is Claude's reading and not the authors' words; `via:: table`, `figure`, `si` or `inferred` when it did not come from the running text (a value read off a plot is `via:: figure`, with its reading error and the panel's data file, as `brain-mesh-add-paper` describes); `null:: true` for a null or negative result; `flag:: <doubt about the extraction>`; `ref::` on cited cards; `lens:: L003` when added in a lens pass.

### Claims cards: what each paper says it shows

Every paper, preprint, thesis or report has one claims card, `P012-claims.md`, in its folder: the argument of the paper as its authors make it, one **main claim** and at most five **sub-claims** the main claim depends on. It is the quickest way into a paper and the place to judge how far its evidence carries it.

- Human part: `# P012 claims: <the main claim>`, **Main claim.**, **Sub-claims** (a numbered list), **How far the evidence carries it.** (where the evidence is strong, where thin, what the paper does not show), then the AUTO markers, where `build` tabulates each claim's evidence by type and status and the findings it feeds.
- Codes: one `- main_claim:: <the claim as a sentence> — [[P012-031]] states it; rests on [[P012-012]], [[P012-014]]; feeds [[K003]]` line, and up to five `- sub_claim::` lines in the same form. Each line links the paper's own evidence: the claim card that states it (required for the main claim) and the observations or models it rests on. Each also links the findings, tensions, gaps or hypotheses it feeds, or says `no finding yet`. Status `drafted` or `checked`.
- The links are mirrored, so a finding shows `main_claim_of` or `sub_claim_of` each paper whose claims it carries, and so do the evidence cards. `check` enforces one main claim, at most five sub-claims, links only to the paper's own evidence, and that a linked finding actually cites some of the claim's evidence.
- `python3 tools/mesh.py claims P012` lists the paper's claim cards with what they rest on and feed, and writes a skeleton to fill in.

**Claims and findings are different things.** A claim belongs to one paper and is in the authors' voice: what they say they showed, as they framed it, graded by nobody, fixed once written apart from corrections. A finding (`K`) belongs to the brain: one proposition with its scope, built from evidence across every source that bears on it, graded on independence, directness and replication, and re-graded as papers arrive. A claim feeds findings but is never one. Two papers can make the same claim and yield one finding; one paper's claim can be split across several scoped findings, or count against one. Claim *cards* (evidence of type `claim`) are the individual statements; the claims card arranges them into the paper's argument.

### Data-set cards

One per data set any study uses, in `data-sets/`, `D003-<short name>.md`. Find data sets in a paper with `python3 tools/mesh.py mentions P012`, which lists the paragraphs that name data sets and code, the links and accessions in them, cited works that look like databases, and the cards already in the brain that match.

- Human part: `# <what the data set is, in a sentence>`, **What it is.**, **What it contains.** (samples, variables, size, how collected), **Access.**, **How the brain's studies use it.**
- Codes: `name`, `version`, `creators`, `year`, `url`, `doi`, `accession`, `licence`, `size`, `samples`, `variables`, `modality`, `format`, `collection`, `concepts::`, `derived_from:: [[D001]] — how` for a data set built from others, `see_also::` for any other relevant card, and one `- used_by:: [[P012]] — how the study uses it (training set, re-analysis, validation)` per study. A resource the studies only look things up in (a chemical database, a supplier's catalogue, a compendium of thresholds) also carries `- role:: lookup`: it is carded and linked like any data set, but sharing it does not make two studies dependent (`independence` names it as not counted). Status is its availability: `open`, `on-request`, `restricted`, `unavailable`, `unknown`.
- Cards that rest on a data set link it with `uses_data:: [[D003]] — what for` (evidence cards, code cards). Both directions show: the study's source card lists its data sets, and the data-set card's `## Linked from` lists every card that uses it.

### Code cards

One per code repository or software package any study uses, in `code/`, `C002-<short name>.md`. The card summarises the code the way a good README would, so a reader knows what it does without opening it.

- Human part: `# <name> <does what, in a sentence>`, **What it does.**, **Inputs and outputs.**, **How it works** (method, language, main dependencies), **How the brain's studies use it.**, **Getting it.** (install or access, licence, maintained or not).
- Codes: `name`, `repo` (its URL), `url`, `doi` (a Zenodo or software DOI), `language`, `licence`, `version` or `commit` used, `last_push`, `concepts::` (the methods it implements), `uses_data:: [[D003]] — what for`, `depends_on:: [[C001]] — what for`, `see_also::`, and one `- used_by:: [[P012]] — how the study uses it` per study. Status as for data sets; commercial software that cannot be inspected is `restricted` or `unavailable`.
- `python3 tools/mesh.py repoinfo <github URL>` prints a repository's description, language, licence, activity and the start of its README. Read the README, not just the description, and summarise from it; never describe a repository you have not read. If GitHub cannot be reached, open the repository page with whatever tool can.

### Citations in cards

Any card may cite works: a link in the prose to a reference card (`[[R0042-keller-2017-predicting-human-olfactory|Keller et al. 2017]]`) or to a source in the brain (`[[P001-lee-2023-principal-odor-map|Lee et al. 2023]]`), with the same work in Codes as `- cites:: [[R0042]] — what it supports here`. `check` warns about a reference cited in the prose and missing from Codes.

**Facts carry the citations the paper gives for them.** An evidence card whose statement the paper backs with a citation lists each such work: `- cites:: [[R0042]] — what it supports`. The source's own measured or derived results need none. Where the paragraph's citations support a different sentence, write `- cites:: none — <why>`. `check` warns about a card that is not `measured` or `derived` whose anchored paragraph cites works and that has neither; `scan` names the works cited in the card's own sentence (numbered and author-year styles). On a concept hub, a line stating a fact from such a card cites the work too, `[[R0042-…|Keller et al. 2017]]`, with its `cites::` line, and `check` flags the lines that do not. The hub's generated evidence list shows the works each card cites.

Concept hubs should cite the closely relevant works in their text: `build` lists, under **Key references** in each concept's generated block, the works cited in the very paragraphs where that concept's evidence cards are anchored, strongest first, and marks those the card already cites. Each reference card lists the cards that cite it.

### Synthesis cards

Written by Claude across sources. One proposition, disagreement or unknown per card. Each cites evidence cards and lists its concepts in `concepts::`.

- **Finding `K`.** `# <the proposition, with its scope>`, **In brief.**, `## Evidence` (for and against, in words, with links), `## Where it holds and where it breaks`, `## What would change this`. Codes: `support::`, `against::`, and the scope as `when::` lines like those on evidence cards (`- when:: [[solvent]] = [[water]]`, `- when:: [[temperature]] = 25 to 45 degC`; several lines for one variable allow several values). The scope in Codes must match the scope in the title. Status: `single-source`, `tentative`, `probable`, `established`, `contested`. Grade on independent sources, directness and replication, not on how confident the authors sound.
  - **Independent means independent.** Sources that share a data-set card (other than a lookup resource, `- role:: lookup`), or two or more authors, or an author who is first or last on both, count once. `python3 tools/mesh.py independence K001` shows the groups behind a finding. `check` warns when a `probable` or `established` finding rests on one group, and questions a `replicates::` link between sources that use the same data. When two grouped sources are independent for this finding (different data, different laboratories' work), say so on the finding: `- independent:: [[P001]], [[P003]] — <why>`.
- **Tension `X`.** **The disagreement.**, `## Sides`, `## Possible explanations` (differing conditions, methods or definitions first), `## What would settle it`. Codes: `sides::`, and once it changes status `explained_by::` (the hypothesis or evidence that accounts for both sides, or a hypothesis that `explains::` it) or `resolved_by::` (the evidence that settled it). Status: `open`, `explained`, `resolved`.
- **Gap `G`.** See `brain-mesh-gaps`.
- **Contradiction `V`: the contradictions register.** Two or more cards that cannot both hold as stated: values of one quantity that disagree beyond error under the same conditions, opposite directions of one effect, a null result against an effect, evidence against a finding, a concept fact the evidence denies, or statements that exclude each other in words. One clash per card, light to write: `# <the clash in one sentence>`, **The clash.**, **Sides.**, **Why both cannot hold.**, **Ways out.** (different conditions, methods or definitions; an error on one side; a moderator: each a candidate hypothesis or experiment). Codes: one `sides::` line per side (evidence, findings or concepts), `concepts::`, `kind::` (`values`, `direction`, `null`, `against`, `link`, `mechanism`, `definition`, `scope`, `other`), `logged_by::` (the import of P012, a concept scan, a discovery miner, the user), and a `graded::` history. Status: `open`, `explained` (`explained_by::` a hypothesis, theory or evidence that makes both sides true), `resolved` (`resolved_by::` evidence showing one side wrong), `dissolved` (`dissolved:: <why it was not a contradiction after all>`, with the cards fixed). A tension (`X`) is a disagreement worked up into a question; several contradictions can feed one (`tension::`).
  - **Logging.** `python3 tools/mesh.py contradictions` lists the logged ones and the possible contradictions the tooling sees in the Codes and that are not yet logged (`contradicts::` links, value clashes, opposite directions, null results against effects, evidence against findings). `contradictions add <key>` logs one (or `contradictions add <card> <card> "<the clash>" --by "<who found it>"` for one seen by reading); `contradictions dismiss <key> "<why>"` records that a candidate is not one. `check` warns about candidates neither logged nor dismissed. Dismissing `values:<card>~<card>` also settles `check`'s warning that the two are unlinked parallel results, and works for any two results with the same variable and conditions in different sources, whether or not their values clash: use it when the two are not one quantity (different scales, different targets), where a link between them would say something untrue. The paper import, the concept scan and the discovery miners all log what they find.
  - **The register,** `ledger/contradictions.md`, is rebuilt by `build`: open contradictions with what works on them (theories, hypotheses, seeds, experiments linking them), the explained, resolved and dissolved ones, tensions, candidates not yet logged, and the dismissed. An open contradiction nothing works on is marked: contradictions are a first source of theories, hypotheses and experiments.
  - **Contradictions free a constraint.** Every proposal from discovery must agree with the evidence and the concept facts; it may go against a card only where that card is a side of an open or explained contradiction (`brain-mesh-discover`). After a paper is integrated, each open contradiction it bears on gets a decision, like gaps and tensions.
- **Review after each paper.** Once a paper is integrated, every open gap, tension and hypothesis it bears on carries a decision for it: a status change with a `graded::` line naming the paper, or `- reviewed:: <date> P012 — untouched: <why>`. `check` lists those still undecided (add-paper step 8).
- **Grading history.** Findings, tensions, gaps and hypotheses keep one `- graded:: <date> <status> — <why>` line per change of status, oldest first, so each carries its own reasoning trail (`- graded:: 2026-11-21 probable — P003 replicates P001 in the same conditions`). `build` starts the history of a card that has none; `check` warns when the status differs from the last `graded::` line.

### Workbench cards

Hypothesis `H` and experiment `E`: see `brain-mesh-experiment`.

### Discovery cards

Theory `T` (a rival account, judged against every finding with `explains::` and `conflicts_with::`), analogy `A` (a mapping between two systems, `maps:: [[base]] = [[target]] — role`) and seed `S` (an idea the user judged worth a card, not yet a hypothesis or gap). Claude proposes them from the miners and reading passes, and writes only what the user accepts. A card that came from a miner carries a `- mined::` stamp, so `discover --recheck` can tell, after new sources, whether its signal stands, grew, weakened or dissolved. See `brain-mesh-discover`.

### Reference cards: what the sources cite

Every work cited by a source in the brain has one reference card in `references/`, `R0042-keller-2017-predicting-human-olfactory.md`, shared by every source that cites it. It is bibliographic, not evidence: it says what the work is, who cites it and where, and gives its BibTeX. The tooling makes and maintains them (`refs` and `cite` in `brain-mesh-add-paper`); edit only their Codes and the `## Notes` section.

- Front matter `type: reference`; status `not-held` (cited, not in the brain), `queued` (asked for or downloading), `held` (now a source in the brain), `skip` (decided against).
- Codes: `id`, `authors` (`Surname, I.; Surname, I.`, ending `; others` for et al.), `year`, `title`, `journal` or `booktitle` and `publisher`, `volume`, `pages`, `doi`, `pmid`, `arxiv`, `url`, `kind` (article, incollection, book, misc), one `cited_by:: [[P012]] ref 7 — b0031, b0040` per citing source (its number in that list and the paragraphs that cite it), and `held:: [[P015]]` once the work is a source in the brain. Optional: `foundational:: <why>` for an old work the field still rests on, and `cited_count:: <n> (<source>, <date>)` for an external citation count copied from a record (OpenAlex, Crossref, Google Scholar); both keep an old work at full weight in the reading queue. `build` marks a work held by itself when a source card with the same DOI, or the same first author, year, volume and page, appears.
- The generated block shows the citation with DOI, PubMed and arXiv links, each citing passage with the evidence cards anchored there ("where P001-039 says this"), and the BibTeX.
- A source card lists its references by number; `P012_refs.bib` and `references/library.bib` are rebuilt on every `build`.
- `ledger/reading-queue.md` gets a generated list, rebuilt on every `build`: works cited where research gaps rest (★, read first), works cited where open gaps and tensions rest, works cited near cards that share concepts with a gap or tension, and works cited by more than one source. Within each list recent work comes first: a work's score halves with every 8 years of age (`queue_half_life` in `MESH.json`), unless it is foundational, in which case it keeps full weight and, once older than the half-life, is marked ⌛. A work is foundational when two or more sources in the brain cite it, when one source cites it in two or more paragraphs where its methods, models or results rest, when the user marks it high, or when its card carries `foundational::` or a `cited_count::` of at least 500 (`queue_foundational_citations`). Mark progress on the reference card's status, never in the generated list.
- Discovery keeps its history in the ledger, never on evidence cards: `ledger/signals.md` (signals the user set aside), `ledger/routes.md` (what `routes` showed at the last record), `ledger/outside.md` (what was asked outside the brain and what came back) and `ledger/explored.md` (branches worked). `PROFILE.md` at the top of the vault is the research profile. A seed, hypothesis, gap or experiment made from an opportunity may carry `- route:: <route> — <need>`. `MESH.json` may set `system_variables` (the categorical conditions that count as systems one can work in; `species` and `preparation` unless set) and `resources` (the literature and data services to name in an outside brief).

## Priority: where the brain spends its effort

Every card has a priority: `high`, `normal` (the default) or `low`. **Priority is attention, never evidence.** It decides how much effort the brain spends around a card; grades, statuses and scopes stay governed by evidence alone.

- **Recorded** in front matter as `priority: high` (absent means normal), with one `- prioritised:: <date> <level> — <why>` line in Codes per change, like `graded::`. `build` records a change made by hand (in Obsidian's Properties panel, say) as "set without a reason", and `check` asks for the reason.
- **Set** by the user: in Obsidian, or with `python3 tools/mesh.py priority <id> <high|normal|low> "<why>" [--sync]`, or by asking an agent, which runs that command with the user's reason. Claude never sets priority on its own; it may suggest a change with a reason. `priority` with no arguments lists the high and low cards.
- **Spreads one link.** A normal card one link from a card the user set high is *elevated*:
  - a high paper lifts its own evidence, claims card, the reference cards it cites, and the data sets and code it uses;
  - a high concept lifts every card that names it;
  - any high card lifts the cards it links to and that link to it.
  Nothing spreads further, an explicit level always beats an inherited one, and low never spreads. `index/priority.tsv` lists every card's effective level and what lifted it; `MAP.md` opens with the **Focus**.
- **What it changes:**
  - **High:** full-depth extraction and a verifying agent for a paper; more of its citations queued; a wider gap scan, an extended agreement test and more key references for a concept; earlier re-grading for a finding; settling sought for a tension; searches kept fresh (90 days) for a gap; first place in `health`, `gaps`, `gapsdoc` and the reading queue.
  - **Elevated:** queue weight, and lower thresholds for review decisions and cross-paper links; not full-depth extraction.
  - **Low:** a lighter touch (skim allowed) and a lower rank everywhere; nothing is ever hidden.
- **Hygiene:** a card high for 90 days with no change is flagged for the user to confirm. High should stay rare.

## Links

Links live in Codes as `- relation:: [[target]] — reason`.

| on evidence cards | meaning |
|---|---|
| `obtained_by` | this observation was made with that method |
| `based_on` | this claim or model rests on those observations |
| `qualifies` | this limitation restricts that statement |
| `underlies` | this assumption is needed by that statement |
| `supports`, `contradicts` | agrees or disagrees with that card |
| `replicates` | the same measurement under the same conditions from an independent source |
| `extends` | follows on from that card: further conditions, a next step, a refinement |

| `uses_data`, `uses_code` | this card rests on that data set or code |

Synthesis, workbench and discovery cards use `support`, `against`, `sides`, `explained_by`, `resolved_by`, `from`, `closed_by`, `explains`, `rivals`, `tests`, `addresses`, `uses`, `results`, `conflicts_with`, `includes`, `maps`, `promoted_to` and `answered_by`; data-set and code cards `used_by`, `derived_from`, `uses_data` and `depends_on`; claims cards `main_claim` and `sub_claim`. Any card may carry `cites::` (a reference card or a source in the brain) and `see_also::` (any card), each with a reason. `python3 tools/mesh.py schema` prints every allowed key and status.

- A link to a card from another source must carry a reason of a few words after ` — `. The reason is what makes the link worth following later, and `build` rejects a cross-source link without one.
- Write each link once, on the newer card. `build` mirrors it onto the target under `## Linked from`, in inverse wording with the same reason, so both cards show the connection and nobody maintains two ends.
- **Every link can be followed both ways.** Not only typed links: `build` gives every card, of every kind, a `## Linked from` section listing each card that links to it and that it does not already link back to. A link in the prose comes back as `mentioned_in`; an evidence or claims card links its source card (`in_source`); a data set or code base the source card lists links that source (`used_in_source`); a reference card lists the concepts whose hub names it among the key references (`key_reference_for`); an evidence card lists the works cited in the paragraph it is anchored to (`cited_in_its_paragraph`). Concept hubs list every card that uses them, the overflow by id, and a concept appears alongside another on both their hubs. `check` warns about any link with no way back, and `build` writes it. A `- key::` line written below `## Linked from` by mistake is moved up into the Codes, not lost.
- Evidence cards link to evidence cards. Findings cite evidence. Hypotheses and experiments cite findings, tensions, gaps and evidence. Nothing cites upward. Claims cards are the exception that proves the rule: they belong to their source but point up to the findings they feed, which is what lets each finding list the papers whose claims it carries.

## The PDF as ground truth

Every statement in the brain must be checkable against the page it came from, in one click.

- **Evidence cards point at the page.** Write the link in the **Source:** line as `[[P012.pdf#page=5|open page]]`. `build` then re-points it at the card's own highlight in the marked copy, as `[[P012_marked.pdf#page=5&annotation=27R|open page]]`. Never write the annotation number by hand; it is regenerated.
- **The marked copy.** `P012_marked.pdf` is rebuilt whenever the source's cards change. Each evidence card appears as a highlight on its `loc` phrase, coloured by card type (method blue, observation yellow, claim green, model teal, limitation and assumption orange, question purple, oddity pink, cited and definition grey), with a tag in the margin showing the card id. The highlight's comment holds the card's id and title, and the tag opens the card in Obsidian. A table or figure card is marked on its caption. A card that cannot be placed gets a tag at the top of the page and a warning.
- **It doubles as a coverage map.** Text with no highlight has no card. Looking through the marked pages is the quickest way to see what was not extracted.
- **The original is sealed.** `anchor` records a checksum of the file in `ledger/checksums.txt`, and `build` reports an error if the file ever differs. The user's own highlights and notes belong on the marked copy, where they are preserved, never on the original.
- **Everything else reaches the PDF through evidence.** A finding cites evidence cards, and each of those opens the page. Concept hubs cite findings and evidence. No synthesis card should state a fact that cannot be followed down to a highlighted passage.
- **Supplementary material is ground truth too.** `anchor P012 --si <files>` seals it: a supplementary PDF is anchored (`P012_SI_text.md`, paragraphs `^s0001` ...) and gets its own marked copy, and data files and code are sealed as `P012_SI-<name>.*`. A value checked against a supplementary data file is checked like one in the text.
- **Figure values.** `P012-F2.png` (the panel) and `P012-F2.csv` (every value read from it, each with its reading error) sit beside the PDF. A card that cites a figure value is checked against that file.
- **Sources that are not PDFs** (a results file, lab notes) are anchored the same way. Their cards link to the paragraph with `[[P003_text#^b0002|open passage]]`.
- Marking needs PyMuPDF. Without it `build` says that marking was skipped; the cards and every other check still work.
