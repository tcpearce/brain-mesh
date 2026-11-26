---
name: "brain-mesh-campaign"
description: "Run a discovery campaign on a brain mesh: several discovery agents, one lens each, compete for the proposals that score highest on impact, cogency and realism, meet every hour to compare notes, run registered proofs of concept of under an hour on open data, search outside the brain for novelty, and ask for downloads only with the case for them; blind referees and a verifier score; the user gets one slate at the end. Use when the user asks for a campaign, competing or coordinated discovery agents, or a long unattended discovery run."
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

**Size and cost.** A pilot is three agents, three rounds of about 50 minutes, two referees and a verifier at each
meeting: about 18 agent runs over three hours. A standard campaign is five agents and four rounds. Every agent starts cold
and reads the brain, so a campaign uses a great deal of the user's allowance; say so before starting a larger one.

## The chair

**Set up**

1. Sync and upgrade the vault (`brain-mesh-access`). Run `zoom` and `routes` to choose the scope: the user's choice, else
   the hottest topic that is rich in open data and is not a catch-all (a topic of species or preparations is too broad).
2. Read `PROFILE.md`. If there is none, the campaign runs on the constraints the user has stated; offer to build the profile
   (`brain-mesh-discover`, **The research profile**).
3. `python3 tools/mesh.py campaign init <name> --scope topic:<slug> --agents recombiner,mechanist,sceptic --rounds 3 --minutes 50 --constraint "<each limit the user stated>"`.
   It writes `CAMPAIGN.md`, one `agents/<lens>/BRIEF.md` per agent, `referee-brief.md` and `verifier-brief.md`.
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

**Stop** after the last round, or earlier when the top five have not changed for two meetings, or when the budget is spent.

**Close**

1. `python3 tools/mesh.py campaign close` writes `REPORT.md`: the slate (the top live proposals by composite, then pairwise
   rating), informative nulls, the download requests by value over effort, the scoreboard and the credit.
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
```

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

## Scoring

Each referee scores each live proposal on three axes, 1 to 5.

| | 1 | 3 | 5 |
|---|---|---|---|
| **Impact** | touches one card; nothing builds on it | settles an open contradiction or gap, or re-grades a finding others rest on | separates rival theories or overturns a cornerstone; changes what the field would do next |
| **Cogency** | asserted; a mechanism is missing or it strains a fact | a plausible mechanism, consistent with every fact that bears on it, rivals named | a mechanism with independent support, rivals addressed, a proof of concept pointing its way |
| **Realism** | needs what the user cannot reach, years or a new field | a partner's technique or months of work; the decisive experiment is specified | in reach with the user's means, weeks, every outcome informative |

**Gates.** A proposal fails a gate, and scores 0 however good it looks, when: a claim traces to no card and no cited source;
it clashes with a fact or piece of evidence no logged contradiction frees; it has no way to be killed; or its proof of concept
was reported without registration, the registration was changed afterwards, or the verifier could not reproduce it.

**Novelty** multiplies: open 1, unchecked 0.8, partly 0.6, answered 0. The verifier's verdict counts; without one, the most
cautious referee's.

**Composite** = the cube root of impact × cogency × realism (each the median of the round's referees) × novelty, × 0.9 while a
reported proof of concept awaits replication. The geometric mean keeps a brilliant but unworkable idea from winning.

**Pairwise.** Referees also say which of two live proposals they would rather the user pursued, up to ten pairs each. A
Bradley-Terry fit turns these into a rating (1000 is average), shown beside the composite: it is the steadier of the two
when absolute scores drift between referees, and it breaks ties.

**Credit.** An agent's credit is the composite of its live proposals, plus a quarter of the composite of others' live
proposals that build on its work (`builds_on::` a proposal or `notes:<lens>`), plus one for each proposal killed on its
evidence. Withdrawing a weak proposal costs nothing. Credit is reported, not rewarded: it shows who carried the campaign
and keeps sharing worth an agent's while.

**Successive halving.** Each meeting but the last cuts the bottom half of the live, scored proposals, so the later rounds
spend their time on the proofs of concept and experiment designs of the best.

## After the campaign

The campaign folder stays in the vault as the record: briefs, notes, proposals, registrations, results, scores, meetings and
the report. A later campaign on the same scope starts by reading the last one's report and notes, and by `discover --recheck`:
what the user accepted is followed by the brain's own lifecycle from then on.
