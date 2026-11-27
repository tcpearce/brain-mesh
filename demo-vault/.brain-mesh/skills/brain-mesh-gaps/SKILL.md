---
name: "brain-mesh-gaps"
description: "Find the key knowledge gaps in a brain mesh, search for papers that fill them, and maintain the research-gaps document for gaps no paper answers. Use for what is missing, what to read next, literature gaps, or research gaps to propose experiments from."
---

# Brain mesh: gaps

> **Date the gap before you card it.** A paper's open question is open as of that paper's year. Check it against the
> sources the brain has read since (`mesh.py chronology`, which lists the later sources bearing on the same concepts)
> and then against the literature. A 2007 review's unanswered question may have been answered in 2010. Carding it as a
> gap makes the brain assert that something is unknown when it is not, which misdirects reading and can stand for
> years. Where the answer exists and the brain has not read it, that is a reading list, not a research gap.

Read `brain-mesh` first, and its FORMATS.md before writing or changing a card, and `brain-mesh-access` for syncing. Find the vault and run `python3 tools/mesh.py build`.

## The ladder

"The brain does not know" has three different meanings, and each needs a different response. Every candidate gap climbs this ladder, one rung at a time:

1. **Extraction gap.** The answer is in a source already in the brain but was never carded. Response: a lens pass.
2. **Brain gap.** The literature answers it but the brain does not hold the paper. Response: a reading list, then ingestion.
3. **Research gap.** A logged search finds no answer. Response: it enters the research-gaps document, and experiments are proposed from it.

Skipping a rung is the main way this goes wrong: proposing an experiment that page 7 of a paper already in the vault has answered. For one idea, `python3 tools/mesh.py report novelty "<the idea>"` lays the rungs out: passages in held papers that no card covers, unread works cited on its concepts, and a starting query (`brain-mesh-report`).

## 1. Scan for candidates

`python3 tools/mesh.py gaps` prints signals, grouped, the first eight of each group (`gaps --all` prints every row). They are prompts for judgement, not a list of gaps. `python3 tools/mesh.py discover recognised` adds the open questions and limits that two or more independent groups state themselves, the strongest sign that the field already counts something a gap, and `routes --route fill-gap` shows each open gap with what it still lacks and whether closing it is within the research profile.

| signal in the scan | kind of gap it may indicate |
|---|---|
| findings resting on one source, or on sources that are not independent of each other (shared data set or authors) | `unreplicated` |
| open tensions | `unresolved-tension` |
| authors' open questions not taken up | `open-question` |
| oddities not taken up | `unexplained` |
| assumptions not taken up | `untested-assumption` |
| models not taken up | `unvalidated-model` (never tested outside the fitted range) |
| limitations not taken up | `method` or `scope` |
| condition variables only ever held at one value; sparse condition pairs | `untested-region` |
| numeric variables never measured as an outcome | `unmeasured` |
| source units not fully extracted | an extraction gap, rung 1 |
| most-cited sources not in the brain, and `ledger/reading-queue.md` (what the skills suggested, the recent works citing the sources, the works cited where gaps and tensions rest) | a brain gap, rung 2 |
| evidence the sources do not give (`missing::`) | marked "supplementary material unread": an extraction gap, rung 1, so get the supplementary material. Otherwise a missing method or basis that a finding or design depends on is a gap of kind `method` or `untested-assumption`, and missing data or statistics a gap of kind `unmeasured` |

For each sparse pair the scan names, run `python3 tools/mesh.py matrix <variable> <variable>` to see exactly which combinations nobody has measured. Read the **Open questions** and **Relationships** sections of the main concept hubs too: a relationship stated with no finding behind it is a gap. The marked PDFs help with rung 1: passages with no highlight were never carded.

**High-priority concepts get a wider scan.** For each concept set to high, `gaps` also lists every untested combination of its variable with the others (not only the sparsest), each line under the hub's **Relationships** with no finding, tension or gap behind it, and each **Open question** not yet a gap card. Take each up as a candidate, or note on the hub why it is not one.

## 2. Choose the key gaps

Most signals are not worth a card. Keep a gap when the answer would matter, judged on three things:

- **Dependence.** How much rests on it. `python3 tools/mesh.py impact <id>` shows what depends on a card, and a gap on a hub concept outranks one at the edge.
- **Decision value.** Would the answer change a finding's status, separate rival hypotheses, or change what the user does next?
- **Tractability.** Could a paper or a feasible experiment answer it?

Give it a priority, the same scale every card uses (`brain-mesh`): `high` when the brain's conclusions turn on it, `normal` (the default) when it would sharpen them, `low` when it is worth recording and no more. Set it with `python3 tools/mesh.py priority G004 high "<why>"`, which records the reason; the old 1/2/3 in Codes is converted by `build`.

Search existing gap cards first (`python3 tools/mesh.py find <words> --type gap`). The same unknown reached from two directions is one gap; add the new origin to its `from::` line.

## 3. Write the gap card

