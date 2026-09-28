# *******************************************************************************
# Copyright (c) 2026 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************

"""Macro that lets downstream repositories pull score_tooling's shared Copilot assets."""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

# Files shipped by score_tooling under .github. Only skill directories and
# agent files following the "score-*" naming convention are distributed to
# downstream repositories.
_TOOLING_ASSETS = "@score_tooling//.github:copilot_assets"

def sync_skills(name = "sync_skills"):
    """Registers targets to pull and verify score_tooling's shared Copilot assets.

    Adds two targets to the calling package (expected to be the repository
    root, next to .github):

    - `<name>`: a runnable target (`bazel run //:sync_skills`) that copies
      score_tooling's "score-*" skill directories into the local
      `.github/skills` directory and its "score-*.agent.md" agents into
      `.github/agents`, overwriting outdated copies and removing assets that
      score_tooling no longer ships.
    - `<name>.check`: a `bazel test` target that fails when the committed
      `.github/skills/score-*` directories or `.github/agents/score-*.agent.md`
      files are missing, out of date, or stale relative to the version of
      score_tooling currently in use. Wire this target into CI so upstream
      updates are caught automatically.

    Note: a single target cannot serve both purposes, because `bazel run` on
    an `sh_test` target still executes through Bazel's test-setup.sh wrapper,
    which sets $TEST_TMPDIR the same as a real `bazel test` invocation - there
    is no reliable way to distinguish "run" from "test" from inside the script.

    Args:
        name: Name of the runnable sync target. Defaults to "sync_skills".
    """
    repo_asset_files = native.glob(
        [
            ".github/skills/score-*/**",
            ".github/agents/score-*.agent.md",
            ".github/prompts/score-*.prompt.md",
        ],
        allow_empty = True,
    )

    sh_binary(
        name = name,
        srcs = ["@score_tooling//skills_sync:sync_skills.sh"],
        args = [
            "sync",
            "$(locations {})".format(_TOOLING_ASSETS),
        ],
        data = [_TOOLING_ASSETS],
    )

    sh_test(
        name = name + ".check",
        srcs = ["@score_tooling//skills_sync:sync_skills.sh"],
        args = [
            "check",
            "$(locations {})".format(_TOOLING_ASSETS),
            "--",
        ] + repo_asset_files,
        data = [_TOOLING_ASSETS] + repo_asset_files,
    )
