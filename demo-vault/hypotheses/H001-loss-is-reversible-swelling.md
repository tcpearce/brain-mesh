---
type: hypothesis
status: supported
updated: 2026-11-20
---
# The loss of binding capacity on heating in water is reversible swelling, not damage

**Hypothesis.** Heating in [[water]] lowers [[binding-capacity|binding capacity]] because the film swells; cooling lets it shrink and the capacity returns.

## Rationale
Capacity falls with an 18% thickening in water ([[K001-capacity-falls-on-heating-in-water|finding K001]]) but not in acetonitrile ([[X001-does-heat-or-solvent-uptake-lower-capacity|tension X001]]).

## Rival explanations
- Heat permanently damages the cavities: capacity would not recover on cooling.
- The assay under-reads at 45 °C because equilibrium is slower: capacity would recover with longer contact time.

## Predictions
- If true: capacity after a 25 → 45 → 25 °C cycle in water returns to within error of its starting value.
- If damage: it stays near the 45 °C value.

## Connections

What the brain holds that bears on this claim, swept from the whole ontology by `mesh.py hypothesis deepen`. Every
line ends `· bears: ?` until it is read and judged: replace the `?` with how the card bears — supports, contradicts,
the mechanism of one stage, an alternative route, a confound, a scope limit, or irrelevant and why. A line left with
`?` is a card nobody has weighed.

**How far the claim reaches.**

- named in the claim (5): [[acetonitrile]], [[binding-capacity]], [[equilibration-time]], [[swelling]], [[water]]
- on the cards it cites (5): [[analyte-x]], [[film-thickness]], [[imprinted-polymer-film]], [[solvent]], [[temperature]]
- one step in the concept graph (1): [[quartz-crystal-microbalance]]
- named by its head word (1): [[batch-rebinding-assay]]

### Evidence that bears on the claim directly

- [[P001-005-film-thickens-18-percent]] [observation] The film thickens by 18% between 25 and 45 °C in water · via film-thickness, swelling, water · bears: the swelling step measured: 18% thickening in water over the same range the capacity falls
- [[P003-004-capacity-3-9-at-25c-acetonitrile]] [observation] Own films: binding capacity is 3.9 at 25 °C in acetonitrile by batch rebinding · via acetonitrile, analyte-x, batch-rebinding-assay · bears: the acetonitrile control on our own films: capacity is as high as at 25 °C, so the solvent, not the heat, carries the effect
- [[P003-003-capacity-recovers-on-cooling]] [observation] Own films: binding capacity recovers to 3.8 after cooling back to 25 °C in water · via swelling, analyte-x, water · bears: **the reversibility test**: capacity recovers to 3.8 on cooling, which damage would not allow
- [[P002-002-capacity-3-9-at-25c-acetonitrile]] [observation] Binding capacity for analyte X is 3.9 at 25 °C in acetonitrile · via acetonitrile, analyte-x, solvent · bears: the independent acetonitrile baseline at 25 °C
- [[P002-003-capacity-3-7-at-45c-acetonitrile]] [observation] Binding capacity for analyte X is 3.7 at 45 °C in acetonitrile · via acetonitrile, analyte-x, solvent · bears: the independent acetonitrile value at 45 °C: unchanged, as this hypothesis needs
- [[P002-004-no-change-on-heating-in-acetonitrile]] [observation] Heating from 25 to 45 °C does not change binding capacity in acetonitrile · via acetonitrile, analyte-x, solvent · bears: the same comparison stated as a result: no loss in a solvent the film does not take up
- [[P003-001-capacity-4-0-at-25c-water]] [observation] Own films: binding capacity is 4.0 at 25 °C in water · via analyte-x, water, batch-rebinding-assay · bears: our own water baseline at 25 °C
- [[P003-002-capacity-1-4-at-45c-water]] [observation] Own films: binding capacity falls to 1.4 at 45 °C in water · via analyte-x, water, batch-rebinding-assay · bears: our own water value at 45 °C: the loss this hypothesis explains
- [[P001-003-capacity-4-2-at-25c-water]] [observation] Binding capacity for analyte X is 4.2 at 25 °C in water · via analyte-x, water, solvent · bears: the published water baseline, agreeing with ours
- [[P001-004-capacity-1-3-at-45c-water]] [observation] Binding capacity for analyte X falls to 1.3 at 45 °C in water · via analyte-x, water, solvent · bears: the published loss in water, agreeing with ours
- [[P002-006-water-uptake-causes-loss-in-water]] [claim] The loss reported in water is suggested to come from water uptake, not heating · via swelling, water, binding-capacity · bears: the rival authors' own reading: uptake rather than heating — the same mechanism, proposed without the thickness measurement
- [[P001-007-swelling-distorts-cavities]] [claim] Swelling of the polymer network distorts the cavities and lowers binding capacity · via swelling, imprinted-polymer-film, binding-capacity · bears: the mechanism: swelling distorts the cavities and lowers capacity
- [[P002-005-heat-alone-does-not-degrade-cavities]] [claim] Temperature alone does not degrade the imprinted cavities · via side of X001 · bears: the other side of X001: temperature alone leaves the cavities intact

