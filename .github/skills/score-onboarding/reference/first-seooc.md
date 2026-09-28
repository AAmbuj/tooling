# Your first SEooC

The smallest complete `dependable_element` that builds. Transcribed from
[`bazel/rules/rules_score/examples/minimal`](../../../../bazel/rules/rules_score/examples/minimal) — read that example directly if anything here
looks stale.

## Layout

```
BUILD
MODULE.bazel
.bazelrc
bazel/toolchains/BUILD          libclang_toolchain + toolchain()
requirements/asr.trlc
requirements/feature_requirements.trlc
docs/static_design.puml
docs/class_design.puml
src/my_unit.h
src/my_unit.cpp
src/my_unit_test.cpp
```

## BUILD

```starlark
load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "architectural_design",
    "assumed_system_requirements",
    "component",
    "dependable_element",
    "feature_requirements",
    "unit",
    "unit_design",
)

assumed_system_requirements(
    name = "assumed_system_requirements",
    srcs = ["requirements/asr.trlc"],
)

feature_requirements(
    name = "feature_requirements",
    srcs = ["requirements/feature_requirements.trlc"],
    deps = [":assumed_system_requirements"],
)

architectural_design(
    name = "my_arch",
    static = ["docs/static_design.puml"],
)

cc_library(
    name = "my_unit_lib",
    srcs = ["src/my_unit.cpp"],
    hdrs = ["src/my_unit.h"],
)

cc_test(
    name = "my_unit_test",
    srcs = ["src/my_unit_test.cpp"],
    deps = [
        ":my_unit_lib",
        "@googletest//:gtest_main",
    ],
)

unit_design(
    name = "MyUnit_design",
    static = ["docs/class_design.puml"],
)

unit(
    name = "MyUnit",
    implementation = [":my_unit_lib"],
    scope = ["//:my_unit_lib"],
    tests = [":my_unit_test"],
    unit_design = [":MyUnit_design"],
)

component(
    name = "MyComponent",
    components = [":MyUnit"],
    requirements = [],
    tests = [],
)

dependable_element(
    name = "my_element",
    architectural_design = [":my_arch"],
    assumptions_of_use = [],
    components = [":MyComponent"],
    dependability_analysis = [],
    integrity_level = "B",
    requirements = [":feature_requirements"],
    tests = [],
)
```

Note the shape: a `unit` is never attached to the `dependable_element` directly — it is wrapped
in a `component`, and the component is listed in `components`.

## Order of work, and who does it

| Step | Produces | Skill to load |
|------|----------|---------------|
| 0 | empty `dependable_element` with `maturity = "development"` | this skill |
| 1 | `AssumedSystemReq`, `FeatReq`, `CompReq`, `AoU` | `score-requirements` (syntax: `score-trlc`) |
| 2 | static / dynamic / API diagrams, `component` and `unit` tree | `score-architecture` (syntax: `score-plantuml`) |
| 3 | implementation, unit and integration tests, coverage lock | `score-testing` |
| 4 | `FailureMode`, FTA, `ControlMeasure` | `score-safety-analysis` (FTA syntax: `score-plantuml`) |
| 5 | narrative pages, glossary | `score-docs` |
| 6 | flip `maturity` to `"release"` | this skill |

Complete, non-trivial reference: [`bazel/rules/rules_score/examples/seooc`](../../../../bazel/rules/rules_score/examples/seooc).
Multi-SEooC integration: [`bazel/rules/rules_score/examples/integrator`](../../../../bazel/rules/rules_score/examples/integrator).

## Tutorial

[`bazel/rules/rules_score/docs/user_guide/tutorial/`](../../../../bazel/rules/rules_score/docs/user_guide/tutorial) walks the same path in prose:
`setup`, `requirements`, `architecture`, `unit_design`, `build`, `validation`.
