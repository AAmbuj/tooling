---
name: scorekit-seooc-review
description: "Read-only review of a complete Safety Element out of Context (SEooC) built with score_tooling, including the full safety analysis. USE FOR: reviewing a dependable_element, a folder, or a pull request for requirement quality and traceability (ASR→FeatReq→CompReq, version pins, ASIL inheritance), architecture consistency, test coverage and lock freshness, FMEA completeness (public API × guidewords), FTA correctness, control measure / AoU closure, AoU handling/forwarding, docs; producing a severity-ranked findings table with concrete fixes. DO NOT USE FOR: making changes (scorekit-seooc-implement or the specific scorekit-* skill). INVOKES: reference/checklist.md, reference/findings-template.md."
argument-hint: "dependable_element label, folder, or PR"
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

# Review a full SEooC

**Read-only.** Do not edit files. Report findings; the user decides what to fix.

## Procedure

1. **Scope.** Resolve the target: a `dependable_element` label, a folder, or the changed files
   of a PR (review only affected work products plus everything they trace to).
2. **Inventory.** Locate: requirement `.trlc` + BUILD, `.puml` diagrams + `architectural_design`,
   units/components/element, tests + lock files, `failure_modes.trlc`, `safetymeasures.trlc`,
   `fta_*.puml`, AoUs, `aou_forwarding.yaml`, glossary. Note `maturity` values.
3. **Machine checks** (run, do not fix):
   ```bash
   bazel test //... --test_output=errors
   bazel test //:<element>                     # traceability report
   bazel test //:<dependability_analysis>
   ```
   Record every failure/warning. In `development` maturity also read the warnings in the
   build output – they become errors in `release`.
4. **Manual checks.** Walk [reference/checklist.md](reference/checklist.md) section by section.
   Cross-check by reading files (grep IDs, aliases, versions).
5. **Report** with [reference/findings-template.md](reference/findings-template.md).

## Severity

| Severity | Meaning | Examples |
|----------|---------|----------|
| **Blocker** | Fails `release` gate or breaks a safety argument | missing FTA for a FailureMode; public API method without failure mode analysis; CompReq without test; unhandled received AoU; ASIL of child lower than parent without justification; declared ≠ implemented architecture |
| **Major** | Safety argument weak or misleading | non-atomic/unverifiable requirement; control measure that does not address its root cause; AND gate without justification; stale `@version` pin; missing given/when/then |
| **Minor** | Quality/consistency | naming, missing glossary term, typos, unsorted `fta_files` |

## Rules

- Every finding cites `file:line` (or target label), the violated rule, and a concrete fix.
- Distinguish tool-verified findings (from bazel output) from reviewer judgement.
- Do not invent missing context; list it as a question.
- Never post PR comments or change external systems without explicit user confirmation.
