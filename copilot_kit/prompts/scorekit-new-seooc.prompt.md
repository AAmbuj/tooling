---
description: "Scaffold a new minimal dependable_element (SEooC) skeleton: static diagram, unit, component, requirements, element target."
agent: "scorekit-router"
argument-hint: "element name, component and unit names"
---
Follow skill `scorekit-seooc`.

- Element name: ${input:element:dependable_element target name}
- Components/units: ${input:structure:e.g. comp_a(unit_a1, unit_a2)}
- Integrity level: ${input:level:A, B, C or D}

Propose the static diagram first; after my confirmation create the targets 1:1 with
`maturity = "development"`, then run `bazel build //...`.
