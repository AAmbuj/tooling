---
name: scorekit-clickable-plantuml
description: "Clickable PlantUML diagrams in score_tooling generated HTML docs (consumer side). USE FOR: understanding why an element in a rendered diagram links (or does not link) to another diagram, making an overview diagram drill down into a detail diagram, alias/define/reference rules, FTA $TransferInGate links, previewing with bazel run :<element>.serve. DO NOT USE FOR: writing diagram content or stereotypes (scorekit-plantuml), FTA semantics (scorekit-fta), Sphinx page placement (scorekit-docs)."
argument-hint: "diagram element that is not clickable"
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

# Clickable diagrams

Nothing to configure: every `.puml` passed to `architectural_design` (and FTA files passed to
`fmea`) gets an id-map at build time, and the Sphinx build of `dependable_element` /
`sphinx_module` turns references into links. You control links only through **how you write
the diagrams**.

## Rules

An element is a **define** (link target) in a diagram when any of:

- another element in that diagram is nested inside it (component/package with children),
- it has members or methods (class/interface diagrams),
- the diagram name in `@startuml <name>` equals its alias or display name,
- it is the `$TopEvent` of an FTA.

An element is a **reference** (becomes a link) when it is:

- a top-level leaf box or a relation endpoint (component diagrams),
- any participant (sequence diagrams),
- an FTA `$TransferInGate` whose alias is a `Package.Record` of another FTA's top event.

A reference links to the diagram that defines the same **alias / fully-qualified id**.

## Recipes

**Overview → detail drill-down**

```text
' overview.puml : Proxy is a top-level leaf → reference
@startuml
[Gateway] --> [Proxy]
@enduml
```

```text
' proxy_detail.puml : Proxy has a child → define
@startuml
package Proxy { [RequestHandler] }
@enduml
```

`Proxy` in the overview now links to `proxy_detail`. `Gateway` has no definer → no link.

**FTA sub-tree**: in the parent FTA use
`$TransferInGate("MyModule.FM_SUB", "<parent gate alias>")`, and give the sub-tree FTA
`$TopEvent("...", "MyModule.FM_SUB")`.

## Resolution when several diagrams define the same element

1. The definer sharing the longest common directory prefix with the referencing diagram wins.
2. Still tied: the definer that elaborates more nested children wins.
3. Still tied: **no link** (safe over wrong).

## Preview

```bash
bazel run //:my_element.serve     # serves the HTML of the dependable_element locally
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Element not clickable | Make sure some diagram *defines* it (give it children/members or name the diagram after it) and that the alias is spelled identically. |
| Link points to the wrong diagram | Two diagrams define the same alias; move the intended one closer (same directory) or give the other a different alias. |
| Build error about duplicate sources/basenames | Two `.puml` files in one target share a file stem; rename one. |
| Diagram not rendered at all | The `.puml` is not listed in any `architectural_design`/`unit_design`/`fmea` attribute. |

## Related skills

`scorekit-plantuml`, `scorekit-fta`, `scorekit-docs`.
