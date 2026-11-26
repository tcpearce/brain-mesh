---
name: "brain-mesh-campaign"
description: "Run a discovery campaign on a brain mesh, on a topic or as a follow-on from named papers: several discovery agents, one lens each, compete for the proposals that score highest on impact, cogency, realism and originality against the list of what is already obvious, meet every hour to compare notes, run registered proofs of concept of under an hour on open data, search outside the brain for novelty, and ask for downloads only with the case for them; blind referees and a verifier score; the user gets one slate at the end. Use when the user asks for a campaign, competing or coordinated discovery agents, a long unattended discovery run, or the next study or follow-on experiments from a paper or set of papers in the brain."
---

# Brain mesh: discovery campaigns

Read `brain-mesh`, `brain-mesh-access` and `brain-mesh-discover` first. A campaign is discovery done by a team: the same
miners, routes, facts and outside checks, run by agents that compete on the quality of what they propose and share
everything else. It ends where discovery always ends: with proposals put to the user, who decides what enters the brain.

## The rules

1. **Nothing enters the brain without the user.** Agents write only in the campaign folder (`campaigns/<date>-<name>/`).
   The slate at the end goes to the user in the format of `brain-mesh-discover` section 5; accepted proposals become seeds,
   hypotheses, gaps or experiments (`- miner:: campaign`), rejected ones stay in the campaign folder as its record.
2. **Ideas compete; information does not.** Every agent writes what it learns in its shared notes. A proposal cannot score
   on anything that was not shared at a meeting before it was scored.
3. **The facts are constraints.** Rule 2 of `brain-mesh-discover` holds for every proposal: it agrees with every evidence
   card, finding and concept fact that bears on it, unless a logged contradiction frees that card.
4. **Outside knowledge is a lead.** What an agent finds on the web may aim a proposal and must be cited in it; it enters the
   brain only as a carded source, through a download request the user approves.
5. **Registered before run.** A proof of concept is preregistered and sealed before its code is run; changes after that are
   amendments, said as such.
6. **Blind scoring.** Referees judge the proposal file, not its author. No agent scores its own lens.
7. **The user's limits decide reach.** The research profile (`PROFILE.md`) and any constraints the user stated for the
   campaign. An idea out of reach is scored low on realism, not hidden.

## Who takes part

| Role | Number | What it does |
|---|---|---|
| Chair | the main session | sets scope and budget, keeps the clock, launches and resumes agents, runs meetings, keeps the record, writes the slate. Never proposes. |
| Discovery agents | 3 (pilot) to 5 | one lens each (below); propose, test, attack, build on each other's work |
| Referees | 2 (pilot) or 3, fresh each meeting | blind scores on the three axes, gates, pairwise preferences |
| Verifier | 1, fresh each meeting | adversarial novelty audit; reruns every reported proof of concept |

The lenses (`mesh.py campaign init --agents`):

| Lens | Looks for | Starts from miners | and routes |
|---|---|---|---|
| `recombiner` | contradictions, hidden moderators, literatures that never meet, poolable numbers | contradictions, moderators, bridges, constraints, definitions, unify | resolve-contradiction, joining-literatures, pooling, framework, unification |
| `mechanist` | untested chains of effects, theories nothing separates, beatable models | implied, mechanism, theories, analogies, ceilings | mechanism, decisive-test, concept-transfer, new-model |
| `sceptic` | load-bearing assumptions, single-group cornerstones, oddities, much-cited unread claims | assumptions, cornerstones, oddities, genealogy, limits | overturn-assumption, replication, new-phenomenon, existence-proof |
| `transferer` | untried species, preparations and levels; tools from other fields | transfer, tools, analogies, bottlenecks | extension, tool-transfer, concept-transfer, new-method |
| `datascout` | what open data can answer now | data, constraints, ceilings, recognised | scale, new-resource, new-model, pooling |
| `instrumentalist` | the field measures the wrong quantity: build or validate the right one (a horizon, a ceiling, a coefficient, a missing control) | bottlenecks, ceilings, definitions, limits | new-method, new-model, framework, existence-proof |

