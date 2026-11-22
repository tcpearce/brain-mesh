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

1. **Gather.** The user puts the papers and their supplementary files in the vault's `ingest/` folder, which git ignores; large ones are linked, not committed, when anchored (`brain-mesh-setup`, **Large files are linked**). List the papers. For each, do add-paper step 0: find its supplementary material and released data. Ask the user once for everything missing across all papers, naming each item, and for any paper they want treated as high or low priority (suggest high for papers rich in high-priority concepts or bearing on research gaps).
2. **Register.** Allocate source ids here and nowhere else, in order (`python3 tools/mesh.py id P`), so no two agents take the same id. Anchor each paper (`anchor P012 file.pdf`, and `anchor P012 --si <files>` for its supplementary material). Write a minimal source card for each: title, authors, year, venue, DOI and a `coverage::` line per unit, including the supplementary material. The extraction agent completes its study profile (`question::`, `design::`, `sample::`, `framework::`). Then, for each paper in order, `refs P012` and `cite P012`, so the reference cards exist before the agents start and their cards can carry `cites::` lines. The agents check `P012_refs.md` against the paper; the merge runs `cite` again, which fills in what they found. A list `refs` cannot read (author-year style) is written by the agent, and its `cites::` lines are added at the merge.
3. **Seed the vocabulary.** Start from the high-priority concepts. Read every abstract, and the introduction of the two or three most central papers. Propose the concepts that will recur across papers (`propose ... `, without `--from`): the main variables (with units), methods, materials, phenomena and categorical variables, each with its aliases. Show the user the list in one message and adopt what they approve before the agents start. A shared starting vocabulary is what stops ten agents inventing ten names for one thing.
4. **Build and commit.** `python3 tools/mesh.py build` must end with 0 errors. If the vault is a git repository, commit, so each agent starts from the same state.
5. **Write one brief per agent** from the template below, and run the papers in priority order: each high-priority paper gets its own agent and, once it reports, an independent verifying agent that checks a sample of its cards against the pages; low-priority papers may share an agent with a brief that allows skimming background and discussion.

## Phase 2: extract

### The agent brief

Give each agent, in its prompt:

- The vault's path, its paper's id and title, and where the clone of `tcpearce/brain-mesh` is (or how to get it).
- "Read `skills/brain-mesh/SKILL.md`, then `skills/brain-mesh-add-paper/SKILL.md`. Carry out steps 2 to 7 for P012 only. Step 8 (integration) is done later by the session that launched you."
- **May write only** inside its own source folder (`sources/P012-<slug>/`, or `sources/P012/` before its source card exists): its evidence cards, figure files (`P012-F2.png`, `P012-F2.csv`), `P012_refs.md`, `P012-claims.md`, `P012_concepts.md`, `P012_scan.md` and `P012_progress.md`.
- **Must not write** `concepts/`, `findings/`, `tensions/`, `gaps/`, `hypotheses/`, `experiments/`, `index/`, `MAP.md`, `ledger/`, or another source's folder. Must not run `build`, `mark`, `log`, `anchor`, `seal`, `upgrade`, `sync` or `remove`, which write shared files or the repository.
- **May run** `check P012`, `unread P012`, `sample P012`, `progress P012`, `figure P012 ...`, `refs P012`, `mentions P012`, `claims P012`, `id P012`, `find`, `show`, `concept`, `propose ... --from P012`, `scan P012`, `neighbours P012`, and `split` for batches that hold only its own evidence cards. Must not run `cite`, which allocates reference ids shared by every paper.
- **References.** Run `refs P012` and check `P012_refs.md` as add-paper step 1 says, filling in missing titles and DOIs from records it can look up.
- **Data sets and code.** Run `mentions P012` and list in the progress note every data set and code base the paper uses, with its name, link or accession, licence if stated, and the cards that rest on it. Do not write data-set or code cards: their ids are shared.
- **Claims.** Draft `P012-claims.md` (`claims P012`) with the main claim and up to five sub-claims linked to its own evidence, writing `no finding yet` where a finding would go; the merging session links the findings.
- **New concepts.** Look first with `python3 tools/mesh.py concept "<name>"`. It shows the existing concepts, the concepts other agents in this batch have proposed so far (marked PROPOSED) and names the user has turned down (REJECTED). If an existing concept fits, link it. If another paper's proposal fits, link to that exact name and do not propose it again. Only if nothing fits, propose it: `python3 tools/mesh.py propose <slug> "<one-sentence definition>" --from P012 [--kind variable --unit 1] [--alias "other name"]`, and link the proposed name from the cards as usual. Search again before each new proposal: other agents keep adding theirs. Links to proposed names are warnings, not errors. Never put concept blocks in a batch for `split`.
- **Citations.** Give every card the works the paper cites for its statement (`- cites:: [[R0042]] — what it supports`), or `- cites:: none — <why>` where the paragraph's citations support another sentence; the paper's own measured or derived results need none.
- **Concept scan.** Once the paper is carded, run `scan P012` and work through it as `brain-mesh-concept-scan` says: card each new fact about an existing concept, add a repeated passage to the card that already states it, or write why there is nothing new on the concept's `decided::` line.
- **Vault rules.** Read the vault's `CLAUDE.md`, including the rules the user set below its generated part, and follow them within these limits. Where a rule asks for a shared change, propose it in your own files: a concept the rules say must be low priority is proposed with `--low "<the rule's reason>"`, and the merging session adopts it as such. Never run `sync`, `build` or `priority`: `CLAUDE.md` exempts extraction agents from its sync rule.
- **Contradictions.** Where a card of the paper cannot hold together with a card of a paper already integrated, or with a hub's facts, link it `contradicts::` with the reason and list it in the progress note. The merging session logs it on the register (`ledger/` is shared).
- **Links to other papers.** Typed links with reasons are welcome from its own cards to cards of papers already integrated. Never edit another paper's cards. Candidate links to papers in the same batch go in the progress note.
- **Progress note.** After each section of the paper, append to `P012_progress.md`: the date, the section done, the last card id, and anything open (figures still to read, flags, questions for the user). A resumed agent starts with `python3 tools/mesh.py progress P012` and then reads the note.
- **Finish** when `check P012` shows no errors and no warnings other than proposed concepts, and `scan P012` has nothing left to do. **Report back in at most ten lines:** cards by type, proposed concepts, flagged cards, `missing::` lines, figures read, and suggested links to other papers.

