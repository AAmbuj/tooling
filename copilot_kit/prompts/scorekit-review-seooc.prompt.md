---
description: "Review a complete SEooC, folder, or pull request (requirements, architecture, tests, full safety analysis) and report severity-ranked findings. Read-only."
agent: "scorekit-seooc-engineer"
argument-hint: "dependable_element label, folder, or PR"
---
Mode: **review** (read-only). Follow skill `scorekit-seooc-review`.

- Target: ${input:target:dependable_element label, a folder, or a PR reference}

Run the machine checks, walk the full checklist, and produce the findings report. Do not modify
any file.
