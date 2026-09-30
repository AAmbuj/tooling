---
name: scorekit-coverage
description: "LLVM source-based line/branch coverage with score_tooling in a consumer repository. USE FOR: score_coverage_scope and score_coverage_reporter targets, the coverage:llvm_cov bazelrc config, running bazel coverage, generating the HTML/LCOV report with a threshold gate, COV_JUSTIFIED justification markers and the justification YAML, effective vs raw coverage. DO NOT USE FOR: requirement-to-test traceability or the test_case_coverage lock (scorekit-lobster-tracing), toolchain bootstrap (scorekit-onboarding). INVOKES: templates/coverage.BUILD.tpl, templates/coverage.bazelrc."
argument-hint: "targets to measure or coverage error"
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

# Structural coverage

## Setup

1. `MODULE.bazel`: `toolchains_llvm` with `use_repo(llvm, "llvm_toolchain", "llvm_toolchain_llvm")`
   (see `scorekit-onboarding`). Rust additionally needs `score_toolchains_rust` ≥ 0.10.0.
2. Root `BUILD`: `exports_files(["MODULE.bazel"])`.
3. `tools/coverage/BUILD`: [templates/coverage.BUILD.tpl](templates/coverage.BUILD.tpl)
   - `score_coverage_scope(deps=[production targets])` – in-workspace transitive sources become
     the allowlist; untested files appear at 0 %; tests/mocks/external are filtered out.
   - `score_coverage_reporter(coverage_scope, llvm_cov, llvm_profdata, llvm_cxxfilt)`.
4. `.bazelrc`: [templates/coverage.bazelrc](templates/coverage.bazelrc) (`coverage:llvm_cov` block).
   Do not combine `--config=llvm_cov` with configs that add other `--extra_toolchains`.

## Run

```bash
bazel coverage --config=llvm_cov //... --build_tests_only
bazel run @score_tooling//coverage:generate_coverage_html -- --yaml tools/coverage/coverage_justifications.yaml
# CI gate + artifacts
COVERAGE_THRESHOLD=95 bazel run @score_tooling//coverage:generate_coverage_html -- \
    --yaml tools/coverage/coverage_justifications.yaml --archive-dir coverage_artifacts
```

`COVERAGE_THRESHOLD` defaults to 100. With `--yaml` it gates *effective* coverage, else raw.
In GitHub Actions a markdown summary is appended automatically; elsewhere use `--summary-md <path>`.

## Justifications

`tools/coverage/coverage_justifications.yaml`:

```yaml
version: 1
justifications:
  - id: hw-unreachable-on-x86          # kebab-case
    category: platform_specific        # defensive_programming | tool_false_positive | platform_specific | other
    platforms: [linux]
    reason: |
      ARM-only error path; cannot be exercised by x86 CI.
```

```cpp
return false;  // COV_JUSTIFIED hw-unreachable-on-x86
// COV_JUSTIFIED_START hw-unreachable-on-x86
...
// COV_JUSTIFIED_STOP
```

A justification on a line that is now covered is reported as **stale** – remove it.

## Error lookup

| Symptom | Fix |
|---------|-----|
| Empty report / no covmap | Another config overrode the LLVM toolchain; run with `--config=llvm_cov` only. |
| Reporter cannot find workspace | Add `exports_files(["MODULE.bazel"])` to the root BUILD. |
| Manual/incompatible tests built | Add `--build_tests_only`. |
| Rust files missing | Use a Ferrocene toolchain from `score_toolchains_rust` ≥ 0.10.0. |

## Related skills

`scorekit-onboarding`, `scorekit-lobster-tracing`, `scorekit-ci`.
