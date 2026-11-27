---
name: "brain-mesh-experiment"
description: "Use a brain mesh to specify, register, run and document studies, computational ones above all: shortlist what to test next, write hypotheses with rivals, scaffold an experiment card that sweeps every dimension of the ontology, seal its analysis plan and predictions by checksum before anything runs, seal the finished run with its code, data checksums, environment and output anchored line by line, then card each result against the line that produced it and judge every registered prediction. Use for an experiment the user specifies, or one promoted from a campaign proposal they have accepted."
---

# Brain mesh: experiments

Read `brain-mesh` first, and its FORMATS.md before writing or changing a card. Find the vault and run `python3 tools/mesh.py build`.

This is what the brain is for. Every choice made here should trace back to cards, and every result should flow back into them.

## What a study is here

A study in a brain mesh is four linked cards and one sealed record, and nothing in it is a free-text promise:

| Stage | What it is | Sealed how |
|---|---|---|
| **Hypothesis** `H###` | the claim, its rivals, and a prediction for each | graded history |
| **Experiment** `E###` | what the brain brings, the data, the code, the analysis plan, the controls, the pipeline null, a prediction per rival, a decision rule | `experiment register` checksums the analysis plan, predictions and decision rule |
| **Run** | the finished run folder, turned into an own-result source `P###` | `experiment run` checksums every file, stores the code, records the commit and environment, and anchors the output line by line |
| **Result cards** | one observation card per result, each anchored to the line of output that produced it | `check` matches each number against the sealed log |
| **Assessment** | every registered prediction judged under the experiment's own decision rule | the grading history of what it changes |

**Computational is the default case.** The design sections are written for an analysis of existing data; `--bench` adds the levels, replicates and wet controls when a partner runs something at a bench. The point is the same either way: a result can only be judged against predictions written before it was known, and a number only means something when the brain can show where it came from.

## 1. Propose: what is worth testing

Draw candidates from, roughly in this order of value:

1. **Confirmed research gaps**, high priority first (`gaps/RESEARCH-GAPS.md`, or `python3 tools/mesh.py gaps`). Propose for high-priority gaps, tensions and hypotheses first and design them in full; a low-priority one gets a one-line idea at most. If a gap's search is old, repeat it first with `brain-mesh-gaps`.
2. **Open contradictions and tensions** (`ledger/contradictions.md`). The best experiment is the one whose result differs depending on which side is right, or which tells the ways out of a contradiction apart (its **Ways out** section). A hypothesis written for one `explains::` it, and an experiment `addresses::` it, so the register shows what works on it.
3. **Findings resting on one source**, where much depends on them: replication.
4. **Untested assumptions** beneath important observations.
5. **Models** never tested outside the range they were fitted on.
6. The **What would change this** section of each key finding.
7. **Oddities** nobody has explained.
8. **Method transfer**: a technique carded for one system that has never been applied to another.
9. **Discovery cards** (`brain-mesh-discover`): seeds the user is developing, theory pairs that nothing in the brain separates (the most decisive experiments), and predictions carried across an analogy. A hypothesis made from a seed sets the seed to `promoted`.

A study may also arrive the other way: from a discovery campaign (`brain-mesh-campaign`). When the user accepts a proposal from the final slate, `python3 tools/mesh.py experiment new --from-proposal REC-04` carries it in: the proposal's hypothesis, what it rests on, its prior and its decisive experiment become the first draft of the cards, and its campaign file stays as the record of how it arose. Only proposals the user has accepted are promoted; a proposal is not a study until they say so.

Give the user a shortlist. `python3 tools/mesh.py routes` is where candidates come from: it names the route each would take, the ingredients the brain already holds, the proof that route needs and whether the work is within the research profile. For each candidate state: what would be done; why, citing card ids; what each possible result would mean; whether the methods already exist as method cards; and whether the literature has been checked for it and when. Rank by how much a result would change the brain, then by feasibility.

The brain holds only what was put into it. Before calling an idea novel, make sure its gap has been through the ladder in `brain-mesh-gaps`.

Two reports help here (`brain-mesh-report`): `report frontier` ranks everything on this list in one table, and `report novelty "<the idea>"` checks a proposed study against the brain, rung by rung, before any design work.

## 2. Hypothesis cards