**Adjacent and distant lenses.** Recombining what is published and reanalysing open data (`recombiner`, `datascout`) stay close
to the papers' own neighbourhood and reliably produce the obvious; attacking a premise (`sceptic`), building the right
instrument (`instrumentalist`), importing from another field (`transferer`) and mechanisms (`mechanist`) are distant. Put most
agents on distant lenses. A follow-on campaign defaults to `sceptic`, `instrumentalist` and `transferer`.

**Size and cost.** A pilot is three agents, three rounds of about 50 minutes, two referees and a verifier at each
meeting: about 18 agent runs over three hours. A standard campaign is five agents and four rounds. Every agent starts cold
and reads the brain, so a campaign uses a great deal of the user's allowance; say so before starting a larger one.

## The chair

**Set up**

1. Sync and upgrade the vault (`brain-mesh-access`). Choose the scope: a topic (`--scope topic:<slug>`; the user's choice,
   else the hottest topic that is rich in open data and is not a catch-all), or, for a **follow-on campaign**, the papers the
   next study should follow from (`--sources P004,P005`). A follow-on campaign uses the rest of the brain as the literature
   around those papers: every proposal names the result in them it builds on.
2. Read `PROFILE.md`. If there is none, the campaign runs on the constraints the user has stated; offer to build the profile
   (`brain-mesh-discover`, **The research profile**).
3. `python3 tools/mesh.py campaign init <name> --scope topic:<slug> --agents recombiner,mechanist,sceptic --rounds 3 --minutes 50 --constraint "<each limit the user stated>"`.
   It writes `CAMPAIGN.md`, one `agents/<lens>/BRIEF.md` per agent, `referee-brief.md`, `verifier-brief.md`, `decisions.md` and
   `OBVIOUS.md`, the list of what is already obvious (below). Read OBVIOUS.md before the agents start: if an entry is wrong or a
   standard move is missing, edit it; it is the bar every proposal must clear. Campaigns rank by impact unless `--rank composite`
   is given. `campaign briefs` rewrites the briefs from the current templates. With more than one campaign running, every
   `campaign` command takes `--campaign <name>`.
4. Commit the campaign folder (`sync "campaign <name>: started"`) so that it can be resumed from anywhere.

**Each round**

1. Start every discovery agent in the background, at once: "You are the `<lens>` agent of campaign `<slug>` in the vault at
   `<path>`. Round `<n>` ends at `<UTC time>`. Read `<campaign>/agents/<lens>/BRIEF.md` and follow it." In later rounds,
   resume each agent with its context (send it a message) rather than starting it afresh, with the meeting's digest, its
   scores and the referees' notes on its proposals, its assignment and the new deadline.
2. Set a wake-up for the meeting (a reminder in this session for the round length plus five minutes) as a backstop; an agent
   that has not returned by then is asked to stop and report.
3. While they work, do nothing to the vault. Answer the user if they write.

**Each meeting**

1. When every agent has reported: `python3 tools/mesh.py campaign check`. Errors in an agent's files go back to that agent;
   do not fix them for it.
2. Start two or three referees and the verifier in the background, fresh: "Read `<campaign>/referee-brief.md` (or
   `verifier-brief.md`) and follow it; your name is R1." Each scores with `campaign score`, compares with `campaign compare`,
   replicates with `campaign poc replicate`.
3. `python3 tools/mesh.py campaign meeting <n>` prints and writes the scoreboard, the credit, the ranked download requests and
   the proposed cut (the bottom half of the live proposals, except at the last meeting). Decide merges and kills
   (`campaign set <id> merged --into <id> --why …`, `campaign set <id> killed --by <agent> --why …` only where a refutation
   rests on evidence), then `campaign meeting <n> --cut`.
4. Write in `meetings/round-<n>.md`, below the generated part: the merges and kills with reasons; the **digest** of everything
   the agents shared (data sets and how to reach them, searches and their results, dead ends, nulls, outside facts), in
   short lines; and each agent's **assignment** for the next round. Agents whose proposals were all cut or killed join a
   leader: as its replicator, its red team, or the author of its decisive experiment, with `builds_on::` credit.
5. Record the outside searches worth keeping with `outside add` (the agents do not write the shared ledger).
6. `sync "campaign <name>: meeting <n>"`, then resume the agents for the next round.

