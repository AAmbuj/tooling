---
name: scorekit-manual-analysis
description: "Manual verification evidence (reviews, inspections, manual safety arguments) with score_tooling in a consumer repository. USE FOR: the manual_analysis rule, context providers (manual_analysis_context_from_cc_library / _from_filegroup / custom ManualAnalysisContextInfo), the analysis YAML step types (action, automated_action, decision, assertion, repeat), running the interactive .update runner, lock/results files and the drift test, lobster output for requirements. DO NOT USE FOR: automated test traceability (scorekit-lobster-tracing), FMEA (scorekit-fmea). INVOKES: templates/analysis.yaml, templates/manual_analysis.BUILD.tpl."
argument-hint: "code or requirement that needs a manual analysis"
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

# Manual analysis

Use when a requirement cannot be verified by an automated test. The result is recorded,
locked against its context (sources + build attributes) and re-requested when the context changes.

| Target | Kind | Purpose |
|--------|------|---------|
| `<name>` | test | Fails if the lock is stale; emits `.lobster` for the listed requirements |
| `<name>.update` | run | Interactive runner; records answers in `results_file`, refreshes `lock_file` |

## BUILD

Template: [templates/manual_analysis.BUILD.tpl](templates/manual_analysis.BUILD.tpl)

```starlark
load("@score_tooling//manual_analysis:manual_analysis.bzl", "manual_analysis")
load("@score_tooling//manual_analysis:context_from_cc_library.bzl", "manual_analysis_context_from_cc_library")
# or: load("@score_tooling//manual_analysis:context_from_filegroup.bzl", "manual_analysis_context_from_filegroup")

manual_analysis(
    name = "my_unit_review",
    contexts = [":my_unit_context"],        # targets providing ManualAnalysisContextInfo
    analysis = "analysis.yaml",
    lock_file = "my_unit_review.lock",      # committed
    results_file = "results.json",          # committed
)
```

## Analysis YAML

Template: [templates/analysis.yaml](templates/analysis.yaml). Top-level `requirements` lists the
`Package.Record` IDs this analysis verifies; `steps` uses:

| Step | Key fields |
|------|-----------|
| `action` | `description` |
| `automated_action` | `description`, `command` (with `{arg}` placeholders), `args` (`name`, optional `default`), `expected_return_code` |
| `decision` | `description`, `branches` (`answer`, nested `steps`) |
| `assertion` | `description`, `positive`, `negative` |
| `repeat` | `until`, `steps` |

## Workflow

1. Write BUILD + YAML (create empty lock/results files if needed).
2. `bazel run //pkg:my_unit_review.update` – terminal UI: `Tab` switch pane, `Ctrl-S`/`F2`
   submit, `F4` opens `$EDITOR`, `Ctrl-C` abort.
3. Review and commit `results.json` and the lock file.
4. `bazel test //pkg:my_unit_review` in CI; any context change makes it fail until re-run.

The `.update` runner is interactive; an agent must not run it on behalf of the user.

## Related skills

`scorekit-lobster-tracing`, `scorekit-requirements`, `scorekit-seooc-review`.
