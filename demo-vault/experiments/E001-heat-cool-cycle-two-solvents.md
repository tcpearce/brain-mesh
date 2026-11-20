---
type: experiment
status: done
updated: 2026-11-20
---
# Heat-then-cool cycle in water and acetonitrile with one assay

**Question.** Does [[binding-capacity|binding capacity]] recover on cooling in [[water]], and does the solvent difference survive when one method is used for both?

## Design
Films from one batch; [[batch-rebinding-assay|batch rebinding]] as in [[P001-002-batch-rebinding-uv-254|Smith & Jones 2021]]; [[solvent]] = water or [[acetonitrile]]; [[temperature]] 25, 45, then back to 25 °C; four films per condition.

## Registered predictions
- [[H001-loss-is-reversible-swelling|Reversible swelling]]: water 25 °C about 4, 45 °C about 1.3, after cooling at least 3.5. Acetonitrile unchanged.
- Permanent damage: after cooling stays below 2.
- Method artefact: acetonitrile by batch rebinding also falls at 45 °C.

## Decision rule
Recovery to within one standard deviation of the starting value supports H001; recovery below half refutes it; anything between is inconclusive.

## Risks and controls
Equilibrium assumed at 60 min ([[P001-009-equilibrium-assumed-within-60-min|untested assumption]]); read at 60 and 120 min.

## Amendments
None.

## Outcome and assessment
Run 2026-11-18 as registered, with no deviations ([[P003-own-2026-heat-cool-cycle-results|own result P003]]).

- Reversible swelling: **supported.** Water 4.0 → 1.4 → 3.8 on cooling ([[P003-003-capacity-recovers-on-cooling|recovery]]), within one standard deviation of the start.
- Permanent damage: **refuted.**
- Method artefact: **refuted.** Acetonitrile by batch rebinding is unchanged ([[P003-004-capacity-3-9-at-25c-acetonitrile|own result]]).

## Codes
- id:: E001
- tests:: [[H001-loss-is-reversible-swelling]]
- addresses:: [[G001-is-capacity-loss-reversible-on-cooling]], [[X001-does-heat-or-solvent-uptake-lower-capacity]]
- uses:: [[P001-002-batch-rebinding-uv-254]]
- registered:: 2026-11-20
- results:: [[P003-own-2026-heat-cool-cycle-results]]
- concepts:: [[binding-capacity]], [[temperature]], [[solvent]], [[water]], [[acetonitrile]], [[batch-rebinding-assay]]
