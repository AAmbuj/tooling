---
name: scorekit-fta
description: "Fault Tree Analysis diagrams for score_tooling in a consumer repository. USE FOR: writing fta_<failure_mode>.puml files with !include fta_metamodel.puml, the $TopEvent/$IntermediateEvent/$BasicEvent/$AndGate/$OrGate/$TransferInGate procedures and their exact parameters, alias rules linking FTA to FailureMode and ControlMeasure records, OR vs AND gate choice, wiring FTA files via fmea(root_causes=...). DO NOT USE FOR: choosing failure modes or writing TRLC safety records (scorekit-fmea), architecture diagrams (scorekit-plantuml). INVOKES: templates/fta_template.puml."
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

# Fault Tree Analysis (FTA)

One file `fta_<snake_failure_mode>.puml` per `FailureMode`. The metamodel is shipped by
`score_tooling` and inlined at build time; just write `!include fta_metamodel.puml`.

Template: [templates/fta_template.puml](templates/fta_template.puml)

```plantuml
@startuml
!include fta_metamodel.puml

$TopEvent("DoWork returns no result", "MyModule.FM_DOWORK_LOSS")
$OrGate("OG1", "MyModule.FM_DOWORK_LOSS")
$BasicEvent("Worker thread hangs", "MyModule.CM_DOWORK_WATCHDOG", "OG1")
@enduml
```

## Procedures (exact signatures)

| Procedure | Parameters | Meaning |
|-----------|-----------|---------|
| `$TopEvent` | `(name, alias)` | Root = the failure mode. `alias` = `Package.FailureModeRecord`. |
| `$OrGate` | `(alias, connection)` | Any child causes the parent. Default choice. |
| `$AndGate` | `(alias, connection)` | All children must co-occur (fault **and** failed safety mechanism). |
| `$IntermediateEvent` | `(name, alias, connection)` | Non-leaf cause, decomposed further by a gate below it. |
| `$BasicEvent` | `(name, alias, connection)` | Leaf root cause. `alias` = `Package.ControlMeasureRecord` that closes it. |
| `$TransferInGate` | `(alias, connection)` | Continue in another FTA; `alias` = that FTA's top-event FQN. |

`connection` is always the alias of the **parent** node. Gate and intermediate aliases are local
(`OG1`, `AG1`, `IE1`); only the top event, basic events and transfer gates use TRLC FQNs.

## Rules

1. `$TopEvent` alias == an existing `ScoreReq.FailureMode` FQN (exact spelling).
2. Every `$BasicEvent` alias == an existing `ScoreReq.ControlMeasure` (or `AoU`) FQN.
3. The same measure may close causes in several FTAs (reuse the alias).
4. Decompose until each leaf is something a single measure can address.
5. Use `$AndGate` only when all causes are required; it justifies a lower residual risk and must
   be argued in the measure's description.
6. Write top-down in the file: `$TopEvent`, gates, intermediate events, basic events.

## Wiring

```starlark
filegroup(name = "fta_files", srcs = ["fta_fm_dowork_loss.puml"])   # keep sorted
fmea(name = "fmea", ..., root_causes = [":fta_files"])
```

Every new FTA file must be added to the filegroup.

## Validate

```bash
bazel build //safety_analysis:fmea
bazel test  //:dependability_analysis
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| FailureMode not covered by root causes | Top-event alias misspelled or file not in `fta_files`. |
| Basic event not resolved | Create the ControlMeasure with that exact FQN, or fix the alias. |
| Parse error around a procedure | Check parameter count (gates take 2, events take 3, top event takes 2) and quotes. |
| `!include` not found | Use exactly `!include fta_metamodel.puml`; do not vendor or path-qualify it. |

## Related skills

`scorekit-fmea`, `scorekit-clickable-plantuml` (transfer-in links), `scorekit-aou`.
