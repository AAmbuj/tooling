---
name: scorekit-seooc
description: "Assembling a Safety Element out of Context (SEooC) with score_tooling rules in a consumer repository. USE FOR: the unit → component → dependable_element Bazel tree, mapping the static diagram 1:1 to targets, unit(implementation/scope/tests/unit_design), component(components/requirements/tests/test_case_coverage_lock), dependable_element attributes (integrity_level, maturity, deps, aou_forwarding, glossary, dependability_analysis), recommended repository layout, which work product lives where. DO NOT USE FOR: the end-to-end guided implementation of a whole SEooC (scorekit-seooc-implement), reviewing one (scorekit-seooc-review), diagram syntax (scorekit-plantuml). INVOKES: templates/root.BUILD.tpl, templates/docs.BUILD.tpl, templates/glossary.rst, templates/my_unit.h, templates/my_unit.cpp."
argument-hint: "element, component or unit to add or wire"
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

# SEooC assembly

```
dependable_element   (<<SEooC>>)        requirements = FeatReq, AoUs, arch, analysis, glossary
└── component        (<<component>>)    requirements = CompReq (+ FeatReq), integration tests, lock
    ├── unit         (<<unit>>)         implementation + unit_design + unit tests
    └── component    (nesting allowed)
```

- A `unit` must be inside a `component`, never directly in `dependable_element`.
- Target names and nesting == aliases and nesting of the `static` diagram.

## Recommended layout

```
MODULE.bazel  .bazelrc  BUILD                     # root: units, components, analysis, element
bazel/toolchains/BUILD                            # libclang toolchain (scorekit-onboarding)
design/*.puml                                     # static, public_api, class (no BUILD here)
requirements/{BUILD, asr.trlc, feature_requirements.trlc, component_requirements.trlc}
docs/{BUILD, aous.trlc, glossary.rst}
safety_analysis/{BUILD, failure_modes.trlc, control_measures.trlc, fta_*.puml}
src/*.h *.cpp *_test.cpp
test_case_coverage.lock.yaml  aou_forwarding.yaml
```

Templates: [root.BUILD.tpl](templates/root.BUILD.tpl), [docs.BUILD.tpl](templates/docs.BUILD.tpl),
[glossary.rst](templates/glossary.rst), [my_unit.h](templates/my_unit.h), [my_unit.cpp](templates/my_unit.cpp).
Other templates live in the matching skills (`scorekit-requirements`, `scorekit-plantuml`,
`scorekit-fmea`, `scorekit-fta`, `scorekit-aou`, `scorekit-lobster-tracing`, `scorekit-onboarding`).

## Rule reference

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl",
     "unit", "unit_design", "component", "dependable_element", "architectural_design",
     "dependability_analysis")
```

| Rule | Mandatory | Optional |
|------|-----------|----------|
| `unit` | `unit_design`, `implementation`, `tests` | `scope` (extra targets that belong to the unit; **absolute labels** `//pkg:target`, never `:target`) |
| `component` | – | `components`, `requirements`, `tests`, `test_case_coverage_lock` (creates `<name>.update`) |
| `dependable_element` | `assumptions_of_use`, `requirements`, `architectural_design`, `dependability_analysis`, `components`, `tests`, `integrity_level` | `glossary`, `checklists`, `deps`, `aou_forwarding`, `maturity`, `generate_html_report` |

`dependable_element` notes:

- `integrity_level`: `A`/`B`/`C`/`D`. An element must not depend on elements with a lower level.
  (Requirement records use `QM`/`B`/`D`.)
- `maturity`: `release` (default) fails on certified-scope, architecture-consistency and
  traceability violations; `development` makes them warnings.
- `deps`: other `dependable_element` targets (other modules); their AoUs are received.
- Generated targets: `<name>` (test: traceability + HTML docs), `<name>.serve` (local preview),
  `<name>_index`.
- `unit`, `component`, `dependable_element` are `testonly` by default.

## Adding a unit / component

1. Update `design/static_design.puml` first (new `<<unit>>` inside a `<<component>>`); agree it.
2. Add `cc_library`, `cc_test`, `unit_design` (+ class diagram), `unit`.
3. Add it to the parent `component(components=...)`.
4. New component: add its `component_requirements` file + target and a lock file.
5. `bazel test //...`.

## Validate

```bash
bazel build //:my_element          # architecture consistency + docs
bazel test  //...                  # everything incl. traceability
bazel run   //:my_element.serve    # preview HTML
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Declared vs implemented mismatch | Target names/nesting differ from static diagram aliases. |
| Certified scope violation (`Not in certified scope //pkg:lib`) | Every implementation dependency must be covered by some unit's `scope`; list it there as an absolute label (`"//pkg:lib"`). A relative `":lib"` is not resolved against your package. |
| Integrity level violation | A `deps` element has a lower `integrity_level`. |
| Unit directly under element | Wrap it in a `component`. |

## Related skills

`scorekit-seooc-implement`, `scorekit-seooc-review`, `scorekit-plantuml`,
`scorekit-requirements`, `scorekit-fmea`, `scorekit-lobster-tracing`, `scorekit-onboarding`.