### Working copies

If the vault is a git repository and agents can be given their own worktree, give each one its own. They touch only their own folders, so merging the branches back is clean. Otherwise all agents work in the same folder under the rules above.

### When an agent stops

Launch a new agent with the same brief plus "Resume: run `progress P012` first and continue from the progress note." Never run two agents on the same paper at once.

## Phase 3: merge

1. **Concepts.** `python3 tools/mesh.py staged` lists every proposed concept, which papers propose it, the existing concepts it resembles and its likely twins from other agents.
   - Fold twins and near matches yourself: `python3 tools/mesh.py adopt <name> into <concept or other proposal>` adds its names as aliases and rewrites every link to it in every paper's cards. Into another proposal, the target stays a proposal. Do the twins first, so each idea ends with one name.
   - The rest are new concepts, and those are the user's call. Show the user the list, one line each (name, definition, papers), and act on their word: `adopt <name>` makes the card (a proposal marked low keeps that level), `adopt --all` makes every proposal that matches nothing, `reject <name> "<why>"` turns one down. A vault rule that tells agents to make a kind of concept (as a rule on generic terms may) counts as the user's word for it. Proposals the user has not answered stay proposals: the cards keep linking them, `check` warns, and the next session asks again.
   - Settle the folds, and adopt what the user approves, before step 5: `neighbours` finds links between papers through the concepts they share.
   - Each new concept may be named in papers from earlier batches: `scan` (no arguments) lists them, and `brain-mesh-concept-scan` cards what they say.
2. **References.** Run `python3 tools/mesh.py cite P012` for each paper in turn, never in parallel: it allocates reference ids, and a work cited by several papers in the batch gets one card. For a paper whose agent wrote its reference list by hand, then run `scan P012` and add the `cites::` lines it lists.
3. **Data sets and code.** From the agents' notes, make one data-set or code card per data set or code base (several papers often share one), with a `used_by::` line per paper, and add the `uses_data::` and `uses_code::` links to the evidence cards.
4. **Build.** `python3 tools/mesh.py build` must end with 0 errors. This also marks every new PDF and rebuilds the reading queue.
5. **Links across papers.** For each new paper run `python3 tools/mesh.py neighbours P012`. Candidates are ranked by the concepts two cards share, rare concepts weighing most. Read both cards and link with a reason, or decide they are unrelated. Add the links the agents suggested in their reports. Then scan for contradictions across the batch and the brain as add-paper step 6 says (`contradictions P012` for each paper, and reading), and log each real one on the register: papers extracted in parallel have never been read against each other.
6. **Integrate.** Do add-paper step 8 for each paper: update the findings, decide on the gaps, tensions, contradictions and hypotheses each bears on, link the findings into its claims card, update the concept hubs, and set each source to `integrated`. Then run `python3 tools/mesh.py discover --recheck` once for the whole batch and take the changes to the user (`brain-mesh-discover` section 8).
7. **Verify.** Do the spot checks of add-paper step 7 on a sample of each paper's cards. For a vault that decisions will rest on, a fresh agent that did not write the cards does the checking.
8. **Close.** `python3 tools/mesh.py log "..."`, `gapsdoc`, then `python3 tools/mesh.py sync "<batch>"`. Report the works now cited by several papers in the brain and the ★ works in the reading queue.

Then the next batch: phases 2 and 3 again. The vocabulary that later agents start from now includes every concept merged so far.

**How large a batch.** Phase 3 is done by one session, so the merge, not the extraction, sets the pace: about 5 to 8 papers per batch. Each paper is set to `integrated` as it is done, so a resumed merge session sees where it stopped (`health` lists sources not yet integrated). While a batch runs, pause Obsidian Git's auto commit-and-sync on the user's machine, or give the agents their own worktrees, so half-written cards are not pushed.
