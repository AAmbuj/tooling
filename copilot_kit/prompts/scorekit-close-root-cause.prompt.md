---
description: "Close a generated safety-analysis RootCause with a CompReq, AoU, or justified Mitigation."
agent: "scorekit-safety-analyst"
argument-hint: "generated RootCause FQN and the owning FTA"
---
Follow skills `scorekit-fmea`, `scorekit-fta`, and `scorekit-aou` when relevant.

- RootCause: ${input:root_cause:<safety_analysis_name>_fta.<RootCauseAlias>}
- FTA: ${input:fta:safety_analysis/fta_<name>.puml}

1. Propose a closure and rationale, then wait for confirmation:
   - `CompReq.derived_from` when the component implements and tests a requirement that addresses
     the cause.
   - `AoU.root_causes` when only the integrator can prevent the cause.
   - `Mitigation.root_causes` only when the cause is inapplicable; include its mandatory
     `justification`.
2. Reference the generated RootCause package from the TRLC record; never author a RootCause by
   hand. Do not use an own AoU as a `CompReq.derived_from` source.
3. If a CompReq represents a software control, ask before adding implementation and traced tests.
   If an AoU closes the cause, wire its file to `safety_analysis.safetymeasures` and make the
   assumptions_of_use target depend on that safety-analysis target.
4. Run `bazel test` for the safety analysis, dependability analysis, and enclosing element.