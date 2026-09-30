---
description: "Review a GitHub pull request that changes S-CORE work products (requirements, diagrams, tests, safety analysis) against linked Jira/Codebeamer items. Read-only; comments are drafted, not posted."
agent: "scorekit-seooc-engineer"
argument-hint: "PR URL or owner/repo#number"
---
Mode: **review** (read-only).

- Pull request: ${input:pr:PR URL or owner/repo#number}

1. Read the PR (metadata, changed files, diff, CI status) via the GitHub MCP server.
2. If the PR or its Jira ticket references Codebeamer/Jira items, read them (`scorekit-alm-intake`)
   and check they are fully covered by the change.
3. Follow `scorekit-seooc-review` for the changed work products and their trace chain.
4. Output the findings table plus drafted review comments (file, line, text).
   Post nothing until I confirm each comment.
