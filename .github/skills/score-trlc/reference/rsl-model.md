# ScoreReq model — full field reference

Transcribed from [`bazel/rules/rules_score/trlc/config/score_requirements_model.rsl`](../../../../bazel/rules/rules_score/trlc/config/score_requirements_model.rsl)
(package `ScoreReq`). The `.rsl` is the source of truth.

## Enums

```rsl
enum Asil { QM  B  D }

enum Status { valid  invalid }

enum Guideword {
    LossOfFunction      "The function is completely absent when it should be active."
    PartialFunction     "The function is active but only partially fulfils its purpose."
    Corrupted           "Data or message content is incorrect due to corruption during transmission or storage."
    UnintendedFunction  "The function is active when it should not be."
    TooEarly            "The function or signal occurs earlier than expected."
    TooLate             "The function or signal occurs later than expected."
    Wrong               "The function produces an incorrect value or signal due to a logic error."
    DelayedFunction     "The function is active but with an unacceptable delay."
    ExceedingFunction   "The function operates beyond its specified bounds."
    ArbitraryExecution  "Processing deviates from its specified behaviour and executes in an unpredictable manner."
}
```

`Asil` has no `A` and no `C` literal.

## Abstract bases

| Type | Field | Type | Required | Notes |
|------|-------|------|----------|-------|
| `Requirement` | `description` | `Markup_String` | yes | RST inline markup is rendered |
| | `version` | `Integer` | yes | manual, monotonically increasing |
| | `note` | `String` | optional | non-normative |
| | `status` | `Status` | frozen | `freeze status = Status.valid` — never write it |
| `RequirementSafety` extends `Requirement` | `safety` | `Asil` | yes | |

## Concrete types

| Type | Extends | Additional fields |
|------|---------|-------------------|
| `AssumedSystemReq` | `RequirementSafety` | `rationale` : `String` (required) |
| `FeatReq` | `RequirementSafety` | `derived_from` : `AssumedSystemReqId[1..*]` (required) |
| `CompReq` | `RequirementSafety` | `derived_from` : `CompReqSourceId[1..*]` (required) |
| `ControlMeasure` | `RequirementSafety` | `mitigates` : `String` (optional) |
| `AoU` | `ControlMeasure` | — |
| `Mitigation` | `AssumedSystemReq` | `mitigates` : `String` (optional); inherits required `rationale` |
| `PreventiveMeasure` | — | no fields |
| `FailureMode` | `RequirementSafety` | `guidewords` : `Guideword[1..*]` (required)<br>`failureeffect` : `String` (required)<br>`rationale` : `String` (optional)<br>`interface` : `String` (optional) |

`CompReq.derived_from` may reference a `FeatReq`, an `AssumedSystemReq`, or a received `AoU`.
An `AoU` reference must come from a target listed directly in that target's `deps` — either the
`dependable_element`'s own `assumptions_of_use` or one received/forwarded from its deps.
Omit `derived_from` only for component-internal requirements with no feature-level parent.

## Versioned reference tuples

```rsl
tuple AssumedSystemReqId { item AssumedSystemReq  separator @  version Integer }
tuple FeatReqId          { item FeatReq           separator @  version Integer }
tuple CompReqId          { item CompReq           separator @  version Integer }
tuple CompReqSourceId    { item [FeatReq, AssumedSystemReq, AoU]        separator @  version Integer }
tuple Measure            { item [ControlMeasure, PreventiveMeasure, Mitigation]  separator @  version Integer }
```

Written in a `.trlc` file as `Package.RECORD_ID@<version>`, always inside a list:

```trlc
derived_from = [SampleSEooC.FEAT_001@1]
derived_from = [Integrator.FEAT_INT_001@1, SampleType.SampleAoU@1]
```

## Verbatim examples by type

### AssumedSystemReq

```trlc
ScoreReq.AssumedSystemReq ASR_SAMPLE_001 {
    description = "The system shall provide safe and reliable numeric value management through encapsulated classes, compliant with the selected :term:`integrity level`."
    safety = ScoreReq.Asil.B
    version = 1
    rationale = "System-level requirement for managing numeric values in a safety-critical context"
}
```

### FeatReq

```trlc
ScoreReq.FeatReq FEAT_001 {
    description = "The :term:`component` shall provide a numeric value management interface that returns a `uint8_t` value on every read access, aligned with the :term:`feature requirements`."
    safety = ScoreReq.Asil.B
    derived_from = [SampleSEooC.ASR_SAMPLE_001@1]
    version = 1
}
```

### CompReq derived from a FeatReq

```trlc
package SampleComponent

import ScoreReq
import SampleSEooC

ScoreReq.CompReq REQ_COMP_001 {
    description = "The numeric value management interface shall provide a read operation that returns a uint8_t value"
    safety = ScoreReq.Asil.B
    derived_from = [SampleSEooC.FEAT_001@1]
    version = 1
}
```

### CompReq derived from a FeatReq and an AoU

```trlc
package IntegratorComponent

import ScoreReq
import Integrator
import SampleType

ScoreReq.CompReq COMP_INT_001 {
    description = "The startup module shall call the SEooC initialization routine before entering the main loop"
    safety = ScoreReq.Asil.B
    derived_from = [Integrator.FEAT_INT_001@1, SampleType.SampleAoU@1]
    version = 1
}
```

### AoU

```trlc
ScoreReq.AoU TimingConstraint {
    description = "The caller shall ensure that invocations do not exceed 10ms cycle time"
    safety = ScoreReq.Asil.B
    version = 1
}
```

### FailureMode

```trlc
ScoreReq.FailureMode SampleFailureMode {
    guidewords = [ScoreReq.Guideword.LossOfFunction]
    description = "SampleFailureMode takes over the world"
    failureeffect = "The world as we know it will end"
    version = 1
    safety = ScoreReq.Asil.B
    interface = "safety_software_seooc_example.SampleLibraryAPI.GetNumber"
}
```

`interface` is the fully qualified name of the public API operation as it appears in the
`public_api` diagram.

### ControlMeasure

```trlc
ScoreReq.ControlMeasure WatchdogTimer {
    safety = ScoreReq.Asil.D
    description = "A watchdog shall detect overruns and force a safe state"
    version = 1
}
```

### Mitigation

```trlc
ScoreReq.Mitigation SomeMitigation {
    safety      = ScoreReq.Asil.B
    description = "A mitigation that reduces the severity of a hazard"
    rationale   = "Reduces severity by providing an alternative processing path"
    version     = 1
}
```

## Multi-line strings

```trlc
description = '''
    Line one of the description.
    Line two — indentation is preserved, so keep it consistent.
'''
```

## Tool qualification model (separate package)

[`bazel/rules/rules_score/trlc/config/qualification_model.rsl`](../../../../bazel/rules/rules_score/trlc/config/qualification_model.rsl), package `ToolQualification`,
defines `Tool`, `UseCase`, `PotentialError`, `ToolRequirement` and the enums `Impact_Type`
(`Safety`, `Financial`) and `Classification` (`None`, `TCL_1`, `TCL_2`, `TCL_3`). It is only
needed when qualifying a tool, not when specifying a SEooC.
