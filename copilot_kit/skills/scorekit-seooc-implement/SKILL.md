---
name: scorekit-seooc-implement
description: "Guided end-to-end implementation of a complete Safety Element out of Context (SEooC) with score_tooling, including the full safety analysis. USE FOR: turning a feature request, requirement text, or an external requirement/ticket into requirements → architecture → units/code → annotated tests → FMEA/FTA/control measures/AoUs → dependable_element, stage by stage with bazel validation gates and a final self-review. DO NOT USE FOR: a single isolated change (use the specific scorekit-* skill), reviewing existing work (scorekit-seooc-review). INVOKES: reference/stage-checklist.md and the templates of scorekit-requirements, scorekit-plantuml, scorekit-seooc, scorekit-lobster-tracing, scorekit-fmea, scorekit-fta, scorekit-aou."
argument-hint: "feature / requirement source, module name, target ASIL"
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

# Implement a full SEooC

Work in **stages**. Each stage has an agreement point (ask the user) and a validation gate
(`bazel` must pass or report only accepted warnings). Track stages with a todo list.
Per-stage checklist: [reference/stage-checklist.md](reference/stage-checklist.md).

Use `maturity = "development"` while building up; switch to `release` in stage 8.

## Stage 0 — Intake

- Read the source (user text, files, or external requirement/ticket items when an intake skill
  for that system is installed).
- Fix: module/package name, `dependable_element` name, target `integrity_level`, ASIL of the
  safety goal(s), whether the repo is already onboarded (`scorekit-onboarding` if not).
- List open questions. **Stop and confirm** before writing files.

## Stage 1 — Requirements (`scorekit-requirements`, `scorekit-trlc`)

- Draft ASR → FeatReq (and CompReq later, after stage 2 fixes the components).
- Atomic, verifiable, `shall`; ASIL inherited top-down.
- Agree the list with the user. Write `.trlc` + `requirements/BUILD`.
- Gate: `bazel test //requirements/...`

## Stage 2 — Architecture (`scorekit-plantuml`)

- Propose static decomposition (1–2 options with trade-offs), public API, internal API.
- **Stop for agreement** on the decomposition.
- Write `static_design.puml`, `public_api.puml` (+ dynamic/internal if needed), `architectural_design`.
- Write CompReq per component now (`derived_from` FeatReq), one file per component.
- Gate: `bazel build //:<arch target>` and `bazel test //requirements/...`

## Stage 3 — Units and code (`scorekit-seooc`)

- Per unit: header/impl, `cc_library`, class diagram + `unit_design`, `unit`.
- Components mirror the static diagram; allocate CompReq files via `component(requirements=...)`.
- Gate: `bazel build //...`

## Stage 4 — Tests (`scorekit-lobster-tracing`)

- GoogleTest per CompReq with `lobster-tracing` + given/when/then.
- Set `test_case_coverage_lock`; run `bazel run //:<component>.update`; show the lock diff.
- Gate: `bazel test //...` (all tests pass, lock in sync)

## Stage 5 — Full safety analysis (`scorekit-fmea`, `scorekit-fta`, `scorekit-aou`)

1. For every public API method apply the guidewords; propose failure modes (keep/dismiss with
   reason). **Confirm severity and ASIL with the user.**
2. `failure_modes.trlc` (one per interface/effect, `interface` = `<ns>.<Api>.<Method>`).
3. One `fta_<fm>.puml` per failure mode down to actionable root causes.
4. One `ControlMeasure` per basic event; obligations for the integrator become `AoU`s.
5. Implement control measures that are code (monitors, checks) → new CompReq + tests
   (loop back to stages 1/3/4 for those).
6. `fmea`, `dependability_analysis`, `assumptions_of_use`; received AoUs handled or forwarded.
- Gate: `bazel test //:dependability_analysis`

## Stage 6 — Assembly and docs (`scorekit-seooc`, `scorekit-docs`)

- `dependable_element` with requirements, arch, AoUs, analysis, components, glossary, deps.
- Gate: `bazel test //...` and `bazel run //:<element>.serve` (check diagrams render/link).

## Stage 7 — Self-review

Run the full `scorekit-seooc-review` checklist on the result. Fix every **blocker**; list
remaining majors/minors for the user.

## Stage 8 — Release readiness

- Switch `maturity` to `release` on `dependable_element`, `architectural_design`,
  `dependability_analysis`.
- Gate: `bazel test //...` with zero traceability/lock/architecture failures.
- Report: files created, commands run with results, open decisions, residual findings.

## Rules

- Never invent safety judgements (severity, ASIL, sufficiency of a measure): propose and confirm.
- Never edit `score_tooling` itself; only the consumer repo.
- Do not commit or push unless asked.
- Keep IDs stable; bump `version` and re-pin `derived_from` on content changes.
