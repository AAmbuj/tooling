---
description: "Implement a complete SEooC end to end (requirements, architecture, units, tests, FailureModes, FTAs, RootCause closure, AoUs, dependable_element) with validation gates and a final self-review."
agent: "scorekit-seooc-engineer"
argument-hint: "requirement source, module, ASIL"
---
Mode: **implement**. Follow skill `scorekit-seooc-implement`.

- Source: ${input:source:Requirement text, file path, or ticket/requirement IDs}
- Module / element name: ${input:module:dependable_element name}
- Safety goal ASIL / integrity level: ${input:asil:e.g. ASIL B / integrity level B}

Start with Stage 0 (intake): summarise the source, list assumptions and open questions, and
wait for my confirmation before creating files.
