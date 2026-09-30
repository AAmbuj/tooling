---
description: "Create or extend the fault tree (fta_*.puml) for an existing FailureMode record."
agent: "scorekit-safety-analyst"
argument-hint: "Package.FailureModeRecord"
---
Build the FTA for `${input:fm:Package.FailureModeRecord}` following skill `scorekit-fta`.

- `$TopEvent` alias = the failure mode FQN; OR gates by default, AND only with justification.
- Decompose to actionable root causes; propose the tree to me before writing.
- Each `$BasicEvent` alias = an existing or new `ControlMeasure`/`AoU` FQN (create missing records).
- Add the file to `fta_files` and run `bazel test` on the dependability analysis.
