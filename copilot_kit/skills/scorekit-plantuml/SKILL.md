---
name: scorekit-plantuml
description: "PlantUML architecture diagrams for score_tooling in a consumer repository. USE FOR: static component diagrams (<<SEooC>>/<<component>>/<<unit>> stereotypes, aliases = Bazel target names), public_api and internal_api interface diagrams, dynamic sequence diagrams, unit class diagrams, the architectural_design and unit_design rules, element identifiers, fixing architecture validator or parser findings. DO NOT USE FOR: FTA diagrams (scorekit-fta), making links clickable in the HTML docs (scorekit-clickable-plantuml), component/unit Bazel tree wiring (scorekit-seooc). INVOKES: templates/static_design.puml, templates/public_api.puml, templates/internal_api.puml, templates/dynamic_design.puml, templates/class_design.puml, templates/design.BUILD.tpl."
argument-hint: "diagram kind (static/public_api/internal_api/dynamic/class) or validator finding"
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

# Architecture diagrams (PlantUML)

**The `static` diagram is the design; Bazel targets are a 1:1 transcription.** Design the
decomposition first, agree it with the user, then write targets (`scorekit-seooc`).

## Diagram kinds

| View | `architectural_design` attr | Checked against | Template |
|------|-----------------------------|-----------------|----------|
| Static | `static` | Bazel `dependable_element`/`component`/`unit` tree | [static_design.puml](templates/static_design.puml) |
| Public API | `public_api` | Interfaces bound from the `<<SEooC>>` in static; feeds `FailureMode.interface` | [public_api.puml](templates/public_api.puml) |
| Internal API | `internal_api` | Static diagram, sequences | [internal_api.puml](templates/internal_api.puml) |
| Dynamic | `dynamic` | Static units, internal API | [dynamic_design.puml](templates/dynamic_design.puml) |
| Unit class | `unit_design(static=...)` | C++ implementation of the unit | [class_design.puml](templates/class_design.puml) |

`static`/`dynamic` also accept `.md`/`.rst` pages and `.svg`/`.png` images.

## Static diagram rules

| Stereotype | Keywords allowed | Bazel rule | Alias must equal |
|------------|------------------|------------|------------------|
| `<<SEooC>>` | `package`, `component` | `dependable_element` | its `name` |
| `<<component>>` | `component`, `package` | `component` | its `name` |
| `<<unit>>` | `component`, `package` | `unit` | its `name` |

- Nesting in the diagram = nesting in Bazel. A `<<unit>>` must sit inside a `<<component>>`.
- Always give an explicit `as alias`; never rely on the display label.
- Several `static` files are merged by entity id; re-declaring an element is allowed if its
  stereotype matches everywhere.
- Interface bindings: `-(` required, `)-` provided. For named ports use `portin`/`portout`
  inside a `<<SEooC>>`/`<<component>>`.

## Names and references

- `.` and `::` are equivalent separators in class/component identifiers. A leading `.` or `::`
  roots a name instead of resolving it relative to the enclosing namespace.
- Qualified declarations inside a package/namespace are relative to that enclosing scope unless
  rooted. Relationships may be declared inside namespaces; their endpoints use the same lookup.
- A simple reference resolves to the direct scoped match first, otherwise to a unique matching
  leaf. A qualified reference must resolve either in the current scope or from the root. The
  parser reports ambiguous and unresolved references; it does not search arbitrary descendants.
- In class diagrams, references see prior declarations only, except that a direct scoped match
  may be declared later.
- Use `.` in component diagrams where PlantUML rendering matters; `::` parses equivalently but
  may not render in all component-diagram positions.

## Public vs internal API

- Public API interfaces are top-level in the static diagram and bound from the `<<SEooC>>`
  (`my_element )-d- MyApi`). In `public_api.puml` they live in `namespace <element_name>`.
- Internal interfaces are declared inside the owning element's namespace path
  (`namespace my_element { namespace my_component { ... } }`).
- Keep the public API minimal: every public method becomes a failure-mode entry point.

## Sequence diagrams

- Participant identity comes from the quoted label after `:` (`"a : Comp::Unit"`), else the alias.
- Use `ExternalEndpoint` for actors outside the architecture.

## Element identifiers

For class/component elements, identifiers use the declared scope and leaf alias (or name when no
alias). The current parser does **not** prepend the owning Bazel package. Mirror scopes and aliases
between static and class diagrams; do not encode Bazel package paths in aliases. FTA TRLC names are
not architecture identifiers.

## BUILD

Template: [design.BUILD.tpl](templates/design.BUILD.tpl)

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "architectural_design", "unit_design")

architectural_design(
    name = "my_arch",
    static = ["design/static_design.puml"],
    public_api = ["design/public_api.puml"],
    dynamic = [],
    internal_api = [],
    maturity = "release",          # "development" = findings are warnings
)

unit_design(name = "my_unit_design", static = ["design/class_design.puml"])
```

Unit design with prose: list the `.puml` and an `.rst` wrapper (`.. uml:: x.puml`) together;
headings inside that `.rst` must use `^` underline.

The C++ class check needs the libclang toolchain registered (`scorekit-onboarding`).

## Validate

```bash
bazel build //:my_arch            # parse + architecture validation
bazel build //:my_element         # declared (static) vs implemented (Bazel) check
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Component/unit in Bazel but not in diagram (or vice versa) | Make alias and nesting identical to the Bazel target names. |
| Public API interface treated as internal | Declare it top-level in static and bind it from the `<<SEooC>>`. |
| Sequence participant does not match static | Use a qualified label `"x : Component::Unit"`. |
| Class diagram vs implementation mismatch | Align member/method names and types with the header; check the unit's `implementation`. |
| Parse error | Check `@startuml`/`@enduml`, stereotypes spelled `<<unit>>`, braces balanced. |

## Related skills

`scorekit-seooc` (Bazel tree), `scorekit-fta`, `scorekit-clickable-plantuml`, `scorekit-fmea`.
