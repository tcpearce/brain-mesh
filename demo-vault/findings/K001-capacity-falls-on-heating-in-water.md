---
type: finding
status: probable
updated: 2026-11-20
---
# In water, binding capacity of the imprinted film for analyte X falls about threefold between 25 and 45 °C

**In brief.** Heating an [[imprinted-polymer-film|imprinted polymer film]] from 25 to 45 °C in [[water]] cuts its [[binding-capacity|binding capacity]] for [[analyte-x|analyte X]] from 4.2 to 1.3. Two independent sets of films agree.

## Evidence
- For: [[P001-003-capacity-4-2-at-25c-water|4.2 ± 0.3 at 25 °C]] and [[P001-004-capacity-1-3-at-45c-water|1.3 ± 0.2 at 45 °C]] (Smith & Jones 2021, batch rebinding).
- Replicated in our own films: [[P003-001-capacity-4-0-at-25c-water|4.0]] and [[P003-002-capacity-1-4-at-45c-water|1.4]] (own result 2026).
- Against: nothing in water.

## Where it holds and where it breaks
Water only. In acetonitrile the capacity does not fall ([[P002-004-no-change-on-heating-in-acetonitrile|Garcia & Chen 2023]]), though that study used a different method.

## What would change this
A replication in water with a second method, or kinetics showing the 45 °C films had not reached equilibrium ([[P001-009-equilibrium-assumed-within-60-min|assumed, not shown]]).

## Codes
- graded:: 2026-11-20 probable — status when the grading history began
- id:: K001
- support:: [[P003-001-capacity-4-0-at-25c-water]], [[P003-002-capacity-1-4-at-45c-water]], [[P001-003-capacity-4-2-at-25c-water]], [[P001-004-capacity-1-3-at-45c-water]]
- against::
- when:: [[solvent]] = [[water]]
- when:: [[temperature]] = 25 to 45 degC
- concepts:: [[binding-capacity]], [[temperature]], [[water]], [[imprinted-polymer-film]], [[analyte-x]]

## Linked from
- explained_by:: [[H001-loss-is-reversible-swelling|The loss of binding capacity on heating in water is reversible swelling, not damage]]
- raises:: [[G001-is-capacity-loss-reversible-on-cooling|Is the loss of binding capacity on heating in water reversible on cooling?]]
