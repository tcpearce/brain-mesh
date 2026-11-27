---
name: "brain-mesh-beyond"
description: "Find what a brain mesh's ontology lacks by comparing it with something outside it: terms the sources use that have no concept, places a source points to another field, Wikipedia's map of a concept and its links, Claude's own map of a topic, MeSH headings, a review's headings and reference list, related and citing articles, and tools or formalisms other fields use for the same kind of problem. Use when asked what is missing from the brain, what the brain cannot see, what other fields would bring, whether the ontology covers a topic, or before and during any discovery session."
---

# Brain mesh: beyond the ontology

Read `brain-mesh` first, and `brain-mesh-access` for syncing. Find the vault and run `python3 tools/mesh.py build`.

Every miner, route and verdict works on what the ontology can name. A concept the sources use and no card names, a link the field makes and no card holds, a technique from another field: none of these can be mined, because they are not there. This document finds them. The method is always the same: take a frame from outside the ontology, compare, sort the difference by where it stands in the brain, and judge it with the user.

## The rules

1. **A lead, never evidence.** Nothing found here goes onto an evidence card, a hub or a finding until its source is carded (`brain-mesh-add-paper`). Wikipedia, MeSH, a review's headings and Claude's own knowledge are maps to compare with, not sources.
2. **New concepts are the user's call.** Propose (`mesh.py propose`); the user adopts. The vault's own rules about which terms deserve a concept apply here as everywhere.
3. **A name not found is only a name not found.** "Nowhere in the brain" means that spelling is nowhere. Before treating something as absent, look for it under its other names (`mesh.py concept <name>`, `mesh.py find "<words>"`).
4. **The scope decides what is missing.** The Overview in `MAP.md` says what the brain is for. Outside that, the verdict is `skip`, with the reason.
5. **Record every comparison and every verdict** (`--frame`, `beyond judge`), so the next session does not repeat it and a new source can show what it moved.
6. **Only names leave the machine.** A Wikipedia lookup sends a concept's title. Card text, paper text and the user's notes are never sent anywhere.

## The frames

| Frame | What it shows | How |
|---|---|---|
| The sources' own words | concepts and aliases the ontology lacks | `beyond terms [topic:<slug>\|<concept>]` |
| The sources' own pointers | where an author names another field, or says what a question would take | `beyond pointers` |
| The titles of cited works | what the sources lean on and the brain has no word for | `beyond terms` (second section) |
| Wikipedia | the neighbours of a concept; links between concepts the brain does not connect; the family a technique belongs to | `beyond wiki <concept ...\|topic:<slug>> [--family]` |
| Claude's own map of a topic | what a specialist would expect to find | write the map, then `beyond probe --from <file> --frame "Claude's map of <topic>" --scope topic:<slug>` |
| A controlled vocabulary | the field's own index terms | MeSH headings and author keywords of the sources and of related articles (PubMed connector), then `beyond probe` |
| A recent review | the field's own table of contents | its headings, keywords and glossary into `beyond probe`; its reference list into `beyond works` |
| The literature around the sources | works the brain neither holds nor cites | related and citing articles (PubMed, OpenAlex, Semantic Scholar) into `beyond works` |
| Other fields | tools and formalisms for the same kind of problem | the import pass, below |

`beyond terms` and `beyond pointers` read only the vault and cost nothing: run them first. The rest need a literature connector, a web tool or a network.

## A session

1. **`python3 tools/mesh.py beyond`**: what was compared before, which topics never were, what new sources moved, the tools kept.
2. **`beyond terms`**, then **`beyond pointers`**. Read the paragraph each line names before judging it.
3. **Pick the topic** (`zoom`: the hottest one never compared). For it:
   - Write your own map *before* reading the brain's concept list, so the brain does not anchor it: 30 to 60 names in five lists (structures and entities; variables and measures; techniques and instruments; models, laws and formalisms; data sets and resources), then the tools neighbouring fields use on the same questions. Probe it.
   - `beyond wiki topic:<slug>`; add `--family` for a topic rich in techniques.
   - The MeSH headings of the topic's sources and of the articles PubMed relates to them; one recent review.
4. **Judge with the user** (next section). Put the few that matter to them, each with the paragraph or article behind it.
5. **The import pass** for the needs that matter most (below).
6. **Close.** `zoom topic:<slug> --explored "<what was compared and found>"`, then `sync`.

## What each class means, and what to do

