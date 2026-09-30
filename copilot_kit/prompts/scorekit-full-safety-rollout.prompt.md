---
description: "Roll out a complete safety-focused SEooC from confirmed source requirements through implementation, tests, safety analysis, traceability, documentation, and release checks."
agent: "scorekit-seooc-engineer"
argument-hint: "source requirements, element/component, safety goals, ASIL and integrity level"
---
Mode: **implement**. Follow `scorekit-seooc-implement` and its stage checklist. Use the focused
`scorekit-*` skills for each work product.

- Source of truth: ${input:source:Requirement text, files, or ticket IDs}
- Element / component: ${input:element:dependable_element and component names}
- Safety goals and ASIL: ${input:safety:Confirmed goals and ASIL classification}
- Integrity level: ${input:integrity:Element integrity level}
- Scope: ${input:scope:New rollout or existing SEooC to extend}

1. Inspect repository instructions, worktree changes, Bazel targets, and existing artifacts. Reuse
   existing records and designs; do not overwrite unrelated or user-modified files.
2. Perform intake first: summarize the source, identify missing decisions, and propose the work
   stages. Wait for confirmation before creating or changing work products.
3. Build requirements traceability (`scorekit-requirements`, `scorekit-trlc`): draft ASR, FeatReq,
   and CompReq at the correct levels; keep IDs stable, version pins current, and requirements
   atomic and verifiable. Confirm requirement intent and every safety classification.
4. Design and agree the architecture (`scorekit-plantuml`, `scorekit-seooc`): static decomposition,
   public/internal APIs, component/unit allocation, and target names/nesting. Validate parser and
   architecture findings before implementing the tree.
5. Implement units and component wiring. Keep implementation dependencies inside certified scope
   and use absolute labels for `unit(scope=...)`. Add tests that verify behavior, not smoke-only
   coverage.
6. Trace tests to CompReqs (`scorekit-lobster-tracing`), include Given/When/Then metadata, attach
   tests at the correct level, and update coverage locks only through the documented `.update`
   target after reviewing its diff.
7. Complete the safety analysis (`scorekit-fmea`, `scorekit-fta`, `scorekit-aou`): consider
   relevant guidewords per public API method; write confirmed FailureModes; link them from FTA
   `$FailureMode` macros; use `$RootCause` aliases to generate RootCause records; close each cause
   through `CompReq.derived_from`, `AoU.root_causes`, or a justified `Mitigation`. Never author
   generated RootCause records or invent failure severity, ASIL, or measure sufficiency. Confirm
   safety judgements before recording them.
8. Wire `safety_analysis`, `dependability_analysis`, assumptions of use, the dependable element,
   glossary, and documentation. Received AoUs must be handled or forwarded; own AoUs closing root
   causes must have the required safety-analysis and assumptions target dependencies.
9. Validate each stage with its narrow Bazel gate, then run the relevant full test suite. Inspect
   generated docs/diagrams and the final diff. Set `maturity = "release"` only after explicit
   release-readiness confirmation.
10. Report changed files, decisions confirmed, commands and results, unresolved decisions, and
    residual findings. Do not commit, push, or change external systems.