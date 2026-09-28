# PlantUML parser CLI

Binary: `//plantuml/parser:parser` (Rust, `puml_cli`). `rules_score` invokes it automatically;
run it by hand only to reproduce a parse error outside Bazel.

```bash
bazel run //plantuml/parser:parser -- \
    --file $PWD/design/static_design.puml \
    --diagram-type component \
    --fbs-output-dir /tmp/out \
    --log-level debug
```

Paths must be absolute or relative to the runfiles cwd — pass `$PWD/...` to be safe.

## Flags

At least one of `--file` or `--folders` is required.

| Flag | Values | Default | Purpose |
|------|--------|---------|---------|
| `--file <FILE>` | repeatable | — | Input `.puml` file(s) |
| `--folders <DIR>` | path | — | Scan a folder for `.puml` files |
| `--diagram-type` | `none`, `activity`, `component`, `deployment`, `class`, `sequence` | `none` | Type hint; `none` auto-detects |
| `--log-level` | `error`, `warn`, `info`, `debug`, `trace` | `warn` | Verbosity |
| `--fbs-output-dir <DIR>` | path | — | Emit `<stem>.fbs.bin` FlatBuffers model |
| `--lobster-output-dir <DIR>` | path | — | Emit `<stem>.lobster` traceability (component/class only) |
| `--idmap-output-dir <DIR>` | path | — | Emit `<stem>.idmap.json` sidecar for clickable links |
| `--fta-output-dir <DIR>` | path | — | FTA mode: emit metamodel-inlined `.puml`, `root_causes.lobster`, `fta_chains.json` |
| `--source-name <PATH>` | path | derived from input | Workspace-relative source path stamped into idmap/fbs; required for cross-diagram link matching |
| `--output-stem <STEM>` | single path component | input basename | Override output filename stem |

Constraints:

- `--source-name` and `--output-stem` each require exactly one input file, and `--output-stem`
  must be a single component (no `/`, `.` or `..`).
- `--fta-output-dir` is exclusive with `--fbs-output-dir`, `--lobster-output-dir`,
  `--source-name` and `--output-stem`.

## What the rules actually run

`architectural_design` → `--fbs-output-dir --lobster-output-dir --idmap-output-dir --source-name --output-stem`

`unit_design` → `--fbs-output-dir --idmap-output-dir` (no lobster)

`fmea` → `--fta-output-dir`

Implementations: [`bazel/rules/rules_score/private/architectural_design.bzl`](../../../../bazel/rules/rules_score/private/architectural_design.bzl),
[`unit_design.bzl`](../../../../bazel/rules/rules_score/private/unit_design.bzl), [`fmea.bzl`](../../../../bazel/rules/rules_score/private/fmea.bzl).
