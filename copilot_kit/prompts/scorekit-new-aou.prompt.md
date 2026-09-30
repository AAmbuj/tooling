---
description: "Add an Assumption of Use (AoU) for the integrator, or handle/forward an AoU received from a dependency."
agent: "scorekit-router"
argument-hint: "obligation text or received AoU ID"
---
Follow skill `scorekit-aou`.

- Obligation or received AoU: ${input:aou:New obligation text, or Package.AOU_ID received from a dependency}
- ASIL: ${input:asil:QM, B or D}

If it is a new obligation: phrase it as a verifiable integrator obligation, add it to the
`assumptions_of_use` target, and link it via `mitigates` if it closes a failure mode.
If it is received: ask me whether to handle it (derive a CompReq) or forward it
(`aou_forwarding.yaml` with justification), then implement that choice.
Validate with `bazel test` and report.