```markdown
---
type: hypothesis
status: open
updated: 2026-11-20
---
# The loss of binding capacity on heating in water is reversible swelling, not damage

**Hypothesis.** One or two sentences, specific enough to be wrong.

## Rationale
The findings, tensions and evidence that suggest it, with links.

## Rival explanations
- Each rival, and what it would predict instead.

## Predictions
- If true: an observable consequence, with numbers where the cards allow.
- If a rival holds: what would be seen instead.

## Codes
- id:: H001
- explains:: [[K001]], [[X001]]
- rivals:: [[H002]]
- concepts:: [[binding-capacity]], [[swelling]], [[temperature]]
```

A hypothesis with no rival cannot be tested informatively, so write the rivals even when they seem unlikely. A rival worth its own card gets one and is linked with `rivals::`. Status: `open`, `supported`, `refuted`, `retired`.

### 2.1 Deepen it against the whole brain before it is tested

A hypothesis written from the cards that prompted it is connected to a handful of them, and will be refuted by something
the brain already held. Before an experiment is registered against it, bring everything pertinent to it:

```bash
python3 tools/mesh.py hypothesis deepen H001 --write      # or --text "<the claim>" for a claim with no card yet
```

It works out how far the claim reaches — the concepts it names, those its cited cards carry, those named by a head word,
one and two steps through the concept graph, those that keep company with its core concepts on evidence cards, and the
rest of a topic it sits in — and then files every card that scores against that reach under how it can bear on the claim:

| Heading | What belongs there |
|---|---|
| Evidence that bears on the claim directly | observations, claims and cited facts for and against it |
| Mechanisms at each stage, and other routes to the same outcome | **the deepening that matters most**: every other way the same result could come about |
| Established findings and hub facts it must agree with | the `K` cards; a hypothesis that contradicts one needs that stated |
| Limitations, assumptions and oddities that could produce or hide the effect | what would make the result an artefact |
| Open gaps, contradictions and tensions it touches | with the evidence on each side brought in with them |
| Theories and analogies it bears on | empty is a signal: no theory in the brain explains or forbids it |
| Data sets and code that could test it | what a design can actually run on |
| Hypotheses, experiments, seeds and own results already on this ground | what has been tried |

Every line arrives ending `· bears: ?`. **Read each card and replace the `?` with how it bears** — supports, contradicts,
the mechanism of one stage, an alternative route, a confound, a scope limit, or irrelevant and why. Then rewrite the
Rationale, the Rival explanations and the Predictions against what was found: the alternative routes usually become
rivals, the confounds become predictions that discriminate, and the data cards become the study's inputs. Judgments
already written survive the next `deepen`, so a card can be re-run as the brain grows.

`check` asks for this: a hypothesis tested by a registered experiment but never deepened is flagged, and so is any line
nobody has weighed. The `## Connections` section is generated — it is left out of the card's own links, so a sweep
cannot make every route look taken up.


## 3. Design the experiment

### 3.1 Sweep the whole brain first: no stone unturned

A design that answers only to the card that prompted it will be refuted by something the brain already held. So the card is
scaffolded from a sweep of the whole ontology:

```bash
python3 tools/mesh.py experiment new H001                 # from a hypothesis
python3 tools/mesh.py experiment new --from-proposal REC-04   # from a campaign proposal the user accepted
python3 tools/mesh.py experiment sweep H001               # the sweep alone, to read before writing anything
```

The sweep writes a **`## What the brain brings`** section with eighteen headings, each filled from the cards:

| Heading | What it brings to the design |
|---|---|
| The claim, its rivals and the theories | what must be told apart, and which accounts are at stake |
| The gaps, contradictions and tensions it would settle | what the result is worth |
| Established facts the design must agree with | the findings and hub facts a prediction may not contradict |
| What these quantities have measured before | the effect size and noise behind the power calculation, from the `value::` lines |
| Conditions already covered, and the untested region | the levels to choose, so results can be compared (`matrix`) |
| Methods that have measured these quantities, and their reach | which technique to use, and whether the group has it |
| Limitations and assumptions to control for | the controls checklist, taken from the cited evidence |
| Unexplained observations that could confound it | oddities near the design |
| Open contradictions the design must not assume a side of | where the brain is not entitled to a premise |
| Quantities the sources define or measure differently | what to define explicitly before measuring |
| Data sets and code, with their access | what can be reanalysed today, and what nobody has used |
| Which groups the supporting evidence comes from | whether a result would be independent of what it tests |
| Sources not read in full | where the answer may already be on an unread page |
| What has been checked outside the brain | the searches already done, and what is queued to read |
| Hypotheses and experiments already working on this | so two cards do not test the same thing |
| What rests on the claim | how far a result would propagate |
| The nearest already-obvious next steps | so the study is not one of them (`mesh.py obvious`) |
| What the research profile says the group can do | reach, designs, data access and the scale of one project |