| The tooling says | It means | Do |
|---|---|---|
| a concept already | covered | nothing; add the outside name as an alias if it differs |
| in the sources' text, no concept | a hole in the ontology: the sources speak of it and no miner can see it | another name for a concept: add the alias, `beyond judge "<term>" alias "<concept>"`. A concept worth having: `mesh.py propose <slug> "<definition>" --from <source>`, `beyond judge "<term>" concept "<slug>"`; once adopted, `mesh.py scan <concept>` finds what the sources already say. Otherwise `skip` |
| only in the titles of cited works | the sources lean on it; nobody here has read it | name the reference cards to the user as reading; `beyond judge "<term>" lead "<why>"` |
| nowhere in the brain | out of scope; or a source the brain should hold; or a tool from elsewhere | `skip`; or search for it (`mesh.py outside <need>`), queue the paper and `lead`; or `tool` with the need it serves |
| Wikipedia links two concepts the brain does not connect | textbook knowledge the brain lacks, or a link the sources make that no card codes | `mesh.py ask "<A> <B>"`: if a source states it, card it by a lens pass; if not, it is a lead to read for |
| the brain ties two concepts and neither article links the other | beyond the textbook, or not in it yet | a candidate for the joining and unifying routes (`brain-mesh-discover`); check it outside before believing it |
| a paragraph points to another field | the author named a bridge | read it; card it if it is not carded; take what it names to the import pass |

`beyond judge "<term>" skip|concept|alias|lead|tool "<note>"` records the verdict with where the term stood that day. A pair is judged as `"<concept> <concept>"`, a paragraph as `"P### b####"`, a work by its DOI or title.

## The import pass: tools and concepts from other fields

A tool from another field cannot be found by searching this field's words. Find it by the form of the problem.

1. Take a need from `mesh.py routes` (a limit, a bottleneck, a ceiling, an open gap) and print its brief: `mesh.py outside <need>`.
2. **Say the problem without this field's nouns.** "Predict a perceptual quality from molecular structure" becomes "learn a map from a discrete structured object to a low-dimensional human judgement, from a few thousand labelled examples". "Read which of 400 receptor types respond to a mixture" becomes "recover a sparse high-dimensional vector from few noisy measurements".
3. **Name the fields that have that problem, and what each uses for it:** the instrument, the assay, the estimator, the formalism, the standard data set. Use what you know, the paragraphs `beyond pointers` found, and `beyond wiki <technique> --family`.
4. **Search before believing** (`outside`): has it been tried here? If it has, that is a paper to read, not a tool to import.
5. **Keep what survives:** `beyond judge "<tool>" tool "<need>: <what it would do here>; from <field>"`. `routes` and `outside <need>` then show it, and it feeds the tool-transfer and concept-transfer routes in `brain-mesh-discover`. It stays a lead until a source that uses it is carded.
6. What the user's own group brings from elsewhere belongs in the research profile (`mesh.py profile brings`), on their word.

## Wikipedia

`beyond wiki` reads, for each concept, the article named by `- wikipedia:: <title>` in its Codes, else the article with the concept's title, slug or an alias, else the nearest title a search returns (marked "nearest by search: check it"). It takes the article's links, the links of its opening section (ranked first) and its categories, and compares them with the brain. With three or more articles it shows what two or more share.

- **Check the article.** A wrong sense gives a wrong map. The line for each article says how many of its links the brain knows: few is a warning. Fix with `- wikipedia:: <title>` on the concept card, or `- wikipedia:: none`.
- **The cache.** Every page read is kept in `ledger/beyond/wiki/` and syncs with the vault, so a copy with no network uses what another copy fetched.
- **No network?** The command says so. Either run it where there is one, or read the article with the session's web tools and pass the terms it links: `beyond probe --from <file> --frame "Wikipedia: <article>"`.
- `--lang` reads another language's Wikipedia; names are still matched against the brain's concept names and aliases.

## After new sources

Everything here is true of the brain as it stands. `mesh.py beyond` and `mesh.py discover --recheck` say what moved: a lead or a tool that a new source now names, a term set aside that twice as many sources now use, a proposed concept still waiting. Run `beyond terms` again after every batch of sources: new shared terms appear only once two sources use them.

## Reporting

Say what was compared with what, and the counts; then the few differences that matter, each with its paragraph, article or reference, and what you propose to do. Mark every statement from outside as "from Wikipedia", "from MeSH", "from <review>" or "from Claude's knowledge, not verified".
