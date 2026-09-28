---
name: score-onboarding
description: "Bootstrapping a repository onto score_tooling. USE FOR: adding the score_tooling bazel_dep/registry to MODULE.bazel and .bazelrc, registering the libclang and Sphinx toolchains, wiring sync_skills/copyright_checker/dash_license_checker/cli_helper/setup_starpls/score_virtualenv, scaffolding the first empty dependable_element. DO NOT USE FOR: authoring work-product content once the repo builds (use the matching score-* skill). INVOKES: templates/MODULE.bazel.snippet, templates/root-BUILD.snippet, reference/first-seooc.md."
argument-hint: "the repository to onboard onto score_tooling"
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

# Onboarding a repository onto score_tooling

Work in this order. Each step must build before you start the next — diagnosing a broken
toolchain from inside a half-written SEooC wastes far more time.

## 1. Registry

`score_tooling` and its S-CORE dependencies are published in the Eclipse S-CORE Bazel registry,
which must be listed **before** the BCR in `.bazelrc`:

```
common --registry=https://raw.githubusercontent.com/eclipse-score/bazel_registry/main/
common --registry=https://bcr.bazel.build
```

## 2. MODULE.bazel

```starlark
bazel_dep(name = "score_tooling", version = "<version>")

bazel_dep(name = "trlc", version = "3.0.0")
bazel_dep(name = "googletest", version = "1.17.0.bcr.2")
bazel_dep(name = "lobster", version = "1.0.4")

bazel_dep(name = "toolchains_llvm", version = "1.6.0")

llvm = use_extension("@toolchains_llvm//toolchain/extensions:llvm.bzl", "llvm")
llvm.toolchain(llvm_version = "19.1.7")
use_repo(llvm, "llvm_toolchain", "llvm_toolchain_llvm")
```

Pick the `score_tooling` version from the registry. `local_path_override` appears in the
in-repo examples only because they live inside `score_tooling` itself — a real consumer does
not use it.

Full snippet: [templates/MODULE.bazel.snippet](templates/MODULE.bazel.snippet).

## 3. libclang toolchain

Unit design validation parses your real C++ with libclang, so a `libclang_toolchain` must be
registered. Put it in `bazel/toolchains/BUILD`:

```starlark
load("@score_tooling//cpp/libclang:libclang_toolchain.bzl", "libclang_toolchain")

libclang_toolchain(
    name = "my_libclang",
    cc_toolchain = "@llvm_toolchain//:cc-clang-x86_64-linux",
    libclang = "@llvm_toolchain_llvm//:lib/libclang.so",
)

toolchain(
    name = "my_libclang_toolchain",
    toolchain = ":my_libclang",
    toolchain_type = "@score_tooling//cpp/libclang:libclang_toolchain_type",
    visibility = ["//:__subpackages__"],
)
```

and register it in `.bazelrc`:

```
common --extra_toolchains=//bazel/toolchains:my_libclang_toolchain
```

A missing libclang toolchain shows up as a toolchain-resolution error on a `unit` target, not
as a helpful message about C++ parsing.

## 4. Copilot assets

```starlark
load("@score_tooling//skills_sync:sync_skills.bzl", "sync_skills")

sync_skills()
```

```bash
bazel run  //:sync_skills        # pull score-* skills and agents into .github/
bazel test //:sync_skills.check  # CI guard against drift
```

Commit what `sync_skills` writes. Wire `.check` into CI so upstream updates are caught.

## 5. Optional tooling

Add only what the repository actually needs — each one is independent.

| Need | Load |
|------|------|
| Sphinx with extra extensions | `@score_tooling//bazel/rules/rules_score:sphinx_toolchain.bzl` → `score_sphinx_toolchain` |
| Copyright headers | `@score_tooling//cr_checker:cr_checker.bzl` → `copyright_checker` |
| License compliance | `@score_tooling//dash:dash.bzl` → `dash_license_checker` |
| Discoverable CLI targets | `@score_tooling//cli_helper:cli_helper.bzl` → `cli_helper` |
| Starlark LSP for the IDE | `@score_tooling//starpls:starpls.bzl` → `setup_starpls` |
| Python venv / pytest | `@score_tooling//python_basics:defs.bzl` → `score_virtualenv`, `score_py_pytest` |
| C++/Rust coverage | `@score_tooling//coverage:defs.bzl` → `score_coverage_scope`, `score_coverage_reporter` |

Concrete calls: [templates/root-BUILD.snippet](templates/root-BUILD.snippet). The default
Sphinx toolchain works out of the box; only call `score_sphinx_toolchain` when you need extra
extensions — see [`bazel/rules/rules_score/docs/integration_guide.rst`](../../../bazel/rules/rules_score/docs/integration_guide.rst).

## 6. Scaffold the first SEooC

Declare the empty `dependable_element` first and fill it in afterwards:

```starlark
load("@score_tooling//bazel/rules/rules_score:rules_score.bzl", "dependable_element")

dependable_element(
    name = "my_element",
    integrity_level = "B",
    maturity = "development",
    requirements = [],
    assumptions_of_use = [],
    architectural_design = [],
    components = [],
    dependability_analysis = [],
    tests = [],
)
```

`maturity = "development"` downgrades consistency violations to warnings while the element is
incomplete. Switch to `"release"` before claiming the element is done.

```bash
bazel build //:my_element
```

Then hand over to the specialised skills in this order: requirements → architecture →
implementation and tests → safety analysis. The complete worked example and the hand-off points
are in [reference/first-seooc.md](reference/first-seooc.md).

## Verifying the onboarding

```bash
bazel build //:my_element        # SEooC assembles and docs build
bazel test  //...                # validators, requirement tests, sync check
bazel run   //:my_element.serve  # read the generated HTML
```