### Mechanisms at each stage of the claim, and other routes to the same outcome

- nothing in the brain under this heading.

### Established findings and hub facts the claim must agree with

- [[K001-capacity-falls-on-heating-in-water]] [probable] In water, binding capacity of the imprinted film for analyte X falls about threefold between 25 and 45 °C · via analyte-x, water, solvent · bears: the finding this hypothesis explains, and the measurement any rival must also account for

### Limitations, assumptions and oddities that could produce or hide the effect

- [[P001-009-equilibrium-assumed-within-60-min]] [assumption] The assay assumes binding reaches equilibrium within 60 minutes · via equilibration-time, batch-rebinding-assay, binding-capacity · bears: a 60-minute equilibration is assumed; if swelling slows uptake, the 45 °C point may be unequilibrated rather than lower
- [[P001-006-transient-capacity-rise-at-35c]] [oddity] One film at 35 °C showed an unexplained transient rise in capacity · via water, solvent, imprinted-polymer-film · bears: a transient rise at 35 °C that nothing explains: it sits between the two temperatures the argument rests on
- [[P002-007-single-film-thickness-tested]] [limitation] Only one film thickness, 200 nm, was tested · via film-thickness, imprinted-polymer-film · bears: only one thickness was tested, so thickness-dependent swelling is untested
- [[P001-008-organic-solvents-not-tested]] [limitation] Organic solvents were not tested · via water, solvent · bears: organic solvents were not tested in the published work, which is why the acetonitrile arm had to be run here

### Open gaps, contradictions and tensions it touches

- [[X001-does-heat-or-solvent-uptake-lower-capacity]] [explained] Does heating itself lower binding capacity, or only heating in water? · via film-thickness, acetonitrile, swelling · bears: the tension this hypothesis resolves: heating itself, or heating in water
- [[G002-no-thickness-data-in-acetonitrile]] [confirmed] Film thickness has never been measured in acetonitrile, so swelling is not ruled in or out there · via film-thickness, acetonitrile, swelling · bears: thickness has never been measured in acetonitrile, so the control arm's swelling is assumed rather than shown

### Theories and analogies it bears on

- nothing in the brain under this heading.

### Data sets and code that could test it

- nothing in the brain under this heading.

### Hypotheses, experiments, seeds and own results already on this ground

- [[E001-heat-cool-cycle-two-solvents]] [done] Heat-then-cool cycle in water and acetonitrile with one assay · via acetonitrile, water, batch-rebinding-assay · bears: **the experiment that tested it**: the heat-then-cool cycle in both solvents, on one assay

## Codes
- deepened:: 2026-11-27 21 cards, 12 concepts
- graded:: 2026-11-20 supported — status when the grading history began
- id:: H001
- explains:: [[K001-capacity-falls-on-heating-in-water]], [[X001-does-heat-or-solvent-uptake-lower-capacity]]
- concepts:: [[binding-capacity]], [[swelling]], [[temperature]], [[water]]

## Linked from
- tested_by:: [[E001-heat-cool-cycle-two-solvents|Heat-then-cool cycle in water and acetonitrile with one assay]]