Record every steer the user gives during the campaign in `decisions.md`, with what it changed.

**Stop** after the last round, or earlier when a round adds fewer than two survivors (the meeting says so), when the top five
have not changed for two meetings, or when the budget is spent.

**Close**

1. `python3 tools/mesh.py campaign close` writes `REPORT.md`: the slate (the top live proposals that pass the gates, by impact
   or composite as the campaign ranks, then pairwise rating), informative nulls, the download requests by value over effort,
   **what would unlock most**, where agents converged independently, the user's steers, the scoreboard and the credit. Write
   its **Recommendation** yourself: which study to do next and why, including whether the highest-impact study is the right one
   to start, given the time to its first result.
2. Put the slate to the user, three to seven proposals, in the format of `brain-mesh-discover` section 5, adding each
   proposal's scores, its proof of concept and replication, and its novelty verdict. Put the download requests to them
   separately, each with what it would settle.
3. Write what the user accepts (`brain-mesh-discover` section 6, `- miner:: campaign`, `- from::` the cards it rests on,
   and a line in the prose naming the campaign file). A proof of concept the user wants kept becomes an own result
   (`brain-mesh-add-paper`, **Own results**). Approved downloads go to the reading queue or straight to `brain-mesh-add-paper`.
4. `sync "campaign <name>: closed; <n> accepted"`.

## For discovery agents

Your brief names your lens, your files and your deadline. These are the formats and rules it refers to.

**A proposal** (`proposals/<PREFIX>-NN-<slug>.md`), one hypothesis each:

```markdown
# <the hypothesis in one sentence, specific enough to be wrong>

**Hypothesis.** What is claimed, with the conditions under which it holds.
**Mechanism.** Why it would be so.
**Rests on.** The cards it builds from, in words with links: [[K003]], [[V005]], [[P012-004]].
**Novelty search.** Where and when searched, the queries, what was found (DOIs), and the verdict.
**Proof of concept.** What was run, the registered prediction, the result; or why none is possible in an hour.
**Decisive experiment.** The cheapest experiment whose outcome would settle it either way: design, n, cost, time, who could run it.
**Impact if true.** Which findings, contradictions, gaps or theories it would change, and what follows outside the brain.
**How it could be killed.** The observation that would refute it.
**Prior and outcomes.** What you expect to find and how sure you are; what each outcome would change; would an expert be
surprised by either? A first measurement of what the field already assumes is the prior dressed as a result.
**Nearest obvious entry.** The entry of OBVIOUS.md closest to this proposal (O-NN) and why this differs from it in kind, not degree.
**Credibility checks.** Each form of circularity and pipeline artefact that could apply (below), and the control that severs it.
**Follows on from.** In a follow-on campaign: the result of the named papers it builds on, with its card.

## Codes
- id:: REC-01
- owner:: recombiner
- round:: 1
- status:: active
- route:: resolve-contradiction
- rests_on:: [[V005]], [[K003]], [[P012-004]]
- signal:: contradictions:V005
- builds_on:: MEC-02 — what it takes from it
- novelty:: open — PubMed, bioRxiv and web, 2026-11-26
- poc:: passed
- reach:: in
- needs:: [[calcium-imaging]] — what the decisive experiment needs that may be out of reach
- first_result:: two weeks
- paper_months:: 9
- follows_on:: [[P004-056]] — in a follow-on campaign
```

`first_result::` is how soon the first informative result could come, and `paper_months::` how long to a submittable paper:
they often differ tenfold, and the first decides what to start on Monday. `needs::` names each technique, system or resource
the decisive experiment needs (concept links), so the unlock table can count what a partner would make possible.

`novelty::` is `open` (searched, nothing found), `partly`, `answered` (published already: withdraw it and request the paper)
or `unchecked`. `poc::` is `none`, `planned`, `registered`, `passed`, `failed` or `inconclusive`. `reach::` is `in`,
`partner`, `unclear` or `out`, judged from the profile and the campaign's constraints. To withdraw your own proposal, set
`status:: withdrawn` and add `- history:: <date> round <n> withdrawn — <why>`; it costs nothing.

**A proof of concept** (`poc/<id>/`), under an hour of wall-clock time including fetching the data:

