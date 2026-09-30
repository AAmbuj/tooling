---
description: "Add a component requirement (CompReq) derived from a FeatReq/ASR/received AoU, allocate it to a component, and add a traced test."
agent: "scorekit-router"
argument-hint: "behaviour, parent ID, component"
---
Add a `ScoreReq.CompReq` following skills `scorekit-requirements` and `scorekit-lobster-tracing`.

- Behaviour: ${input:behaviour:What must the component do?}
- Parent(s): ${input:parent:Package.FEAT_ID or Package.AOU_ID}
- Component: ${input:component:Bazel component target}

Steps:
1. Locate the component's `component_requirements` file (one file per component). Propose text
   and ID; confirm with me.
2. Write the record (`derived_from` pinned to the parent's current version).
3. Add or extend a GoogleTest with `RecordProperty("lobster-tracing", "<Pkg>.<ID>")` and
   given/when/then.
4. `bazel run //<pkg>:<component>.update`, show me the lock diff, then `bazel test //...`.
