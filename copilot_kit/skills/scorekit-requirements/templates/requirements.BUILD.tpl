# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: requirements/BUILD

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "assumed_system_requirements",
    "component_requirements",
    "feature_requirements",
)

assumed_system_requirements(
    name = "assumed_system_requirements",
    srcs = ["asr.trlc"],
    visibility = ["//visibility:public"],
)

feature_requirements(
    name = "feature_requirements",
    srcs = ["feature_requirements.trlc"],
    visibility = ["//visibility:public"],
    deps = [":assumed_system_requirements"],
)

component_requirements(
    name = "component_requirements",
    srcs = ["component_requirements.trlc"],
    visibility = ["//visibility:public"],
    deps = [
        ":assumed_system_requirements",
        ":feature_requirements",
        # Add AoU targets whose records are referenced in derived_from, e.g.
        # "//docs:assumptions_of_use" or "@other_module//:other_aous".
    ],
)
