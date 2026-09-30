---
description: "Add a new feature requirement (FeatReq) derived from an AssumedSystemReq, with ASIL and version pin, and wire it in Bazel."
agent: "scorekit-router"
argument-hint: "feature need, parent ASR ID, ASIL"
---
Add a `ScoreReq.FeatReq` following skill `scorekit-requirements`.

- Need: ${input:need:What must the feature do?}
- Parent AssumedSystemReq: ${input:parent:Package.ASR_ID (leave empty to propose one)}
- ASIL: ${input:asil:QM, B or D}

Steps:
1. Find the feature requirements file and its package; propose the requirement text (atomic,
   verifiable, "shall") and ID; confirm with me.
2. Write the record with `derived_from = [<parent>@<current version>]`, `version = 1`.
3. Ensure the target's `deps` include the parent's target.
4. Run `bazel test` on the requirements package and report the result.
