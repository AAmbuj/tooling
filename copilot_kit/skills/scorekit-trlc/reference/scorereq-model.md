<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# ScoreReq model reference

Package `ScoreReq`, shipped as `@score_tooling//bazel/rules/rules_score/trlc/config:score_requirements_model`.

## Enums

| Enum | Literals |
|------|----------|
| `Asil` | `QM`, `B`, `D` |
| `Status` | `valid`, `invalid` (field is frozen to `valid`) |
| `Guideword` | `LossOfFunction`, `PartialFunction`, `Corrupted`, `UnintendedFunction`, `TooEarly`, `TooLate`, `Wrong`, `DelayedFunction`, `ExceedingFunction`, `ArbitraryExecution` |

`Guideword` meaning:

| Literal | Meaning | Fault model |
|---------|---------|-------------|
| `LossOfFunction` | Function completely absent when it should be active | message not sent/received, loss of execution |
| `PartialFunction` | Function active but only partially fulfils its purpose | message not received by all, incomplete processing |
| `Corrupted` | Data corrupted during transmission/storage | message corrupted |
| `UnintendedFunction` | Function active when it should not be | message unintentionally sent |
| `TooEarly` | Occurs earlier than expected | min time constraint violated |
| `TooLate` | Occurs later than expected | max time constraint violated |
| `Wrong` | Incorrect value due to a logic error | wrong result |
| `DelayedFunction` | Active but with unacceptable delay | processing too slow |
| `ExceedingFunction` | Operates beyond specified bounds | processing too fast |
| `ArbitraryExecution` | Unpredictable / non-deterministic execution | arbitrary process |

## Types

```
Requirement (abstract)
  description   Markup_String          mandatory
  version       Integer                mandatory
  note          String                 optional
  status        Status                 frozen = valid
RequirementSafety (abstract) extends Requirement
  safety        Asil                   mandatory

AssumedSystemReq extends RequirementSafety
  rationale     String                 mandatory
FeatReq extends RequirementSafety
  derived_from  AssumedSystemReqId[1..*]        mandatory
CompReq extends RequirementSafety
  derived_from  CompReqSourceId[1..*]           optional
                (FeatReq | AssumedSystemReq | AoU) @ version
ControlMeasure extends RequirementSafety
  mitigates     String                 optional
AoU extends ControlMeasure             (no extra fields)
FailureMode extends RequirementSafety
  guidewords    Guideword[1..*]        mandatory
  failureeffect String                 mandatory
  rationale     String                 optional
  interface     String                 optional
PreventiveMeasure                      (no fields)
Mitigation extends AssumedSystemReq
  mitigates     String                 optional
```

## Tuples (versioned references)

| Tuple | Item types | Syntax |
|-------|-----------|--------|
| `AssumedSystemReqId` | `AssumedSystemReq` | `Pkg.ASR_001@1` |
| `FeatReqId` | `FeatReq` | `Pkg.FEAT_001@1` |
| `CompReqSourceId` | `FeatReq`, `AssumedSystemReq`, `AoU` | `Pkg.FEAT_001@1` |
| `CompReqId` | `CompReq` | `Pkg.COMP_001@1` |

An `AoU` referenced from `CompReq.derived_from` must come from a target listed directly in the
`component_requirements` rule's `deps` (your own `assumptions_of_use` target, or one received
from a dependency module).
