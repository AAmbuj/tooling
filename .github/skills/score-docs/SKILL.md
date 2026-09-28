---
name: score-docs
description: "Sphinx/reStructuredText authoring for rules_score docs. USE FOR: .rst/.md pages inside a dependable_element, embedding .puml diagrams and images, page placement (standalone/override/compose) next to diagrams, glossary terms (.. glossary::/:term:), wiring sphinx_module and glossary targets, building the HTML. DO NOT USE FOR: PlantUML syntax (score-plantuml); requirement text (score-requirements); Sphinx toolchain setup (score-onboarding). INVOKES: reference/page-placement.md, templates/index.rst."
argument-hint: "the documentation page or doc build issue"
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

# Documentation with rules_score

Most of the documentation is **generated**. `dependable_element` builds an index, the
architecture views, per-unit and per-component pages, the traceability report, the checklists
and the glossary section for you. Your job is the prose in between — and knowing where to put a
file so the generator picks it up instead of ignoring it.

## Build and read the output

```bash
bazel build //path/to:my_seooc          # HTML under bazel-bin/.../my_seooc_doc/html/
bazel run   //path/to:my_seooc.serve    # local HTTP server
```

Always look at the rendered page before declaring a docs change done.

## Where a page goes

Prose belongs **in the same view attribute as the diagrams it describes** — pass the `.rst`
alongside the `.puml` in `architectural_design(static = [...])`, `unit_design(static = [...])`
and so on. What happens then depends purely on the file stem:

| You add | Effect |
|---------|--------|
| `<stem>.rst` with **no** `<stem>.puml` in that directory | **Standalone page** — an extra entry in the directory toctree |
| `<stem>.rst` next to `<stem>.puml` | **Override** — replaces that diagram's generated wrapper page; the `.puml` is still staged as a sibling so you embed it yourself |
| `index.rst` | **Compose** — your content renders *above* the generated toctree, which stays intact; your title becomes the page title |

Two hard errors: a `.puml` whose stem is literally `index` is rejected, and two sources staging
to the same relative path (e.g. both `foo.rst` and `foo.md`) fail the build.

Details and worked examples: [reference/page-placement.md](reference/page-placement.md).

## Embedding

```rst
.. uml:: public_api.puml
   :align: center
   :alt: SEooC example public API
   :width: 100%

.. image:: diagram.png
   :align: center
   :alt: Image description
```

`.. uml::` paths are resolved against the staged sibling, so use the bare filename — not a
workspace path. Diagrams embedded this way are still clickable; see the `score-plantuml` skill.

## Available markup

Enabled extensions (from the generated `conf.py`): `sphinx_module_ext`, `sphinx_needs`,
`sphinx_design`, `myst_parser`, `sphinxcontrib.plantuml`, `trlc`, `clickable_plantuml`,
`sphinx.ext.graphviz`. Theme is `sphinx_rtd_theme`; PlantUML renders to `svg_obj`.

That means you may use, beyond core RST:

| Markup | Use |
|--------|-----|
| `` :term:`component` `` | link to a glossary entry — also works inside TRLC `description` fields |
| `` :need:`FEAT_001` `` | cross-reference a requirement / failure mode item |
| `.. uml::` | embed a PlantUML file |
| `.. grid::`, `.. card::` (sphinx-design) | layout components |
| MyST `.md` with `colon_fence` | Markdown pages are accepted wherever `.rst` is |

## Glossary

Terms are defined in one or more `.rst` files passed to the `glossary` rule:

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "glossary")

glossary(
    name = "glossary",
    srcs = ["glossary.rst"],
)
```

```rst
Glossary
========

.. glossary::

   integrity level
      ASIL rating indicating the level of safety rigor and confidence required.

   component
      A software unit with defined responsibilities and interfaces, allocated
      requirements, and associated implementation and verification evidence.
```

`:term:` resolution is case-insensitive and Sphinx builds the index automatically. Attach the
target through the `dependable_element`'s `glossary` attribute; the generated docs get a
glossary section.

## Standalone Sphinx modules

Use `sphinx_module` only for documentation that is *not* part of a `dependable_element`
(handbooks, process docs). `index` is mandatory:

```starlark
sphinx_module(
    name = "docs",
    srcs = glob(["**/*.rst"], exclude = ["index.rst"]),
    index = "index.rst",
    deps = ["//other/pkg:docs"],   # intersphinx across modules
)
```

Generated targets: `docs` (merged HTML), `docs.serve`, `docs_needs` (needs.json).
Start from [templates/index.rst](templates/index.rst).

## Fixing a doc build

1. Build with the real target and read the *first* Sphinx warning; later ones cascade.
2. "document isn't included in any toctree" → the file landed as a standalone page in a
   directory with no generated index, or the stem collided. Re-check the placement table.
3. A diagram renders bare with no prose → you meant to write an override page; the stem does
   not match the `.puml`.
4. `:term:` renders as plain text → the term is not in a file passed to `glossary`, or the
   `glossary` target is not attached to the `dependable_element`.