**Work through every heading.** Use what it gives, or write one line saying why it does not apply. A heading left with its
"nothing in the brain under this heading" line is a stone unturned, and `check` says so for any experiment that is
registered. When a heading is empty because the brain lacks the coding, that is a housekeeping task that pays here first.

The card records the sweep with `- swept:: <date> <dimensions>`.

### 3.2 The card

```markdown
---
type: experiment
status: proposed
updated: 2026-11-20
---
# Heat-then-cool cycle in water and acetonitrile with one assay

**Question.** What the experiment decides, in one or two sentences.

## What the brain brings
The eighteen headings above, swept from the cards and answered one by one.

## Data
Which data-set cards, at which version, the exact subset, and the split. Every file the run will read.

## Code
The code card, repository and commit; what must be written first.

## Analysis plan
**Primary statistic.** The one number the decision rests on, and how it is computed.
**Secondary.** Everything else reported, named here so it cannot become the headline afterwards.
**Threshold.** What counts as support, refutation and an open question.

## Leakage and circularity controls
Each form that could apply, and the control that severs it: train/test overlap, a label downstream of the ground truth, a
model-scored evaluation, a shared upstream data set, selection on the outcome, a definition that contains its instrument, a
filter validated by itself, preprocessing leakage, unmatched freedom between the things compared, best-of-many choices.
Naming one and controlling it makes the design stronger; leaving one uncontrolled makes the result uninformative.

## Pipeline null
The whole analysis rerun on permuted labels, shuffled correspondences or phase-randomised data, with the number of draws
and what result would show the effect belongs to the machinery rather than the system.

## Registered predictions
- Under [[H001|hypothesis H001]]: the expected values.
- Under each rival: the expected values.

## Decision rule
What result counts as support, as refutation and as inconclusive, fixed in advance.

## Risks and controls
Known confounds from the limitation and assumption cards the sweep found, and how each is handled. With `--bench`: what is
varied, at which levels, what is measured and how, what is held fixed, and the number of replicates with its arithmetic.

## Amendments
None.

## Outcome and assessment
Not yet run.

## Codes
- id:: E001
- tests:: [[H001]]
- addresses:: [[G001]], [[X001]]
- uses:: [[D003]] — the data, [[C001]] — the code, [[P001-002]] — evidence it rests on
- swept:: 2026-11-26 claim needs facts values conditions methods controls oddities contradictions data independence coverage outside workbench rests obvious reach
- concepts:: [[binding-capacity]], [[temperature]], [[solvent]]
```

Ground every choice in cards and cite them in the prose:

- **Levels.** `python3 tools/mesh.py matrix <variable> <variable>` shows what the literature has covered. Choose levels that overlap it, so results can be compared, and that reach the untested region the gap concerns.
- **Methods.** Reuse carded methods (`uses::`) and state every deviation. Read the method on the PDF page itself before copying its parameters. If two sources used different methods, that difference is itself a candidate confound.
- **Controls.** Go through the limitation and assumption cards on the cited evidence. Each one is either controlled for or named as unaddressed.
- **Replication.** Take the expected effect and the noise from the uncertainties and n on the observation cards. Show the arithmetic for the number of replicates, and say when the cards give too little to estimate it.
- **Predictions.** Give numbers for each rival, taken from cards where they exist. A prediction that every rival shares decides nothing; redesign until at least one outcome separates them.
- **Uninformative outcomes.** State which results would leave the question open, and whether the design can be changed to avoid them.

Status runs `proposed`, `registered`, `running`, `done` or `abandoned`.

