---
name: "brain-mesh-setup"
description: "Create a new brain mesh vault, install or upgrade its tooling and set it up for Obsidian. Use when starting a second brain for a research topic, when tools/mesh.py is missing, or when moving or sharing a vault."
---

# Brain mesh: setup

Read `brain-mesh` first, and its FORMATS.md. Together they define the vault this skill creates.

## 1. Decide where the vault lives

One vault per research topic. The vault is an ordinary folder and must outlive the session, so settle its home before creating anything:

- **A folder on the user's computer** connected to this session. Best for Obsidian: the user opens that same folder as a vault and sees every change.
- **A git repository of its own**, private, separate from the `brain-mesh` repository that holds the instructions and tooling. Versioned and reachable from any session; the user clones it to their computer to browse in Obsidian. Decide with the user whether the PDFs go in it (see Sharing and copyright).
- **An archive handed back at the end of each session.** Last resort. Say plainly that the user must keep the archive and bring it back next time.

If none of these is settled, ask the user which they want. It decides whether the work persists.

### When the vault is its own git repository

This is the arrangement that lets Claude work on the vault from anywhere while the user browses it in Obsidian on their computer.

- **Everything is committed** except what is rebuilt from it: the original PDFs, the cards and `index/` are in git; the marked PDFs are not (below), and neither are files over the size limit. After a pull, `python3 tools/mesh.py build` (or `sync`, which builds) on the computer where Obsidian runs makes that computer's marked copies. `init` writes a `.gitignore` that excludes scratch files and `ingest/`, the drop folder where the user puts new papers and their supplementary files before they are anchored.
- **Pull before any work, push after each completed operation**, one commit per changelog line, so the user's next pull shows it. Work on the branch the user has agreed; ask once whether that is `main` or a branch with a pull request, and remember the answer in the vault's `MAP.md` overview.
- **One writer at a time** for a card: if the user edits cards on their computer, they push before Claude works on that source.
- **Marked PDFs are built, not committed** (from 1.25.0). `build` makes `P012_marked.pdf` from the original, the cards and the side file `P012_annotations.json`; `.gitignore` lists `sources/*/P*_marked.pdf`, and the first `sync` with the new tooling stops versioning the copies an older vault committed (they stay on disk; the history keeps the old ones, since removing them would need a force-push). Committed, each marked copy was stored again in full every time its source's cards changed, which was most of a vault's growth in git. The user's own highlights and notes on a marked copy are read at the next `build` into the side file, a small text file that is committed and merges like any other; every copy of the vault draws them again from it, and one the user deletes is removed everywhere. A vault whose owner only pulls and runs no tooling can keep the old arrangement with `"marked_in_git": true` in `MESH.json`. A session that opens no PDF (a report run in the cloud) can set `BRAIN_MESH_NO_MARK=1` to skip building them.
- **Size.** Original PDFs and figure crops are stored once.
- **Large files are linked, not committed.** A source file over the vault's limit (`large_file_mb` in `MESH.json`, 10 MB unless set) is kept out of git: an original PDF, or a supplementary PDF or data file. `anchor`, `build` and `sync` link such a file as they meet it: it stays in its source folder in this copy of the vault, so every command and Obsidian work as before; it is listed in `.gitignore`; and `ledger/linked-files.md` records its size, checksum and where to get it again (the paper's DOI). Stopping tracking a file makes git delete it from every other copy of the vault at its next pull; `sync` then puts back from the history each linked file that was ever committed (`linked --restore` does it by hand). A file linked when it was first added was never committed: in another copy, `check` notes it as absent and says where to get it; put it back in its source folder and run `mesh.py linked --verify`, then `build` rebuilds its marked copy. `linked` lists them, `linked --all` links the large files of a vault that had them before linking existed, and `linked <file> --from <url>` links one file by hand or records where it can be had. `sync` refuses to commit any other binary file over the limit outside the source folders, such as papers left outside `ingest/`; text files (cards, index, tables) are always committed. A file committed before it was linked stays in the history (removing it would need a force-push), but nothing is added after.
- On the user's computer: clone the repository once, open the folder in Obsidian, and pull to update (GitHub Desktop or the Obsidian Git plugin both work).

## 2. Get the tooling

The tooling is one file, `tools/mesh.py`, kept in the `tcpearce/brain-mesh` repository next to these instructions. The loader skill has already cloned or pulled the repository; use that copy. `init` copies it into the new vault, together with an offline copy of the instructions in the hidden `.brain-mesh/` folder, so a vault still works when the repository cannot be reached.

Never retype or reconstruct the tooling from memory: a checker that differs silently from the tested one is worse than none. If neither the repository nor a vault copy can be reached, say so and stop; cards can still be drafted by hand to the formats in `brain-mesh` and checked later.

Requirements: Python 3.8 or later, and PyMuPDF (`pip install pymupdf`). PyMuPDF gives the cleanest paragraphs and is the only route to the marked PDFs that show each card on the page. Without it the tooling falls back to poppler's `pdftotext`, `pdfplumber` or `pypdf` for text and skips marking. Scanned PDFs need OCR first (`ocrmypdf`, or `tesseract` on page images). Pillow (`pip install pillow`; it comes with matplotlib and Anaconda) lets `figure` write its crops as WebP, about a fifth of the size of PNG; without it they are PNG.

## 3. Test the tooling

From the repository root:

```bash
bash tests/run.sh
```

It builds a three-card vault from scratch and rebuilds a copy of the demo vault. Both must finish with `check: 0 errors, 0 warnings`, and the script ends with `ALL TESTS PASSED`. Run it whenever the repository has just been cloned somewhere new, and always before pushing a change to the tooling. If it fails, do not build or upgrade a real vault with that copy.

