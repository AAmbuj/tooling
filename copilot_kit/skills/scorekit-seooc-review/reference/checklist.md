<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# SEooC review checklist

## R — Requirements

- [ ] R1 Every `FeatReq` has `derived_from` to ≥1 `AssumedSystemReq`.
- [ ] R2 Every `CompReq` has `derived_from`, or is justified as component-internal (`note`).
- [ ] R3 All `@version` pins equal the current `version` of the referenced record.
- [ ] R4 Child ASIL ≥ parent ASIL, or lowering justified in `note`.
- [ ] R5 Each requirement is atomic (one `shall`), verifiable (bounds/units), unambiguous.
- [ ] R6 Level fits: ASR = external need, FeatReq = multi-component feature, CompReq = one component.
- [ ] R7 Each `CompReq` file is allocated to exactly one `component`; `FeatReq` to the element.
- [ ] R8 No normative text in `note`; no `status` set.

## A — Architecture

- [ ] A1 Static diagram aliases/nesting == Bazel `dependable_element`/`component`/`unit` names.
- [ ] A2 No `unit` directly under the element.
- [ ] A3 Public API interfaces top-level and bound from the `<<SEooC>>`; in `namespace <element>`.
- [ ] A4 Internal interfaces inside the owning namespace.
- [ ] A5 Sequence participants resolve to static units (qualified labels when nested).
- [ ] A6 Unit class diagrams match the headers (members, methods, types).
- [ ] A7 Public API minimal (each method justified by a requirement).
- [ ] A8 `integrity_level` of `deps` elements ≥ own level.

## T — Tests and traceability

- [ ] T1 Every `CompReq` has ≥1 test with `lobster-tracing` = its FQN.
- [ ] T2 Every traced test has `given`, `when`, `then`.
- [ ] T3 `test_case_coverage.lock.yaml` exists per component with requirements and is in sync.
- [ ] T4 Tests assert the requirement's behaviour (not just smoke).
- [ ] T5 Tests are attached at the right level (unit / component / element).

## S — Safety analysis

- [ ] S1 Every relevant public API failure is analyzed; dismissed guidewords have a reason.
- [ ] S2 Relevant guidewords considered per method (message, timing, execution); dismissals reasoned.
- [ ] S3 `failureeffect` is from the caller/system view, worst case; `safety` = ASIL of violated goal.
- [ ] S4 FTA `$FailureMode` macros reference the intended FailureMode FQNs.
- [ ] S5 FTA uses correct procedure signatures; gates connect to parents; no orphan nodes.
- [ ] S6 Every `$RootCause` has a generated record and is closed by a CompReq, AoU, or Mitigation.
- [ ] S8 `$AndGate` used only for truly co-required causes, with justification.
- [ ] S9 Each CompReq plausibly addresses its root cause; code controls have implementation + tests. Mitigation justifications explain why the cause does not apply.
- [ ] S10 AoUs are phrased as integrator obligations and are verifiable.
- [ ] S11 Every received AoU is handled (CompReq `derived_from`) or forwarded with justification.
- [ ] S12 `safety_analysis` lists all FTA files; `dependability_analysis` attached to the element.

## D — Docs and release readiness

- [ ] D1 Diagrams render; overview elements link to their detail diagrams.
- [ ] D2 Glossary terms used in requirements exist.
- [ ] D3 `maturity` is `release` for a release candidate; no remaining warnings.
- [ ] D4 License headers present on new files.
