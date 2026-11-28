---
name: "brain-mesh-citation-index"
description: "Index the works a brain mesh cites but has not read: fetch each abstract, record what it claims, link the concepts it bears on, and rank where the brain rests on unread literature; then read the index as a whole against the findings, gaps, tensions and the ontology (the synthesis pass). Use when the user asks to index citations, capture abstracts, survey the field around the vault, check the brain's conclusions against the literature it cites, or decide which papers to read next."
---

# Brain mesh: the citation index

Read `brain-mesh` first, its `FORMATS.md` before writing a card, and `brain-mesh-access` for syncing.

A brain mesh holds a few papers in full and cites hundreds it has never read. Those citations are not noise: they are the field around the vault, already filtered by the papers the user chose. Indexing them, one abstract each, turns that list into a map. It shows what the surrounding literature says about each concept, where the brain's own reading is thin, and which paper to read next.

**An indexed claim is never evidence.** It comes from an abstract, which is the authors' summary of themselves, not from text the brain has read and anchored. Nothing may rest on it: no finding, no `support::` or `against::` line, no card citing it as evidence. It is for cross-reference and for choosing what to read. Keeping that line sharp is what makes the index safe to grow quickly.

## 1. Choose what to index

`python3 tools/mesh.py literature --unindexed` lists the cited works with no concepts yet, grouped by the source that cites them. Work through:

1. **Works cited by several sources** first: they are load-bearing. `python3 tools/mesh.py health` lists them, and `index/frontier.tsv` ranks by citation count.
2. **Works cited where a gap, tension or high-priority finding rests** (the ★ and ◆ lists in `ledger/reading-queue.md`).
3. **Works on a high-priority concept**, from `literature` with the concept named.
4. The rest, oldest ids first, so the index stays even.

## 2. Find the abstract

In this order, stopping at the first that works:

1. **The vault already has it**: a work whose status is `held` is a source; it needs no index.
2. **A DOI** on the card: resolve it. Crossref (`https://api.crossref.org/works/<doi>`) returns an abstract for many works; publisher pages for others. A PubMed id: use a PubMed tool or `https://pubmed.ncbi.nlm.nih.gov/<pmid>/`. An arXiv id: the abstract page.
3. **A search** by exact title, when there is no identifier.
4. **The open indexes**, when the first three give nothing: OpenAlex (`https://api.openalex.org/works/doi:<doi>`; the abstract comes as an inverted index, word to positions, to put back in order), Europe PMC (`https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:"<doi>"&resultType=core&format=json`) and Semantic Scholar (`https://api.semanticscholar.org/graph/v1/paper/DOI:<doi>?fields=abstract`). Each holds abstracts the others lack. OpenAlex has a daily allowance; when it runs out, the services not reached must be named on the card (below), so the work is searched again later rather than written off.
5. **No abstract exists** (a book, a 1936 trade journal, a software note): write one line under `## Abstract` saying so and naming every service you searched, and index what the card's own fields and the citing passages say instead. Set `- indexed::` anyway, so the work is not searched for again. A card that says none was found, without having reached all four kinds of service, is a candidate for a recheck: on 2026-11-27 a recheck of 53 such works found real abstracts for 24.

**Check what came back before pasting it.** A service can return the wrong thing with complete confidence:

- **The same work?** Its title, first author and year must match the card. A DOI taken from elsewhere on the card (a link in a citing passage, a related paper) names a different work.
- **An abstract?** Reject page furniture ("Get PDF Email Share …"), a bare citation line ("(2000). Perceptual learning … pp. 295-302"), and the opening paragraph of a letter, comment or review, which reads as an introduction and cites numbered references ("(1, 2)") or authors in brackets. A letter or a news piece usually has no abstract: say so instead. A Crossref abstract can be an editor's teaser or a graphical-abstract caption rather than the authors' abstract; when it is short or reads like publicity, prefer PubMed or Europe PMC.
- **Fix the card while you are there.** A DOI or PubMed id the service confirmed and the card lacks goes in `## Codes`; a `kind::` that is plainly wrong (a *Science* article marked `book`) is corrected.

Paste the abstract **verbatim**. Do not paraphrase it, do not translate it, and do not shorten it. If it is structured (Background/Methods/Results), keep the structure. Record where it came from on the `- indexed::` line.

