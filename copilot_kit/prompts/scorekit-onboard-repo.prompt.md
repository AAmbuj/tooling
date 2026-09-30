---
description: "Onboard this Bazel repository onto score_tooling (MODULE.bazel, registry, libclang toolchain) and scaffold a minimal SEooC that builds."
agent: "scorekit-router"
argument-hint: "score_tooling version"
---
Follow skill `scorekit-onboarding` with score_tooling version `${input:version:e.g. 1.2.0 or local_path_override path}`.

1. Inspect `MODULE.bazel`, `.bazelrc`, `.bazelversion`; list the required additions; confirm.
2. Apply them and add `bazel/toolchains/BUILD` (libclang).
3. Scaffold a minimal element (`scorekit-seooc` templates) with `maturity = "development"`.
4. Run `bazel build //...` and `bazel test //...`; report results.
