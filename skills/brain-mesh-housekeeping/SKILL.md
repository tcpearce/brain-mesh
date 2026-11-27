---
name: "brain-mesh-housekeeping"
description: "Keep a brain mesh healthy as it grows: health report, stale concept hubs, re-grading findings, merging duplicates, corrections and retractions, audits of old cards, and reconciling edits made in Obsidian. Use for tidy, audit, check or maintain requests."
---

# Brain mesh: housekeeping

> Part of every health check: `mesh.py chronology`. It lists the claims the brain asserts that have a shelf life —
> absences, firsts, limits of the day, counts of the day — oldest first, with the sources read since that bear on
> them. Settle what has moved on with `- superseded_by:: [[card]] — <what changed>`; that is progress, not a
> contradiction, and must not go on the contradictions register.

Read `brain-mesh` first, its FORMATS.md before writing or changing a card, and `brain-mesh-access` for syncing. Find the vault.

A vault that only ever grows drifts: hubs fall behind their evidence, findings keep grades they no longer deserve, searches age, and small extraction errors accumulate. Housekeeping is the work that keeps the brain trustworthy enough to design experiments from.

Run it after every five to ten sources, before the brain is used for a proposal or an experiment design, after the user has edited cards in Obsidian, and whenever a source is corrected or retracted.

## The routine

```bash
python3 tools/mesh.py build     # errors, duplicate warnings, prose and Codes out of step, changed source files
python3 tools/mesh.py health    # the queues below
```

Work through the results in this order. Fix what is clear. Bring to the user anything that is a judgement about their science.

