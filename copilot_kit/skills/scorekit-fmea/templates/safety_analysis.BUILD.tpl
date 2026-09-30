# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: safety_analysis/BUILD

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "fmea",
)

# One fta_<failure_mode>.puml per FailureMode record, sorted alphabetically.
filegroup(
    name = "fta_files",
    srcs = [
        "fta_fm_dowork_loss.puml",
    ],
)

fmea(
    name = "fmea",
    arch_design = "//:my_arch",
    controlmeasures = ["control_measures.trlc"],
    failuremodes = ["failure_modes.trlc"],
    root_causes = [":fta_files"],
    visibility = ["//visibility:public"],
)
