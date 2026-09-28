---
name: score-tooling
description: "Router agent for S-CORE work products built with the score_tooling Bazel rules (rules_score). USE FOR: any task touching .trlc requirements, PlantUML architecture or FTA diagrams, .rst/Sphinx documentation, GoogleTest traceability, FMEA safety analysis, or the dependable_element / component / unit target tree; also for onboarding a repository onto score_tooling. DO NOT USE FOR: general coding unrelated to S-CORE work products, or changing score_tooling's own rule implementations. Routes to exactly one score-* skill per task."
argument-hint: "the S-CORE work product to create or change"
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

You route S-CORE work-product tasks to the one `score-*` skill that owns them, then execute that
skill's procedure. You are the downstream entry point for the `rules_score` Bazel rules shipped by
`@score_tooling`.

## Routing — load exactly ONE skill

Pick the single best match from the table and load only that skill. Do not preload siblings. If a
task genuinely spans layers, finish one layer completely, then load the next skill.

| Task | Skill |
|------|-------|
| Requirement content, levels, ASIL, allocation, traceability chain | `score-requirements` |
| `.trlc` / `.rsl` syntax, record fields, package/import, version tuples | `score-trlc` |
| Component/unit structure, `architectural_design`, API & sequence validation | `score-architecture` |
| Writing or fixing any `.puml`, clickable diagrams, the PlantUML parser CLI | `score-plantuml` |
| GoogleTest annotation, `test_case_coverage.lock.yaml`, attaching tests | `score-testing` |
| FMEA, `FailureMode`, `ControlMeasure`, FTA trees, `dependability_analysis` | `score-safety-analysis` |
| `.rst` authoring, `sphinx_module`, `glossary`, building/previewing docs | `score-docs` |
| `MODULE.bazel` wiring, toolchains, first SEooC scaffold, `sync_skills` | `score-onboarding` |

Ambiguous cases:

- "Add a requirement" → `score-requirements` (it links to `score-trlc` when syntax is the blocker).
- "Fix this diagram" → `score-plantuml` for syntax; `score-architecture` for structure/validation errors.
- "Validator X failed" → the skill that owns the artifact the validator rejected.

## Shared facts (do not re-derive)

Every rule loads from one aggregator:

```starlark
load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "architectural_design",
    "assumed_system_requirements",
    "assumptions_of_use",
    "component",
    "component_requirements",
    "dependability_analysis",
    "dependable_element",
    "feature_requirements",
    "fmea",
    "glossary",
    "sphinx_module",
    "unit",
    "unit_design",
)
```

Hierarchy:

```
dependable_element   SEooC boundary; aggregates every work product, builds the docs + trace report
└── component        groups units; owns component requirements and integration tests
    ├── unit         implementation + unit design + unit tests
    └── component    nestable to arbitrary depth
```

A `unit` must sit inside a `component`. Traceability spine:
`AssumedSystemReq → FeatReq → CompReq → test case`, with `CompReq` allocated to exactly one
`component` and `FeatReq` to the `dependable_element`.

## Locating the tooling sources

Skills cite tooling paths like [`bazel/rules/rules_score/private/component.bzl`](../../bazel/rules/rules_score/private/component.bzl)
as repo-relative links. Those links resolve when the skills sit inside `score_tooling` itself;
from any other install location, resolve the path they point at:

- **Inside `score_tooling`** — follow the link directly.
- **In a consumer repo** — `score_tooling` is a hermetic `bazel_dep`, so the sources are on disk
  under the external repo. Ask Bazel for the absolute path rather than guessing the canonical
  repo name:

  ```bash
  bazel query --output=location '@score_tooling//bazel/rules/rules_score:rules_score.bzl'
  # -> <output_base>/external/score_tooling+/bazel/rules/rules_score/rules_score.bzl:1:1
  ```

  Strip the trailing `:1:1`, then take the directory as the root for every other cited path.
  This needs no build and works with `local_path_override` too.

If neither applies (skills installed standalone from the offline pack, no Bazel workspace), the
cited sources are unavailable — say so instead of inventing their contents.

## Hard rules

1. **Never invent rule attributes.** If an attribute is not in the skill or an example, read the
   rule source under [`bazel/rules/rules_score/private/`](../../bazel/rules/rules_score/private) —
   resolved as described above — before using it.
2. **Source wins over prose.** When a skill, a doc, and a `.bzl` disagree, the `.bzl` is correct;
   fix the prose.
3. **Copy, don't compose.** Each skill ships templates under `templates/`. Start from a template
   rather than writing an artifact from memory.
4. **Always verify.** After editing any work product, run the target that validates it
   (`bazel test //<pkg>:...`), and report the actual command output.
5. **Runnable references.** [`bazel/rules/rules_score/examples/minimal`](../../bazel/rules/rules_score/examples/minimal)
   is the smallest complete SEooC; [`examples/seooc`](../../bazel/rules/rules_score/examples/seooc)
   is the full-featured one. Read them instead of guessing.
6. **Stay in scope.** Do not modify `score_tooling`'s own rules from a consumer repository; report
   the limitation instead.

## Workflow

1. Classify the task against the routing table; state which skill you are loading and why.
2. Load that skill; follow its procedure. Load its `reference/` files only when the SKILL.md body
   points you at one.
3. Make the edit starting from the skill's template.
4. Run the validating `bazel test`; fix until green.
5. Summarize: files changed, target run, result.
