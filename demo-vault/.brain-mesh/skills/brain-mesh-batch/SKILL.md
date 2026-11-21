---
name: brain-mesh-batch
description: "Add many papers to a brain mesh at once, with one extraction agent per paper working in parallel: prepare and seed the vocabulary, extract in parallel, then merge concepts, link and integrate. Use when more than about five papers are to be added."
---

# Brain mesh: batch ingest with agents

Read `brain-mesh` and `brain-mesh-add-paper` first. Each agent follows add-paper steps 2 to 7 for its own paper; this document adds the division of labour that lets several agents work on one vault at once.

With up to about five papers, add them one at a time with `brain-mesh-add-paper`. Beyond that one session runs out of room long before it runs out of papers. A 9-page paper's main text came to about 60 cards in the first test, so 50 papers is several thousand cards.

## Why three phases

Each paper's own folder (`sources/P012-<slug>/`) can be written by one agent without touching anyone else's. Everything shared cannot be: concept hubs, findings, tensions, gaps, `index/`, `MAP.md`, the ledger and the marked PDFs. So:

1. **Prepare** (one session, in order): register every paper and seed the shared vocabulary.
2. **Extract** (one agent per paper, in parallel): each writes only its own folder.
3. **Merge** (one session, in order): merge proposed concepts, rebuild, link across papers, integrate.

## Cost, before anything starts

Agents multiply token use. One unplanned fan-out of agents has already used up a whole week's token limit. So before launching:

- Tell the user how many papers, how many agents, how many batches, and an estimate of the tokens: extract the first paper in this session, note what it used, and multiply. Ask the user to confirm.
- Run 5 to 8 agents per batch, not all papers at once. Ask again before each batch unless the user approved the whole run.
- Agents run in the background. Do not poll them; their reports arrive when they finish.

## Phase 1: prepare

1. **Gather.** List the papers. For each, do add-paper step 0: find its supplementary material and released data. Ask the user once for everything missing across all papers, naming each item.
2. **Register.** Allocate source ids here and nowhere else, in order (`python3 tools/mesh.py id P`), so no two agents take the same id. Anchor each paper (`anchor P012 file.pdf`, and `anchor P012 --si <files>` for its supplementary material). Write a minimal source card for each: title, authors, year, venue, DOI and a `coverage::` line per unit, including the supplementary material.
3. **Seed the vocabulary.** Read every abstract, and the introduction of the two or three most central papers. Create the concept cards that will recur across papers: the main variables (with units), methods, materials, phenomena and categorical variables, each with its aliases. A shared starting vocabulary is what stops ten agents inventing ten names for one thing.
4. **Build and commit.** `python3 tools/mesh.py build` must end with 0 errors. If the vault is a git repository, commit, so each agent starts from the same state.
5. **Write one brief per agent** from the template below.

## Phase 2: extract

### The agent brief

Give each agent, in its prompt:

