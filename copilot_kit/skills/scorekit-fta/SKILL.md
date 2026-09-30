---
name: scorekit-fta
description: "Fault Tree Analysis diagrams for score_tooling in a consumer repository. USE FOR: writing FTA PlantUML with !include fta_metamodel.puml, the $FailureMode/$RootCause/$IntermediateEvent/$AndGate/$OrGate/$TransferInGate procedures and their parameters, linking generated RootCause records to safety measures, OR vs AND gate choice, and wiring files through safety_analysis(root_causes=...). DO NOT USE FOR: choosing failure modes or writing TRLC safety records (scorekit-fmea), architecture diagrams (scorekit-plantuml). INVOKES: templates/fta_template.puml."
argument-hint: "FailureMode record to decompose"
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

# Fault Tree Analysis

The FTA parser generates a TRLC `RootCause` record for each `$RootCause` macro. Never author
those generated records by hand. `$FailureMode` links the tree to one or more FailureMode records;
each generated RootCause inherits those FailureMode links.

Template: [templates/fta_template.puml](templates/fta_template.puml).

```plantuml
@startuml
!include fta_metamodel.puml

$FailureMode("DoWork returns no result", "MyModule.FM_DOWORK_LOSS")
$OrGate("OG1", "MyModule.FM_DOWORK_LOSS")
$RootCause("Worker thread hangs", "WORKER_THREAD_HANGS", "OG1")
@enduml
```

## Procedures

| Procedure | Parameters | Meaning |
|-----------|------------|---------|
| `$FailureMode` | `(name, fm1, fm2, ..., fm8)` | Root node; one to eight FailureMode FQNs. `fm1` is also the parent connection for child gates. |
| `$OrGate` | `(alias, connection)` | Any child causes its parent; default choice. |
| `$AndGate` | `(alias, connection)` | All children must co-occur. |
| `$IntermediateEvent` | `(name, alias, connection)` | Non-leaf cause decomposed by a gate below it. |
| `$RootCause` | `(name, alias, connection)` | Leaf cause; a plain identifier alias generates a RootCause record. |
| `$TransferInGate` | `(alias, connection)` | Link to a sub-tree. |

Gate/intermediate aliases are local (`OG1`, `AG1`, `IE1`). `$FailureMode` arguments are fully
qualified record names. `$RootCause` aliases are plain TRLC identifiers, not dotted FQNs.

## Rules

1. `$FailureMode` references existing `ScoreReq.FailureMode` FQNs exactly.
2. `$RootCause` aliases generate records in the safety analysis' FTA package. Use that generated
   package when referring to the root cause from another TRLC record.
3. Close every root cause with at least one `CompReq.derived_from`, `AoU.root_causes`, or
   `Mitigation.root_causes` reference.
4. Decompose until each leaf can be addressed by a component requirement, an integrator AoU, or a
   justified Mitigation.
5. `$OrGate` is the default for independent causes. Use `$AndGate` only when all causes must
   co-occur, and justify the residual-risk argument.
6. Write top-down: `$FailureMode`, gates, intermediate events, then root causes.

## Wiring

```starlark
filegroup(name = "fta_files", srcs = ["fta_fm_dowork_loss.puml"])

safety_analysis(
    name = "safety_analysis",
    failuremodes = ["failure_modes.trlc"],
    root_causes = [":fta_files"],
    safetymeasures = ["safetymeasures.trlc"],
    arch_design = "//design:my_arch",
)
```

Keep every FTA in `fta_files`. Attach the target through
`dependability_analysis(safety_analysis = [":safety_analysis"])`.

## Validate

```bash
bazel build //safety_analysis:safety_analysis
bazel test //:dependability_analysis
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| FailureMode not covered | Add its FQN to `$FailureMode(...)` and include the FTA in `root_causes`. |
| RootCause not closed | Reference its generated FTA-package record from a CompReq, AoU, or Mitigation. |
| Invalid RootCause alias | Use a plain TRLC identifier, not a dotted FQN. |
| Parse error around a procedure | Check the parameter count and quote strings; gates take two parameters, events three, and FailureMode takes one to eight FQNs after the name. |
| `!include` not found | Use exactly `!include fta_metamodel.puml`; do not vendor or path-qualify it. |

## Related skills

`scorekit-fmea`, `scorekit-aou`, `scorekit-clickable-plantuml` (transfer links).
