---
name: scorekit-requirements
description: "Requirements engineering with score_tooling in a consumer repository. USE FOR: deciding the requirement level (AssumedSystemReq vs FeatReq vs CompReq), writing atomic verifiable 'shall' requirements, derived_from traceability with version pinning, ASIL inheritance, wiring assumed_system_requirements / feature_requirements / component_requirements rules, allocating CompReq to component() and FeatReq to dependable_element(), images/diagrams in descriptions. DO NOT USE FOR: TRLC syntax errors (scorekit-trlc), Assumptions of Use (scorekit-aou), failure modes/control measures (scorekit-fmea). INVOKES: templates/asr.trlc, templates/feature_requirements.trlc, templates/component_requirements.trlc, templates/requirements.BUILD.tpl."
argument-hint: "requirement text, level, or target to change"
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

# Requirements (AssumedSystemReq → FeatReq → CompReq)

## Workflow

1. **Author the content first.** Decide level, wording and ASIL. When level, intent or ASIL is
   unclear, propose an option with rationale and ask. Never invent a requirement silently.
2. **Transcribe mechanically** into `.trlc` (see `scorekit-trlc`) and wire the Bazel rule.
3. **Validate** with `bazel test`.

## Choosing the level

| Level | Observer / scope | `derived_from` |
|-------|------------------|----------------|
| `AssumedSystemReq` | Need from outside the SEooC (black box), received from platform/system | none (root) |
| `FeatReq` | One feature, spans several components, solution-neutral | ≥1 `AssumedSystemReq@v` (mandatory) |
| `CompReq` | Fully implementable and testable inside one component | `FeatReq@v`, `AssumedSystemReq@v`, received `AoU@v`, or an unversioned generated `RootCause` |

## Writing good requirements

Template: *subject* **shall** *verb* [*object*] [*parameter*] [*condition*].

- **Atomic**: one `shall`; split "and"/"or" and open lists.
- **Verifiable**: a test or review can pass/fail it objectively; give bounds and units.
- **Unambiguous**: avoid *fast*, *appropriate*, *etc.*; use glossary terms (`:term:`name``).
- **Right level**: no implementation detail in ASR/FeatReq unless it is an intentional constraint.
- **Refinement**: children together satisfy the parent; inherit the parent ASIL or justify lower
  in `note`.
- Non-normative text goes to `note`, never into `description`.

## BUILD wiring

Templates: [asr.trlc](templates/asr.trlc), [feature_requirements.trlc](templates/feature_requirements.trlc),
[component_requirements.trlc](templates/component_requirements.trlc),
[requirements.BUILD.tpl](templates/requirements.BUILD.tpl) (copy to `requirements/BUILD`).

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl",
     "assumed_system_requirements", "feature_requirements", "component_requirements")
```

Every rule takes `name`, `srcs` (`.trlc`), `deps` (targets whose records are referenced) and
optional `spec`, `lobster_config`, `ref_package`, `image_srcs`. Each generates `<name>_test`.

### Allocation

| Record | Allocated via |
|--------|---------------|
| `CompReq` | `component(requirements = ["//requirements:component_requirements"])` — one file per component |
| `FeatReq` | `dependable_element(requirements = ["//requirements:feature_requirements"])` |

A `feature_requirements` target may also be listed in `component(requirements=...)` so
`derived_from` references resolve in the component traceability report.

### Cross-module references

Reference another module's records by adding its target to `deps` and importing its package. A
`CompReq` may also reference a generated FTA `RootCause` without a version pin; own AoUs are not
valid `derived_from` sources (only AoUs received from another dependable element are):

```starlark
component_requirements(
    name = "component_requirements",
    srcs = ["component_requirements.trlc"],
    deps = [
      ":feature_requirements",
      "//safety_analysis:safety_analysis",
      "@other_module//:other_aous",
    ],
)
```

Include `//safety_analysis:safety_analysis` in `deps` when a CompReq derives from an FTA-generated RootCause.

## Images and diagrams in descriptions

Use a raw directive inside a `'''` string and declare the file in `image_srcs`:

```trlc
description = '''The client shall maintain a connection state machine.

.. uml:: client_state.puml'''
```

## Changing a requirement

1. Edit text → bump `version`.
2. Find every `derived_from` pin to the old version (`grep -rn "RECORD@<old>"`) and review each
   child; re-pin to the new version.
3. Refresh the test lock (`scorekit-lobster-tracing`) because the lock stores the version.

## Validate

```bash
bazel test //requirements/...
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Record from another file/package not found | Add the defining target to `deps` and `import` its package. |
| FeatReq without `derived_from` | Mandatory — link at least one ASR. |
| Requirement missing from component report | Add its target to `component(requirements=...)`. |
| AoU in `derived_from` not resolved | It must be an AoU received from another dependable element and its target must be a direct `deps` entry of `component_requirements`. |

## Related skills

`scorekit-trlc` (syntax), `scorekit-aou`, `scorekit-seooc` (allocation targets),
`scorekit-lobster-tracing` (tests that cover requirements).
