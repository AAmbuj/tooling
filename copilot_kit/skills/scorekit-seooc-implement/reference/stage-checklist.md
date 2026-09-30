<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Stage checklist

| Stage | Files | Done when |
|-------|-------|-----------|
| 0 Intake | – | Names, ASIL, integrity level, open questions confirmed by user |
| 1 Requirements | `requirements/asr.trlc`, `feature_requirements.trlc`, `BUILD` | `bazel test //requirements/...` green |
| 2 Architecture | `design/static_design.puml`, `public_api.puml`, root `architectural_design`, `component_requirements*.trlc` | Decomposition agreed; arch target builds |
| 3 Units | `src/*`, `design/class_design*.puml`, `unit_design`, `unit`, `component` | `bazel build //...` green |
| 4 Tests | `src/*_test.cpp`, `test_case_coverage.lock.yaml` | Every CompReq in lock with ≥1 test; `bazel test //...` green |
| 5 Safety | `safety_analysis/failure_modes.trlc`, `control_measures.trlc`, `fta_*.puml`, `BUILD`; `docs/aous.trlc`; `aou_forwarding.yaml` | Every public API method covered; every FM has an FTA; every leaf has a measure; `bazel test //:dependability_analysis` green |
| 6 Assembly | root `dependable_element`, `docs/BUILD`, `glossary.rst` | `bazel test //...` green; docs render |
| 7 Self-review | findings table | No blockers |
| 8 Release | `maturity = "release"` | `bazel test //...` green |

## Final report template

```markdown
## SEooC <name> — implementation report
- Source: <ticket/requirement IDs>
- Integrity level: <A-D>, safety goals ASIL: <QM/B/D>
- Created/changed files: <list>
- Validation: <command> → <result> (one line each)
- Decisions confirmed by user: <list>
- Open points / residual findings: <severity, item>
```
