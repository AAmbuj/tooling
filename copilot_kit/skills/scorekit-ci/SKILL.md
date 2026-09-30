---
name: scorekit-ci
description: "Continuous integration for repositories using score_tooling. USE FOR: which bazel commands to gate on (bazel test //... covers trlc verification, architecture consistency, traceability, lock drift), exporting dependable_element HTML/reports with the dependable_element_export aspect, maturity switch before release, keeping the installed Copilot kit in sync (install.sh --check), coverage gates in CI. DO NOT USE FOR: coverage setup details (scorekit-coverage), fixing individual findings (the matching scorekit-* skill). INVOKES: templates/score.workflow.yml."
argument-hint: "CI system or pipeline step"
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

# CI for score_tooling consumers

## Gate

```bash
bazel test //...
```

This single command runs: `trlc --verify` per requirement target, architecture parsing and
declared-vs-implemented checks, unit class-vs-code checks, `dependability_analysis`
(FM/CM/FTA), `dependable_element` traceability (lobster), test-case lock drift, manual-analysis
lock drift, and your tests. With `maturity = "development"` most of these only warn — switch
every `dependable_element`, `architectural_design` and `dependability_analysis` to `release`
before a release/certification build.

Keep AI checks (`tags = ["manual"]`) out of the blocking gate.

## Export docs and reports

```bash
bazel build //... \
  --aspects=@score_tooling//bazel/aspects/rules_score:dependable_element_export.bzl%dependable_element_export_aspect \
  --output_groups=+dependable_element_export
find -L bazel-bin -type d -name _dependable_element_export
```

With remote execution also add `--remote_download_regex=".*/_dependable_element_export/.*"`.

GitHub Actions example: [templates/score.workflow.yml](templates/score.workflow.yml).

## Copilot kit drift

If the kit is committed into `.github/`, fail CI when it is outdated:

```bash
/path/to/score_tooling/copilot_kit/install.sh --repo . --check
```

## Coverage gate

See `scorekit-coverage` (`COVERAGE_THRESHOLD=<pct> bazel run @score_tooling//coverage:generate_coverage_html -- ...`).

## Related skills

`scorekit-coverage`, `scorekit-lobster-tracing`, `scorekit-seooc`.
