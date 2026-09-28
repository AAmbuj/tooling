---
name: score-safety-analysis-review
description: "Review an existing FMEA safety analysis for completeness, traceability and quality. Checks every public API operation for failure-mode coverage, validates the FailureMode -> FTA -> ControlMeasure alias chain, flags guide words that were dismissed without rationale, and reports findings by severity. Does not edit files unless asked."
argument-hint: "the component or dependability/ directory to review"
agent: score-tooling
tools: [read, search, execute]
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

Review the safety analysis for the component I named. Load the **score-safety-analysis** skill
for the FMEA method; load **score-plantuml** only if an FTA file fails to parse.

This is a **review, not a rewrite**. Report findings; change files only if I ask.

## Check any links I give first

If I supply a Codebeamer requirement link or a Jira ticket link, resolve and read its content
before reviewing — use the Codebeamer tools for a requirement and the Jira tools for a ticket.
Summarize what you found and use it as the reference for the review. If a link cannot be
reached or read, stop and tell me rather than assuming its contents.

## Gather first

Locate and read, without guessing at contents:

- `safety_analysis/failure_modes.trlc` — the `FailureMode` records
- `safety_analysis/control_measures.trlc` and `assumed_system/aous.trlc` — the measures
- `safety_analysis/fta_*.puml` — one fault tree per failure mode
- `safety_analysis/BUILD` — the `fta_files` filegroup and the `fmea` target
- the `public_api` diagram from the enclosing `architectural_design`

Then run the validating targets and use the **actual output**, not an assumption of it:

```bash
bazel test //<pkg>/dependability/...
```

## Check, in this order

**1. Coverage — is anything unanalysed?**

Walk the `public_api` operation by operation. For each, state whether a `FailureMode` exists and
which guide words were considered. Apply the three fault-model categories: message
(not sent/received, corrupted, lost, unintended), timing (too early, too late, boundary
violated), execution (wrong result, loss, arbitrary or incomplete). A guide word that was
considered and dismissed needs a recorded rationale — an unmentioned guide word is a gap, not a
dismissal.

**2. Traceability — does the chain close?**

Verify each link mechanically and report the exact mismatched strings when one breaks:

| Link | Must match |
|------|-----------|
| `FailureMode.interface` | a real operation in the `public_api` diagram, fully qualified |
| `$TopEvent` alias | `<Package>.<FailureModeRecordName>` |
| `$BasicEvent` alias | `<Package>.<MeasureRecordName>` of an existing record |
| every `fta_*.puml` | listed in the `fta_files` filegroup |

**3. Reasoning quality — would this survive a safety review?**

- `failureeffect` written from the **caller/system perspective** and in worst-case terms relative
  to the safety goal, not as an implementation note.
- FTA decomposed to **actionable** root causes — a `$BasicEvent` you cannot place a measure on
  is not yet a root cause.
- `$AndGate` used only where all causes must genuinely co-occur. An AND gate is a claim of lower
  residual risk; if the rationale is absent, treat it as a finding.
- Measure type matches *when* it acts: `PreventiveMeasure` before, `ControlMeasure` during,
  `Mitigation` after, `AoU` at integration. An `AoU` must be an obligation the SEooC genuinely
  cannot discharge itself.
- Each `FailureMode` carries the ASIL of the safety goal it can violate.
- Shared root causes reuse one measure record rather than duplicating it.

## Report

A findings table, ordered by severity, then a short verdict.

| # | Severity | Location | Finding | Suggested fix |
|---|----------|----------|---------|---------------|

- **Blocker** — traceability broken or a build/test failure; the analysis does not hold together.
- **Major** — a public operation with no failure mode, a root cause with no measure, an AND gate
  with no justification.
- **Minor** — wording, a missing rationale, an inconsistency that does not change the conclusion.

State explicitly what you could **not** assess and why — an unreadable file or an unavailable
`public_api` is itself worth reporting. Do not pad the table to look thorough, and do not report
a finding you have not confirmed against the actual file contents.
