---
name: "brain-mesh-discover"
description: "Mine a brain mesh, with the user, for new hypotheses and new links: run the miners (contradictions, bridges, moderators, definitions, transfer, implied effects, constraints, genealogy, assumptions, oddities, theories, analogies, links), propose cards that respect every fact and piece of evidence except where a logged contradiction frees it, log the contradictions found on the register, keep theory, analogy and seed cards, and recheck every mined card as sources are added."
---

# Brain mesh: discovery

Read `brain-mesh` first, and its FORMATS.md before writing or changing a card, and `brain-mesh-access` for syncing. Find the vault and run `python3 tools/mesh.py build`.

The other documents build the brain from what papers say and find what they leave unknown. This one looks for what the brain implies and no paper states: connections between papers, hidden variables behind disagreements, results that ought to carry over to another system, rival accounts and the observations that would separate them. Its output is proposals put to the user, not conclusions.

## The rules

1. **Interactive.** The miners print signals. Claude judges them and proposes cards to the user, each with the case for it. Only what the user accepts is written. The exception is housekeeping, marked `housekeeping` in the miner output: linking two cards (`links`), recording on a concept card an effect the data already show (`implied:data`), a lens pass where a held work has no card for what other sources cite it for (`genealogy:held`), and logging a contradiction on the register once Claude has judged it real (`contradictions:log`). Claude does these, then reports them in one line.
2. **The evidence and the concept facts are constraints.** Every proposal (seed, theory, analogy, hypothesis, gap, verdict) must agree with every evidence card, finding and concept fact (the lines of a hub's **What is known**, **Relationships** and **How it is measured**, and its `affects::` relations) that bears on its concepts. `python3 tools/mesh.py facts <concept> ...` lists them; each signal names the call it needs (`respect: mesh.py facts ...`). A proposal may go against a card only where that card is a side of an open or explained contradiction on the register; it is then offered as a way out of that contradiction, citing it. A proposal that clashes with anything else is wrong as it stands: reshape it or drop it. If the clash shows two pieces of evidence that cannot both hold, that is a contradiction to log, not a licence. The `implied` and `analogies` miners already withhold predictions that evidence in the brain looked for and did not find, unless a logged contradiction frees that evidence; the `theories` miner flags theories in conflict with findings no contradiction frees.
3. **Discovery cards change nothing beneath them.** A seed, theory or analogy never edits evidence, re-grades a finding or moves a gap. Those change only through their own documents, when evidence arrives.
4. **Every mined card carries a stamp,** so it can be followed as the brain grows (section 8).
5. **Nothing is deleted.** A seed is promoted, answered or dropped; a theory abandoned; an analogy failed; always with the reason.
6. **Brain-relative.** "No card holds both" means in this brain. Before a proposal is promoted to a hypothesis or gap, it climbs the ladder in `brain-mesh-gaps` (coverage of the sources held, then a literature search).
7. **Outside knowledge is a lead, never evidence.** What Claude knows of the field and what a search finds may aim a proposal and must be reported with it, marked as such. It enters the brain only as a carded source (section **Outside the brain**).
8. **The research profile is the user's.** Record in it only what they say. It decides what is shown first, never what is true: an opportunity out of reach stays on the books.
9. **Contingent on the brain as it stands.** Every signal, route and verdict is computed from the sources and Codes of the day. Say so in a proposal, and recheck after every source integrated (section 8).

## How a discovery session runs

Everything the miners can find is limited by what the ontology codes, and everything they find is true of the brain as it stands today. So a session reads the brain from the top, matches each need to a way of making a contribution, checks it outside the brain, and records what it saw so that later sources show what they moved.

1. **`python3 tools/mesh.py zoom`.** The topics, hottest first: groups of concepts that appear together on cards (a `broader::` or `part_of::` link keeps a concept with its parent). Heat is need to know: the user's priority first, then the open contradictions, tensions, gaps, hypotheses and seeds in a topic, then its fresh discovery signals. A branch explored with nothing changed since counts half. With a research profile, each topic also shows how many routes are in reach.
2. **Pick a branch:** the user's focus if they gave one, otherwise the hottest topic not explored lately. Two hot topics that no card joins are a branch too.
3. **`routes topic:<slug>`** (section **Routes**). The opportunities in that branch: each a need matched to a way of making a contribution, with the ingredients the ontology shows, the ones missing, the ones not coded, and its reach under the research profile. This list is the session's agenda. `discover --focus topic:<slug>` prints the raw signals behind it when a route needs a closer look.
4. **Verify the best three to five on their cards.** The tooling read the Codes only. `zoom <id>` on the need, `facts` on its concepts (rule 2), the page for anything a decision will rest on. An ingredient the cards do not bear out is struck; a signal that came from a coding slip is housekeeping.
5. **Supply the missing ingredient where that is cheap.** Each opportunity ends with its next step. An opportunity marked `ONE INGREDIENT SHORT` is the best prompt there is: say which ingredient, and what would supply it.
6. **Check outside the brain** (section **Outside the brain**): first what Claude knows of the field, then the literature. `outside <need>` gives the questions. Do this before anything goes to the user as new. What the ontology cannot name is found the same way, by comparison with something outside it (`brain-mesh-beyond`): run `beyond terms` and `beyond pointers` at the start of a session, and compare each topic you mine with an outside map once.
7. **Propose** (sections 5 and 6). Each proposal names its route, its ingredients, its reach, what the outside check found, and the proof it would need.
8. **Record.** `zoom topic:<slug> --explored "<what was mined, proposed, accepted or dropped>"`, and at the end of the session `routes --record`. After the next sources are integrated, `routes --changes` says what they moved (section 8).

Where the session can start subagents, give each branch to one, and each outside check to one: it returns a shortlist, each item with its need, its route, the ingredients it verified, what it found outside and the question to put to the user. The main conversation holds the top level and the shortlists, none of the reading. Without subagents, finish one branch and note its shortlist before the next. For a long run with competing agents, hourly meetings, referees and proofs of concept, see `brain-mesh-campaign`.

## What discovery reads from the ontology

Every miner, route and reach verdict reads one index of the brain, the lens. What is not coded is invisible to all of them, so the first way to improve discovery is to code more. `python3 tools/mesh.py routes --readiness` says how much of each line below is coded and which routes it limits.

| Dimension | Coded as | What it lets discovery see |
|---|---|---|
| Kind of concept | `kind::` entity, variable, technique, concept; `unit::` | what can be measured, what measures, what is a condition |
| Hierarchy | `broader::`, `part_of::` | topics; a profile mark that covers a family of techniques |
| Relations | `affects::` with its basis; effects visible in the data | chains, mechanisms never tested, one driver of several outcomes |
| What a result is of | `value::` | pooling, ceilings, contradictions in the numbers |
| Conditions and systems | `when::`, categorical values as concepts (species, preparation) | moderators, extension to an untried system, whether two halves can be joined |
| How a result was obtained | `obtained_by::` to a method card that links a technique concept | which techniques measure what; tools never brought to a question; reach |
| What is wrong with a method | `limitation` cards that link the technique | bottlenecks: where a new method would move most |
| What the authors say is open | `question` and `limitation` cards | gaps two or more groups already agree on |
| Epistemic grade | evidence `status`, finding grade | whether a statement was ever measured; cornerstones thinly supported |
| The study | `design::`, `sample::`, authors, kind (preprint) | independent groups, not paper counts; what a result can establish |
| Data and code | `uses_data::`, data-set cards with access | what can be reanalysed today; open data nobody else has used |
| What was read | `coverage::` | where the answer may already be on a page nobody read |
| Citations | reference cards, `cites::` | whether two literatures already cite each other; works much leaned on and not held |
| Synthesis | findings, tensions, contradictions, gaps, hypotheses, theories | the needs themselves, and what already works on each |
| The user | priority; the research profile | where to look first; what is in reach |
| History | stamps, `ledger/signals.md`, `ledger/routes.md`, `ledger/outside.md`, `ledger/explored.md` | what was judged, what was shown, what was checked, and what has changed since |

A low line in `--readiness` is a housekeeping task that pays in discovery: a lens pass to code conditions, method cards linked to their technique, `uses_data::` on results, a definition card for a much-used variable.

## The research profile

`PROFILE.md` says what the user's group can do, in the brain's own terms. It is the user's statement, like priority: it directs attention and never counts as evidence. **Record only what the user says.** Never mark a technique from a guess about their lab.

1. `python3 tools/mesh.py profile` lists every technique, organism and preparation the brain uses, most used first, and which are unmarked. `profile init` starts the file.
2. Interview the user in a few questions, the most used first, with the multiple-choice tool where the session has it: which of these do you have, which could you reach through a partner, which are out? Then the designs they run, the data they can access, what they bring from outside the field, where they could apply a finding, and the scale of one project.
3. Record: `profile have|reach|out <concept ...> --note "<why, or through whom>"`, `profile designs <design ...>`, `profile data <access ...>`, `profile brings "<name>" "<what it does>"`, `profile applications "<area>"`, `profile scale "<text>"`. A mark on a broader concept covers the techniques that are a kind of it, so one line can rule out a family: propose the broader concept to the user if the brain lacks it.

Every opportunity then carries a verdict: **in reach**, **with a partner**, **unclear** (not enough is recorded, or it is the user's call: a new method, a resource, an application) or **out of reach**. The verdict is the best of three ways of doing the work: from the published record alone, by reanalysing data its cards use, or by measuring again with a technique and in a system the profile has. Out-of-reach opportunities are never dropped: `routes --reach out` lists them, and they go into the research-gaps document as work for a collaborator.

## Routes

A route is one of the ways a paper makes a contribution. Each is a checklist of ingredients, and each ingredient is a question the lens answers from the Codes: present, missing, or not coded. `python3 tools/mesh.py routes --list` prints them all.

| Family | Route | Fed by | The proof it would need |
|---|---|---|---|
| Recombining what is published | `resolve-contradiction` | open contradictions and tensions | each side reproduced under its own conditions, the one difference varied alone |
| | `unification` | `unify` | a new prediction that survives data the account was not built on |
| | `joining-literatures` | `bridges` | a direct test of A→C |
| | `pooling` | `constraints` | a pooled estimate with its spread explained |
| | `framework` | `definitions` | criteria that sort the cases and show what is missing |
| Established means, well aimed | `fill-gap` | open gaps, `recognised` | a design whose answer matters whichever way it falls |
| | `decisive-test` | `theories`, hypotheses with rivals | predictions stated beforehand that diverge where one can reach |
| | `mechanism` | `mechanism`, `implied` | an intervention showing necessity and sufficiency |
| | `extension` | `transfer` | the same measurement in the new system |
| | `replication` | `cornerstones` | a well-powered repeat by another group |
| | `scale` | `data` | a regularity that only shows at that scale |
| A borrowed means | `tool-transfer` | `tools`, `transfer`, the import pass | a head-to-head with the standard method |
| | `concept-transfer` | `analogies`, the analogy pass | a prediction the home theories do not make |
| Surprise | `new-phenomenon` | `oddities` | controls that exclude artefact, and a repeat |
| | `overturn-assumption` | `assumptions` | a direct test |
| | `existence-proof` | `limits` | one working instance against a stated criterion |
| A new means | `new-method` | `bottlenecks` | validation against a known answer |
| | `new-model` | `ceilings` | the best method beaten on held-out data |
| | `new-resource` | `data` | open release with one demonstration |
| Outward | `translation` | probable and established findings, when the profile names an application | a trial against the current standard |

`routes [topic:<slug> | <concept> | <id>]` lists the opportunities, best first, in about 1,500 tokens (`--budget`); `--route <name>` keeps one route; `--reach in|partner|unclear|out|all` filters by reach. The rank weighs the need (priority, how open it is, the heat of its concepts), how many of its ingredients are present, and its reach; it is a way to order prompts, never a measure of worth. Each opportunity prints:

```
4. resolve-contradiction: V003 [contradiction, open] The paper says ... · topic:odour-intensity
   has: measured or derived on 2 of 2 cards · conditions recorded on 1 of 1 observations · data available: D004 (open)
   missing: nothing works on it · no hypothesis or registered prediction
   not coded: not checked outside the brain (`mesh.py outside V003`)
   reach: in reach (reanalysis of D004 (open))
   next: propose a seed or hypothesis that takes it up · proof it would need: each side reproduced ...
```

The ingredients: `groups` (two or more independent groups behind it), `strength` (measured, not only asserted), `alike` (the sources define and measure the quantity alike), `conditions`, `methods`, `data` (open or on request), `basis` (a relation tested, not only correlated), `rivals` (rival accounts carded), `prediction` (a hypothesis or experiment states one), `works` (some card takes it up), `rests` (how much is built on it), `question` (an open question turns on it), `searched` (a gap's literature search), `uncited` and `system` (two halves that do not cite each other and share a species), `outside` (checked outside the brain) and `read` (its sources read in full). **Not coded is not missing**: it means the cards do not say, and the next step is to look or to code it.

## Outside the brain: what Claude knows, and what the literature holds

The brain holds a handful of sources; the field holds thousands, and Claude has read widely in it. Use both, and keep both apart from the evidence.

1. **`python3 tools/mesh.py outside <need>`** prints the brief for one need (a card id or a signal key): what the brain holds, the sources with their DOIs, search terms from the concepts and their aliases, and one question for each ingredient the ontology lacks. For example: has an independent group reported this; is there an open data set; is there a standard definition; has the relation been tested by intervention; has a preprint since been published or corrected; is a data set of unknown access deposited anywhere.
2. **Ask what you know first.** Answer each question from your own knowledge of the science: the work that probably exists, the method that would supply the ingredient, the known explanation, the name the idea goes by in another field, the confound a specialist would raise. This aims the search and often says what is missing from the brain. It is not evidence: what Claude knows may be wrong, out of date or misremembered.
3. **Then search.** Use the literature connectors the session has (PubMed, bioRxiv and the like), then web search; data repositories for data; the papers that cite the brain's sources as well as keywords. Follow rung 2 of `brain-mesh-gaps` for how to search and screen. A search confirms or kills what you believed.
4. **Record what came back:** `outside add <need> nothing|answered|partly|lead --where "<where searched>" --query "<queries>" --found "<DOIs or links>" --note "<what it means>"`.
   - `nothing`: a search found no answer. Say where and when: "no answer found in PubMed and bioRxiv on 2026-11-23", never "nobody has done this".
   - `answered` or `partly`: name what was found. Put the paper on the reading queue (`ledger/reading-queue.md`) and tell the user which PDF to supply. The opportunity becomes a reading task.
   - `lead`: what Claude believes without a source in hand. It stays a lead until a search finds the source.
5. **Nothing from outside goes onto an evidence card, a concept hub or a finding until its source is carded** (`brain-mesh-add-paper`). In a proposal, mark each outside statement as "found: <reference>" or "from Claude's knowledge, not verified".

`routes` reads the record: a need checked and found open gains the ingredient `outside`; one answered outside says so and points to the paper; one with only a lead, or checked longer ago than the staleness limit for its priority, is shown as not coded. A gap keeps its own Search log on the gap card. Outside checks are also how uncertainties are cleared: a preprint's later version, a retraction, a data set's access, a reference the sources lean on that nobody here has read.

**What the brain cannot name.** An outside check answers a question about one need. The ontology's own blind spots (a concept the sources use and no card names, a link the field makes and no card holds, a tool another field uses for the same kind of problem, the literature around the sources) are found by `mesh.py beyond` and `brain-mesh-beyond`. `outside <need>` ends with the cross-field question and lists the outside tools kept for that need; `routes --readiness` says how many topics have been compared with an outside map; the recheck (section 8) says which leads a new source now names.

## 1. When to run

- The user asks for new ideas, hypotheses or connections, or what the brain implies.
- After a paper or a batch is integrated: always `discover --recheck` (section 8), which also says what the new sources moved among the routes; then `routes` if the user wants new proposals.
- Before proposing experiments: seeds and unseparated theories feed `brain-mesh-experiment`.
- Around a session: a frontier map and a contradiction dossier (`brain-mesh-report`) show where the signals sit among the open contradictions and gaps; `report novelty S004` checks a seed against the brain before it is promoted.
- On a schedule, as an insight pass with nobody watching (section 7).

`python3 tools/mesh.py discover` with no miner named is an overview: the top three signals of every miner, one line each, without detail or stamp lines, so that it stays small however large the brain. Name miners for their cards, tags and stamp lines (`discover bridges moderators`), or add `--full` for every miner in full; `--focus <concept>` keeps signals involving one concept, and `--focus topic:<slug>` those involving any concept of a topic from `zoom`; `--top N` shows more per miner; `--all` includes rejected signals.

## 2. The miners

Each miner reads only the Codes. Scores rank signals within one miner, never across miners.

| Miner | What it finds | What a good proposal from it usually becomes |
|---|---|---|
| `contradictions` | Possible contradictions in the Codes not yet on the register (`contradicts::` links, values of one quantity that clash under the same conditions, a recorded effect the data reverse, opposite directions in different sources, a null result against an effect, evidence against a finding), and open contradictions that no theory, hypothesis, seed or experiment works on yet. | A contradiction logged on the register (housekeeping, once judged real); for an open one, a theory that makes both sides true, a hypothesis naming the hidden variable, or a discriminating experiment. |
| `bridges` | Two concepts that no evidence card or finding holds together, joined through other concepts in different sources (Swanson's ABC: A–B in one paper, B–C in another, A–C never looked at). Sibling values of one variable and hub concepts are skipped. | A seed: does A affect C, or has technique T been used on X? |
| `moderators` | For open and explained tensions and contradictions, findings with evidence against them, and parallel results that disagree beyond their errors: the conditions, methods and materials that differ between the sides. | A seed naming the hidden variable; a rival in a hypothesis; a line in the tension's possible explanations. |
| `definitions` | One term defined or operationalised in its own way by two or more sources (their `definition` cards); one quantity measured by different techniques in different sources; two concepts with overlapping definitions that no card uses together and that different sources use (two names for one thing); open contradictions and tensions whose sides do not define or measure the quantity alike. Low-priority concepts and counts are left out. | A `definition` contradiction on the register; a way out written on a contradiction or tension; a note under **How it is measured** on the hub; on the user's word, one concept folded into another (`merge`) or split into narrower ones. `table <concept> definitions` lays the sources side by side. |
| `transfer` | An outcome, a method or a finding established at one value of a categorical variable and never tried at another value present in the brain (species, preparation, level, solvent …). | A gap of kind `untested-region`, or a seed for a method transfer. |
| `implied` | Chains of effects, recorded on concept cards or visible in the data: A → B → C with A → C never measured (with the sign the chain predicts); a direct effect opposite to the indirect one; loops. Also effects the data show that no concept card records (housekeeping). | A seed or hypothesis with a signed prediction. |
| `constraints` | Every value of one quantity pooled across sources and grouped by conditions: agreement within each condition set, spread, units. | Arithmetic across papers (a seed carrying the derivation); a tension where values clash; a correction where units are mixed. |
| `genealogy` | Works several sources lean on that are not in the brain, and what rests on the passages citing them; held works with no card stating what others cite them for. | A reading-queue entry (rung 2); a lens pass (housekeeping); a seed when a much-repeated claim rests on a weak original. |
| `assumptions` | Assumptions ranked by how many cards rest on them, whether anything tests them, and the same assumption in several sources. | A seed or gap of kind `untested-assumption`; a control in an experiment design. |
| `oddities` | Oddities in different sources that may share a cause; oddities nothing takes up, with the finding, theory or hypothesis that might absorb each. | A seed; an extension of a theory. |
| `theories` | The theory × finding matrix: findings no theory explains, findings no theory has been judged against, theory pairs nothing separates, active theories in conflict with strong findings, open tensions no theory addresses. | Verdicts on theory cards, a new theory, a discriminating experiment. |
| `analogies` | Relations true on the base side of an analogy and unstated on the target side; base findings with no target counterpart; concepts that would extend the mapping. | A seed or hypothesis with the analogy as its rationale. |
| `links` | Cards in different sources that share rare concepts and are not linked. | Housekeeping: link with a reason, or leave. |
| `unify` | One concept that bears on three or more outcomes, or on outcomes in two topics; one form (a law, a model) fitted to several quantities in different sources. | A seed or theory: one account behind them all, with the prediction it adds. |
| `tools` | A technique that measures a variable in another source, which the evidence behind an open contradiction, tension or gap never used. | A seed for a method transfer; a design in `brain-mesh-experiment`. |
| `mechanism` | Relations recorded as correlational, proposed or inferred that nothing has tested by intervention, with what rests on each. | A hypothesis with the intervention that would test it. |
| `recognised` | Open questions and limits that two or more independent groups state themselves (their `question` and `limitation` cards), and whether a gap card holds them. | A gap, already agreed by the field. |
| `cornerstones` | Findings held by one group, one source or a preprint, and evidence cards cited by several conclusions that no other source repeats. | A replication; a search for an independent source. |
| `bottlenecks` | Techniques that carry recorded limitations while observations rest on them; variables only ever inferred, never measured. | A seed for a new method; a gap of kind `method` or `unmeasured`. |
| `ceilings` | One score compared across methods or representations: the best each reaches. | A seed for a new model, with the benchmark it must beat. |
| `data` | Open data that only its own source has analysed; data that open questions turn on and that is unavailable; statements several groups make without the data behind them. | A reanalysis; a seed for a resource. |
| `limits` | Statements that something cannot be done, measured or predicted. | A seed for an existence proof. |

`python3 tools/mesh.py theories` prints the whole theory × finding matrix.

**Work the miners in this order.** Scores do not compare across miners, so the order is by what each settles:

1. **Check the ground:** `contradictions` (log or dismiss every candidate), `definitions`, `constraints`, `links`. Before building on a comparison, make sure the sources mean the same thing by the term, measure it the same way, and agree on the numbers.
2. **Explain disagreements:** `moderators`, then the contradiction pass (section 3).
3. **Extend what holds:** `transfer`, `implied`, `bridges`, `analogies`.
4. **Stress the structure:** `assumptions`, `oddities`, `genealogy`, `theories`, `cornerstones`, `mechanism`, `limits`.
5. **Look at the means:** `tools`, `unify`, `recognised`, `bottlenecks`, `ceilings`, `data`.

In practice `routes` gathers every miner's signals under the route each feeds, so a session reads `routes` and turns to a single miner only for more of one kind.

A signal from a later group that rests on an unsettled one from an earlier group waits for it.

## 3. Passes Claude runs by reading

Some of the best ideas need reading, not counting. Each pass produces proposals like a miner, with `- miner::` naming the pass and no stamp.

- **Contradiction pass.** Open the register (`ledger/contradictions.md`) and take each open contradiction in turn. A contradiction is the strongest prompt the brain has: something is missing from the account that both sides share. For each, ask what would make both sides true (a condition one side did not record, a difference of method or definition, a level of organisation, a time course) and what would show one side wrong. Propose the best answer as a hypothesis or a theory that `explains::` the contradiction, or as a seed `from::` it, with the experiment that would tell the ways out apart (`brain-mesh-experiment`).
- **Contradiction hunt.** The tooling sees contradictions only in the Codes. Reading the cards a signal names, or the evidence on a concept (`facts`), look also for statements that exclude each other in words: two mechanisms that cannot both run, a claim one paper makes that another's data deny, a concept fact a new card overturns. Log each one real with `contradictions add <card> <card> "<the clash>" --by "discover: <pass>"`.
- **Theory pass.** Gather the explanatory claims and models (claim and model cards that are inferred or speculated, especially those cited by findings and tensions). Group them into rival accounts. For each, propose a theory card: core claim, commitments, what it explains, what it forbids. Then propose a verdict for every finding against every theory: explains, conflicts or silent. The miner works from these cards.
- **Analogy pass.** Look for a system, in another field or another part of this brain, with the same relations as a structure here: the same circuit motif in another species, the same computation in an algorithm, the same physics in another material. Propose the mapping as an analogy card; the miner then lists what carries across.
- **Inversion pass.** For each established or probable finding that much rests on (`python3 tools/mesh.py impact K003`), ask what would follow if it failed at the edge of its scope, and propose seeds for the most consequential answers.
- **Levels pass.** Where cards carry a level of organisation (molecule, receptor, cell, circuit, behaviour), check that each claim at one level has evidence at the levels its mechanism needs. A computational claim with no evidence for its implementation is a seed.
- **Import pass.** For each tool or formalism the research profile lists under `brings`, and each one kept from outside the brain (`mesh.py beyond` lists them; `brain-mesh-beyond`, the import pass, says how they are found), take the hottest open needs (`routes`) and ask whether it applies: does the need's data have the form the tool takes, and what would it show that the home methods cannot? Propose each fit as a seed with `- miner:: import`.
- **Limits pass.** Read the `limits` signals in a topic. For each stated impossibility ask what has changed since it was written (a new method, new data, something the profile brings) and whether one working instance would overturn it.
- **Application pass.** For each probable or established finding, and each application the profile names, ask what the finding would let one build or decide. Propose with `- miner:: application`.
- **Red-team pass.** For high-stakes proposals, a separate agent that has not seen them tries to break the top ones and the findings they rest on.

## 4. The axes the miners need

`transfer` and `moderators` see only what is in `when::` lines. A brain that records species, preparation (in vivo, slice, culture, in silico), level of organisation and stimulus class as categorical `when::` conditions, each value its own concept card, can be mined across them; one that leaves them in the prose cannot. `brain-mesh-add-paper` asks for them at extraction. In a brain built without them, a lens pass adds them.

## 5. From signal to proposal

For each signal worth attention:

1. **Is it real?** Open the cards it names. Many signals come from the extraction: a missing `when::` line, one concept used for two things, a value in the wrong unit. Fix that as housekeeping and say so; it is not a proposal.
2. **Is it already known here?** Read the cards listed as `touched by`, and check the coverage of the sources involved (`index/coverage.tsv`).
3. **Does it respect the facts?** Run the `facts` call the signal names and read every line against the proposal (rule 2). Each effect is listed with its basis: a chain through a `correlational` or `proposed` relation predicts an association at most, so word the proposal that way, and prefer the experiment that would make the relation `tested`. Drop or reshape it where it clashes with a card that no logged contradiction frees; where it rests on a logged contradiction, say so in the case. A clash between two cards found on the way is logged on the register.
4. **What card would it become?** A seed by default. A gap, hypothesis, theory verdict or finding directly only when the brain already meets that card's own rules.
5. **Make the case.** Present three to seven proposals at a time, best first, mixed across miners. Never paste the miner output. Each proposal:

```markdown
**1. Seed: Binding capacity may fall in step with film thickness, film by film**
- From: bridges, binding-capacity ~ film-thickness, joined through swelling in P001 and P003
- Why it is worth a card: it turns the swelling account (T001) into a quantitative prediction that the damage account (T002) does not make
- Already known? X001 mentions both only as a possible explanation; both sources are fully extracted; no literature search yet
- Respects the facts? Yes: agrees with K001 and every card on binding-capacity and film-thickness; goes against nothing
- Route and ingredients: joining-literatures; has two independent groups, both halves measured; missing a stated prediction
- Reach: in reach (the rebinding assay and ellipsometry are in the profile)
- Outside the brain: no answer found in PubMed and bioRxiv on 2026-11-23; from Claude's knowledge, not verified: hydrogel work links swelling to lost imprint fidelity
- Proof it would need, and the fastest way to kill it: a paper reporting thickness and capacity on the same films; failing that, one heat cycle with both measured
- How sure the signal is real: high; both quantities are carded with conditions in two sources
- Prior and outcomes: expected to hold (r around 0.5); if it fails, the swelling account loses its strongest prediction; an expert would be surprised by a null
- Nearest obvious entry: "test the prediction in the system the papers name" (`mesh.py obvious`); differs in kind: a film-by-film relation, not a repeat
- Credibility checks: no circularity (thickness and capacity measured independently); best-of-many avoided by one registered correlation
- Time to first result: an afternoon on the published values; a paper in about six months
```

The last four lines come from the planning method (`brain-mesh-campaign`, **The obvious list** and **Credibility checks**):
`mesh.py obvious <topic|sources:P004,P005>` lists what any competent reader would propose next, so a proposal can say how it
differs; the credibility checks catch circular designs and effects made by the analysis rather than the system.

Ask the user to accept, edit, reject or defer each one, with the multiple-choice tool where the session has it.

## 6. Writing what the user accepts

**Seed** (`seeds/S###-<slug>.md`): an idea, judged worth a card and not yet a hypothesis or gap.

A card made from an opportunity also carries `- route:: <route> — <the need: a card id or signal key>` in its Codes, beside the miner's stamp, so the recheck and the next session can tell which contribution it aims at.

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

Everything discovery shows is contingent on the sources in the brain and on how they are coded. Nothing is stored as a result: the miners, the routes and the reach verdicts are computed afresh at every call. What is stored is the history, and the recheck compares the brain with it.

The integrate step of `brain-mesh-add-paper` and the merge phase of `brain-mesh-batch` end with `python3 tools/mesh.py discover --recheck`. It re-runs the miners behind every stamped card that is still live, and behind every rejection, and sorts them:

| State | Meaning | What to do, with the user |
|---|---|---|
| dissolved | The signal is no longer produced. The tool names the new cards that now hold its concepts together, or the cards changed since the stamp. | Read those cards. If they settle the question, the seed is `answered`, with `answered_by::`; if they bear it out, promote it (to a finding through `brain-mesh-add-paper`, or a hypothesis). If an edit or merge removed the signal rather than evidence, rewrite the seed's basis or drop it. |
| strengthened | New sources joined its basis. | Read the new cards; offer to develop or promote the card; replace the stamp. |
| weakened | Sources left its basis: a retraction, merge or correction. | Tell the user, judge it again, then replace the stamp or drop the card. |
| changed | The score moved with no new source (a lens pass, edits). | Re-read it and replace the stamp. |
| re-opened | A rejected signal gained a source. | Propose it again, saying what is new and quoting the reason it was rejected. |
| standing | Nothing changed. | Nothing; the stamp keeps its date. |

The recheck ends with **what moved among the routes** since the last `routes --record` (`routes --changes` prints it alone):

| Heading | Meaning | What to do, with the user |
|---|---|---|
| An ingredient arrived | An opportunity gained what it lacked: an independent group, a measurement, data, a prediction. | It may now be ready: verify it and propose it. |
| Reach changed | The profile changed, or a new source showed another way to measure. | Re-rank; tell the user what came into reach. |
| New | An opportunity that a source or card added since has brought. | Judge it like any other. |
| Set aside before, reopened | A signal the user rejected, on which a source added since now bears. | Propose it again, quoting the reason it was set aside. |
| An ingredient went | A retraction, a correction or a recoding took something away. | Tell the user; the proposal built on it needs another look. |
| Gone | The need was closed, carded or set aside, or the miner no longer raises it. | Nothing, unless a card was built on it. |

Outside checks age too: one older than the staleness limit for its priority counts as not made, and `routes` asks for it again. After the user has seen the changes, `routes --record` so the next comparison starts from here.

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
