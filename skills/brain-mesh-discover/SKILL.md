---
name: "brain-mesh-discover"
description: "Mine a brain mesh, with the user, for new hypotheses and new links: run the miners (contradictions, bridges, moderators, transfer, implied effects, constraints, genealogy, assumptions, oddities, theories, analogies, links), propose cards that respect every fact and piece of evidence except where a logged contradiction frees it, log the contradictions found on the register, keep theory, analogy and seed cards, and recheck every mined card as sources are added."
---

# Brain mesh: discovery

Read `brain-mesh` first. Find the vault and run `python3 tools/mesh.py build`.

The other documents build the brain from what papers say and find what they leave unknown. This one looks for what the brain implies and no paper states: connections between papers, hidden variables behind disagreements, results that ought to carry over to another system, rival accounts and the observations that would separate them. Its output is proposals put to the user, not conclusions.

## The rules

1. **Interactive.** The miners print signals. Claude judges them and proposes cards to the user, each with the case for it. Only what the user accepts is written. The exception is housekeeping, marked `housekeeping` in the miner output: linking two cards (`links`), recording on a concept card an effect the data already show (`implied:data`), a lens pass where a held work has no card for what other sources cite it for (`genealogy:held`), and logging a contradiction on the register once Claude has judged it real (`contradictions:log`). Claude does these, then reports them in one line.
2. **The evidence and the concept facts are constraints.** Every proposal (seed, theory, analogy, hypothesis, gap, verdict) must agree with every evidence card, finding and concept fact (the lines of a hub's **What is known**, **Relationships** and **How it is measured**, and its `affects::` relations) that bears on its concepts. `python3 tools/mesh.py facts <concept> ...` lists them; each signal names the call it needs (`respect: mesh.py facts ...`). A proposal may go against a card only where that card is a side of an open or explained contradiction on the register; it is then offered as a way out of that contradiction, citing it. A proposal that clashes with anything else is wrong as it stands: reshape it or drop it. If the clash shows two pieces of evidence that cannot both hold, that is a contradiction to log, not a licence. The `implied` and `analogies` miners already withhold predictions that evidence in the brain looked for and did not find, unless a logged contradiction frees that evidence; the `theories` miner flags theories in conflict with findings no contradiction frees.
3. **Discovery cards change nothing beneath them.** A seed, theory or analogy never edits evidence, re-grades a finding or moves a gap. Those change only through their own documents, when evidence arrives.
4. **Every mined card carries a stamp,** so it can be followed as the brain grows (section 8).
5. **Nothing is deleted.** A seed is promoted, answered or dropped; a theory abandoned; an analogy failed; always with the reason.
6. **Brain-relative.** "No card holds both" means in this brain. Before a proposal is promoted to a hypothesis or gap, it climbs the ladder in `brain-mesh-gaps` (coverage of the sources held, then a literature search).

## 1. When to run

- The user asks for new ideas, hypotheses or connections, or what the brain implies.
- After a paper or a batch is integrated: always `discover --recheck` (section 8), then the miners if the user wants new proposals.
- Before proposing experiments: seeds and unseparated theories feed `brain-mesh-experiment`.
- On a schedule, as an insight pass with nobody watching (section 7).

`python3 tools/mesh.py discover` runs every miner; name miners to run some (`discover bridges moderators`); `--focus <concept>` keeps signals involving one concept; `--top N` shows more per miner; `--all` includes rejected signals.

## 2. The miners

Each miner reads only the Codes. Scores rank signals within one miner, never across miners.

| Miner | What it finds | What a good proposal from it usually becomes |
|---|---|---|
| `contradictions` | Possible contradictions in the Codes not yet on the register (`contradicts::` links, values of one quantity that clash under the same conditions, a recorded effect the data reverse, opposite directions in different sources, a null result against an effect, evidence against a finding), and open contradictions that no theory, hypothesis, seed or experiment works on yet. | A contradiction logged on the register (housekeeping, once judged real); for an open one, a theory that makes both sides true, a hypothesis naming the hidden variable, or a discriminating experiment. |
| `bridges` | Two concepts that no evidence card or finding holds together, joined through other concepts in different sources (Swanson's ABC: A–B in one paper, B–C in another, A–C never looked at). Sibling values of one variable and hub concepts are skipped. | A seed: does A affect C, or has technique T been used on X? |
| `moderators` | For open and explained tensions and contradictions, findings with evidence against them, and parallel results that disagree beyond their errors: the conditions, methods and materials that differ between the sides. | A seed naming the hidden variable; a rival in a hypothesis; a line in the tension's possible explanations. |
| `transfer` | An outcome, a method or a finding established at one value of a categorical variable and never tried at another value present in the brain (species, preparation, level, solvent …). | A gap of kind `untested-region`, or a seed for a method transfer. |
| `implied` | Chains of effects, recorded on concept cards or visible in the data: A → B → C with A → C never measured (with the sign the chain predicts); a direct effect opposite to the indirect one; loops. Also effects the data show that no concept card records (housekeeping). | A seed or hypothesis with a signed prediction. |
| `constraints` | Every value of one quantity pooled across sources and grouped by conditions: agreement within each condition set, spread, units. | Arithmetic across papers (a seed carrying the derivation); a tension where values clash; a correction where units are mixed. |
| `genealogy` | Works several sources lean on that are not in the brain, and what rests on the passages citing them; held works with no card stating what others cite them for. | A reading-queue entry (rung 2); a lens pass (housekeeping); a seed when a much-repeated claim rests on a weak original. |
| `assumptions` | Assumptions ranked by how many cards rest on them, whether anything tests them, and the same assumption in several sources. | A seed or gap of kind `untested-assumption`; a control in an experiment design. |
| `oddities` | Oddities in different sources that may share a cause; oddities nothing takes up, with the finding, theory or hypothesis that might absorb each. | A seed; an extension of a theory. |
| `theories` | The theory × finding matrix: findings no theory explains, findings no theory has been judged against, theory pairs nothing separates, active theories in conflict with strong findings, open tensions no theory addresses. | Verdicts on theory cards, a new theory, a discriminating experiment. |
| `analogies` | Relations true on the base side of an analogy and unstated on the target side; base findings with no target counterpart; concepts that would extend the mapping. | A seed or hypothesis with the analogy as its rationale. |
| `links` | Cards in different sources that share rare concepts and are not linked. | Housekeeping: link with a reason, or leave. |

`python3 tools/mesh.py theories` prints the whole theory × finding matrix.

## 3. Passes Claude runs by reading

Some of the best ideas need reading, not counting. Each pass produces proposals like a miner, with `- miner::` naming the pass and no stamp.

- **Contradiction pass.** Open the register (`ledger/contradictions.md`) and take each open contradiction in turn. A contradiction is the strongest prompt the brain has: something is missing from the account that both sides share. For each, ask what would make both sides true (a condition one side did not record, a difference of method or definition, a level of organisation, a time course) and what would show one side wrong. Propose the best answer as a hypothesis or a theory that `explains::` the contradiction, or as a seed `from::` it, with the experiment that would tell the ways out apart (`brain-mesh-experiment`).
- **Contradiction hunt.** The tooling sees contradictions only in the Codes. Reading the cards a signal names, or the evidence on a concept (`facts`), look also for statements that exclude each other in words: two mechanisms that cannot both run, a claim one paper makes that another's data deny, a concept fact a new card overturns. Log each one real with `contradictions add <card> <card> "<the clash>" --by "discover: <pass>"`.
- **Theory pass.** Gather the explanatory claims and models (claim and model cards that are inferred or speculated, especially those cited by findings and tensions). Group them into rival accounts. For each, propose a theory card: core claim, commitments, what it explains, what it forbids. Then propose a verdict for every finding against every theory: explains, conflicts or silent. The miner works from these cards.
- **Analogy pass.** Look for a system, in another field or another part of this brain, with the same relations as a structure here: the same circuit motif in another species, the same computation in an algorithm, the same physics in another material. Propose the mapping as an analogy card; the miner then lists what carries across.
- **Inversion pass.** For each established or probable finding that much rests on (`python3 tools/mesh.py impact K003`), ask what would follow if it failed at the edge of its scope, and propose seeds for the most consequential answers.
- **Levels pass.** Where cards carry a level of organisation (molecule, receptor, cell, circuit, behaviour), check that each claim at one level has evidence at the levels its mechanism needs. A computational claim with no evidence for its implementation is a seed.
- **Red-team pass.** For high-stakes proposals, a separate agent that has not seen them tries to break the top ones and the findings they rest on.

## 4. The axes the miners need

`transfer` and `moderators` see only what is in `when::` lines. A brain that records species, preparation (in vivo, slice, culture, in silico), level of organisation and stimulus class as categorical `when::` conditions, each value its own concept card, can be mined across them; one that leaves them in the prose cannot. `brain-mesh-add-paper` asks for them at extraction. In a brain built without them, a lens pass adds them.

## 5. From signal to proposal

For each signal worth attention:

1. **Is it real?** Open the cards it names. Many signals come from the extraction: a missing `when::` line, one concept used for two things, a value in the wrong unit. Fix that as housekeeping and say so; it is not a proposal.
2. **Is it already known here?** Read the cards listed as `touched by`, and check the coverage of the sources involved (`index/coverage.tsv`).
3. **Does it respect the facts?** Run the `facts` call the signal names and read every line against the proposal (rule 2). Drop or reshape it where it clashes with a card that no logged contradiction frees; where it rests on a logged contradiction, say so in the case. A clash between two cards found on the way is logged on the register.
4. **What card would it become?** A seed by default. A gap, hypothesis, theory verdict or finding directly only when the brain already meets that card's own rules.
5. **Make the case.** Present three to seven proposals at a time, best first, mixed across miners. Never paste the miner output. Each proposal:

```markdown
**1. Seed: Binding capacity may fall in step with film thickness, film by film**
- From: bridges, binding-capacity ~ film-thickness, joined through swelling in P001 and P003
- Why it is worth a card: it turns the swelling account (T001) into a quantitative prediction that the damage account (T002) does not make
- Already known? X001 mentions both only as a possible explanation; both sources are fully extracted; no literature search yet
- Respects the facts? Yes: agrees with K001 and every card on binding-capacity and film-thickness; goes against nothing
- Fastest way to kill it: a paper reporting thickness and capacity on the same films; failing that, one heat cycle with both measured
- How sure the signal is real: high; both quantities are carded with conditions in two sources
```

Ask the user to accept, edit, reject or defer each one, with the multiple-choice tool where the session has it.

## 6. Writing what the user accepts

**Seed** (`seeds/S###-<slug>.md`): an idea, judged worth a card and not yet a hypothesis or gap.

```markdown
---
type: seed
status: new
updated: 2026-11-21
---
# Binding capacity may fall in step with film thickness, film by film

**Idea.** One or two sentences, specific enough to be wrong.

**Why it is worth a card.** What would change if it held: which finding, theory or decision.

**What it rests on.** The cards the signal came from, in words with links.

**Fastest test.** The quickest observation, search, lens pass or dataset query that would kill it.

## Codes
- id:: S001
- miner:: bridges
- mined:: bridges:binding-capacity~film-thickness | 2026-11-21 | 3.37 | P001 P002 P003
- from:: [[P001-005]] — thickness rises 18% in water, [[K001]] — the loss on heating
- concepts:: [[binding-capacity]], [[film-thickness]], [[swelling]]
```

Status: `new`; `developing` (being worked on: searched, prediction sharpened); `promoted` (it became another card: `- promoted_to::`); `answered` (evidence settled it, either way: `- answered_by::`); `dropped` (`- dropped:: <date> — <why>`).

**Theory** (`theories/T###-<slug>.md`): a rival account, larger than one hypothesis.

```markdown
---
type: theory
status: active
updated: 2026-11-21
---
# Capacity loss on heating is solvent uptake swelling the network

**Core claim.** One paragraph.

## Commitments
1. What must be true if the account is right, each something an observation could contradict.

## What it explains
- [[K001|finding K001]]: why the account predicts it.

## What strains it
- Findings and evidence it struggles with, and how it might survive them.

## Discriminating predictions
- Against [[T002|T002]]: what this account predicts that the other forbids.

## Codes
- id:: T001
- explains:: [[K001]] — water uptake rises with temperature, [[X001]] — acetonitrile does not swell the film
- conflicts_with:: [[P003-003]] — reason, if any
- includes:: [[H001]]
- rivals:: [[T002]]
- concepts:: [[binding-capacity]], [[swelling]], [[water]], [[temperature]]
- graded:: 2026-11-21 active — written from the claims of P001 and P002
```

Status: `active`, `strained`, `abandoned`, each change with a `graded::` line. Every verdict (`explains`, `conflicts_with`) is a judgement and goes to the user like a proposal.

**Analogy** (`analogies/A###-<slug>.md`): a structural mapping between two systems; the left of each mapping is the base side.

```markdown
---
type: analogy
status: proposed
updated: 2026-11-21
---
# The insect mushroom body and the piriform cortex share one coding design

**The mapping.** Each element and the role it plays on each side, in words.

**Where it breaks.** The known differences.

## Codes
- id:: A001
- maps:: [[kenyon-cell]] = [[piriform-pyramidal-cell]] — the expansion layer
- maps:: [[projection-neuron]] = [[mitral-cell]] — the input layer
- from:: [[P004-012]] — the random-connectivity result
- concepts:: [[sparse-coding]]
- graded:: 2026-11-21 proposed — from the analogy pass
```

Status: `proposed`, `productive` (a prediction from it held), `failed` (a failed prediction showed the mapping wrong).

**Stamps.** Paste the `stamp:` line that `discover` printed for the signal, unchanged, into the accepted card's Codes. A card built from several signals carries several stamps. Any card written directly from a signal (a gap, a hypothesis) carries its stamp too, so the recheck follows it.

**Rejections.** `python3 tools/mesh.py dismiss <signal key> "<the user's reason>"` records the date, the reason and the sources the signal rested on in `ledger/signals.md`. `discover` then hides it until a new source bears on it. Deferred proposals are recorded nowhere, and come back next time.

## 7. When the user is away

In a scheduled or unattended run, do the housekeeping, run `discover --recheck` and the miners, judge the signals, and write the proposals and recheck changes, in the format of section 5, under a dated heading in `ledger/proposals.md`. Write no other card and record no rejection. In the next session with the user, go through `ledger/proposals.md` first and note each decision there.

## 8. After new sources: the recheck

The integrate step of `brain-mesh-add-paper` and the merge phase of `brain-mesh-batch` end with `python3 tools/mesh.py discover --recheck`. It re-runs the miners behind every stamped card that is still live, and behind every rejection, and sorts them:

| State | Meaning | What to do, with the user |
|---|---|---|
| dissolved | The signal is no longer produced. The tool names the new cards that now hold its concepts together, or the cards changed since the stamp. | Read those cards. If they settle the question, the seed is `answered`, with `answered_by::`; if they bear it out, promote it (to a finding through `brain-mesh-add-paper`, or a hypothesis). If an edit or merge removed the signal rather than evidence, rewrite the seed's basis or drop it. |
| strengthened | New sources joined its basis. | Read the new cards; offer to develop or promote the card; replace the stamp. |
| weakened | Sources left its basis: a retraction, merge or correction. | Tell the user, judge it again, then replace the stamp or drop the card. |
| changed | The score moved with no new source (a lens pass, edits). | Re-read it and replace the stamp. |
| re-opened | A rejected signal gained a source. | Propose it again, saying what is new and quoting the reason it was rejected. |
| standing | Nothing changed. | Nothing; the stamp keeps its date. |

Then run `discover theories` (the new findings appear as unjudged: propose verdicts) and `discover analogies`.

Replace a stamp only after the user has seen the change: the new stamp line is printed beside each change. Stamps on promoted, answered and dropped cards stay as they were. A closed card is a record, and its stamp makes `discover` treat its signal as judged, so it returns only when a new source bears on it. `python3 tools/mesh.py health` lists live mined cards whose evidence is newer than their stamp.

## 9. Promotion

- **To a hypothesis** with `brain-mesh-experiment`, where its rivals and predictions are written. The seed becomes `promoted` with `promoted_to::`.
- **To a gap** with `brain-mesh-gaps`, when the seed is an unknown rather than a conjecture.
- **To a finding** only when evidence already in the brain supports it (an effect in the data, a constraint), under the integration rules of `brain-mesh-add-paper`, with its grade.
- **To a theory verdict or a new theory**, as proposed and accepted.

The new card cites the seed's `from::` cards, not the seed, because layers cite downward. The seed stays as the record of how the idea arose; `build` mirrors its `promoted_to::` link onto the new card.

## 10. Close

Run `python3 tools/mesh.py build` until it is clean, then `python3 tools/mesh.py log "discover: <n> proposed, <n> accepted (<ids>), <n> rejected, <n> housekeeping, <n> contradictions logged (<V ids>); recheck: <n> dissolved, <n> strengthened, <n> re-opened"`. Report in a few lines: the cards written, the contradictions logged and the open ones still unworked, the housekeeping done, and the one next step most worth taking.
