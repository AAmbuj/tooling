---
description: "Make an element in a rendered architecture/FTA diagram clickable, or explain why a link is missing or wrong."
agent: "scorekit-router"
argument-hint: "diagram file and element alias"
---
Follow skill `scorekit-clickable-plantuml`.

- Diagram: ${input:diagram:path/to/diagram.puml}
- Element: ${input:element:alias that should link}

Find which diagrams define and reference the alias, explain the current link resolution, propose
the minimal diagram change, apply it after my confirmation, and tell me how to verify with
`bazel run //:<element>.serve`.
