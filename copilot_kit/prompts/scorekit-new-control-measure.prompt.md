---
description: "Add a ControlMeasure for an FTA root cause and, if it is implemented in code, the CompReq and test that realise it."
agent: "scorekit-safety-analyst"
argument-hint: "root cause and FTA file"
---
Follow skills `scorekit-fmea` and `scorekit-fta`.

- Root cause: ${input:cause:Root cause / $BasicEvent label}
- FTA file: ${input:fta:safety_analysis/fta_<fm>.puml}

1. Propose the measure (detect/handle at runtime, or integrator obligation → AoU) and why it is
   sufficient; wait for confirmation.
2. Write the record; use its FQN as the `$BasicEvent` alias.
3. If the measure is code: add a CompReq, implementation and traced test (ask first).
4. Run `bazel test` for the dependability analysis and the element.