**Never invent an abstract.** If you cannot find one, say so. A fabricated abstract would poison every hub it reaches.

## 3. Write what it claims

Under `## What it claims`, two to eight lines, each one statement the abstract makes, each naming the concepts it bears on as links:

```
- Odour pleasantness is the first principal component of perceptual space, and is predictable from molecular structure ([[hedonic]], [[perceptual-space-dimensionality]], [[chemoinformatic-descriptors]])
- The prediction holds across cultures ([[individual-differences]])
```

- **The authors' claim, in your words, not theirs.** Compress; do not copy sentences out of the abstract.
- **Only what the abstract actually says.** No inference, no filling in from what the brain already believes, no "this probably means".
- **A number is worth more than an adjective.** "r = 0.8 across 150 molecules" beats "strongly predicts".
- **Link only concepts that exist.** `python3 tools/mesh.py concept <name>` checks. If a work needs a concept the vault lacks, propose it (`propose <slug> "<definition>" --from <the citing source>`) and link the proposed name; the user decides. Propose rarely: the index is for cross-reference, not for growing the vocabulary.
- **Respect the vault's rules.** A rule that bars a kind of concept (generic machine-learning or statistics terms, say) applies here too.

## 4. Codes

```
- concepts:: [[hedonic]], [[perceptual-space-dimensionality]], [[chemoinformatic-descriptors]]
- indexed:: 2026-11-23 — abstract from Crossref (doi:10.1523/JNEUROSCI.1158-07.2007)
```

`concepts::` is what the work is **about**, three to six concepts, not every term the abstract mentions. These put the card on those hubs, so be strict: a work that merely mentions mixtures in passing is not about mixtures.

If the work now looks worth reading in full, put it on the reading queue: `python3 tools/mesh.py queue add R0266 --why "<what reading it would settle>" --from citation-index`. That records why on the card and lists it under **Suggested by the skills**; `queued` is the user's word that they are fetching it (`queue mark`).

Some works bear on no concept this vault has, and should not grow one: a generic method or optimiser, a piece of tooling, a study in another field the paper cites in passing. Index it for the record and say so, rather than stretching for a concept or inventing one:

```
- concepts:: none — a generic machine-learning optimiser, not odour coding
```

The reason is required. `check` then leaves the card alone and it reaches no hub, which is correct: it is in the index, and in no part of the ontology.

## 4a. Set its priority: this one is yours to judge

A concept is the user's call, but **the priority of a cited work is the indexer's**. Set it as you index, with the reason on the card:

```
python3 tools/mesh.py priority R0266 high "3,000 mouse sensory neurons against 125 odorants: the measurement the brain's combinatorial-code cards assume but do not rest on"
```

- **high** — the work is significant in its field (a first measurement, a method everything else uses, a result others argue with), **or** central to what this vault is about, **or** it would fill a hole the brain plainly has: a concept carried by many cited works and few read sources, an open gap, a contradiction that turns on it, a finding stuck at single-source.
- **low** — the brain cites it only for a method, a reagent or a passing fact, and reading it would change nothing.
- **normal** — everything else; leave it alone rather than setting it.

Be sparing with high: it is a reading list, not a bibliography. A handful per hundred works is right. Say which of the three reasons applies, in a few words, so the user can judge the call.

## 4b. Watch for concepts the brain is missing

The abstracts are where a missing concept shows itself. As you read them, note any term that keeps recurring across works and that `concept <name>` does not find. Report those in your summary with the ids that use them, and propose the clearest few (`propose <slug> "<definition>" --from <a citing source>`). After a run, `mesh.py beyond` raises the same candidates from the abstracts automatically, and the user decides.

## 5. What the index is for

After a run, `python3 tools/mesh.py build` then:

- `python3 tools/mesh.py literature` ranks concepts by cited works against sources read. A concept carried by many cited works and few read sources is where the brain rests on literature it has not read.
- Each concept hub now lists the indexed works about it, with what each claims.
- `python3 tools/mesh.py literature --gaps` names the thin concepts no gap card covers; section 5a says what to do with them.
- `ledger/reading-queue.md` and the gap cards can then be argued from evidence: a gap that a dozen indexed works bear on is a reading list, not a research gap (`brain-mesh-gaps`, rung 2).

