---
name: scorekit-fmea
description: "FMEA-based safety analysis with score_tooling in a consumer repository. USE FOR: identifying FailureModes per public API, writing ScoreReq.FailureMode records, selecting safety-relevant root causes and closing them with CompReq, AoU, or Mitigation, wiring safety_analysis and dependability_analysis, and checking FailureMode → FTA → RootCause traceability. DO NOT USE FOR: authoring fault-tree diagrams (scorekit-fta), AoU forwarding across modules (scorekit-aou), TRLC syntax errors (scorekit-trlc). INVOKES: templates/failure_modes.trlc, templates/safetymeasures.trlc, templates/safety_analysis.BUILD.tpl, templates/dependability_analysis.BUILD.tpl."
argument-hint: "public API interface or method to analyse"
---

<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Safety analysis (FailureMode → FTA → RootCause → closure)

```text
public_api method  ← FailureMode.interface
FailureMode FQN    ← $FailureMode references in an FTA
$RootCause alias   → generated RootCause record
RootCause          → CompReq.derived_from / AoU.root_causes / Mitigation.root_causes
```

The FTA parser generates a `RootCause` record for each `$RootCause` macro. Do not author these
records by hand. Every root cause must be addressed by at least one component requirement,
assumption of use, or justified mitigation. Release-level traceability is checked through the
enclosing `dependable_element`.

## Step A — Analyse

Walk the `public_api` method by method. Apply relevant guidewords and ask whether each failure can
occur and violate a safety goal. Dismiss irrelevant cases with a short reason.

| Category | Guidewords |
|----------|-----------|
| Message | `LossOfFunction`, `PartialFunction`, `Corrupted`, `UnintendedFunction`, `Wrong` |
| Timing | `TooEarly`, `TooLate`, `DelayedFunction` |
| Execution | `Wrong`, `LossOfFunction`, `ExceedingFunction`, `ArbitraryExecution` |

1. Define one `FailureMode` per distinct interface/effect. Methods sharing an effect may share a
   record; one cause with unrelated effects needs separate records.
2. State `failureeffect` from the caller/system perspective, worst case relative to the safety
   goal. Set `safety` to the ASIL of the violated safety goal.
3. Build the FTA (`scorekit-fta`) down to actionable root causes.
4. Select how each root cause is closed:

   | Type | Use when | Traceability |
   |------|----------|--------------|
   | `CompReq` | The component implements and tests a requirement that addresses the cause | `derived_from` references the generated `RootCause` |
   | `AoU` | Only the integrator/caller can prevent the cause (`scorekit-aou`) | `root_causes` references the generated `RootCause` |
   | `Mitigation` | The cause is inapplicable in this context | Mandatory `justification` and `root_causes` |

   A `Mitigation` argues that a root cause does not apply; it is not an implemented runtime
   control. Prefer a `CompReq` for software controls, and implement and test it. Propose safety
   judgements and closure choices to the user for confirmation.

## Step B — FailureMode records

Template: [failure_modes.trlc](templates/failure_modes.trlc).

```trlc
ScoreReq.FailureMode FM_DOWORK_LOSS {
    guidewords    = [ScoreReq.Guideword.LossOfFunction]
    description   = "DoWork does not return a result when invoked."
    failureeffect = "The caller receives no result and cannot reach its safe state in time."
    interface     = "my_element.MyApi.DoWork"
    safety        = ScoreReq.Asil.B
    version       = 1
}
```

`guidewords` is a list; `rationale` and `interface` are optional. Put causes in the FTA, not in a
`potentialcause` field.

## Step C — Safety-measure records

Template: [safetymeasures.trlc](templates/safetymeasures.trlc). Import the generated FTA package
(`<safety_analysis_name>_fta`) to reference its `RootCause` records. The template target name
`safety_analysis` therefore generates package `safety_analysis_fta`.

```trlc
ScoreReq.Mitigation MIT_WORKER_THREAD {
    description   = "The worker thread cannot hang in this configuration."
    safety        = ScoreReq.Asil.B
    justification = "The component uses a bounded, synchronous worker implementation."
    root_causes   = [safety_analysis_fta.WORKER_THREAD_HANGS]
    version       = 1
}
```

`Mitigation.root_causes` and `justification` are mandatory. `AoU.root_causes` is optional and
applies when an integrator obligation closes a cause. A `CompReq` closes a cause by listing the
unversioned generated `RootCause` in `derived_from`; it may also derive from normal requirements.
Add the safety-analysis target to the `component_requirements.deps` that resolves this FTA
package. An AoU in `CompReq.derived_from` is only for an AoU received from another dependable
element.

If an AoU closes a root cause, include its TRLC file in both `safety_analysis.safetymeasures` and
`assumptions_of_use.srcs`; add the safety-analysis target to `assumptions_of_use.deps`. Keep AoUs
without root-cause links out of `safetymeasures`.

## Step D — BUILD wiring

Templates: [safety_analysis.BUILD.tpl](templates/safety_analysis.BUILD.tpl) and
[dependability_analysis.BUILD.tpl](templates/dependability_analysis.BUILD.tpl).

```starlark
safety_analysis(
    name = "safety_analysis",
    arch_design = "//design:my_arch",
    failuremodes = ["failure_modes.trlc"],
    root_causes = [":fta_files"],
    safetymeasures = ["safetymeasures.trlc"],
)

dependability_analysis(
    name = "dependability_analysis",
    arch_design = "//design:my_arch",
    safety_analysis = [":safety_analysis"],
)
```

Attach `dependability_analysis` to the `dependable_element`.

## Validate

```bash
bazel build //safety_analysis:safety_analysis
bazel test //:dependability_analysis
bazel test //:my_element
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| FailureMode not covered by an FTA | Reference its FQN in `$FailureMode(...)` and include the diagram in `root_causes`. |
| RootCause not closed | Reference the generated FTA record from `CompReq.derived_from`, `AoU.root_causes`, or `Mitigation.root_causes`. |
| RootCause reference unresolved | Import the generated `<safety_analysis_name>_fta` package and use its record name. |
| Unknown `potentialcause` field | Put causes in the FTA; `FailureMode` has no `potentialcause` field. |

## Related skills

`scorekit-fta`, `scorekit-aou`, `scorekit-trlc`, `scorekit-plantuml`, `scorekit-seooc-review`.
