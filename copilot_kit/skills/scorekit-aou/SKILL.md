---
name: scorekit-aou
description: "Assumptions of Use (AoU) with score_tooling in a consumer repository. USE FOR: writing ScoreReq.AoU records (integrator obligations), closing generated FTA RootCause records, the assumptions_of_use rule, attaching AoUs to dependable_element, and handling or forwarding received AoUs. DO NOT USE FOR: FailureMode and FTA authoring (scorekit-fmea, scorekit-fta), requirement levels (scorekit-requirements), TRLC syntax errors (scorekit-trlc). INVOKES: templates/aous.trlc, templates/aou_forwarding.yaml, templates/aou.BUILD.tpl."
argument-hint: "obligation for the integrator, or received AoU ID"
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

# Assumptions of Use

An `AoU` is a safety-relevant condition the **integrator/caller** must fulfil because the SEooC
cannot guarantee it itself. An AoU may close an FTA root cause through its optional
`root_causes` field, which references generated RootCause records.

## Writing an AoU

Template: [templates/aous.trlc](templates/aous.trlc)

```trlc
package MyModule
import ScoreReq
import my_safety_analysis_fta

ScoreReq.AoU AOU_CALL_CYCLE {
    description = "The caller shall invoke DoWork at most once every 10 ms."
    safety      = ScoreReq.Asil.B
    root_causes = [my_safety_analysis_fta.CALLER_MISSES_DEADLINE]
    version     = 1
}
```

Rules:

- Phrase it as an obligation on the integrator ("The caller/integrator shall ...").
- Must be verifiable by the integrator; state bounds and units.
- `safety` = ASIL of the safety goal it protects.
- Keep AoUs in their own file (`aous.trlc`).
- Import the generated `<safety_analysis_name>_fta` package to reference an FTA RootCause.

## BUILD

Template: [templates/aou.BUILD.tpl](templates/aou.BUILD.tpl)

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "assumptions_of_use")

assumptions_of_use(
    name = "assumptions_of_use",
    srcs = ["aous.trlc"],            # .trlc or .rst with aou_req directives
    visibility = ["//visibility:public"],
)
```

Attach it: `dependable_element(assumptions_of_use = ["//docs:assumptions_of_use"], ...)`.
A `<name>_test` target runs `trlc --verify`.

When an AoU closes a root cause, also include its file in `safety_analysis.safetymeasures` and
add the safety-analysis target to `assumptions_of_use.deps`. Keep AoUs without `root_causes` out
of the `safetymeasures` input.

## AoUs received from dependencies

When `dependable_element(deps = ["@other//:other_seooc"])` is set, all AoUs of `other_seooc`
are forwarded to your element. For **each** received AoU choose exactly one:

| Option | How |
|--------|-----|
| **Handle it** | Write a `CompReq` with `derived_from = [..., OtherPkg.AOU_ID@1]` and add `@other//:other_aous` to the `component_requirements` `deps`. |
| **Forward it** | List it in `aou_forwarding.yaml` with a justification and set `dependable_element(aou_forwarding = "aou_forwarding.yaml")`. |

Your own AoUs are forwarded to your dependees automatically.

Template: [templates/aou_forwarding.yaml](templates/aou_forwarding.yaml)

```yaml
forwarded_aous:
  - aou_id: "OtherLibrary.TimingConstraint"
    justification: "This SEooC is a library and does not control the call cycle; the integrator must."
```

## Validate

```bash
bazel test //docs:assumptions_of_use_test
bazel build //:my_element          # AoU handling/forwarding is checked here
```

With `maturity = "release"` an AoU that is neither handled nor forwarded fails the build;
with `"development"` it is a warning.

## Error lookup

| Symptom | Fix |
|---------|-----|
| Received AoU reported as unhandled | Derive a CompReq from it or add it to `aou_forwarding.yaml`. |
| `aou_id` in YAML not found | Use the fully-qualified `Package.Record` of a received AoU. |
| AoU reference in CompReq not resolved | Add the AoU target to `component_requirements.deps`. |

## Related skills

`scorekit-fmea` (root-cause closure), `scorekit-requirements`, `scorekit-seooc`.
