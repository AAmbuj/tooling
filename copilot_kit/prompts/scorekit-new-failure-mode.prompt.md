---
description: "Analyse a public API method with HAZOP guidewords and add FailureMode records, each with its FTA and control measures."
agent: "scorekit-safety-analyst"
argument-hint: "interface.method to analyse"
---
Analyse `${input:method:<namespace>.<Interface>.<Method> from public_api.puml}` following skills
`scorekit-fmea` and `scorekit-fta`.

1. List every guideword with keep/dismiss and a one-line reason; propose failure effect and ASIL
   for the kept ones. Wait for my confirmation.
2. Add the `FailureMode` records (`guidewords` list, `failureeffect`, `interface`).
3. Create one `fta_<fm>.puml` per failure mode and the `ControlMeasure`/`AoU` records for every
   basic event.
4. Update `fta_files`, run `bazel test` on the dependability analysis and the element.