## 4. Create the vault

```bash
python3 <repository>/tools/mesh.py init <folder> "<Vault name>" "<One-line topic>"
```

`init` creates the folders (including `data-sets/`, `code/` and `references/`), `MESH.json`, `MAP.md`, `SCHEMA.md`, `CLAUDE.md` (which sends any agent working in a clone to `brain-mesh-access`) and the ledger, and copies the tooling into `tools/`. From then on run everything as `python3 tools/mesh.py <command>` from inside the vault; `help` lists the commands.

Then write the **Overview** in `MAP.md`: the topic, what is in scope and out of scope, and what the brain is for. A stated scope is what later lets a gap be called a gap.

Next step: add the first sources with `brain-mesh-add-paper`.

## 5. Obsidian

Tell the user, briefly:

- Open the vault folder with "Open folder as vault". Start at `MAP`, then follow a concept hub.
- Every link is a normal Obsidian link. The backlinks pane of a concept card lists every card that mentions it, and each card's `## Linked from` section shows every card that links to it and why, so any link can be followed back from inside the card.
- The graph view is most readable with colour groups by folder: `path:concepts`, `path:sources`, `path:findings`, `path:tensions`, `path:gaps`, `path:hypotheses`, `path:experiments`, `path:data-sets`, `path:code`, `path:references`. A paper's claims card (`P012-claims`) is the quickest way into it. Add a colour group for `[priority:high]` so the focus stands out. Add `-path:index` to the graph's filter: `index/hubs/` holds one generated page for each large concept, listing every card that names it, and those pages would otherwise sit in the graph as hubs of their own.
- Priority is the `priority` property in each card's Properties panel: type `high`, `normal` or `low` (Obsidian has no fixed dropdown, but it suggests the values already used). Remove the property for normal.
- So that edits made in Obsidian, priorities included, reach GitHub: in the Obsidian Git plugin set **Auto commit-and-sync interval** to a few minutes (with auto-pull already on). Without it, the next `sync` from any Claude session commits them.
- Each paper has two PDFs. `P012.pdf` is the original and is never changed. `P012_marked.pdf` shows every card as a coloured highlight with a tag beside it: the full card id in the page margin, or the card number alone (`014` for `P012-014`) in the gutter between columns. A card's **open page** link jumps to its highlight, and clicking a margin tag opens the card. Unhighlighted text has no card.
- Their own highlights and notes go on the marked copy. The next `build` saves them to `P012_annotations.json` beside it, which is what git carries, and draws them again whenever the copy is rebuilt: highlights, underlines, strike-outs, notes, typed text, pen strokes, boxes, ovals, lines and polygons. Anything else (a stamp, an attached file) stays in that computer's copy, and `build` keeps the copy and says so before replacing it. Annotating the original would trip its checksum.
- The tags open cards by vault name. `init` records the folder name as `"obsidian_vault"` in `MESH.json`. If the vault appears under another name in Obsidian, for example a clone kept in a differently named folder, change that value and run `python3 tools/mesh.py mark --force`.
- The `key:: value` lines under `## Codes` are plain text. The Dataview plugin, if installed, can query them, but nothing depends on it.
- Safe to edit in Obsidian: the prose of any card, concept hubs most of all. Tell Claude afterwards so the Codes can be brought into line.
- Do not edit: `## Linked from` sections, anything between AUTO markers, `index/`, the original PDFs or the `_text` files. Do not rename card files; the id at the start of the name must stay.
- Their own free-form notes belong in a `notes/` folder. The tooling ignores it, and notes there can link to any card.

The first time a vault is opened in Obsidian, ask the user to confirm two things that cannot be checked from here: that a card's **open page** link lands on its highlight, and that a margin tag opens the right card. If either fails, the page link still works; report it so the link format can be corrected.

## 6. Sharing and copyright

Cards are written in Claude's and the user's own words and can be shared. Publisher PDFs and the anchored full text usually cannot. Before a vault is pushed to a shared or public repository, or sent to people outside the group, leave out `sources/*/P*.pdf` (which covers the marked copies too) and `sources/*/P*_text.md`; in git, a `.gitignore` with those two patterns. The page links in cards then go dead for those readers, but the citations in each **Source:** line still stand.

## 7. Upgrading

- New tooling or instructions: pull the repository, then `python3 <repository>/tools/mesh.py upgrade <vault folder>` and `build` in the vault. `python3 tools/mesh.py version` shows what a vault is running.
- Changing the tooling or these instructions: edit them in the repository, run `bash tests/run.sh`, raise `VERSION` in `tools/mesh.py` and the `VERSION` file together, add a line to `CHANGELOG.md`, commit and push. Every session picks the change up at its next pull.
- A vault whose figure and equation crops are PNG (made before 1.24.1): `python3 tools/mesh.py crops` shows the room they take and what WebP would save; `crops --convert` writes each as WebP at the same pixel size, rewrites every embed and mention to the new name and removes the PNG, then `build` and sync. A crop whose thin coloured lines would fade is kept lossless. Needs Pillow.
- A vault made before source checksums existed: run `python3 tools/mesh.py seal` once to record them, then `build` to create the marked PDFs.
- `MESH.json` records the schema number the vault was built with, and `python3 tools/mesh.py schema` prints what the tooling enforces.
- If the card format changes, write a one-off migration script, run it on a copy of the vault, `build`, and compare card counts and error counts before replacing the original. Log the migration.