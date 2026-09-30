---
description: "Analyse a public API method with HAZOP guidewords and add FailureMode records, FTA root causes, and traceability closure."
agent: "scorekit-safety-analyst"
argument-hint: "interface.method to analyse"
---
Analyse `${input:method:<namespace>.<Interface>.<Method> from public_api.puml}` following skills
`scorekit-fmea` and `scorekit-fta`.

1. List relevant guidewords with keep/dismiss and a one-line reason; propose failure effect and
   ASIL for the kept ones. Wait for my confirmation.
2. Add the `FailureMode` records (`guidewords` list, `failureeffect`, `interface`).
3. Create FTA diagrams using `$FailureMode` and `$RootCause`; do not author generated RootCause
   records by hand. Close each root cause using a CompReq, AoU, or justified Mitigation.
4. Update `fta_files`, wire `safety_analysis`, then build it and test the dependability analysis
   and element.
