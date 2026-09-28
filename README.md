<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Score Tooling

A unified Bazel module containing development tools and utilities for building, testing, and maintaining code quality.

## Quick Start

Add this module to your `MODULE.bazel`:

```starlark
bazel_dep(name = "score_tooling", version = "1.0.0")
```

## Available Tools

Each tool maintains its own documentation and examples in their respective subdirectories.
See the individual README files for detailed usage instructions and configuration options.

| Tool | Description | Documentation |
|------|-------------|---------------|
| **cli_helper** | Command-line interface utilities | [README](cli_helper/README.md) |
| **cr_checker** | Code review and compliance checking | [README](cr_checker/README.md) |
| **dash** | Eclipse Dash license scanning | [README](dash/README.md) |
| **format** | Code formatting validation | [README](third_party/format/README.md) |
| **lint** | Python lint aspects (ruff, pylint) | [README](third_party/lint/README.md) |
| **python_basics** | Python development utilities and testing | [README](python_basics/README.md) |
| **starpls** | Starlark language server support | [README](starpls/README.md) |
| **tools** | Formatters & Linters | [README](tools/README.md) |
| **coverage** | Unified LLVM source-based coverage (C++ + Rust) | [README](coverage/README.md) |

## Copilot Skills & Agent

`score_tooling` ships GitHub Copilot customizations for the `rules_score` workflow: a router
agent under `.github/agents`, task prompts under `.github/prompts`, and specialized skills under
`.github/skills`. Consumer repos pull them in with one target so Copilot does not have to
re-derive the same guidance per prompt.

```starlark
load("@score_tooling//skills_sync:sync_skills.bzl", "sync_skills")

sync_skills()
```

```bash
bazel run  //:sync_skills        # copy into .github/{agents,prompts,skills}
bazel test //:sync_skills.check  # CI guard against drift
```

| Asset | Covers |
|-------|--------|
| `score-tooling` (agent) | Routes a task to exactly one skill |
| `score-safety-analysis-review` (prompt) | Reviews an existing FMEA, reports findings by severity |
| `score-safety-analysis-rollout` (prompt) | Creates or extends an FMEA, with sign-off before writing |
| `score-onboarding` | `MODULE.bazel`, toolchains, first SEooC scaffold |
| `score-requirements` | Requirement content, levels, ASIL, allocation |
| `score-trlc` | TRLC / `.rsl` syntax and the `ScoreReq` field tables |
| `score-architecture` | Component/unit decomposition, validators |
| `score-plantuml` | `.puml` conventions, parser CLI, clickable diagrams |
| `score-testing` | GoogleTest traceability, test-case coverage lock |
| `score-safety-analysis` | FMEA, `FailureMode` / `ControlMeasure`, FTA |
| `score-docs` | `.rst` authoring, page placement, glossary |

Only `score-*` names are distributed; anything else stays local. Details:
[skills_setup.rst](bazel/rules/rules_score/docs/skills_setup.rst).

### Offline pack

For users who cannot build with Bazel, `//.github:copilot_pack` produces a self-contained
archive with the same agent, prompts and skills plus an installer:

```bash
bazel build //.github:copilot_pack
tar -xzf bazel-bin/.github/score-copilot-pack.tar.gz
cd score-copilot-pack && ./install.sh          # -> ~/.copilot/{agents,skills}
```

Use `./install.sh --workspace /path/to/repo` to install into `<repo>/.github` instead. The pack
needs no network, no Bazel and no dependency on `score_tooling`; see `INSTALL.md` inside it.

## Coverage

The `coverage/` module provides the reusable LLVM source-based coverage pipeline
used across S-CORE repositories: one report covering C++ and Rust (line + branch),
exact 0% entries for untested in-scope files, a justification system
(`COV_JUSTIFIED` markers + YAML), and effective-coverage gating. See the
[adoption guide](coverage/README.md) and the
[mechanism deep-dive](coverage/COVERAGE_GUIDE.md).

> **Breaking change:** the former Ferrocene `symbol-report`/`blanket` workflow
> (`rust_coverage_report`, `//coverage:ferrocene_report`) was removed. The LLVM
> pipeline replaces it with unified C++ + Rust reports; see the
> [adoption guide](coverage/README.md) for migration.

Generate a combined Rust + Python HTML coverage report for this repository's own
tools (`plantuml`, `validation`, `manual_analysis`):

```bash
bazel run //coverage:combined_report
```

## Usage Examples

Load tools in your `BUILD` files:

```starlark
load("@score_tooling//:defs.bzl", "score_py_pytest")
load("@score_tooling//:defs.bzl", "cli_tool")
load("@score_tooling//coverage:defs.bzl", "score_coverage_reporter", "score_coverage_scope")
```

Declare the coverage scope and reporter for your repository (see the
[coverage adoption guide](coverage/README.md) for the full setup, including the
required `.bazelrc` configuration and toolchains):

```starlark
score_coverage_scope(
    name = "coverage_scope",
    testonly = True,
    deps = ["//src/mylib"],
)

score_coverage_reporter(
    name = "reporter_wrapper",
    testonly = True,
    coverage_scope = ":coverage_scope",
    llvm_cov = "@llvm_toolchain//:llvm-cov",
    llvm_profdata = "@llvm_toolchain//:llvm-profdata",
    llvm_cxxfilt = "@llvm_toolchain_llvm//:bin/llvm-cxxfilt",
)
```

## Upgrading from separate MODULES

If you are still using separate module imports and want to upgrade to the new version.
Here are two examples to showcase how to do this.

```
load("@score_python_basics//:defs.bzl", "score_py_pytest") => load("@score_tooling//:defs.bzl", "score_py_pytest")
load("@score_cr_checker//:cr_checker.bzl", "copyright_checker") => load("@score_tooling//cr_checker:cr_checker.bzl", "copyright_checker")
```

All things inside of 'tooling' can now be imported from `@score_tooling//:defs.bzl`.
The available import targets are:

- score_virtualenv
- score_py_pytest
- dash_license_checker
- cli_helper
- setup_starpls
- score_coverage_scope
- score_coverage_reporter

Formatting, linting, and cr_checker are no longer re-exported from `defs.bzl`; use
`@score_tooling//third_party/format:macros.bzl`, `@score_tooling//third_party/lint:macros.bzl`,
`@score_tooling//cr_checker:cr_checker.bzl`, or the `@score_tooling//third_party/format:rustfmt_with_policies`
label directly.

## Format the tooling repository

```bash
bazel run //:format.fix
```
