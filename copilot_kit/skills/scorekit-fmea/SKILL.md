---
name: scorekit-fmea
description: "FMEA with score_tooling in a consumer repository. USE FOR: identifying failure modes per public API method with HAZOP guidewords, writing ScoreReq.FailureMode and ScoreReq.ControlMeasure records, choosing ControlMeasure vs AoU vs PreventiveMeasure vs Mitigation, the fmea and dependability_analysis rules, attaching the analysis to dependable_element, closing traceability gaps (FailureMode ↔ public API ↔ FTA ↔ measures). DO NOT USE FOR: drawing fault trees (scorekit-fta), AoU forwarding across modules (scorekit-aou), TRLC syntax errors (scorekit-trlc). INVOKES: templates/failure_modes.trlc, templates/control_measures.trlc, templates/safety_analysis.BUILD.tpl, templates/dependability_analysis.BUILD.tpl."
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

# FMEA (FailureMode → FTA → ControlMeasure)

Traceability chain enforced by `dependability_analysis` / `dependable_element`:

```
public_api method  ◄── FailureMode.interface
FailureMode FQN    ◄── $TopEvent alias of fta_<fm>.puml
$BasicEvent alias  ──► ControlMeasure / AoU FQN
```

In `maturity = "release"` every public API method must be covered by a failure mode, and every
failure mode and control measure must appear in an FTA. Missing links fail `bazel test`.

## Step A — analyse (safety reasoning, collaborate)

1. Walk the `public_api` **method by method**. For each, apply the guidewords and ask: *can this
   occur, and would it violate a safety goal?* Dismiss irrelevant ones with a short reason.

   | Category | Guidewords |
   |----------|-----------|
   | Message | `LossOfFunction`, `PartialFunction`, `Corrupted`, `UnintendedFunction`, `Wrong` |
   | Timing | `TooEarly`, `TooLate`, `DelayedFunction` |
   | Execution | `Wrong`, `LossOfFunction`, `ExceedingFunction`, `ArbitraryExecution` |

2. One `FailureMode` per *(interface, effect)*. Methods sharing a root cause may share one
   record; one cause under two unrelated effects → two records.
3. `failureeffect` from the caller/system view, worst case relative to the safety goal.
   `safety` = ASIL of the violated safety goal.
4. Build the FTA (`scorekit-fta`) down to actionable root causes.
5. One measure per root cause:

   | Type | Acts | Use when |
   |------|------|----------|
   | `ControlMeasure` | during | runtime detection/handling (monitor, plausibility check); **default** |
   | `AoU` | integration | only the integrator can guarantee it (`scorekit-aou`); extends `ControlMeasure` |
   | `PreventiveMeasure` | before | design removes the cause (record has no fields) |
   | `Mitigation` | after | reduces severity/probability (extends AssumedSystemReq: needs `rationale`) |

   The default traceability config only collects `ControlMeasure` records as FTA leaves, so use
   `ControlMeasure` (or `AoU`) for every `$BasicEvent`; describe preventive/mitigating intent in
   its `description`. Confirm with `bazel test` when using an `AoU` leaf.

Propose failure modes, causes and measures to the user and confirm severity/sufficiency; do not
invent safety judgements.

## Step B — write the records

Templates: [failure_modes.trlc](templates/failure_modes.trlc),
[control_measures.trlc](templates/control_measures.trlc).

```trlc
ScoreReq.FailureMode FM_DOWORK_LOSS {
    guidewords    = [ScoreReq.Guideword.LossOfFunction]     // list, ≥1
    description   = "DoWork does not return a result when invoked."
    failureeffect = "The caller receives no result and cannot reach its safe state in time."
    interface     = "my_element.MyApi.DoWork"                // <public_api namespace>.<Interface>.<Method>
    safety        = ScoreReq.Asil.B
    version       = 1
    // optional: rationale = "..."
}

ScoreReq.ControlMeasure CM_DOWORK_WATCHDOG {
    description = "A watchdog shall detect a missing DoWork result within 10 ms ..."
    safety      = ScoreReq.Asil.B
    mitigates   = "MyModule.FM_DOWORK_LOSS"                  // optional
    version     = 1
}
```

Field names are exact: `guidewords` (plural list), `failureeffect`. There is no `guideword` or
`potentialcause` field.

## Step C — wire Bazel

Templates: [safety_analysis.BUILD.tpl](templates/safety_analysis.BUILD.tpl) (→ `safety_analysis/BUILD`),
[dependability_analysis.BUILD.tpl](templates/dependability_analysis.BUILD.tpl) (→ root `BUILD`).

```starlark
fmea(
    name = "fmea",
    failuremodes = ["failure_modes.trlc"],
    controlmeasures = ["control_measures.trlc"],
    root_causes = [":fta_files"],          # filegroup of fta_*.puml
    arch_design = "//:my_arch",
)

dependability_analysis(
    name = "dependability_analysis",
    fmea = ["//safety_analysis:fmea"],
    arch_design = ":my_arch",
)

dependable_element(..., dependability_analysis = [":dependability_analysis"])
```

`fmea` is build-only; `dependability_analysis` is a test rule that checks FM + CM + FTA links.
AoUs used as `$BasicEvent` stay in the `assumptions_of_use` target attached to the
`dependable_element`.

## Validate

```bash
bazel test //:dependability_analysis   # FM + CM + FTA chain
bazel test //:my_element               # element-level traceability (incl. public API coverage)
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Public API method not covered | Add a FailureMode whose `interface` is `<ns>.<Interface>.<Method>` exactly as in `public_api.puml`. |
| FailureMode not covered by root causes | Create `fta_<fm>.puml` with `$TopEvent(..., "<Pkg>.<FM>")` and add it to `fta_files`. |
| ControlMeasure not covered | Use its FQN as a `$BasicEvent` alias in some FTA, or delete it. |
| `$BasicEvent` alias unresolved | Create the ControlMeasure/AoU record with exactly that `Package.Record`. |
| Unknown field `guideword` / `potentialcause` | Use `guidewords = [...]`; put causes into the FTA. |

## Related skills

`scorekit-fta`, `scorekit-aou`, `scorekit-plantuml` (public API), `scorekit-seooc-review`.
