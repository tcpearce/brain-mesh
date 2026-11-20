# Changelog

Newest first. Raise `VERSION` here, in the `VERSION` file and in `tools/mesh.py` together.

## 1.0.3 (2026-11-20)

Also from the first test on real papers.

- New command `unread <P###>`: lists the paragraphs of a source that no card is anchored to. On the two test papers it found six statements the first pass had missed.
- Add-paper instructions: the verification step now runs `unread` and reviews each listed paragraph, as well as viewing the marked pages.
- Marking: the legend at the top of page 1 is no longer cut off.

## 1.0.2 (2026-11-20)

Found by the first test on real papers.

- Marking: PDF search now expands typeset ligatures, so a locator phrase containing "fi" or "fl" is found on the page.
- Marking: each tag now sits immediately left of the column holding its highlight, so on a two- or three-column page a tag is beside its own passage. A page margin takes the full card id; a gutter between columns takes the card number alone.
- Marking: a card with two anchors that resolve to the same passage gets one highlight, not two.
- Checks: a value written with a thousands separator in the prose (5,000) now matches the same value in Codes (5000).
- Add-paper instructions: choose locator phrases made of plain words, avoiding symbols, operators and words split by a line-break hyphen.

## 1.0.1 (2026-11-20)

- Vaults kept in their own git repository: `init` writes a `.gitignore`; generated files no longer carry the build date, so they change only when the content does; the setup document explains what to commit, pull and push.

## 1.0.0 (2026-11-20)

First version.

- Card format: human-readable part first, then `## Codes`; one statement per evidence card; concept cards as living hubs.
- Tooling `tools/mesh.py`: anchoring, batch card writing, link expansion and mirroring, checks, duplicate rules, concept hub and source lists, search, condition matrix, gap scan, research-gaps document, health report, impact tracing, merge.
- PDF ground truth: sealed originals with checksums, marked copies with each card highlighted on the page.
- Six instruction documents under `skills/`, a loader skill under `loader/`, a demo vault and tests.