1. **Errors from `build`.** Broken links, missing codes, anchors that do not exist, a source file whose checksum no longer matches. Fix all of them. A changed source file is restored from a backup or from git, never re-sealed, unless the user confirms that the registered file was the wrong one.
2. **Cards with only a page-level marker.** Their `loc` phrase was not found on the PDF page. Correct the phrase or the anchor so the card sits on its passage.
3. **Duplicate warnings.** Same-source near-duplicates, parallel results from different sources left unlinked, repeated background claims, near-identical concept names, overlapping findings. Apply the duplicate rules in `brain-mesh-add-paper`; merge as described below.
4. **Concept hubs older than their newest card.** Reread the cards listed under **Where it appears**, then bring **What is known**, **Relationships** and **Open questions** up to date and set `updated`. The hubs are what the user reads, so a stale hub misleads even when every card beneath it is right. A hub with a definition and nothing else is the stalest of all: count those too. **Many hubs at once, with agents:** hubs are shared files, so agents never write them. Each agent takes a list of hubs and writes a draft of each hub's hand-written sections into a folder outside the vault that the session names (its scratch or temporary directory). The session then puts each draft in place by hand or with a short script that keeps the live front matter, the generated block between `<!--AUTO:START-->` and `<!--AUTO:END-->`, `## Linked from` and the Codes, refuses a draft whose definition differs from the live one (a definition change is the user's call), and sets `updated`. Then `build`, and read the hub checks it reports (lines whose evidence cites works the line does not credit, issue #61).
5. **Findings whose status no longer matches their evidence.** Re-grade: still `single-source` after a second source supports it, still `established` after counter-evidence arrived, graded above `single-source` on one paper.
6. **Old gap searches.** Repeat them with `brain-mesh-gaps`. A confirmed research gap is only as good as its last search.
7. **Claims, observations and models cited by nothing.** Either integrate them into a finding or a tension, or leave them deliberately. Not every card needs a finding, but a paper's main results do.
8. **Flagged cards.** Go back to the PDF page, resolve the doubt and remove the flag, or keep it with a clearer note.
9. **Concepts used by at most one card.** Fold them into a broader concept as an alias, or leave them if more sources on the topic are coming.
10. **References.** `check` warns when a source's reference list is extracted but not turned into cards (`cite P012`), when two reference cards look like the same work (merge them: the survivor takes over every `cited_by::` line), and when a card has no year or a malformed DOI. `health` counts the papers whose reference list was never extracted: run `refs` on them (add-paper step 1). Read `ledger/reading-queue.md` with the user and record each decision with `queue mark <ref> queued` (they are fetching it) or `queue mark <ref> skip` (it will not be read), so the list stays short. Cards a later source has made `held` need nothing. `health`, and the last line of `sync`, say how current the queue is: sources not searched forward (`forward`), suggestions undecided or works queued with no PDF for over 30 days, and cited works not yet indexed (`brain-mesh-citation-index`). Work them off here.
11. **Undecided gaps, tensions and hypotheses.** `check` lists each open one that an integrated paper bears on without a recorded decision. Decide as add-paper step 8 says: a status change with its `graded::` line, or `- reviewed:: <date> P012 — untouched: <why>`. It also flags experiments still planned against a closed gap and hypotheses explaining a resolved tension: amend, abandon or re-grade them.
12. **Claims, data sets and code.** Integrated papers without a claims card; claims linked to findings that no longer cite their evidence; data-set and code cards with no study (`used_by::`), no location, or a summary too thin to stand in for a README; two cards for one data set or repository (merge them).
13. **Priority.** `health` opens with the focus (the cards the user set high, and how many cards each lifts) and orders its queues by effective priority; low-priority sources drop out of the unused-evidence list. Work high items first. It also lists high cards untouched for 90 days (ask the user to confirm them or set them back to normal), disagreements on high concepts (tension candidates) and lens passes worth making for high concepts. In periodic audits, sample high-priority cards at twice the rate.
14. **Concept scan and citations.** `check` warns about sources whose text names a concept in passages no card covers and no decision answers (often because a concept was added after the source), about cards whose passage cites works but which carry no `cites::` line, and about hub lines that state a cited fact without its work. `python3 tools/mesh.py scan` lists the sources with work left; clear them with `brain-mesh-concept-scan`. Proposed concepts the user has not answered are listed by `staged`: ask them again.
15. **The contradictions register.** `check` warns about possible contradictions neither logged nor dismissed, about contradiction cards still missing **Why both cannot hold** or **Ways out**, and, once a paper is integrated, about open contradictions it bears on with no decision. Read `ledger/contradictions.md`: an open contradiction that nothing works on goes to `brain-mesh-discover` (contradiction pass) or `brain-mesh-experiment`; one whose side was retired or corrected is re-read and dissolved, resolved or kept with a `graded::` line.
16. **Study profiles, independence and the basis of relations.** `check` warns about extracted sources with no study profile, about `affects::` lines with no basis or with `tested` and no experiment behind it, and about `probable` or `established` findings whose sources are not independent. `health` lists findings to regrade for that reason, and `independence` shows the groups. Fill the profiles from each paper's methods; regrade, or declare the sources independent on the finding with the reason.
17. **Hubs that have grown long.** Split: propose narrower concepts to the user and, once they adopt them, give each `- broader::` pointing at the hub, move the relevant lines to them, and re-point the cards whose statement is specifically about the narrower concept.
18. **Experiments registered or running for a long time; sources not yet integrated.** Ask the user, or finish the integration.
19. **Mined cards with newer evidence.** Run `python3 tools/mesh.py discover --recheck` and take the changes to the user (`brain-mesh-discover` section 8). The housekeeping signals of `discover` (`links`, `implied:data`, `genealogy:held`) can be done without asking; everything else from the miners is proposed, never written unasked.

20. **Hypotheses the brain has moved past.** A hypothesis never deepened, or deepened before the newest evidence that shares a concept with it, is being tested against a brain that has since changed. Run `python3 tools/mesh.py hypothesis deepen <H###> --write`, judge the new lines, and rewrite the rationale, the rivals and the predictions against what they say (`brain-mesh-experiment`, section 2.1). Deepen before registering an experiment, never after.
21. **Studies whose data or code moved after they were sealed.** The analysis plan is sealed; its inputs are not. Check that the study still runs on what it registered: if the data-set or code card changed in a way that matters, write it under `## Amendments` on the experiment card before the run, or re-register.
22. **Citation-index entries whose work has since been read.** Retire the indexed claim (`- retired:: read as P0xx`): an abstract is the authors' summary of themselves, and nothing should rest on it once the text is in the brain and carded.

Finish with `build`, then `python3 tools/mesh.py log "housekeeping: <what was done>"`.

## Splitting and merging synthesis cards

The identity rules in `brain-mesh-add-paper` step 8 decide when two findings, tensions, gaps or hypotheses are one card, and when one card has become two.

- **Split a finding** when the one-sentence test fails, when `check` reports evidence outside its scope or supporting cards that disagree, or when its evidence falls into groups by condition with different results. Write a sibling finding for each scope, with the scope in its title and `when::` lines, and move the evidence to the finding it belongs to. Keep the original card for the scope it still describes, or retire it as a pointer to its successors with `merge`; never delete it. Record the change with a `graded::` line on each card involved.
- **Split a tension** whose sides argue about different quantities or conditions: one tension per question that would settle it.
- **Merge two findings, tensions, gaps or hypotheses** whose identities match (same proposition and scope, same settling question, same closing measurement, same predictions), as below.
- A gap partly filled by a new source is narrowed, not duplicated: rewrite what is still missing, and keep the evidence that narrowed it in its Codes.

## Merging

Merging keeps both ids: the dropped card becomes a pointer. To delete a card outright, see **Removing a card** in `brain-mesh-access` (`mesh.py remove`); it is for cards added by mistake or that must not be kept, not for wrong or duplicate cards.

Never delete a card file; other cards and the user's own notes may point at it.

1. Decide which card survives: the older id, unless the newer card is clearly the better one.
2. Move anything worth keeping into the survivor by hand: for a concept, its aliases and the lines of its article; for an evidence card, its anchors and any detail the survivor lacks.
3. `python3 tools/mesh.py merge <keep> <drop>` redirects every link and retires the dropped card with a pointer to the survivor.
4. `build`.

Two cards from different sources that say the same thing are not duplicates. They are independent evidence and stay separate, linked by `replicates`.

- **Two concepts the papers seem to use as one.** Before merging, read how the cited literature uses each (their hubs list the indexed works, with what each claims). If the meanings differ even slightly, put the choice to the user with the difference stated: merge, keep both and link them, or make one an alias. Merging concepts, splitting them and changing a definition are the user's decisions, like a new concept.
- **Reference cards are merged only when they are one work.** Two entries one source cites under different numbers are two works (issue #62), even when their titles are close; compare authors, year, journal and pages, not title words alone.
- **Undoing a wrong merge.** Remove the `- retired:: merged into …` line from the dropped card, restore what it lost (for a reference card, its `- cited_by::` lines, read again from each citing source's `P###_refs.md`), and re-point the links `merge` redirected that belonged to it: `python3 tools/mesh.py impact <survivor>` lists what links the survivor. If the dropped card has a true twin elsewhere, merge it into that twin instead. Then `build`, and log it.
- **Links left pointing at a merged-away card.** Re-running `merge <keep> <drop>` redirects them again, so run it once more for any merged pair a later edit or a late agent linked to the old id.

## Corrections and retractions

`python3 tools/mesh.py impact <card id or P###>` lists everything that rests, directly or through other cards, on a card or on a whole source: the claims built on an observation, the findings that cite it, the hypotheses those findings prompted, the experiments testing them, and the concept relations that cite it.

- **An extraction error found later.** Check the passage on the PDF page, then fix the card, prose and Codes together. Run `impact` on it and review each dependant. Log it.
- **A published correction** (erratum, corrigendum, notice). Register it with `python3 tools/mesh.py anchor P012 --correction notice.pdf`. Each correction is appended to `P012_correction.pdf`, sealed, and its paragraphs added to `P012_correction_text.md` as `^c0001`, `^c0002` …, numbered on so that anchors already cited never move. Add a `coverage::` line for it on the source card. Then fix each affected card, keeping its id: correct prose and Codes together, say in the prose what the correction changed, add `- corrected:: <date> — <what changed>`, and add an anchor into the correction (`[[P012_correction_text#^c0003]]`). `check` warns about a corrected card with no such anchor; `build` marks the correction notice like any other PDF; `health` lists the sources that have corrections. Run `impact` on each corrected card and review its dependants.
- **A retraction.** Do not remove the source or its cards; the history matters. Add `- retracted:: <date and reason>` to the source card's Codes and state the retraction at the top of its prose (`check` warns until the prose says so). One retracted statement within a source gets `retracted::` on its own card instead. From then on:
  - every card that rests on the retracted evidence, directly or through other cards, including concept hubs whose relations cite it, is a warning until it has been reviewed. Re-grade each finding as though that evidence were absent, re-open gaps it had closed, correct hubs and hypotheses, then record the review on the card: `- retraction_checked:: P012 — <what changed>`;
  - the source's marked PDF carries a RETRACTED banner on its first page, and concept hubs label its cards **retracted**;
  - `health` lists retracted sources with the number of dependants still to review.

- **A retracted cited work.** When a work the brain cites but has not read is retracted (an index such as PubMed marks it so), add `- retracted:: <date and reason>` to its reference card, then run `impact` on every evidence card that cites it (`- cites::`) and on the hubs whose lines credit it: state the retraction on each card that repeats the work's result, and record the review with `- retraction_checked:: R0123 — <what changed>`.

Tell the user what changed in the brain's conclusions, not only which cards were edited.

## Edits made in Obsidian

The user is free to edit prose. After they have, `build` shows what moved: a value or concept in the prose that no longer matches the Codes, a renamed file whose name no longer starts with its id, a broken link.

- Treat the user's prose as their intent. Where an edit corrects content, change the Codes to match, then check the PDF page to see who is right, and say so if the source disagrees with the edit.
- Where the intent is unclear, ask. Never silently revert a user's edit.
- A note the user made in `concepts/` becomes a concept card at the next `build` (`brain-mesh` FORMATS.md, **Concept cards**). Check its kind and aliases with them, then `scan <concept>` to find it in the sources already in the brain.
- A renamed file gets its id back automatically. If a card was renamed but kept its id at the start, `build` re-points the links. If the id was dropped, `build` restores it from the card's `- id::` line, keeps the user's wording as the slug, and rewrites the links Obsidian had pointed at the new name. A renamed concept keeps its old file name, which is its id, and gains the user's new name as an alias.
- A link list in Codes that names one card twice or has an empty item (`- concepts:: [[a]], [[a]], , [[b]]`), left by a hand edit or an older fold, is a `check` warning: each item would be counted twice, or as nothing, wherever links are counted. `python3 tools/mesh.py tidy [P012|<id>]` keeps each link once and drops the empty items, and changes nothing else. `adopt <name> into <concept>` does this itself on the lines it rewrites.
- Edits inside `## Linked from` or an AUTO block are overwritten by the next `build`. Move anything of value into the card's own prose first.
- The user's own highlights and notes on a marked PDF are saved by `build` to `P012_annotations.json` (committed; the marked copy is not) and drawn again each time the copy is rebuilt, on every computer. Annotations on an original PDF change its checksum: move them to the marked copy and restore the original.

## Periodic audit

Checks on anchors and numbers catch transcription slips, not misreadings. Every so often run `python3 tools/mesh.py sample P### 10` on a few sources, favouring older ones and those the main findings rest on. Read each card against its passage on the marked PDF for meaning, completeness of conditions and fairness of status.

Run `python3 tools/mesh.py routes --readiness` as part of each audit: it says how much of each dimension discovery reads is coded (methods linked to techniques, conditions, data sets, definitions, reference lists, outside checks) and which routes each limits. The lowest lines are the coding work that would let the miners see most.

Where the session can start subagents, give each source's sample to one; it returns only the cards that need correcting, with what is wrong and the page, so the main conversation does not hold every card read.

Log the result, for example `audit: 30 cards across P004, P011, P019; 1 corrected`. If more than about one card in twenty needs correcting in a source, re-verify that source in full.

**Practice against the skills.** After a long session, or one that needed scripts of its own, compare what was done by hand with what the skills and `mesh.py` say. Every ad hoc script, workaround and correction the user gave is either a gap in the method or a departure from it. File each gap as an issue on the method's repository and close it there with a test (`brain-mesh-access`, section 8), and fix any departure in the vault. The user asked for this on 2026-11-27: practice that lives only in one session's scripts is lost to the next.

## Versioning and safety

- One writer at a time. If the vault is in git, `python3 tools/mesh.py sync` before starting and `sync "<what changed>"` after each completed operation (`brain-mesh-access`).
- Before a large change such as a batch merge, a hub split or a migration, commit or copy the vault first.
- Tooling and card-format upgrades go through `brain-mesh-setup`.
- Publisher PDFs, their marked copies and anchored text stay out of any shared copy; see `brain-mesh-setup`.

## Running it on a schedule

Where scheduled tasks are available and the vault is somewhere a scheduled run can reach (a git repository, say), offer a weekly or monthly check. The run clones the vault, runs `build`, `health` and `gaps` in its own copy, and reports the queues and any errors. It may also assemble the what-changed digest (`report changes`) in its own copy and include it. It never commits, pushes or edits cards: a scheduled run reports, and the next working session acts on the report.

## Report

Give the user a short account: errors fixed; duplicates merged; hubs refreshed; findings re-graded and why; searches repeated; anything they need to decide; and the audit result.
