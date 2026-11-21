---
name: "brain-mesh-housekeeping"
description: "Keep a brain mesh healthy as it grows: health report, stale concept hubs, re-grading findings, merging duplicates, corrections and retractions, audits of old cards, and reconciling edits made in Obsidian. Use for tidy, audit, check or maintain requests."
---

# Brain mesh: housekeeping

Read `brain-mesh` first. Find the vault.

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
4. **Concept hubs older than their newest card.** Reread the cards listed under **Where it appears**, then bring **What is known**, **Relationships** and **Open questions** up to date and set `updated`. The hubs are what the user reads, so a stale hub misleads even when every card beneath it is right.
5. **Findings whose status no longer matches their evidence.** Re-grade: still `single-source` after a second source supports it, still `established` after counter-evidence arrived, graded above `single-source` on one paper.
6. **Old gap searches.** Repeat them with `brain-mesh-gaps`. A confirmed research gap is only as good as its last search.
7. **Claims, observations and models cited by nothing.** Either integrate them into a finding or a tension, or leave them deliberately. Not every card needs a finding, but a paper's main results do.
8. **Flagged cards.** Go back to the PDF page, resolve the doubt and remove the flag, or keep it with a clearer note.
9. **Concepts used by at most one card.** Fold them into a broader concept as an alias, or leave them if more sources on the topic are coming.
10. **References.** `check` warns when a source's reference list is extracted but not turned into cards (`cite P012`), when two reference cards look like the same work (merge them: the survivor takes over every `cited_by::` line), and when a card has no year or a malformed DOI. `health` counts the papers whose reference list was never extracted: run `refs` on them (add-paper step 1). Read the generated list in `ledger/reading-queue.md` and set statuses on the reference cards: `queued` for what the user is fetching, `skip` for what will not be read, so the list stays short. Cards a later source has made `held` need nothing.
11. **Undecided gaps, tensions and hypotheses.** `check` lists each open one that an integrated paper bears on without a recorded decision. Decide as add-paper step 8 says: a status change with its `graded::` line, or `- reviewed:: <date> P012 — untouched: <why>`. It also flags experiments still planned against a closed gap and hypotheses explaining a resolved tension: amend, abandon or re-grade them.
12. **Claims, data sets and code.** Integrated papers without a claims card; claims linked to findings that no longer cite their evidence; data-set and code cards with no study (`used_by::`), no location, or a summary too thin to stand in for a README; two cards for one data set or repository (merge them).
13. **Priority.** `health` opens with the focus (the cards the user set high, and how many cards each lifts) and orders its queues by effective priority; low-priority sources drop out of the unused-evidence list. Work high items first. It also lists high cards untouched for 90 days (ask the user to confirm them or set them back to normal), disagreements on high concepts (tension candidates) and lens passes worth making for high concepts. In periodic audits, sample high-priority cards at twice the rate.
10. **Hubs that have grown long.** Split: create narrower concept cards with `- broader::` pointing at the hub, move the relevant lines to them, and re-point the cards whose statement is specifically about the narrower concept.
11. **Experiments registered or running for a long time; sources not yet integrated.** Ask the user, or finish the integration.

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

## Corrections and retractions

`python3 tools/mesh.py impact <card id or P###>` lists everything that rests, directly or through other cards, on a card or on a whole source: the claims built on an observation, the findings that cite it, the hypotheses those findings prompted, the experiments testing them, and the concept relations that cite it.

- **An extraction error found later.** Check the passage on the PDF page, then fix the card, prose and Codes together. Run `impact` on it and review each dependant. Log it.
- **A published correction** (erratum, corrigendum, notice). Register it with `python3 tools/mesh.py anchor P012 --correction notice.pdf`. Each correction is appended to `P012_correction.pdf`, sealed, and its paragraphs added to `P012_correction_text.md` as `^c0001`, `^c0002` …, numbered on so that anchors already cited never move. Add a `coverage::` line for it on the source card. Then fix each affected card, keeping its id: correct prose and Codes together, say in the prose what the correction changed, add `- corrected:: <date> — <what changed>`, and add an anchor into the correction (`[[P012_correction_text#^c0003]]`). `check` warns about a corrected card with no such anchor; `build` marks the correction notice like any other PDF; `health` lists the sources that have corrections. Run `impact` on each corrected card and review its dependants.
- **A retraction.** Do not remove the source or its cards; the history matters. Add `- retracted:: <date and reason>` to the source card's Codes and state the retraction at the top of its prose (`check` warns until the prose says so). One retracted statement within a source gets `retracted::` on its own card instead. From then on:
  - every card that rests on the retracted evidence, directly or through other cards, including concept hubs whose relations cite it, is a warning until it has been reviewed. Re-grade each finding as though that evidence were absent, re-open gaps it had closed, correct hubs and hypotheses, then record the review on the card: `- retraction_checked:: P012 — <what changed>`;
  - the source's marked PDF carries a RETRACTED banner on its first page, and concept hubs label its cards **retracted**;
  - `health` lists retracted sources with the number of dependants still to review.

Tell the user what changed in the brain's conclusions, not only which cards were edited.

## Edits made in Obsidian

The user is free to edit prose. After they have, `build` shows what moved: a value or concept in the prose that no longer matches the Codes, a renamed file whose name no longer starts with its id, a broken link.

- Treat the user's prose as their intent. Where an edit corrects content, change the Codes to match, then check the PDF page to see who is right, and say so if the source disagrees with the edit.
- Where the intent is unclear, ask. Never silently revert a user's edit.
- A renamed file gets its id back automatically. If a card was renamed but kept its id at the start, `build` re-points the links. If the id was dropped, `build` restores it from the card's `- id::` line, keeps the user's wording as the slug, and rewrites the links Obsidian had pointed at the new name. A renamed concept keeps its old file name, which is its id, and gains the user's new name as an alias.
- Edits inside `## Linked from` or an AUTO block are overwritten by the next `build`. Move anything of value into the card's own prose first.
- The user's own highlights and notes on a marked PDF are kept when it is regenerated. Annotations on an original PDF change its checksum: move them to the marked copy and restore the original.

## Periodic audit

Checks on anchors and numbers catch transcription slips, not misreadings. Every so often run `python3 tools/mesh.py sample P### 10` on a few sources, favouring older ones and those the main findings rest on. Read each card against its passage on the marked PDF for meaning, completeness of conditions and fairness of status.

Log the result, for example `audit: 30 cards across P004, P011, P019; 1 corrected`. If more than about one card in twenty needs correcting in a source, re-verify that source in full.

## Versioning and safety

- One writer at a time. If the vault is in git, `python3 tools/mesh.py sync` before starting and `sync "<what changed>"` after each completed operation (`brain-mesh-access`).
- Before a large change such as a batch merge, a hub split or a migration, commit or copy the vault first.
- Tooling and card-format upgrades go through `brain-mesh-setup`.
- Publisher PDFs, their marked copies and anchored text stay out of any shared copy; see `brain-mesh-setup`.

## Running it on a schedule

Where scheduled tasks are available and the vault is somewhere a scheduled run can reach (a git repository, say), offer a weekly or monthly check. The run clones the vault, runs `build`, `health` and `gaps` in its own copy, and reports the queues and any errors. It never commits, pushes or edits cards: a scheduled run reports, and the next working session acts on the report.

## Report

Give the user a short account: errors fixed; duplicates merged; hubs refreshed; findings re-graded and why; searches repeated; anything they need to decide; and the audit result.
