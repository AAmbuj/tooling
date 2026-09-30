---
description: "Read-only review of a SEooC implementation for correctness, requirement and test traceability, architecture consistency, safety-analysis closure, and release risks."
agent: "scorekit-seooc-engineer"
argument-hint: "dependable_element, folder, branch diff, or pull request"
---
Mode: **review** (read-only). Follow `scorekit-seooc-review` and its complete checklist.

- Review target: ${input:target:dependable_element, folder, branch diff, or PR}
- Maturity / review goal: ${input:goal:Development feedback or release readiness}

1. Establish scope from the requested target and repository diff. Read applicable instructions,
   relevant requirements/designs/implementation/tests, and the owning Bazel BUILD targets. Do not
   assume every changed file is in scope, and do not modify, create, delete, or format files.
2. Check requirements: level and allocation, atomic/verifiable wording, `derived_from` links,
   version pins, ASIL inheritance/justification, and whether each CompReq has behavior-focused
   tests.
3. Check architecture and implementation: static diagram names/nesting match Bazel targets;
   public/internal APIs are consistent; units and scopes match implementation dependencies; class
   diagrams match code; inspect relevant error handling, bounds, lifetime, and concurrency risks.
4. Check tests and traceability: tests are attached at the right level, trace to real CompReq IDs,
   include Given/When/Then, assert required behavior, and coverage locks are current.
5. Check safety analysis: relevant public API failures and guideword dismissals are justified;
   FailureModes match the API/effects and confirmed safety goals; FTA `$FailureMode` references
   are valid; each generated `$RootCause` is closed by a valid CompReq, AoU, or justified
   Mitigation; AoUs are verifiable and received AoUs are handled or forwarded. Do not make new
   ASIL, severity, plausibility, or measure-sufficiency judgements.
6. Check docs, glossary, maturity, and rendered diagrams. Run the most relevant Bazel checks; run
   broader tests when practical. Never run `.update` targets during review. Record checks that
   could not be run and why.
7. Report findings first, ordered by severity (`Blocker`, `Major`, `Minor`). Each finding must cite
   a file/location, explain the concrete failure or risk, and propose a specific fix. If there are
   no findings, say so clearly and list remaining test gaps or residual risks. Follow with open
   questions, validation results, then a brief summary.