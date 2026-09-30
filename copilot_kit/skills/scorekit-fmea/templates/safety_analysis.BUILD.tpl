# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: safety_analysis/BUILD

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "safety_analysis",
)

# List every FTA input in sorted order.
filegroup(
    name = "fta_files",
    srcs = [
        "fta_fm_dowork_loss.puml",
    ],
)

safety_analysis(
    name = "safety_analysis",
    arch_design = "//:my_arch",
    failuremodes = ["failure_modes.trlc"],
    root_causes = [":fta_files"],
    safetymeasures = ["safetymeasures.trlc"],
    visibility = ["//visibility:public"],
)
