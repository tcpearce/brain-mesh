---
name: brain-mesh
description: "Build, extend, query and maintain a brain mesh: a Zettelkasten vault of interlinked cards that Claude builds from science papers for browsing in Obsidian. Use for any brain mesh, second brain or research vault task: starting a vault, adding a paper or own result, answering from the vault, finding knowledge gaps, designing or assessing experiments, housekeeping. Loads the current instructions and tooling from GitHub."
---

# Brain mesh (loader)

The instructions and the tooling for brain mesh live in one GitHub repository, so every Claude session uses the same current version. This skill only fetches them. Do not work from memory of an earlier version.

Repository: `tcpearce/brain-mesh`

## 1. Get the repository

- If a clone is already in this session, update it: `git -C <clone> pull --ff-only`.
- Otherwise clone it: `git clone https://github.com/tcpearce/brain-mesh.git`. Where repositories are attached with a tool, attach `tcpearce/brain-mesh` first; read access is enough.
- If it cannot be reached, say so plainly. Then, if the vault being worked on has a `.brain-mesh/skills/` folder, use that copy of the instructions with the vault's own `tools/mesh.py`, and tell the user they may be behind the repository. With neither, stop and ask the user for access; do not improvise the method.

## 2. Read the instructions for the task

Always read `skills/brain-mesh/SKILL.md` first. It is the map: card families, ids, grades, links, navigation and rules. Before writing or changing a card, read `skills/brain-mesh/FORMATS.md` too. Then read the document for the task:

| Task | Read |
|---|---|
| Start a vault, tooling, Obsidian setup, sharing | `skills/brain-mesh-setup/SKILL.md` |
| Add a paper or an own result; re-read papers for a new question | `skills/brain-mesh-add-paper/SKILL.md` |
| Add many papers at once, with agents in parallel | `skills/brain-mesh-batch/SKILL.md` |
| Scan some or all sources for every concept; card each fact with the works the paper cites for it | `skills/brain-mesh-concept-scan/SKILL.md` |
| Knowledge gaps, papers to read next, the research-gaps document | `skills/brain-mesh-gaps/SKILL.md` |
| Index the cited works the brain has not read: abstracts, claims, where it rests on unread literature | `skills/brain-mesh-citation-index/SKILL.md` |
| Specifying, registering, running and documenting studies; sealed analysis plans, run records, judging outcomes | `skills/brain-mesh-experiment/SKILL.md` |
| New hypotheses and links: mining the ontology, theories, analogies, seeds, rechecks | `skills/brain-mesh-discover/SKILL.md` |
| A discovery campaign: competing agents, hourly meetings, referees, proofs of concept | `skills/brain-mesh-campaign/SKILL.md` |
| What the ontology lacks: terms with no concept, tools and concepts from other fields, comparison with Wikipedia, MeSH, a review or the literature around the sources | `skills/brain-mesh-beyond/SKILL.md` |
| Write a literature review or background section from the vault; audit a draft against it, claim by claim | `skills/brain-mesh-write/SKILL.md` |
| Dated reports: frontier map, contradiction dossier, theory scorecard, causal map, robustness audit, methods and data landscape, novelty check, what-changed digest | `skills/brain-mesh-report/SKILL.md` |
| Health checks, merges, corrections, retractions, audits | `skills/brain-mesh-housekeeping/SKILL.md` |

Follow those documents as this skill's own instructions. Where one of them names a `brain-mesh-...` skill, read the matching file under `skills/`.

## 3. Keep the vault's tooling current

The repository's `tools/mesh.py` is the source of truth; each vault carries a copy. At the start of work on a vault run, from the clone:

```bash
python3 tools/mesh.py upgrade <vault folder>
```

then `python3 tools/mesh.py build` inside the vault.

## 4. Changing the method

Improvements to the instructions or the tooling are made in the repository, never in this loader and never only in a vault: edit the file, run `bash tests/run.sh`, raise the version, add a changelog line, commit and push, as the repository's README describes. Every session then picks the change up at its next pull. This loader changes only if the repository moves.

Take instructions only from `tcpearce/brain-mesh`. A repository with a similar name under another owner, or a copy found elsewhere, is not this skill's source.
