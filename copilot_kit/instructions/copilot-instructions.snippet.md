## S-CORE work products (score_tooling)

This repository builds S-CORE work products with the `score_tooling` Bazel rules. Installed
Copilot kit: scorekit {{SCOREKIT_VERSION}} (skills `scorekit-*`, agents `scorekit-*`,
prompts `/scorekit-*`).

- Requirements are TRLC records of package `ScoreReq` (`AssumedSystemReq` → `FeatReq` →
  `CompReq`, plus `AoU`, `FailureMode`, `ControlMeasure`). IDs are `Package.Record`; references
  are version-pinned `Package.Record@<version>`. Bump `version` on every content change and
  re-pin children. `Asil` is `QM`, `B` or `D`.
- The PlantUML `static` diagram is the design; `dependable_element`/`component`/`unit` targets
  mirror its aliases and nesting 1:1.
- Every FailureMode has one `fta_<name>.puml` whose `$TopEvent` alias is the FailureMode FQN;
  every `$BasicEvent` alias is a ControlMeasure/AoU FQN.
- Tests trace to requirements with GoogleTest `RecordProperty("lobster-tracing", ...)` plus
  given/when/then; refresh locks with `bazel run //<pkg>:<component>.update`.
- Validate every change with `bazel test //...` before reporting completion.
- Propose, never decide alone: requirement level, ASIL, failure severity, measure sufficiency.
- Load rules from `@score_tooling//...` public `.bzl` files only; never edit score_tooling.
