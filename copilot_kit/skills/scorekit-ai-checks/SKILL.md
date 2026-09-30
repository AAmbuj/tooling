---
name: scorekit-ai-checks
description: "AI-based quality review of TRLC requirements and architecture designs with score_tooling in a consumer repository. USE FOR: trlc_requirements_ai_test and architecture_ai_test targets (reqs/designs, model, score_threshold, batch_size, context, guidelines), running them locally with Copilot credentials, tagging them manual, reading their findings. DO NOT USE FOR: deterministic trlc/architecture validation (scorekit-requirements, scorekit-plantuml), full SEooC review (scorekit-seooc-review)."
argument-hint: "requirement or design target to review"
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

# AI quality checks

Non-deterministic, network- and credential-dependent: tag them `manual` and keep them out of the
blocking CI gate.

```starlark
load("@score_tooling//:defs.bzl", "architecture_ai_test", "trlc_requirements_ai_test")

trlc_requirements_ai_test(
    name = "feature_requirements_ai_check",
    reqs = ["//requirements:feature_requirements"],   # targets with TrlcProviderInfo
    score_threshold = "6.0",                          # average score 0-10 to pass
    tags = ["manual"],
)

filegroup(name = "design_context", srcs = ["design_context.md"])   # optional background

architecture_ai_test(
    name = "my_arch_ai_check",
    designs = [":my_arch"],                           # architectural_design targets
    context = ":design_context",                      # .md / .puml, read-only reference
    tags = ["manual"],
)
```

| Attribute | Default | Notes |
|-----------|---------|-------|
| `model` | `claude-sonnet-4.6` | Model name passed to the AI backend |
| `score_threshold` | `"0.0"` | String, 0–10 |
| `batch_size` | `0` | Artefacts per request, 0 = all |
| `context` | – | Filegroup of `.md`/`.puml` background files |
| `guidelines` | score_tooling defaults | Filegroup of guideline markdown files |

## Run

```bash
bazel test //requirements:feature_requirements_ai_check --test_output=all
```

Credentials: the test inherits `HOME` (Copilot CLI config) and proxy/token variables from the
environment; no extra flags. Tests run un-sandboxed with network access. Findings (JSON, HTML,
RST) are written to the test's undeclared outputs (`bazel-testlogs/.../test.outputs/`).

## Related skills

`scorekit-requirements`, `scorekit-plantuml`, `scorekit-seooc-review`.
