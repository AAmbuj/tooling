<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# copilot_kit

GitHub Copilot skills, agents, prompts and instructions that teach Copilot how to use
score_tooling **from a consumer repository**: TRLC requirements, Assumptions of Use, PlantUML
architecture, clickable diagrams, FMEA, FTA, LOBSTER tracing, full SEooC implementation and
review. Everything is written against the public API (`@score_tooling//...`), never against
score_tooling internals.

## Install

```bash
# from a score_tooling checkout
./copilot_kit/install.sh --repo /path/to/consumer          # into <repo>/.github
./copilot_kit/install.sh --user                             # ~/.copilot/skills + VS Code user prompts folder

# from a repo that already depends on score_tooling
bazel run @score_tooling//copilot_kit:install -- --repo "$PWD"
```

| Option | Purpose |
|--------|---------|
| `--profile core\|full` | `core`: requirements, AoU, PlantUML, clickable diagrams, FMEA, FTA, tracing, SEooC (+ implement/review). `full` (default): adds onboarding, docs, coverage, manual analysis, AI checks, CI. |
| `--overlay alm` | Adds Codebeamer/Jira/GitHub-MCP intake and an MCP-enabled `scorekit-seooc-engineer` agent. Server names: auto-detected from `mcp.json`, or `--mcp-codebeamer/--mcp-jira/--mcp-github`. |
| `--check` | Exit 1 if installed files are missing, outdated or stale (use in CI). |
| `--uninstall` | Remove everything recorded in the manifest. |
| `--symlink`, `--only <category>`, `--force`, `--dry-run`, `--list` | See `--help`. |

Only `scorekit-*` files and a `<!-- BEGIN/END scorekit -->` block in
`.github/copilot-instructions.md` are touched. Locally modified files are never overwritten
without `--force`. The manifest (`.github/.scorekit-manifest`) stores paths relative to the
repository and can be committed.

## Contents

| Kind | Items |
|------|-------|
| Skills | `scorekit-trlc`, `-requirements`, `-aou`, `-plantuml`, `-clickable-plantuml`, `-fmea`, `-fta`, `-lobster-tracing`, `-seooc`, `-seooc-implement`, `-seooc-review`; full: `-onboarding`, `-docs`, `-coverage`, `-manual-analysis`, `-ai-checks`, `-ci` |
| Agents | `scorekit-router`, `scorekit-safety-analyst`, `scorekit-trace-auditor`, `scorekit-seooc-engineer` (implement / review) |
| Prompts | `/scorekit-new-feature-req`, `-new-component-req`, `-new-aou`, `-new-failure-mode`, `-new-fta`, `-close-root-cause`, `-full-safety-rollout`, `-review-implementation`, `-clickable-diagram`, `-trace-tests`, `-audit-traceability`, `-new-seooc`, `-onboard-repo`, `-implement-seooc`, `-review-seooc`; overlay alm: `-implement-from-codebeamer`, `-review-pr` |

## Maintaining

- `bazel test //copilot_kit:install_test` — installer behaviour and frontmatter lint.
- `./copilot_kit/consumer_sim.sh [dir]` — assembles all templates into a throw-away consumer
  module (local_path_override to this checkout) and runs `bazel test //...`.
- Bump `VERSION` when the payload changes so consumers see `--check` drift.