1. Write `PREREG.md` with **Prediction.** (direction and size), **Primary analysis.** (one), **Threshold.** (what counts as
   passed, failed, inconclusive), **Data.** (the set, version and subset) and **Controls.** (a shuffled-label or
   permutation null, a negative control, held-out data where the set allows).
2. `python3 tools/mesh.py campaign poc register <id>` seals it. Only then run the code.
3. Keep the code in `poc/<id>/` (a script that runs from a clean copy), the raw data in `poc/<id>/data/` (not committed),
   `DATA.md` saying where the data came from and how to fetch them again, and `result.md` starting `- outcome:: passed|failed|inconclusive`,
   then the numbers, the figure if any, and an **Amendments.** paragraph for anything done differently from the registration.
   Any further analysis is labelled exploratory and does not change the outcome.
4. A failed proof of concept is worth reporting: it is an informative null, and the slate lists it.

**Data you can reach.** In a cloud session the shell reaches GitHub and the package indexes (PyPI and the like) only:
data sets kept on GitHub (cloned, or read through a package that fetches from GitHub) work directly; Zenodo, figshare,
Hugging Face, EBI and NCBI downloads are refused. Do not try other routes around the refusal. Such a set becomes a
download request, or the user runs the fetch on their own computer. Data sets in the brain have cards (`data-sets/`):
start from those marked open. A data set is in scope when its variables map onto concepts of the brain; say which in `DATA.md`.

**Novelty.** Before a proposal is scored, search: what you know first, then PubMed and bioRxiv where the session has them,
then the web, with at least three phrasings and the papers that cite the brain's key sources (`outside <need>` gives the
questions and terms). Report it in **Novelty search.** "Nothing found" always says where and when.

**Download requests** (`downloads/<PREFIX>-DLNN-<slug>.md`), for a paper, data set or code the brain lacks:

```markdown
# <what it is, in a line>

**What it would settle.** The contradiction, gap, seed or theory it bears on, the signals it should move, and the proposals
that depend on it; what would be different in the brain once it is carded.

## Codes
- id:: REC-DL01
- what:: <DOI, accession or URL>
- kind:: paper | data-set | code
- access:: open | on-request | restricted | unknown
- licence:: <licence>
- effort:: <1 (a table) to 5 (a long paper with supplements)>
- solves:: [[V005]] — how, [[G002]] — how
- for:: REC-01, MEC-02
- by:: recombiner
```

**Notes and reports.** Everything worth sharing goes in `agents/<lens>/notes.md` under `## Round <n>`. Your round report
to the chair is at most 300 words.

## The obvious list

`python3 tools/mesh.py obvious <scope>` (written to `OBVIOUS.md` at init) lists what any competent reader of the papers would
propose next, from the brain itself: every question and limitation the papers state, the open questions several independent
groups already share, what would settle the open gaps, contradictions and tensions, the findings resting on one group, and the
standard moves (test the prediction, another data set, a newer model, scale up, a second target, prospective validation, another
species or level, make and test). Agents read it first; a proposal on it must differ in kind, not degree; referees score
**originality** against it. Without such a list, "be original" is an exhortation; with it, originality can be checked.

Originality is a gate, never a goal: striking the obvious must not reward the merely exotic. Impact stays the ranking axis.

## Credibility checks

Every proposal works through these, and every referee checks them whether or not the proposal raised them. Named and
controlled is a strength; uncontrolled is a failed gate.