Report to the user: how many works indexed, the concepts that gained most, the concepts where reading is thinnest, any work that turned out to be already held, the gap candidates from section 5a with their verdicts, and the handful you would read next, with the reason. After a large run, go on to the synthesis pass (section 7): indexing puts each work on its hubs, but only the synthesis pass asks what the index as a whole says about the brain's conclusions and its ontology.

## 5a. Turn thin coverage into gap candidates

This is the step that makes the index pay. An index that nothing acts on is a bibliography.

`python3 tools/mesh.py literature --gaps` lists the concepts where the cited literature far outweighs the sources read and no gap card covers it yet. Work through that list. A thin concept is **not** automatically a gap: it is a gap only where the brain cannot state something it needs to state.

For each candidate, in this order:

1. **Ask the brain first.** `python3 tools/mesh.py ask "<the question the concept raises>"` and `python3 tools/mesh.py concept <slug>`. If the brain can already answer from evidence it holds, there is no gap: the literature simply repeats what is known. Say so and move on.
2. **Check it is not already carded.** Read the existing gap cards' titles (`gaps/`) and `ledger/` for a signal already judged. Never raise a second gap for the same hole; add to the one that exists.
3. **Decide which kind it is**, because this is the distinction that matters and the one the index is uniquely able to settle:
   - **Fillable** — the field has written the answer and this brain has not read it. A dozen indexed works bearing on the concept is the evidence for that. The outcome is a reading list, not a research gap.
   - **A research gap** — the indexed works circle the concept without answering it. Say what each of the closest three or four *does* say and where each stops, which is what shows the hole is real.

Write each candidate with: the concept and its read-against-cited counts; the three or four cited works that carry the weight, by id, with what each claims; what the brain cannot currently state; why it matters; and your verdict, fillable or research gap, with the reason. That is the material a gap card is made of, assembled from the index.

**Where the candidate goes.** `gaps/` is shared, like `concepts/` and `ledger/`. So:

- **In an agent, in a run with other agents:** write the candidates into your own report and nowhere else. The launching session writes the cards, exactly as it adopts the proposed concepts.
- **Alone in the vault, with no other agent running:** write the gap cards yourself, following `brain-mesh-gaps`, and say in your report which ids you took.

**Never set a gap's priority.** A cited work's priority is yours to judge (section 4a); a gap's is the user's, like a concept's. Write the card without a priority and let the user rank it.


## 5b. Concepts that arrive after a work was indexed

An abstract is indexed against the concepts the brain had that day. Concepts adopted later are linked on it by the tooling where its title or a claim names them (`adopt` does this for each new concept; `mesh.py scan --abstracts --apply` does it for all), and the mentions only in the abstract body are judged: link the concept, or write `- concept_decided:: [[concept]] — <why the work is not about it>` on the card. `ledger/concept-coverage.md` records which concepts are meshed across the indexed abstracts and which are not (`brain-mesh-concept-scan`).
## 6. Working in agents

With more than about fifty works to index, split them between agents as `brain-mesh-batch` does. Each agent takes a block of reference ids, writes **only** in `references/`, touches no other folder, and never runs `build`, `sync` or `cite`. Give each agent its list explicitly, so two never take the same card. The services' allowances are shared: OpenAlex's daily allowance is spent by all the agents together, so give each agent the order to try them in and tell it to record on the card any service it could not reach. Each agent writes its fetch scripts and downloads in a scratch folder of its own, outside the vault. The launching session builds, checks and syncs when they are done, adopts or rejects the proposed concepts, and writes the gap cards from the candidates the agents reported (section 5a).

## 7. The synthesis pass: read the index as a whole

Indexing card by card puts each work on its hubs. It does not ask what the hundreds of abstracts, taken together, say about the brain's own conclusions, or about its vocabulary. That is this pass. Run it:

- after a large indexing run (a hundred works or more);
- when `literature` reports synthesis cards with bearing works never checked, or with works indexed since their check;
- before writing from a finding (`brain-mesh-write`), on the findings the text will rest on.

The rule at the top of this skill still holds: **an indexed claim is never evidence.** The pass decides what the brain reads next and which questions it asks. It changes no finding, grade, relation or `support::` line until the work is read and carded.

### 7a. The synthesis layer against the literature

