---
description: "Implement an SEooC (incl. full safety analysis) from a Codebeamer requirement and Jira ticket: read both via MCP first, confirm, then implement with validation gates."
agent: "scorekit-seooc-engineer"
argument-hint: "Codebeamer item ID and Jira key"
---
Mode: **implement**.

- Codebeamer item(s): ${input:cbId:Codebeamer item ID(s) or URL}
- Jira ticket: ${input:jiraKey:Jira key, e.g. ABC-123}
- Target element: ${input:module:dependable_element name (new or existing)}

1. Follow skill `scorekit-alm-intake`: read the Codebeamer item(s) with links and link types and
   the Jira ticket with acceptance criteria. Summarise, propose the TRLC mapping, list
   ambiguities, and **wait for my confirmation**.
2. Then follow `scorekit-seooc-implement` from Stage 1.
3. Do not write to Codebeamer or Jira.
