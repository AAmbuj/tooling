---
description: "Annotate GoogleTest cases with lobster-tracing and given/when/then for component requirements and refresh the test_case_coverage lock."
agent: "scorekit-router"
argument-hint: "test file or component"
---
Follow skill `scorekit-lobster-tracing` for `${input:target:test file or component target}`.

1. Map each test to the CompReq(s) it verifies; list unmapped tests and untested CompReqs.
2. Add `RecordProperty` calls (`lobster-tracing`, `given`, `when`, `then`) — confirm mapping first.
3. Ensure `test_case_coverage_lock` is set; run `bazel run //<pkg>:<component>.update`;
   show the lock diff; run `bazel test //...`.
