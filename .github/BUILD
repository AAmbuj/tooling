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

package(default_visibility = ["//visibility:public"])

# Copilot agents shared with downstream repositories. As for skills, only the
# "score-*" naming convention is distributed; anything else stays local.
filegroup(
    name = "agents",
    srcs = glob(
        ["agents/score-*.agent.md"],
        allow_empty = True,
    ),
)

filegroup(
    name = "prompts",
    srcs = glob(
        ["prompts/score-*.prompt.md"],
        allow_empty = True,
    ),
)

# Everything score_tooling ships into a downstream repository's .github
# directory via //:sync_skills.
filegroup(
    name = "copilot_assets",
    srcs = [
        ":agents",
        ":prompts",
        "//.github/skills",
    ],
)

# Offline distribution: a self-contained tarball of the agents and skills plus
# an installer, for users who cannot (or do not want to) build with Bazel.
#   bazel build //.github:copilot_pack
genrule(
    name = "copilot_pack",
    srcs = [
        "pack/INSTALL.md",
        "pack/install.sh",
        ":copilot_assets",
    ],
    outs = ["score-copilot-pack.tar.gz"],
    cmd = "$(execpath //skills_sync:make_pack.sh) $@ " +
          "$(execpath pack/INSTALL.md) $(execpath pack/install.sh) " +
          "$(locations :copilot_assets)",
    tools = ["//skills_sync:make_pack.sh"],
)