```markdown
---
type: gap
status: open
priority: high
updated: 2026-11-20
---
# Film thickness has never been measured in acetonitrile, so swelling is not ruled in or out there

**Unknown.** One or two sentences stating exactly what is not known, with its scope.

## Why it matters
What depends on the answer: which findings, hypotheses or decisions change.

## What is known
The nearest evidence, with links, and how far it reaches.

## Search log
- Not yet searched.

## What would close it
The observation, paper or experiment that would answer it.

## Codes
- id:: G002
- kind:: unmeasured
- prioritised:: 2026-11-20 high — whether swelling explains the loss turns on it
- from:: [[P001-005]], [[X001]]
- concepts:: [[film-thickness]], [[acetonitrile]], [[swelling]]
```

`kind` is one of: untested-region, unreplicated, unresolved-tension, unexplained, untested-assumption, unvalidated-model, unmeasured, open-question, method, scope. The title states the unknown as a full sentence or question. `from::` lists the cards that reveal the gap.

Status moves through: `open` (found, not yet searched), `fillable` (papers found, not yet added), `confirmed` (searched; the literature does not answer it), `planned` (an experiment is registered against it), `closed` (answered; `closed_by::` names the cards), `dropped` (ill-posed or not worth pursuing, with the reason in the prose).

## 4. Take each gap up the ladder

Record every step in the card's **Search log**, dated. The log is what makes an absence claim checkable and repeatable.

**Rung 1: is it in a source we already hold?** Look at `index/coverage.tsv` for the sources that share the gap's concepts. If any relevant section, table, figure or supplementary item is not `full`, or the question is finer than the extraction was, run a lens pass (`brain-mesh-add-paper`). If the answer turns up, card it, set the gap to `closed` or `dropped`, and say in the log that it was an extraction gap.

**Rung 2: is it in the literature?**

- Build queries from the gap's concept cards. Their names and `aliases` are ready-made synonym lists; combine the variable, the system and the condition.
- Use whatever search this session offers: literature connectors, a literature-search skill, web search. Use at least two independent routes for a high-priority gap.
- Follow citations as well as keywords. Start with the works the brain's own sources cite in the passages this gap rests on: the gap's entries in the Backward part of `ledger/reading-queue.md`, or the reference cards whose "Cited by" names the gap's evidence cards. Then the most-cited references (`index/frontier.tsv`) and the papers that cite the brain's key sources: the queue's Forward part, from `python3 tools/mesh.py forward` (run it if the queue's staleness line says sources are not yet searched).
- Look for recent work first: the last five to ten years, then reviews, then the classic papers those cite. A fundamental older paper that recent work still rests on is admissible, but an old paper alone rarely settles whether a gap is still open.
- Screen each hit against the gap as stated: does it measure this variable, in this system, under these conditions? A paper on the general topic does not fill a specific gap.
- Log the date, where you searched, the exact queries, the number of hits, how many were screened, and a one-line verdict on each serious candidate.

Then:

- **Papers that would fill it.** Set status `fillable` and `- searched:: <date>`. Put each on the reading queue, whether or not it has a reference card: `python3 tools/mesh.py queue add <doi | R id | "author year title"> --why "<the gap it would fill, and whether the full text is openly available>" --from gaps:G003` (`--high` for one the gap cannot do without). It finds or makes the reference card and records the suggestion; the generated queue lists it with every reason given. Tell the user which PDFs to supply; full text often cannot be fetched from here. Once a paper is ingested with `brain-mesh-add-paper`, its step 8 decides on the gap: `closed` with `closed_by::` if it is answered, a rewritten **Unknown** if it is only narrowed, or a `reviewed::` line saying why it is untouched. `check` will not let a paper that bears on an open gap stay undecided.
- **Nothing answers it.** Set status `confirmed` and `- searched:: <date>`. Word the conclusion as what it is: "no answer found in <where> on <date>". Never "nobody has done this".

**Rung 3: a research gap.** A confirmed gap goes into the research-gaps document and is offered to `brain-mesh-experiment`. From then on the reading queue stars (★) every work cited where it rests: read those before designing anything, since one of them may answer it after all. When an experiment is registered against it, set status `planned`. When results answer it, `closed`.

A search goes stale: after 90 days for a high-priority gap, 180 for normal and 365 for low. Repeat it before an experiment is designed on a confirmed gap, and whenever `python3 tools/mesh.py health` reports it as stale; `check` warns about a high-priority gap whose search is stale or not yet made.

## 5. The research-gaps document

`python3 tools/mesh.py gapsdoc` assembles `gaps/RESEARCH-GAPS.md` from the gap cards:

- a summary table of confirmed and planned gaps, high priority first, with the date last searched and any experiment addressing each;
- the full human-readable part of each of those gaps, including its search log;
- gaps that papers may fill, and gaps not yet searched, as short lists;
- the sources cited.

Everything below its AUTO marker is regenerated, so edit the gap cards and rerun, never the assembled text. Above the marker, write and maintain an introduction: the scope of the brain, how the gaps were identified, where and when the literature was searched, the three or four gaps that matter most and why, and the limits of the search.

To share it outside Obsidian, produce it in whatever document format the user asks for, replacing card links with author-year citations and keeping the gap ids.

## 6. Close

- Add each key gap to **Open questions** on the concept hubs it concerns, with a link.
- Run `python3 tools/mesh.py build`, then `gapsdoc`, then `python3 tools/mesh.py log "gaps: <n> new, <n> fillable, <n> confirmed, <n> closed"`.
- Report to the user: how many candidates were extraction gaps, brain gaps and research gaps; the reading list in score order; and the top research gaps, each with one line on what would close it.