| Circularity | The question |
|---|---|
| Train/test overlap | was the model or representation fitted on any data now used to evaluate it? Count it. |
| Label downstream of the ground truth | is the predicted quantity a coarsening of the target? |
| Model-scored evaluation | is the "ground truth" itself a model's output? |
| Shared upstream data | do predictor and outcome come from a common source (the brain's data-set cards and `independence` show it)? |
| Selection on the outcome | was the test set chosen by criteria related to the outcome? |
| Definitional | is the measured thing defined by its instrument? |
| Filter validated by itself | does it select on a criterion and then demonstrate that criterion? |

| Pipeline artefact | Where it bites |
|---|---|
| Dimensionality | distances concentrate as dimensions grow: decaying curves are the default, not a finding |
| Compression | performance against number of components has a generic shape whatever the features mean |
| Capacity | more parameters fit better in sample |
| Double dipping | features or thresholds selected by their association with the outcome, then tested on the same data |
| Best of many | sweeping a parameter and reporting the best value |
| Base rates | accuracy driven by class priors |
| Preprocessing leakage | normalisation, imputation or selection before the split |
| Unmatched freedom | a learned or weighted metric compared with a fixed one without matching their freedom |

The general test: would the effect appear if the real structure were destroyed and the pipeline left identical? The control is
the **pipeline null**: the whole analysis rerun on permuted labels, shuffled correspondences or phase-randomised data. Every
proof of concept in a format-2 campaign registers one among its controls.

## Scoring

Each referee scores each live proposal on four axes, 1 to 5: impact, cogency, realism and, where the campaign has an
OBVIOUS.md, originality.

| | 1 | 3 | 5 |
|---|---|---|---|
| **Impact** | touches one card; nothing builds on it | settles an open contradiction or gap, or re-grades a finding others rest on | separates rival theories or overturns a cornerstone; changes what the field would do next |
| **Cogency** | asserted; a mechanism is missing or it strains a fact | a plausible mechanism, consistent with every fact that bears on it, rivals named | a mechanism with independent support, rivals addressed, a proof of concept pointing its way |
| **Realism** | needs what the user cannot reach, years or a new field | a partner's technique or months of work; the decisive experiment is specified | in reach with the user's means, weeks, every outcome informative |
| **Originality** | an OBVIOUS.md entry, or the papers' own future work | a real idea, visibly adjacent to an entry but asking a different question | nobody reading the papers would have proposed it: it reframes, attacks an unquestioned premise, or imports from a field that does not cite this one |

Impact weighs **surprise** (would an expert be surprised by either outcome?), **knowledge over capability** (a property of the
system, such as a horizon, a ceiling or a coefficient, outlives one of an artefact, such as a hit rate for one library),
reach, durability and what it leaves for others to reuse.

**Gates.** A proposal fails a gate, and scores 0 however good it looks, when: a claim traces to no card and no cited source;
it clashes with a fact or piece of evidence no logged contradiction frees; it has no way to be killed; or its proof of concept
was reported without registration, the registration was changed afterwards, or the verifier could not reproduce it.

**Novelty** multiplies: open 1, unchecked 0.8, partly 0.6, answered 0. The verifier's verdict counts; without one, the most
cautious referee's.

**Ranking.** A campaign ranks by **impact** (the default) among the proposals that pass the gates: in such a campaign
cogency below 2.5 (it cannot answer its own question) and originality below 2 (an OBVIOUS.md entry in disguise) are gates too.
Realism is reported, never used to rank: low realism is a finding, and **what would unlock most** (from each proposal's
`needs::` and the research profile) says which partner or resource opens the best ideas. A campaign started with
`--rank composite` ranks instead by the cube root of impact × cogency × realism × novelty, × 0.9 while a reported proof of
concept awaits replication.

**Pairwise.** Referees also say which of two live proposals they would rather the user pursued, up to ten pairs each. A
Bradley-Terry fit turns these into a rating (1000 is average), shown beside the composite: it is the steadier of the two
when absolute scores drift between referees, and it breaks ties.

**Credit.** An agent's credit is the composite of its live proposals, plus a quarter of the composite of others' live
proposals that build on its work (`builds_on::` a proposal or `notes:<lens>`), plus one for each proposal killed on its
evidence. Withdrawing a weak proposal costs nothing. Credit is reported, not rewarded: it shows who carried the campaign
and keeps sharing worth an agent's while.

**Successive halving.** Each meeting but the last cuts the bottom half of the live, scored proposals, so the later rounds
spend their time on the proofs of concept and experiment designs of the best. The meeting also counts the **survivors**
(gates passed, impact at least 4) and how many are new this round.

## After the campaign

The campaign folder stays in the vault as the record: briefs, notes, proposals, registrations, results, scores, meetings and
the report. A later campaign on the same scope starts by reading the last one's report and notes, and by `discover --recheck`:
what the user accepted is followed by the brain's own lifecycle from then on.
