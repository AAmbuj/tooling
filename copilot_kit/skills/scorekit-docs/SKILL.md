---
name: scorekit-docs
description: "Documentation pages for score_tooling generated HTML in a consumer repository. USE FOR: adding .rst/.md prose next to diagrams in architectural_design/unit_design views (index and <stem> pages that compose with or override the generated navigation), glossary targets and :term: references, standalone sphinx_module targets, previewing with bazel run :<name>.serve, embedding the element docs into another Sphinx build (docs_prefix). DO NOT USE FOR: diagram syntax (scorekit-plantuml), link behaviour in diagrams (scorekit-clickable-plantuml), requirement text (scorekit-requirements)."
argument-hint: "page or glossary term to add"
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

# Documentation

`dependable_element` generates the complete HTML documentation (requirements, architecture,
safety analysis, traceability report). You only add prose where the generated pages are not
enough.

## Prose next to diagrams

`architectural_design` and `unit_design` views accept `.rst`/`.md` files in the same list as
the diagrams. Each view gets a generated, directory-matching navigation tree:

| You add | Effect |
|---------|--------|
| `design/index.md` (or `.rst`) | Composes with the generated navigation of that directory |
| `design/<stem>.rst` next to `design/<stem>.puml` | Overrides the generated page for that diagram |
| Other `.rst`/`.md` | Standalone page in the view |

In `unit_design` RST fragments, use `^` for headings (the parent page already uses `=` and `-`),
and reference diagrams with `.. uml:: file.puml`.

## Glossary

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "glossary")
glossary(name = "glossary", srcs = ["glossary.rst"], visibility = ["//visibility:public"])
# dependable_element(..., glossary = ["//docs:glossary"])
```

```rst
Glossary
========

.. glossary::

   integrity level
      Level of safety rigor required for an element.
```

Reference terms from requirement descriptions or pages with ``:term:`integrity level```.

## Standalone Sphinx module

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "sphinx_module")

sphinx_module(
    name = "handbook",
    srcs = ["index.rst", "usage.rst"],   # index first
    index = "index.rst",
    deps = [],                           # other sphinx_module targets (cross-references)
)
```

Generated: `<name>` (merged HTML), `<name>.serve`, `<name>_needs`.

## Preview

```bash
bazel run //:my_element.serve
```

## Embedding into another Sphinx build

`dependable_element` exposes `<name>_rst` (a `sphinx_docs_library`) under `docs_prefix`
(default `docs/sphinx/`). Set `docs_prefix` relative to the consuming build's source root.

## Error lookup

| Symptom | Fix |
|---------|-----|
| Unknown term warning | Term missing in a glossary listed in `dependable_element(glossary=...)`. |
| Page not shown | File not listed in any view/`srcs`. |
| Heading level error in unit page | Use `^` headings in unit design RST fragments. |

## Related skills

`scorekit-plantuml`, `scorekit-clickable-plantuml`, `scorekit-seooc`.
