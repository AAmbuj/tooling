# S-CORE Copilot Pack

A self-contained, **offline** set of GitHub Copilot customizations for working with the
`rules_score` Bazel rules: one router agent and eight specialized skills.

Nothing in this pack calls out to a network, a Bazel registry, or `score_tooling`. Unpack it
once, install it, use it forever. Re-install only when you want a newer version.

## Contents

```
score-copilot-pack/
├── agents/
│   └── score-tooling.agent.md    router: picks exactly one skill per task
├── prompts/
│   ├── score-safety-analysis-review.prompt.md    review an existing FMEA
│   └── score-safety-analysis-rollout.prompt.md   create/extend an FMEA
├── skills/
│   ├── score-onboarding/         MODULE.bazel, toolchains, first SEooC scaffold
│   ├── score-requirements/       requirement content, levels, ASIL, allocation
│   ├── score-trlc/               .trlc / .rsl syntax + ScoreReq field tables
│   ├── score-architecture/       component/unit decomposition, validators
│   ├── score-plantuml/           .puml conventions, parser CLI, clickable diagrams
│   ├── score-testing/            GoogleTest traceability, coverage lock
│   ├── score-safety-analysis/    FMEA, FailureMode / ControlMeasure, FTA
│   └── score-docs/               .rst authoring, page placement, glossary
├── install.sh
└── INSTALL.md
```

## Install

### Personal — available in every workspace (recommended)

```bash
./install.sh
```

Copies agents to `~/.copilot/agents/`, prompts to `~/.config/Code/User/prompts/` and skills to
`~/.copilot/skills/`.

### Workspace — committed, shared with the team

```bash
./install.sh --workspace /path/to/your/repo
```

Copies to `<repo>/.github/agents/`, `<repo>/.github/prompts/` and `<repo>/.github/skills/`,
which you then commit.

### Manual

Copy the directories yourself:

| Source | Personal destination | Workspace destination |
|--------|---------------------|-----------------------|
| `agents/*.agent.md` | `~/.copilot/agents/` | `<repo>/.github/agents/` |
| `prompts/*.prompt.md` | `~/.config/Code/User/prompts/` | `<repo>/.github/prompts/` |
| `skills/score-*/` | `~/.copilot/skills/` | `<repo>/.github/skills/` |

Keep each skill's folder intact — `SKILL.md` must stay next to its `reference/` and
`templates/` subdirectories.

Reload the VS Code window after installing.

## Use

**Pick the agent.** Open Chat, choose **score-tooling** from the agent picker, and describe the
work product you want. The agent classifies the task and loads exactly one skill, which keeps
each request small and cheap.

**Or invoke a skill directly.** Type `/` in Chat and pick the skill by name, e.g.
`/score-plantuml`, when you already know which one you need.

**Or run a prompt.** Prompts are single, focused tasks and also appear after `/`:

| Prompt | Does |
|--------|------|
| `/score-safety-analysis-review` | Reviews an existing FMEA for coverage, traceability and reasoning quality, and reports findings by severity. Read-only unless you ask for fixes. |
| `/score-safety-analysis-rollout` | Walks the public API with HAZOP guide words, gets your sign-off on the safety judgements, then writes the `FailureMode` records, FTAs, measures and BUILD wiring. |

**Or say nothing special.** Copilot loads a skill automatically when your request matches its
description.

### What to ask for

| Your request | What loads |
|--------------|------------|
| "Set this repo up for rules_score" | `score-onboarding` |
| "Add a component requirement for the read operation" | `score-requirements` |
| "Fix this trlc parse error" | `score-trlc` |
| "Split this component into two units" | `score-architecture` |
| "The static design diagram fails validation" | `score-plantuml` |
| "Trace this GoogleTest case to COMP_001" | `score-testing` |
| "Add a failure mode for GetNumber" | `score-safety-analysis` |
| "Write the design page for unit_1" | `score-docs` |

## Updating

This pack is a snapshot. To move to a newer one, re-run `install.sh` with the new pack —
it overwrites in place and removes `score-*` assets that the new pack no longer contains.

If your repository already builds with Bazel and depends on `score_tooling`, prefer the
automated route instead:

```starlark
load("@score_tooling//skills_sync:sync_skills.bzl", "sync_skills")

sync_skills()
```

```bash
bazel run  //:sync_skills        # pull the current assets
bazel test //:sync_skills.check  # CI guard against drift
```

## Troubleshooting

**The agent does not appear in the picker.** Reload the window. Check that the file is at
`~/.copilot/agents/score-tooling.agent.md` (not nested one level deeper) and that its YAML
frontmatter is intact — the first line must be exactly `---`.

**A skill never loads.** Skill folder name must match the `name:` in its `SKILL.md`. Verify
`~/.copilot/skills/score-plantuml/SKILL.md` exists, not `.../score-plantuml/score-plantuml/SKILL.md`.

**The agent gives advice that does not match your rules.** The skills describe `rules_score` as
of the version this pack was cut from. The rule sources always win — the agent is instructed to
read `bazel/rules/rules_score/private/` when an attribute is in doubt.
