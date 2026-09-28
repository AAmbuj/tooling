---
name: score-safety-analysis-rollout
description: "Create or extend an FMEA safety analysis for a component: walk the public API with HAZOP guide words, agree the failure modes and root causes, then write the FailureMode records, one FTA per failure mode, the matching ControlMeasure / AoU records, and the BUILD wiring. Confirms safety judgements before writing files."
argument-hint: "the component to roll the safety analysis out for"
agent: score-tooling
tools: [read, search, edit, execute, todo]
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

Roll out the safety analysis for the component I named. Load the **score-safety-analysis** skill
and follow its two-phase workflow. Load **score-plantuml** for FTA syntax and **score-trlc** for
record syntax only when you reach the writing phase.

## Check any links I give first

If I supply a Codebeamer requirement link or a Jira ticket link, resolve and read its content
before analysing — use the Codebeamer tools for a requirement and the Jira tools for a ticket.
Summarize what you found and use it as an input to the analysis. If a link cannot be reached or
read, stop and tell me rather than assuming its contents.

## Phase A — analyse, and get my agreement

**Do not create or edit any file in this phase.** The `.trlc` and `.puml` files are the *output*
of the analysis, not the analysis itself.

1. Read the `public_api` diagram and the component requirements. Tell me the operations you
   found. If the public API is missing or unclear, stop and say so — there is nothing to analyse
   against.

2. Walk each operation against the fault models — message, timing, execution — and produce a
   table:

   | Operation | Guide word | Plausible? | Effect on the caller |
   |-----------|-----------|------------|----------------------|

   Include the guide words you are **dismissing**, each with a one-line rationale. Silent
   omission is what review will catch.

3. Cluster into failure modes: one record per *(interface, guide word)* effect. Group operations
   sharing a root cause in the `interface` field. One root cause under two guide words means two
   records.

4. For each failure mode, propose the fault tree down to **actionable** root causes — leaves you
   can actually place a measure on. Use `$OrGate` unless all causes must genuinely co-occur;
   justify every `$AndGate`, because it claims lower residual risk.

5. For each root cause, propose a measure and say why that type: `PreventiveMeasure` (acts
   before), `ControlMeasure` (detects or handles at runtime), `Mitigation` (reduces severity
   after), `AoU` (only the integrator can guarantee it).

6. Propose the ASIL for each failure mode, derived from the safety goal it can violate.

**Then stop and ask me to confirm.** Severity, plausibility and measure sufficiency are safety
judgements — present them for sign-off rather than deciding them silently. Where you are
genuinely unsure, say so and offer the alternatives instead of picking one quietly.

## Phase B — write the artifacts

Only after I confirm. This part is mechanical transcription of what we agreed — no new analysis.
Start from the skill's templates rather than writing from memory.

1. `safety_analysis/failure_modes.trlc` — one `FailureMode` per agreed effect, with
   `guidewords`, `failureeffect`, `interface` (fully qualified, matching the `public_api`), ASIL
   and `version`.

2. `safety_analysis/fta_<snake_name>.puml` — one per failure mode, `!include fta_metamodel.puml`
   with no directory prefix. The `$TopEvent` alias **is** the traceability link and must be
   exactly `<Package>.<FailureModeRecordName>`.

3. `safety_analysis/control_measures.trlc` (and `assumed_system/aous.trlc` for AoUs) — one record
   per `$BasicEvent`. The `$BasicEvent` alias must equal `<Package>.<MeasureRecordName>`
   verbatim. Reuse one record where a root cause is shared; do not duplicate it.

4. `safety_analysis/BUILD` — every new `.puml` added to the `fta_files` filegroup, kept
   alphabetically sorted, and the `fmea` / `dependability_analysis` targets wired.

## Finish

```bash
bazel test //<pkg>/dependability/...
```

Iterate until green, and show the real command output. Then summarize: files created or changed,
failure modes added, root causes and measures per failure mode, any AoU the integrator now has
to discharge, and anything we consciously left out of scope.
