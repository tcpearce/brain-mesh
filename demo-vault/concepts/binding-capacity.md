---
type: concept
aliases: ["Binding capacity", "rebinding capacity"]
updated: 2026-11-20
---
# Binding capacity

**Definition.** The amount of analyte an imprinted film takes up at equilibrium, relative to its mass or area. In this brain it is reported as a dimensionless ratio.

**How it is measured.** By a [[batch-rebinding-assay|batch rebinding assay]] with UV detection ([[P001-002-batch-rebinding-uv-254|Smith & Jones 2021]]) or with a [[quartz-crystal-microbalance|quartz crystal microbalance]] ([[P002-001-capacity-measured-by-qcm|Garcia & Chen 2023]]). No source has compared the two methods on the same film.

## What is known
- In [[water]] it falls from 4.2 to 1.3 between 25 and 45 °C ([[K001-capacity-falls-on-heating-in-water|finding K001]]).
- In [[acetonitrile]] it stays near 3.8 over the same range ([[P002-004-no-change-on-heating-in-acetonitrile|Garcia & Chen 2023]]).

## Relationships
- **[[temperature]]** lowers it in water but not in acetonitrile; the disagreement is tracked in [[X001-does-heat-or-solvent-uptake-lower-capacity|tension X001]].
- **[[swelling]]** is the proposed cause of the loss in water ([[P001-007-swelling-distorts-cavities|claim, Smith & Jones 2021]]).
- **[[solvent]]** seems to decide whether temperature matters at all.

## Open questions
- Is the loss on heating reversible on cooling? ([[G001-is-capacity-loss-reversible-on-cooling|gap G001]])

## Where it appears
<!--AUTO:START-->
**Findings, tensions, gaps, hypotheses and experiments (5)**
- [[E001-heat-cool-cycle-two-solvents|E001 Heat-then-cool cycle in water and acetonitrile with one assay]] · done
- [[G001-is-capacity-loss-reversible-on-cooling|G001 Is the loss of binding capacity on heating in water reversible on cooling?]] · closed
- [[H001-loss-is-reversible-swelling|H001 The loss of binding capacity on heating in water is reversible swelling, not damage]] · supported
- [[K001-capacity-falls-on-heating-in-water|K001 In water, binding capacity of the imprinted film for analyte X falls about threefold between 25 and 45 °C]] · probable
- [[X001-does-heat-or-solvent-uptake-lower-capacity|X001 Does heating itself lower binding capacity, or only heating in water?]] · explained

**Evidence: 17 cards from 3 sources** (observation 9, claim 3, method 2, assumption 1, oddity 1, question 1)
- [[P001-003-capacity-4-2-at-25c-water|Binding capacity for analyte X is 4.2 at 25 °C in water]] · observation
- [[P001-004-capacity-1-3-at-45c-water|Binding capacity for analyte X falls to 1.3 at 45 °C in water]] · observation
- [[P002-002-capacity-3-9-at-25c-acetonitrile|Binding capacity for analyte X is 3.9 at 25 °C in acetonitrile]] · observation
- [[P002-003-capacity-3-7-at-45c-acetonitrile|Binding capacity for analyte X is 3.7 at 45 °C in acetonitrile]] · observation
- [[P002-004-no-change-on-heating-in-acetonitrile|Heating from 25 to 45 °C does not change binding capacity in acetonitrile]] · observation
- [[P003-001-capacity-4-0-at-25c-water|Own films: binding capacity is 4.0 at 25 °C in water]] · observation
- [[P003-002-capacity-1-4-at-45c-water|Own films: binding capacity falls to 1.4 at 45 °C in water]] · observation
- [[P003-003-capacity-recovers-on-cooling|Own films: binding capacity recovers to 3.8 after cooling back to 25 °C in water]] · observation
- [[P003-004-capacity-3-9-at-25c-acetonitrile|Own films: binding capacity is 3.9 at 25 °C in acetonitrile by batch rebinding]] · observation
- [[P001-007-swelling-distorts-cavities|Swelling of the polymer network distorts the cavities and lowers binding capacity]] · claim
- [[P002-005-heat-alone-does-not-degrade-cavities|Temperature alone does not degrade the imprinted cavities]] · claim
- [[P002-006-water-uptake-causes-loss-in-water|The loss reported in water is suggested to come from water uptake, not heating]] · claim
- [[P001-002-batch-rebinding-uv-254|Binding capacity was measured by batch rebinding with UV detection at 254 nm]] · method
- [[P002-001-capacity-measured-by-qcm|Binding capacity was measured with a quartz crystal microbalance]] · method
- [[P001-009-equilibrium-assumed-within-60-min|The assay assumes binding reaches equilibrium within 60 minutes]] · assumption
- [[P001-011-reversibility-on-cooling-unknown|Whether the capacity loss reverses on cooling is unknown]] · question
- [[P001-006-transient-capacity-rise-at-35c|One film at 35 °C showed an unexplained transient rise in capacity]] · oddity

**Linked from other concepts**
- affected_by:: [[swelling|Swelling]] — proposed, not tested, [[P001-007-swelling-distorts-cavities]]
- affected_by:: [[temperature|Temperature]] — in water only, [[K001-capacity-falls-on-heating-in-water]], [[X001-does-heat-or-solvent-uptake-lower-capacity]]

**Appears alongside:** [[temperature]] (19) · [[imprinted-polymer-film]] (15) · [[solvent]] (12) · [[water]] (12) · [[analyte-x]] (10) · [[acetonitrile]] (7) · [[batch-rebinding-assay]] (6) · [[swelling]] (6) · [[equilibration-time]] (1) · [[film-thickness]] (1) · [[quartz-crystal-microbalance]] (1)

<!--AUTO:END-->

## Codes
- id:: binding-capacity
- kind:: variable
- unit:: 1
- measured_by:: [[batch-rebinding-assay]], [[quartz-crystal-microbalance]]
