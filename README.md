# brain-mesh

A method and tooling for building a **second brain from science papers** with Claude, as a Zettelkasten vault of interlinked markdown cards that you browse in Obsidian. The brain is meant for doing new science: proposing experiments, designing them and judging their outcomes.

This repository is the single source of truth for the method. Claude sessions load it through a small synced skill, so a change made here reaches every session.

## What is here

| Path | What it is |
|---|---|
| `skills/brain-mesh/SKILL.md` | The map: card formats, ids, link types, the PDF as ground truth, navigation, rules. Read first. |
| `skills/brain-mesh-access/SKILL.md` | Read every session, by any agent: syncing with GitHub, navigating and answering, adding your own material, editing, retiring and deleting cards. |
| `skills/brain-mesh-setup/SKILL.md` | Starting a vault, tooling, Obsidian, sharing, upgrading. |
| `skills/brain-mesh-add-paper/SKILL.md` | Adding a paper or an own result: anchor, references, extract, duplicate rules, link, verify, integrate, update the hubs. Lens passes. |
| `skills/brain-mesh-batch/SKILL.md` | Adding many papers at once: prepare, extract with one agent per paper in parallel, merge. |
| `skills/brain-mesh-concept-scan/SKILL.md` | Scanning chosen or all sources for every concept in the brain, carding each new fact with the works the paper cites for it, adding missing citations, updating the hubs. |
| `skills/brain-mesh-gaps/SKILL.md` | Finding key gaps, hunting papers that fill them, the research-gaps document. |
| `skills/brain-mesh-experiment/SKILL.md` | Hypotheses, experiment design, registered predictions, assessing outcomes. |
| `skills/brain-mesh-discover/SKILL.md` | Mining the brain with the user for new hypotheses and links; theory, analogy and seed cards; rechecking them as sources arrive. |
| `skills/brain-mesh-housekeeping/SKILL.md` | Health report, merges, corrections and retractions, audits, edits made in Obsidian. |
| `tools/mesh.py` | The tooling. One file, Python 3.8+, standard library plus PyMuPDF for PDFs. `python3 tools/mesh.py help` lists the commands. |
| `loader/SKILL.md` | The small skill that is synced to Claude. It clones or pulls this repository and routes to the right document. |
| `demo-vault/` | A complete small vault built from invented papers. Open the folder in Obsidian and start at `MAP`. |
| `tests/run.sh` | Tests for the tooling. |
| `VERSION`, `CHANGELOG.md` | Version of the method and tooling. |

## The ideas in one paragraph

Every note is a card with a permanent id and a meaningful name. An evidence card holds one statement from one source, written for a person first and repeated underneath as codes that Claude and the tooling can traverse. Concept cards are the hubs you browse; they grow with every paper. Links are typed, carry a reason, and are mirrored onto both cards. Findings, tensions and gaps are built on evidence, and hypotheses and experiments on those. The source PDF is the ground truth: the original is sealed with a checksum, and a marked copy shows every card as a highlight on the page it came from. Each paper gets a claims card (its main claim and up to five sub-claims, linked to its evidence and to the findings they feed), every data set and code base a study uses gets its own card, and every work the sources cite gets a reference card with BibTeX, and the brain suggests what to read next: works cited by several of its sources, and works cited where its gaps and tensions rest. You steer its effort with a priority on any card (high, normal, low): a high card draws deeper treatment to everything one link away.

## Using it

In Claude, the synced `brain-mesh` skill does the loading. By hand:

```bash
git clone https://github.com/tcpearce/brain-mesh.git && cd brain-mesh
pip install pymupdf
bash tests/run.sh                                   # should end with ALL TESTS PASSED
python3 tools/mesh.py init ../my-vault "My topic brain" "One-line topic"
```

Vaults do not live in this repository. Each vault is its own folder, or its own private repository, with a `CLAUDE.md` that tells any agent working in a clone (Claude Code, say) to follow `brain-mesh-access` and sync with GitHub first and last, because it holds your papers and your unpublished thinking. Publisher PDFs and their extracted text should stay out of anything shared.

## Changing the method

1. Edit the document under `skills/`, or `tools/mesh.py`.
2. Run `bash tests/run.sh`. Add a test for anything new that the tooling enforces.
3. Raise the version in `VERSION` and in `tools/mesh.py` together, and add a line to `CHANGELOG.md`.
4. Commit and push.

Each Claude session picks the change up at its next pull. A vault picks up new tooling with `python3 tools/mesh.py upgrade <vault>` run from this repository, followed by `build` in the vault. The loader skill only needs re-saving in Claude if this repository moves or is renamed.

The documents here are followed by Claude as instructions, so keep write access to this repository to people you trust.