The literature can overtake an experiment. When a newly added paper closes a gap an experiment `addresses`, `check` warns until the experiment is amended (under **Amendments**), re-aimed or `abandoned`, with a `- reviewed:: <date> P012 — G004 closed: <what changes>` line on the experiment. The same goes for a hypothesis whose tension a paper resolves: re-grade it with a `graded::` line naming the tension.

## 4. Register: seal it before anything runs

```bash
python3 tools/mesh.py experiment register E001
```

It checksums the **Analysis plan**, **Registered predictions** and **Decision rule** into `ledger/registrations.txt` with the
date and time, sets the status to `registered` and writes a `- registered::` line. From then on those three sections are
frozen: any later change goes under **Amendments** with its date and reason, leaving the original text in place, and `check`
reports an error if the sealed text has moved. Set any gap the experiment addresses to `planned`.

This is the point of the whole card. An outcome can only be judged against predictions written before it was known, and the
seal is what lets anyone else believe that they were.

## 4a. Run it, and seal the run

Run it wherever the work happens — a scratch folder, a cluster, the user's own machine — and keep the folder intact: the
code, the configuration, the data, the complete output, and an `environment.txt`. The vault stays read-only while a run is in
progress. Then:

```bash
python3 tools/mesh.py experiment run E001 --from <folder> [--log output.txt] [--as P036]
```

It refuses to record a run of an experiment that was never sealed, or one whose sealed sections have changed since, and it
writes an own-result source `P###` holding:

- every code and configuration file of the folder, copied in and checksummed;
- `P###_MANIFEST.tsv`: every file of the run folder with its size and checksum, data included, so the inputs can be matched
  exactly without copying gigabytes into the brain;
- the git commit (and whether the folder had uncommitted changes), the environment, the run time;
- `P###_text.md`: the complete output, **anchored line by line**, so a card can cite the line its number came from exactly as
  a card from a paper cites a paragraph.

A run dated before its registration is an error, not a warning. A run of an unsealed experiment is recorded as exploratory.

## 4b. Card the results against the lines that produced them

One observation card per result, in the run's own folder, as for any source (`brain-mesh-add-paper`):

```markdown
- value:: [[share-above-boundary]] = 3.4 %
- anchor:: [[P036_text#^b0042]]
- loc:: "share of labelled-odourless molecules above the boundary: 3.4%"
- uses_data:: [[D029]] — the labelled molecules
- obtained_by:: [[P036-001]] — the method card for this run
```

`check` then verifies that each number really appears in the sealed output, exactly as it does for a number read off a
figure or a page. A number that is not in the log is not in the brain: rerun, or correct the card.

## 5. Assess the outcome

1. **Card everything the run produced**, including nulls, failed runs and the pipeline null, and card every departure from the registration as a limitation, with its line of the log. Link the cards to the literature cards they replicate, contradict or extend.
2. **Judge each registered prediction** under `## Outcome and assessment`: supported, refuted, inconclusive, or not tested because of a deviation, with the numbers and links to the result cards. Apply the decision rule as written. Add `- results:: [[P0nn]]` and set status `done`.
3. **Propagate.**
   - Hypotheses: set the status of the one tested and of its rivals.
   - Findings: add the result cards as `support` or `against` and re-grade.
   - Tensions: `explained` or `resolved` when the result settles them, saying how.
   - Gaps: `closed` with `closed_by::` when answered; rewrite the **Unknown** when only narrowed.
   - Concept hubs: update **What is known**, **Relationships** and **Open questions**.
   - New oddities and new gaps the result raises get their own cards.
4. **Suggest the next experiment** the result points to.

Standards for the assessment:

- An ambiguous result is recorded as inconclusive. Do not stretch it toward the favoured hypothesis.
- A refuted hypothesis stays refuted. A rescue is a new hypothesis card with its own predictions.
- A surprise is a result. Card it as an oddity; do not explain it away.
- Own results carry no extra weight. Where they conflict with a paper, open a tension.
- If the protocol deviated in a way that bears on a prediction, that prediction was not tested. Say so.

## 6. Close

Run `python3 tools/mesh.py build` until there are no errors, regenerate the research-gaps document with `python3 tools/mesh.py gapsdoc` if any gap changed, and `python3 tools/mesh.py log "<what was proposed, registered or assessed, and what changed>"`. Report to the user in a few lines: the verdict on each prediction, what changed in the brain, and what to do next.
