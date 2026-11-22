---
name: "brain-mesh-report"
description: "Assemble dated reports from a brain mesh for deciding what to do next: frontier map, contradiction dossier, theory scorecard, causal map, robustness audit, methods and data landscape, novelty check, what-changed digest. Use when the user asks for a report, briefing, overview, digest or status of the brain or of a topic; asks where to work next, what is weak, what changed or whether an idea is new; and before planning experiments, bids or reading."
---

# Brain mesh: reports

Read `brain-mesh` first, and `brain-mesh-access` for syncing.

A report is one dated document that answers one question from the cards as they stand. `python3 tools/mesh.py report <kind>` assembles it, every line linked to the cards it rests on, into `reports/<date>-<kind>.md`. Claude then reads it, checks what matters on the cards and the page, and writes its **Reading**.

## The reports

| Report | Command | The question | When |
|---|---|---|---|
| Frontier map | `report frontier [--focus <concept>] [--top n]` | Where is a discovery most likely? | Before choosing what to work on, read or bid for |
| Contradiction dossier | `report contradictions [V001 X001 ...]` | Why do these results disagree, and what would settle it? | Before designing an experiment; before a discovery session |
| Theory scorecard | `report theories` | Which account is winning? | Once rival explanations exist; after a theory pass |
| Causal map | `report causal [--focus <concept>]` | What is known to cause what, and how do we know? | Before claiming a mechanism; when choosing which link to test |
| Robustness audit | `report robustness` | What do we believe on thin evidence? | Before building on a finding; when choosing replications; before writing |
| Methods and data landscape | `report methods` | What could be done with what already exists? | When planning methods; when looking for a reanalysis instead of an experiment |
| Novelty check | `report novelty "<the idea>"` or `report novelty S004`, with `--concepts a b` to name concepts | Is this idea new? | Before promoting a seed, proposing a study or claiming novelty |
| What-changed digest | `report changes [--since <date or P012>]` | What moved in the brain? | After a paper or batch; weekly; when coming back after time away |

`report all` writes the seven that need no argument. `report` alone lists the kinds and the reports already written. `MAP.md` links the latest of each kind.

What each one holds:

- **Frontier map.** Open contradictions, open tensions, gaps by rung, hypotheses with no experiment, experiments not yet run, seeds, and the strongest two signals from each discovery miner, in one ranked table: what it is, its priority, how much rests on it, what would settle it and what is working on it. The order is base weight by kind, times priority, plus a little for what rests on it.
- **Contradiction dossier.** For each open or explained contradiction and tension: the clash, the sides in an evidence table, what differs between them (conditions, methods, designs, samples, definitions, independence), what the miners point at, the ways out, what works on it, what would settle it and the decisions so far.
- **Theory scorecard.** Each theory against each finding, tension and contradiction: explains, conflicts, not judged; what separates the theories, pairs nothing separates, findings no theory explains, and each theory's discriminating predictions. With no theory cards, the claims and models a theory pass would start from.
- **Causal map.** Every directed relation with its direction, basis, evidence and the designs behind it, and any contradiction or tension that holds both of its concepts (open the card: it may not be about this relation), drawn as a graph; relations that carry weight without a test; chains with an untested link; effects looked for and not found.
- **Robustness audit.** Each finding with its sources, independent groups, designs and weak points; replication priorities; claims the brain knows only second-hand, by how much rests on them; assumptions much rests on; and each source's unread parts and verification.
- **Methods and data landscape.** Study designs and samples; techniques and who uses them; quantities not defined or measured alike; what is established in one system and untried in another; data sets and code with their access; and, for each open question, first the data sets its own evidence uses (`uses_data::` on the cards it links), whatever their access, then the accessible data sets that share its concepts.
- **Novelty check.** The concepts in the idea; the cards that already hold them together; whether it has been asked; what it must respect; then the three rungs: passages in papers already held that no card covers, unread works cited on these concepts, and a starting query for the literature.
- **What-changed digest.** New cards, status changes with their reasons, decisions recorded, priority changes, what the discovery recheck now says of earlier ideas, the log, and what waits for the user.

