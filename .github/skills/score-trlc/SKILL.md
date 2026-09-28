---
name: score-trlc
description: "TRLC language and ScoreReq model reference for S-CORE. USE FOR: .trlc/.rsl syntax - package/import, record declarations, field types (Markup_String, Integer, String, enums, lists), versioned @ reference tuples, cross-package refs, multi-line strings, required fields per ScoreReq record type; fixing trlc parse/type errors. DO NOT USE FOR: requirement content, level, ASIL, or allocation (score-requirements); FMEA (score-safety-analysis). INVOKES: reference/rsl-model.md."
argument-hint: "the .trlc record or syntax error to fix"
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

# TRLC & the ScoreReq Model

Pure syntax and model reference. The model is defined in
`@score_tooling//bazel/rules/rules_score/trlc/config:score_requirements_model.rsl`
(package `ScoreReq`). That file is the source of truth; if this skill and the `.rsl` disagree,
the `.rsl` wins.

## File skeleton

Every `.trlc` file starts with the license block, then exactly one `package`, then imports:

```trlc
package MyComponent

import ScoreReq
import MySeooc
```

- `package` — your own namespace, free choice, must be unique across the build.
- `import ScoreReq` — always required; record types are written fully qualified as
  `ScoreReq.<Type>`.
- Import every *other* package you reference in a `derived_from` list.
- The `.rsl` is never imported by path and never copied into your repo; the Bazel rule supplies it.

## Record syntax

```trlc
ScoreReq.<Type> <RECORD_ID> {
    <field> = <value>
}
```

`<RECORD_ID>` is the stable identifier used in traceability links — treat it as an API.

## Field value syntax

| Field type | Write it as |
|------------|-------------|
| `String`, `Markup_String` | `"single line"` or `'''multi\nline'''` |
| `Integer` | `version = 1` (bare number, no quotes) |
| Enum | fully qualified: `ScoreReq.Asil.B`, `ScoreReq.Guideword.TooLate` |
| List | `[a, b]` — square brackets, comma separated, even for a single element |
| Versioned reference tuple | `Package.RECORD_ID@<version>` — no spaces around `@` |
| Optional field | omit the line entirely; never write `= null` or `= ""` |

`Markup_String` fields render through Sphinx, so RST inline markup is live:
`` :term:`integrity level` `` and `` `uint8_t` `` both work. See the `score-docs` skill for
what markup is available.

## The three rules that break builds most often

1. **`version` is a manual counter.** Increment it on every content change, and update every
   `@<version>` in records that point at it. A stale pin is a hard error.
2. **Enums must be fully qualified.** `safety = B` fails; `safety = ScoreReq.Asil.B` is correct.
   `Asil` has exactly three literals: `QM`, `B`, `D` — there is no `A` or `C`.
3. **`status` is frozen** to `Status.valid` in the model. Never set it.

## Minimal records

```trlc
package MinimalExample

import ScoreReq

ScoreReq.AssumedSystemReq ASR_001 {
    description = "The system shall support configurable key-value parameters accessible at runtime"
    safety      = ScoreReq.Asil.B
    rationale   = "Runtime configuration is required so the component can be adapted without recompilation"
    version     = 1
}

ScoreReq.FeatReq FEAT_001 {
    description  = "The :term:`component` shall return a `uint8_t` value on every read access"
    safety       = ScoreReq.Asil.B
    derived_from = [MinimalExample.ASR_001@1]
    version      = 1
}

ScoreReq.CompReq REQ_COMP_001 {
    description  = "The read operation shall return a uint8_t value"
    safety       = ScoreReq.Asil.B
    derived_from = [MinimalExample.FEAT_001@1]
    version      = 1
}
```

Start from [templates/requirements.trlc](templates/requirements.trlc) rather than typing from memory.

## Which fields does type X need?

Open [reference/rsl-model.md](reference/rsl-model.md) — it carries the complete field table for
every type and the verbatim enum literal sets. Load it only when you need a field you are not
sure about.

Quick map:

| Type | Mandatory beyond `description` / `version` / `safety` |
|------|--------------------------------------------------------|
| `AssumedSystemReq` | `rationale` |
| `FeatReq` | `derived_from` (`AssumedSystemReqId[1..*]`) |
| `CompReq` | `derived_from` (`CompReqSourceId[1..*]`: FeatReq, AssumedSystemReq or AoU) |
| `AoU` | — (`mitigates` optional) |
| `FailureMode` | `guidewords`, `failureeffect` |
| `ControlMeasure` | — (`mitigates` optional) |
| `Mitigation` | `rationale` |

## Validating

Requirement macros generate a `<name>_test` target:

```bash
bazel test //path/to/pkg:my_requirements_test
```

Run it after every edit. Typical failures and their cause:

| Message contains | Cause |
|------------------|-------|
| `unknown symbol` / `not a known type` | missing `import`, or record type not prefixed with `ScoreReq.` |
| `expected Integer` | quoted a number, e.g. `version = "1"` |
| `reference to ... version N` mismatch | a `@<version>` pin is stale — bump the pin, not the target |
| `required field ... missing` | see the table above / `reference/rsl-model.md` |
