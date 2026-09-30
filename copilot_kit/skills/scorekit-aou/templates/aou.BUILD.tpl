# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: docs/BUILD

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "assumptions_of_use",
)

assumptions_of_use(
    name = "assumptions_of_use",
    srcs = ["aous.trlc"],
    visibility = ["//visibility:public"],
)
