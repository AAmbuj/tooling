---
description: "Create or extend the fault tree (fta_*.puml) for an existing FailureMode record."
agent: "scorekit-safety-analyst"
argument-hint: "Package.FailureModeRecord"
---
Build the FTA for `${input:fm:Package.FailureModeRecord}` following skill `scorekit-fta`.

- `$FailureMode` references the FailureMode FQN(s); OR gates by default, AND only with
	justification.
- Decompose to actionable root causes; propose the tree to me before writing.
- `$RootCause` aliases are plain identifiers that generate TRLC records. Do not author those
	records by hand; close each cause with a CompReq, AoU, or justified Mitigation.
- Add the file to `fta_files`, build `safety_analysis`, then test `dependability_analysis` and
	the enclosing element.