`python3 tools/mesh.py literature --against` lists every finding, tension, gap, contradiction and hypothesis with the number of indexed works that bear on it, when it was last checked, and how many were indexed since. A work bears on a card when it shares the card's concepts and at least one of them is specific (few works carry it). Work from the top of the list: never checked, most bearing works first.

For each card, `literature --against K014` lists the bearing works, rarest shared concepts first, with the claims that name them. Judge each work as one of:

- **agrees**: its abstract reports the card's claim, or a result the claim rests on, from another study. Note whether it is independent: another group, other data, another species.
- **disagrees**: its abstract reports something the claim cannot also be true with, or a limit on it (another species, concentration range or preparation).
- **answers**: for a gap, a hypothesis or an open question, the abstract reports the measurement that is said to be missing. Date it against the card (`brain-mesh-gaps`): a 2007 gap answered in 2015 is a reading list, not a gap.
- **does not bear**: it shares the concepts, not the question. Most works will be this. Say nothing about them.

Then act on each card:

1. **Queue what disagrees or answers**, at once and at high priority (section 4a): `python3 tools/mesh.py queue add R0222 --why "would test K014: the abstract reports that the receptor code changes with concentration" --from citation-index`. Reading it is the only way the disagreement becomes a contradiction card, a re-graded finding or a closed gap.
2. **Queue corroboration where a finding is thin**: when a finding rests on one source or one group, and indexed works from other groups agree, queue the strongest one or two.
3. **Record the check on the card**, in its `## Codes`:
   ```
   - literature_checked:: 2026-11-27 — 12 indexed works read; agree [[R0730]], [[R1551]]; disagree [[R0222]] (queued); answer none
   ```
   Name only the works that agree, disagree or answer. The date is what `literature` compares with the dates the works were indexed, so a card goes stale when new works bear on it.
4. **Change nothing else on the card.** If a disagreement looks decisive, say so in the report; the user decides whether to read it first.

### 7b. The ontology against the literature

The ontology (the concepts, their names and definitions, and how they relate) is vocabulary and structure, not evidence. The index is the best view the brain has of how the field uses its words, so it may shape the ontology, through the user:

1. **Missing concepts.** `beyond` raises terms the abstracts share that no concept names, and `check` counts the claims that name no concept. A term that recurs across five or more works, inside the vault's subject, is a candidate: propose it with the works that use it (`propose <slug> "<definition>" --from <citing source>`).
2. **Definitions that do not fit their use.** Read the claims filed under a concept (its hub lists them). When most use it in a sense its definition excludes (receptor potency filed under a point on a perceived-intensity curve, say), propose a definition fix or a split.
3. **Splits and merges.** A concept carrying hundreds of works across distinct questions is a candidate split; two concepts the claims use interchangeably, a candidate merge.
4. **Relations the literature draws and the brain has no evidence on.** `literature --pairs` lists pairs of concepts that several abstracts claim together and no evidence card names together. For a pair that matters to the profile, add an open question to both hubs, asked as a question and naming the works as the reason it is asked, never stated as known:
   ```
   - Does adaptation reshape odour responses in the olfactory bulb itself? Four cited works claim so, none read: [[R0656]], [[R1054]], [[R1275]], [[R1278]]
   ```
   Credit the works in the hub's Codes as well (`- cites:: [[R0656]] — named as a reason to ask: <the question> (indexed, not read)`), since `check` asks for a `cites::` line for every cited work a hub's text names. Queue the clearest of those works.

New concepts, definition changes, splits, merges and every priority on a concept are the user's call. Gather them into **one numbered list of decisions**, each with your recommendation and the counts behind it, so the user can answer "yes to all" or name the numbers to change. Act on the answer.

### 7c. Patterns no card holds

A claim that recurs across three or more works, from different groups, on a question no finding, tension or gap covers, is a finding the brain could hold if it read them. Report each with the works and what each says, and queue the two that would let it be carded. Never write a finding from abstracts.

### 7d. Agents, and the report

With many cards, give each agent a block of synthesis cards to judge (7a), or a block of concepts (7b). Agents judge and report; they write nothing in shared folders. The launching session writes the `literature_checked::` lines and the queue entries, and puts the ontology proposals to the user.

Report: the cards checked; by card, the works that disagree or answer, now queued; the ontology decisions as a numbered list; the candidate findings from 7c.
