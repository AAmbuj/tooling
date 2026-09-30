---
name: scorekit-lobster-tracing
description: "Requirement-to-test and requirement-to-code traceability (LOBSTER) with score_tooling in a consumer repository. USE FOR: annotating GoogleTest cases with RecordProperty lobster-tracing + given/when/then, attaching tests to unit/component/dependable_element, the test_case_coverage.lock.yaml workflow (bazel run :<component>.update vs bazel test drift check), maturity-dependent enforcement, source-code tracing tags (// lobster-trace: ID) with lobster_linker, reading traceability failures. DO NOT USE FOR: writing requirements (scorekit-requirements), FMEA/FTA links (scorekit-fmea, scorekit-fta), coverage percentages (scorekit-coverage). INVOKES: templates/my_unit_test.cpp, templates/test_case_coverage.lock.yaml, templates/lobster_linker.BUILD.tpl."
argument-hint: "test file, component, or traceability error"
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

# LOBSTER traceability

```
FeatReq ◄─ CompReq ◄─ GoogleTest case (RecordProperty "lobster-tracing")
                 ▲
                 └── component(requirements=...)   (architecture allocation, automatic)
test_case_coverage.lock.yaml  = committed coverage claim, compared on every bazel test
```

## 1. Annotate tests

Template: [templates/my_unit_test.cpp](templates/my_unit_test.cpp)

```cpp
TEST(MyUnitTest, DoWorkReturnsResult) {
  ::testing::Test::RecordProperty("lobster-tracing", "MyModule.COMP_001");
  ::testing::Test::RecordProperty("given", "a default-constructed MyUnit");
  ::testing::Test::RecordProperty("when", "DoWork is called once");
  ::testing::Test::RecordProperty("then", "it returns 1");
  ...
}
```

| Property | Required | Notes |
|----------|----------|-------|
| `lobster-tracing` | yes | One or more `Package.Record` IDs separated by spaces. Tests without it are not traced. |
| `given` / `when` / `then` | yes in `release` | Missing GWT is an error in `release`, a warning in `development`. |

Trace tests to `CompReq` (component level). Tests may also reference `FeatReq` IDs when those
are listed in the component's `requirements`.

## 2. Attach tests

| Level | Attribute | Scope |
|-------|-----------|-------|
| `unit` | `unit(tests = [":my_unit_test"])` | unit tests |
| `component` | `component(tests = [...])` | integration tests of its units |
| `dependable_element` | `dependable_element(tests = [...])` | system tests |

## 3. Lock file

```starlark
component(
    name = "my_component",
    components = [":my_unit"],
    requirements = ["//requirements:component_requirements"],
    test_case_coverage_lock = "test_case_coverage.lock.yaml",
)
```

1. Create an empty `test_case_coverage.lock.yaml` and set the attribute.
2. `bazel run //:my_component.update` → rewrites the lock from current test results.
3. Review `git diff` (this is the coverage claim) and commit.
4. `bazel test //...` recomputes and fails on drift (new/removed test, changed GWT text,
   requirement version bump).

Format reference: [templates/test_case_coverage.lock.yaml](templates/test_case_coverage.lock.yaml).
UIDs are `//<bazel_package>/<Suite>:<Test>`. Never hand-edit; re-run `.update`.

## 4. Maturity

`dependable_element(maturity = ...)`:

| Value | Effect |
|-------|--------|
| `development` | Lock drift, missing GWT and missing trace links are warnings. |
| `release` (default) | All of the above fail build/test. Required before certification. |

## 5. Source-code tracing (optional, standalone)

Tag lines **at the start of a line** (not trailing):

```cpp
// lobster-trace: MyModule.COMP_001
int MyUnit::DoWork() { ... }
```

Comment sign per language: `//` for C/C++/Rust, `#` for Python/Starlark/TRLC.
Collect with `lobster_linker` ([templates/lobster_linker.BUILD.tpl](templates/lobster_linker.BUILD.tpl)):

```starlark
load("@score_tooling//lobster_bazel:lobster_bazel.bzl", "lobster_linker")
lobster_linker(name = "impl_trace", srcs = ["//:my_unit_lib"])   # tag default: lobster-trace
```

The output is a `.lobster` file + `LobsterProvider` for your own `lobster_test` configuration.
`rules_score` itself does not require source tags; test and allocation links are enough.

## Validate

```bash
bazel test //...                       # tests + lock drift + element traceability
bazel test //:my_element               # element-level lobster report
bazel run  //:my_component.update      # after intended test changes
```

## Error lookup

| Symptom | Fix |
|---------|-----|
| Lock drift / coverage mismatch | Intended change → `bazel run //:<component>.update`, review, commit. |
| Requirement not covered by tests | Add a test with `lobster-tracing` = its ID, or check the ID spelling. |
| `.update` target missing | Set `test_case_coverage_lock` on the `component`. |
| Test ID unresolved | The requirement target must be in `component(requirements=...)`. |
| Missing given/when/then | Add all three `RecordProperty` calls in the test body. |

## Related skills

`scorekit-requirements`, `scorekit-seooc`, `scorekit-coverage`, `scorekit-seooc-review`.
