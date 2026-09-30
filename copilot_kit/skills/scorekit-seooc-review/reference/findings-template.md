<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Findings report template

```markdown
## SEooC review: <element / PR>

**Scope:** <targets, folders or PR files reviewed>
**Maturity:** <development|release>   **Verdict:** <ready | not ready (N blockers)>

### Machine checks
| Command | Result |
|---------|--------|
| bazel test //... | <pass / N failures> |

### Findings
| # | Sev | Check | Location | Finding | Fix | Source |
|---|-----|-------|----------|---------|-----|--------|
| 1 | Blocker | S4 | safety_analysis/failure_modes.trlc:12 | FM_X has no FTA reference | add its FQN to an FTA `$FailureMode(...)` macro | tool |
| 2 | Major | R5 | requirements/feature_requirements.trlc:20 | "fast" is unverifiable | state bound, e.g. "within 10 ms" | review |

### Questions / missing context
- <question>

### Summary
Blockers: N · Major: N · Minor: N
```

`Source` = `tool` (reported by bazel) or `review` (reviewer judgement).
