---
name: "brain-mesh-experiment"
description: "Use a brain mesh to propose and design experiments and judge their outcomes: shortlist what to test next, write hypotheses with rivals, register predictions before the result, then assess results and update findings, gaps and concept hubs."
---

# Brain mesh: experiments

Read `brain-mesh` first. Find the vault and run `python3 tools/mesh.py build`.

This is what the brain is for. Every choice made here should trace back to cards, and every result should flow back into them.

## 1. Propose: what is worth testing

Draw candidates from, roughly in this order of value:

1. **Confirmed research gaps**, by priority (`gaps/RESEARCH-GAPS.md`, or `python3 tools/mesh.py gaps`). If a gap's search is old, repeat it first with `brain-mesh-gaps`.
2. **Open tensions.** The best experiment is the one whose result differs depending on which side is right.
3. **Findings resting on one source**, where much depends on them: replication.
4. **Untested assumptions** beneath important observations.
5. **Models** never tested outside the range they were fitted on.
6. The **What would change this** section of each key finding.
7. **Oddities** nobody has explained.
8. **Method transfer**: a technique carded for one system that has never been applied to another.
9. **Discovery cards** (`brain-mesh-discover`): seeds the user is developing, theory pairs that nothing in the brain separates (the most decisive experiments), and predictions carried across an analogy. A hypothesis made from a seed sets the seed to `promoted`.

Give the user a shortlist. For each candidate state: what would be done; why, citing card ids; what each possible result would mean; whether the methods already exist as method cards; and whether the literature has been checked for it and when. Rank by how much a result would change the brain, then by feasibility.

The brain holds only what was put into it. Before calling an idea novel, make sure its gap has been through the ladder in `brain-mesh-gaps`.

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

## 3. Design the experiment

```markdown
---
type: experiment
status: proposed
updated: 2026-11-20
---
# Heat-then-cool cycle in water and acetonitrile with one assay

**Question.** What the experiment decides, in one or two sentences.

## Design
What is varied, at which levels; what is measured and how; what is held fixed; controls; number of replicates.

## Registered predictions
- Under [[H001|hypothesis H001]]: the expected values.
- Under each rival: the expected values.

## Decision rule
What result counts as support, as refutation and as inconclusive, fixed in advance.

## Risks and controls
Known confounds from limitation and assumption cards, and how each is handled.

## Amendments
None.

## Outcome and assessment
Not yet run.

## Codes
- id:: E001
- tests:: [[H001]]
- addresses:: [[G001]], [[X001]]
- uses:: [[P001-002]]
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

## 4. Register

When the user approves the design, set status `registered` and add `- registered:: <date>` to Codes. From then on the **Registered predictions** and **Decision rule** sections are frozen. Any later change goes under **Amendments** with its date and reason, leaving the original text in place.

This is the point of the whole card. An outcome can only be judged against predictions that were written before it was known. Set any gap the experiment addresses to `planned`.

## 5. Assess the outcome

1. **Ingest the results** as an own-result source with `brain-mesh-add-paper`. Card every measured value, including nulls and failed runs, and card protocol deviations as limitations. Link the cards to the literature cards they replicate, contradict or extend.
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
