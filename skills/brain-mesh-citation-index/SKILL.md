---
name: "brain-mesh-citation-index"
description: "Index the works a brain mesh cites but has not read: fetch each abstract, record what it claims, link the concepts it bears on, and rank where the brain rests on unread literature. Use when the user asks to index citations, capture abstracts, survey the field around the vault, or decide which papers to read next."
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
4. **No abstract exists** (a book, a 1936 trade journal, a software note): write one line under `## Abstract` saying so and where you looked, and index what the card's own fields and the citing passages say instead. Set `- indexed::` anyway, so the work is not searched for again.

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

Set `status: queued` if the work now looks worth reading in full, and say why in `## Notes`.

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

Report to the user: how many works indexed, the concepts that gained most, the concepts where reading is thinnest, any work that turned out to be already held, the gap candidates from section 5a with their verdicts, and the handful you would read next, with the reason.

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

## 6. Working in agents

With more than about fifty works to index, split them between agents as `brain-mesh-batch` does. Each agent takes a block of reference ids, writes **only** in `references/`, touches no other folder, and never runs `build`, `sync` or `cite`. Give each agent its list explicitly, so two never take the same card. The launching session builds, checks and syncs when they are done, adopts or rejects the proposed concepts, and writes the gap cards from the candidates the agents reported (section 5a).
