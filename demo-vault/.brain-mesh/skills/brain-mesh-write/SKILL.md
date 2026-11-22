---
name: "brain-mesh-write"
description: "Write from a brain mesh (a literature review, a background or related-work section, a paragraph for a paper or a bid, an evidence table) with every claim traced to a card and a page, or audit a draft against the brain claim by claim: supported, overstated, contradicted or not in the brain, with corrections. Use when the user asks for a review or synthesis of the literature to keep, or to check, fact-check or audit a draft, manuscript, bid or slide text against the papers."
---

# Brain mesh: writing from the brain and auditing a draft

Read `brain-mesh` first for the card formats, and `brain-mesh-access` for syncing and navigating.

Part A writes text from the brain. Part B checks text the user wrote against it. The same rules govern both.

## The rules

1. **Every claim traces to a card, and through it to a page.** While drafting, each sentence that states something about the science carries the ids of the cards it rests on. They become the citations.
2. **The brain is the only source.** Nothing from memory or the web goes into the text as if the brain held it. "Not in the brain" is never "not in the literature".
3. **Say it as strongly as the evidence, and no more.**

   | What the brain holds | How to say it |
   |---|---|
   | Finding `established` | plainly |
   | Finding `probable` | "the evidence indicates" |
   | Finding `tentative` | "suggests", with what is missing |
   | Finding `single-source` | "one study reports" |
   | Finding `contested`, or a logged contradiction or tension | both sides, and what separates them |
   | Evidence `measured` or `derived` | "found", "measured", with the value, its uncertainty and n as on the card |
   | Evidence `inferred`, `asserted`, `speculated` | "the authors argue", "propose" |
   | Evidence `cited` | second-hand (rule 5) |
   | A relation with basis `tested` | causal words: "raises", "causes" |
   | Basis `correlational` | "is associated with", "predicts" |
   | Basis `proposed` or `inferred` | "is proposed to", "may" |
   | Sources that are not independent (`independence`) | one line of evidence: "two studies from one group", "a reanalysis of the same data" |
   | A source whose design is `review` or `theory` | cited for its argument, not as evidence |

   State the scope: the species, system, conditions and range on the cards' `when::` lines. Do not generalise past them.
4. **Contradictions are shown, not smoothed.** Where the register holds a contradiction or a tension on the point, the text says that the sources disagree, and how.
5. **Second-hand citations are marked.** A `cited` card records what one paper says of another work. If that work is not itself a source in the brain, write "as cited in", or cite the paper that was read, and set the work's reference card to `queued` so it appears in the reading queue. Never cite it as if it had been read.
6. **A draft is not a source.** Nothing from the user's draft enters a card. If they want its content in the brain, it goes in as their own source (`brain-mesh-access`, section 3).

## Part A. Write from the brain

1. **The brief.** `python3 tools/mesh.py sync`. If the user has not said, ask once for what the text needs: the question or topic, the audience and where it will appear, the length, the citation style, and the study it should lead up to, if any.
2. **Gather.** For each theme: `facts <concept> ...`; `table <concept or K001>` for the evidence, one row per card with design, sample, result, conditions, limits and page; `table <concept> relations` for the framework and the basis of each relation; `table <concept> definitions` where sources use a term differently. Read the hubs, the findings, and every open contradiction, tension and gap on the topic. Check the `coverage::` lines of the sources involved: a section only skimmed is a stated limit of the text.
3. **Outline by theme or debate, never paper by paper.** For each theme: the central claim (a finding, where one exists), the evidence for it, the disagreement, the methodological qualification (designs, measures and definitions that differ, limitation cards, independence), and what is unresolved. For anything longer than a few paragraphs, show the user the outline first.
4. **Draft.** Integrate the sources within paragraphs: compare them, do not list them. Tag each claim with its card ids as you write (`[P001-015]`). Tell original studies from reviews and theory. If the text leads up to a study, end on the gap that motivates it, from the gap card, and say how far the gap has been checked: "no study in this collection" for a gap known only from the brain, "a search on <date> found none" where the gap card's search log says so.
5. **Where the brain cannot support a claim the argument needs,** do not write it as fact. Mark it `[NOT IN THE BRAIN: <what is missing>]` and list these at the end with what would supply each: a work in the reading queue, an unread section, a gap.
6. **Audit your own draft.** Save it and run Part B on it. Fix every flag before the user sees it.
7. **Citations.** Replace the card ids with citations in the style asked for: the source of each evidence card, with the page for any number or quotation. `references/library.bib` holds every source and cited work, keyed by card id. Keep the claim-to-card table (sentence, cards, page) and hand it over with the text, so every statement can be checked.
8. **Deliver** in the form the user asked for. A copy for the vault goes in `notes/drafts/`, and tables in `notes/tables/` (`table ... --out`). Report in a few lines: what is well supported, what rests on one study or one group, which disagreements the text shows, and what is missing.

## Part B. Audit a draft against the brain

1. **Get the draft as text, markdown or LaTeX** (a Word file: `pandoc draft.docx -t markdown -o draft.md`). `python3 tools/mesh.py sync`.
2. **`python3 tools/mesh.py draft <file>`** prints a worklist (`--out <file>` saves it). For each sentence that names a concept, cites a work or gives a number, it lists: the works cited and whether the brain holds them (author-year, numbered against the draft's own reference list, or citation keys); the concepts named; each number and the card that holds it; the cards most likely to bear on the sentence, with their values, conditions and pages; and what to check.
3. **Judge every sentence on the worklist.** Read the cards, and open the page wherever a value or a wording matters. The listed cards are the likeliest, not the only ones: search (`find`, `facts`, `table`) before calling a claim unsupported.

   | Verdict | When |
   |---|---|
   | supported | a card from the cited source states it, with the same number, scope and strength |
   | overstated | the brain supports a weaker claim: a number rounded in the claim's favour; a scope wider than the card's conditions; causal wording for a relation that is not `tested`; "showed" for something inferred or speculated; one study given as consensus; a finding graded tentative, single-source or contested given as settled; sources that are not independent counted as replication; a citation that supports only part of the sentence |
   | contradicted | a card says otherwise, or the sentence takes one side of a logged contradiction without saying so |
   | not in the brain | no card bears on it: the cited work is not a source, or its passage is not carded. Check the source's `coverage::` lines first; if the section was not read closely, read it (a lens pass) before giving this verdict |

   Check, for each: the number, with its unit, uncertainty and n; the population and scope; causal wording against the basis of the relation; attribution (did the cited paper find this, or cite someone else for it?); and whether the citation supports the whole sentence.
4. **Second-hand citations.** Where a claim rests on a work the brain knows only through another paper, say so in the table, suggest "as cited in" or reading the original, and set the reference card to `queued`.
5. **The audit table,** errors that change the argument first: contradicted claims, then overstated ones that carry a conclusion, then the rest. Supported claims can be counted in one line.

   | Draft claim | Cited | The brain: cards and page | Verdict | Suggested correction |
   |---|---|---|---|---|

6. **The corrected draft.** Keep the user's voice and structure; change only what a verdict requires, and show what changed. Mark what could not be settled `[UNVERIFIED: <why>]`. Do not delete an unverifiable claim: the user decides.
7. **What the audit shows about the brain.** A draft claim that exposes two cards in conflict is a contradiction to log; one that points at something nobody has measured is a gap candidate. Tell the user. The draft itself changes no card (rule 6).
8. **Report** in a few lines: the count for each verdict, the three corrections that matter most, and what to read to settle the unverified claims. If the vault changed (queued references, saved tables), `python3 tools/mesh.py sync "audit of <draft>"`.