## The rules

1. **A report is a snapshot, not a source.** Nothing is carded from a report, and a report is never cited as evidence. When the brain changes, run it again; do not edit the assembled part. Run again on the same day, a report keeps its Reading.
2. **The assembled part is the tooling's; the Reading is Claude's judgement,** kept under its own heading. It follows the rules of `brain-mesh-write`: said as strongly as the evidence and no more, causal wording only for tested relations, groups not papers, contradictions shown, "not in the brain" never "not in the literature".
3. **A report sees only what is coded.** A condition left in the prose, a source with no study profile, a section not read in full: say in the Reading what the report could not see.
4. **Build first.** `python3 tools/mesh.py build` with no errors. A brain with unlogged contradictions, decisions owed or proposals waiting gives a misleading report; clear what bears on the report, or say so in the Reading.
5. **What a report reveals goes into the brain by the usual route:** a contradiction to the register, an unknown to a gap card, an idea to the user as a proposal (`brain-mesh-discover`). Never straight from the report.

## Making one

1. `python3 tools/mesh.py sync`, then `build`.
2. Run the command from the table.
3. **Read the whole document.** Open the cards behind the items at the top, and the page wherever a number or a wording decides something.
4. **Write the Reading** in place of its placeholder: three to six sentences, each resting on lines of the report.

   | Report | What the Reading says |
   |---|---|
   | Frontier map | The two or three places most worth work and why; which need reading or a literature search before any experiment (the gap ladder); where the ranking is wrong and why |
   | Contradiction dossier | For each open one, the likeliest way out and the experiment or paper that would tell the ways out apart; which look like differences of definition or measure and which look real |
   | Theory scorecard | Where the theories truly differ; the most decisive test available; what none of them explains |
   | Causal map | What is tested; what the brain treats as causal on a correlational or proposed basis; the one link whose test would matter most |
   | Robustness audit | Which findings can be built on and which cannot yet; what to replicate first; which second-hand claims to read in the original |
   | Methods and data landscape | Where results cannot be compared; which existing data set could answer which open question (a data set its evidence uses comes first; read the data-set card before counting on one matched by concepts, since sharing concepts is not holding the needed measurements); which method is worth carrying across |
   | Novelty check | The verdict: already answered in the brain, partly answered, asked but not answered, new to the brain, or against the evidence. And the rung checked: read the rung 1 passages before saying it is new to the brain; only a logged search (`brain-mesh-gaps`) supports "new to the literature" |
   | What-changed digest | What changed that bears on the user's focus, and what waits for them |

5. **Deliver.** Tell the user in a few lines what the report shows and name the file. If they want it outside the vault, hand it over in the form they ask for. `python3 tools/mesh.py sync "report: <kind>"`.
6. **Act on it** with the skill that fits:

   | The report points at | Next |
   |---|---|
   | An open contradiction or tension | `brain-mesh-discover` (contradiction pass), then `brain-mesh-experiment` |
   | A gap not yet searched, or papers waiting | `brain-mesh-gaps`, then `brain-mesh-add-paper` |
   | A research gap, a hypothesis with no experiment, an untested link | `brain-mesh-experiment` |
   | Passages not carded (novelty rung 1), sources not read in full | a lens pass or `brain-mesh-concept-scan` |
   | A finding that needs regrading, a second-hand claim | `brain-mesh-housekeeping`; the reading queue |
   | A signal worth pursuing | `brain-mesh-discover` |

## When to run which

- **After each paper or batch:** the what-changed digest; the robustness audit when findings were regraded.
- **Before planning** (a project, a bid, the next few months): the frontier map, then the contradiction dossier and the causal map for the areas it puts first; the theory scorecard once theories exist.
- **Before proposing a study or promoting a seed:** the novelty check.
- **Before choosing methods:** the methods and data landscape.
- **On a schedule:** a scheduled run may build the digest in its own copy and report it. It commits nothing (`brain-mesh-housekeeping`, **Running it on a schedule**).

In Obsidian the reports link every card they mention, so they crowd the graph view; filter them out with `-path:reports`.
