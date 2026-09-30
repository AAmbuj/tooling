---
name: scorekit-trlc
description: "TRLC language and ScoreReq model reference for repositories that use score_tooling. USE FOR: .trlc syntax (package/import, record declarations, Markup_String, enums, lists), the ScoreReq record types and their mandatory fields, versioned Package.Record@version references, cross-package imports, multi-line strings, fixing trlc parse/type errors. DO NOT USE FOR: deciding requirement content/level/ASIL (scorekit-requirements), AoU content (scorekit-aou), FMEA content (scorekit-fmea). INVOKES: reference/scorereq-model.md."
argument-hint: "record type or trlc error message"
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

# TRLC and the ScoreReq model

Consumer repositories never define their own requirement schema. They `import ScoreReq`, which
`score_tooling` injects automatically into every requirement rule (`spec` defaults to
`@score_tooling//bazel/rules/rules_score/trlc/config:score_requirements_model`).

Full field reference: [reference/scorereq-model.md](reference/scorereq-model.md).

## File skeleton

```trlc
package MyModule          // one package per logical scope; shared across files is fine
import ScoreReq           // always
import OtherPackage       // every package you reference in derived_from

ScoreReq.FeatReq FEAT_001 {
    description  = "The component shall ..."
    safety       = ScoreReq.Asil.B
    derived_from = [MyModule.ASR_001@1]
    version      = 1
}
```

- File header comment: `/* ... */` block with your repository's license header.
- Record name: a TRLC identifier (`[A-Za-z][A-Za-z0-9_]*`), unique inside the package.
- Fully-qualified requirement ID: `Package.RecordName`. `$FailureMode` references FailureMode
  FQNs; `$RootCause` uses a plain identifier that generates an FTA-package record.

## Value syntax

| Type | Syntax |
|------|--------|
| `String` | `"text"` |
| `Markup_String` | `"text with :term:`glossary`"` or `'''multi-line'''` |
| `Integer` | `1` |
| enum | `ScoreReq.Asil.B`, `ScoreReq.Guideword.TooLate` |
| list | `[a, b]` |
| versioned reference (tuple) | `Package.Record@version`, e.g. `MyModule.FEAT_001@2` |

Multi-line descriptions use triple single quotes:

```trlc
description = '''The client shall maintain a state machine.

.. uml:: client_state.puml'''
```

## Record types at a glance

| Type | Extra mandatory fields (besides `description`, `version`, `safety`) | Optional |
|------|----------------------|----------|
| `AssumedSystemReq` | `rationale` | `note` |
| `FeatReq` | `derived_from` = `[AssumedSystemReq@v, ...]` (≥1) | `note` |
| `CompReq` | `derived_from` = `[FeatReq@v, AssumedSystemReq@v, received AoU@v, or generated RootCause]` | `note` |
| `AoU` | – | `root_causes` = generated `RootCause` list, `note` |
| `FailureMode` | `guidewords` (≥1), `failureeffect` | `rationale`, `interface`, `note` |
| `Mitigation` | `root_causes` (≥1), `justification` | `note` |
| `RootCause` | Generated from FTA `$RootCause`; do not author manually | — |

- `Asil` has only `QM`, `B`, `D`. There is no `A` or `C`.
- `status` is frozen to `valid`. Do not set it.
- `note` is non-normative free text. Put external references there (issue keys, source IDs).

## Versioning rules

1. Bump `version` on every content change of a record.
2. Every downstream `derived_from` still pinned to the old version must be reviewed and re-pinned
   (`@1` → `@2`). This is intentional: nothing changes silently.

## Validate

```bash
bazel build //path/to/requirements/...     # parse + type check
bazel test  //path/to/requirements/...     # runs <name>_test (trlc --verify) per rule
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Referenced record/package cannot be resolved | Add `import <Package>` and add the defining target to the rule's `deps`. |
| Error right after `@` in a reference | Version pins are integers: `Pkg.Rec@1`. |
| Missing value for a component (e.g. `rationale`) | Add the mandatory field listed in the table above. |
| `A` / `C` rejected for `safety` | Use `QM`, `B` or `D`. |
| Error on `status` | `status` is frozen; remove the line. |
| Type mismatch inside `derived_from` | `FeatReq` derives from `AssumedSystemReq`; `CompReq` may reference a `FeatReq`, `AssumedSystemReq`, received AoU, or generated RootCause. |

## Related skills

- `scorekit-requirements` – what to write, at which level, and the Bazel rules.
- `scorekit-aou` / `scorekit-fmea` – safety records.
