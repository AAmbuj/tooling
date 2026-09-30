---
name: scorekit-onboarding
description: "Bootstrapping a Bazel repository onto score_tooling. USE FOR: MODULE.bazel bazel_dep entries (score_tooling, trlc, lobster, googletest, toolchains_llvm), the Eclipse S-CORE registry in .bazelrc, registering the libclang toolchain required by unit_design, optional helpers from @score_tooling//:defs.bzl (copyright_checker, dash_license_checker, cli_helper, setup_starpls, score_virtualenv, score_py_pytest), installing/updating this Copilot kit, scaffolding the first empty SEooC. DO NOT USE FOR: authoring work products once the repo builds (use the matching scorekit-* skill). INVOKES: templates/MODULE.bazel.snippet, templates/bazelrc.snippet, templates/toolchains.BUILD.tpl."
argument-hint: "repository to onboard"
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

# Onboarding onto score_tooling

## 1. MODULE.bazel

Append [templates/MODULE.bazel.snippet](templates/MODULE.bazel.snippet). Pin `score_tooling`
to the release your organisation uses. Local development against a checkout:

```starlark
local_path_override(module_name = "score_tooling", path = "../tooling")
```

## 2. .bazelrc

Append [templates/bazelrc.snippet](templates/bazelrc.snippet): the S-CORE registry before BCR,
plus the libclang toolchain registration. Add a `.bazelversion` (score_tooling examples use
Bazel 8.x).

## 3. libclang toolchain

Copy [templates/toolchains.BUILD.tpl](templates/toolchains.BUILD.tpl) to
`bazel/toolchains/BUILD`. Without it `unit_design` cannot validate the C++ class design.
Adjust the `cc_toolchain` label for non-x86_64 hosts.

## 4. First (empty) SEooC

Minimal element that builds: one `static_design.puml`, one `unit` (library + test +
`unit_design`), one `component`, one `dependable_element` with `maturity = "development"` and
empty `assumptions_of_use`/`dependability_analysis`/`tests`. Templates: `scorekit-seooc`.

```bash
bazel build //...
bazel test //...
bazel run //:my_element.serve
```

## 5. Optional helpers

```starlark
load("@score_tooling//:defs.bzl",
     "copyright_checker",       # creates <name>.check / <name>.fix (copyright headers)
     "dash_license_checker",    # Eclipse DASH license check
     "cli_helper",              # lists runnable CLI targets
     "setup_starpls",           # Starlark language server
     "score_virtualenv", "score_py_pytest")
```

`copyright_checker(name, visibility, template, config, exclusion=None, srcs=[], ...)`.
See each macro's docstring in score_tooling for its attributes.

## 6. Copilot kit

From a score_tooling checkout:

```bash
./copilot_kit/install.sh --repo /path/to/your/repo            # full profile
./copilot_kit/install.sh --repo . --check                     # CI drift check
./copilot_kit/install.sh --user                               # all workspaces
```

or from a repo that depends on score_tooling:

```bash
bazel run @score_tooling//copilot_kit:install -- --repo "$PWD"
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| `score_tooling` not found in registry | Add the S-CORE registry line before BCR in `.bazelrc`. |
| No matching libclang toolchain | Register `//bazel/toolchains:my_libclang_toolchain` via `--extra_toolchains`. |
| `@llvm_toolchain` unknown | `use_repo(llvm, "llvm_toolchain", "llvm_toolchain_llvm")` in MODULE.bazel. |
| `ScoreReq` import fails | `bazel_dep(name = "trlc", ...)` missing. |

## Related skills

`scorekit-seooc`, `scorekit-coverage`, `scorekit-ci`.