- The vault's path, its paper's id and title, and where the clone of `tcpearce/brain-mesh` is (or how to get it).
- "Read `skills/brain-mesh/SKILL.md`, then `skills/brain-mesh-add-paper/SKILL.md`. Carry out steps 2 to 7 for P012 only. Step 8 (integration) is done later by the session that launched you."
- **May write only** inside its own source folder (`sources/P012-<slug>/`, or `sources/P012/` before its source card exists): its evidence cards, figure files (`P012-F2.png`, `P012-F2.csv`), `P012_refs.md`, `P012-claims.md`, `P012_concepts.md` and `P012_progress.md`.
- **Must not write** `concepts/`, `findings/`, `tensions/`, `gaps/`, `hypotheses/`, `experiments/`, `index/`, `MAP.md`, `ledger/`, or another source's folder. Must not run `build`, `mark`, `log`, `anchor`, `seal`, `upgrade`, `sync` or `remove`, which write shared files or the repository.
- **May run** `check P012`, `unread P012`, `sample P012`, `progress P012`, `figure P012 ...`, `refs P012`, `mentions P012`, `claims P012`, `id P012`, `find`, `show`, `concept`, `neighbours P012`, and `split` for batches that hold only its own evidence cards. Must not run `cite`, which allocates reference ids shared by every paper.
- **References.** Run `refs P012` and check `P012_refs.md` as add-paper step 1 says, filling in missing titles and DOIs from records it can look up.
- **Data sets and code.** Run `mentions P012` and list in the progress note every data set and code base the paper uses, with its name, link or accession, licence if stated, and the cards that rest on it. Do not write data-set or code cards: their ids are shared.
- **Claims.** Draft `P012-claims.md` (`claims P012`) with the main claim and up to five sub-claims linked to its own evidence, writing `no finding yet` where a finding would go; the merging session links the findings.
- **New concepts.** Look for an existing concept first (`python3 tools/mesh.py concept "<name>"`). Only if none fits, write a full concept card block, in the usual `=== <name>` batch format, into `sources/P012/P012_concepts.md`, and link it from the cards as usual. `check P012` reports those links as warnings, not errors. Never put concept blocks in a batch for `split`.
- **Links to other papers.** Typed links with reasons are welcome from its own cards to cards of papers already integrated. Never edit another paper's cards. Candidate links to papers in the same batch go in the progress note.
- **Progress note.** After each section of the paper, append to `P012_progress.md`: the date, the section done, the last card id, and anything open (figures still to read, flags, questions for the user). A resumed agent starts with `python3 tools/mesh.py progress P012` and then reads the note.
- **Finish** when `check P012` shows no errors and no warnings other than staged concepts. **Report back in at most ten lines:** cards by type, staged concepts, flagged cards, `missing::` lines, figures read, and suggested links to other papers.

### Working copies

If the vault is a git repository and agents can be given their own worktree, give each one its own. They touch only their own folders, so merging the branches back is clean. Otherwise all agents work in the same folder under the rules above.

### When an agent stops

Launch a new agent with the same brief plus "Resume: run `progress P012` first and continue from the progress note." Never run two agents on the same paper at once.

## Phase 3: merge

1. **Concepts.** `python3 tools/mesh.py staged` lists every proposed concept, which papers propose it, the existing concepts it resembles and its twins proposed by other agents. For each, either merge it into an existing concept (add the alias there, and change the links in the proposing cards to `[[existing|text]]`), or create it once from the best of the proposed blocks. Then delete the `P###_concepts.md` files.
2. **References.** Run `python3 tools/mesh.py cite P012` for each paper in turn, never in parallel: it allocates reference ids, and a work cited by several papers in the batch gets one card.
3. **Data sets and code.** From the agents' notes, make one data-set or code card per data set or code base (several papers often share one), with a `used_by::` line per paper, and add the `uses_data::` and `uses_code::` links to the evidence cards.
4. **Build.** `python3 tools/mesh.py build` must end with 0 errors. This also marks every new PDF and rebuilds the reading queue.
5. **Links across papers.** For each new paper run `python3 tools/mesh.py neighbours P012`. Candidates are ranked by the concepts two cards share, rare concepts weighing most. Read both cards and link with a reason, or decide they are unrelated. Add the links the agents suggested in their reports.
6. **Integrate.** Do add-paper step 8 for each paper: update the findings, decide on the gaps, tensions and hypotheses each bears on, link the findings into its claims card, update the concept hubs, and set each source to `integrated`.
7. **Verify.** Do the spot checks of add-paper step 7 on a sample of each paper's cards. For a vault that decisions will rest on, a fresh agent that did not write the cards does the checking.
8. **Close.** `python3 tools/mesh.py log "..."`, `gapsdoc`, then `python3 tools/mesh.py sync "<batch>"`. Report the works now cited by several papers in the brain and the ★ works in the reading queue.

Then the next batch: phases 2 and 3 again. The vocabulary that later agents start from now includes every concept merged so far.
