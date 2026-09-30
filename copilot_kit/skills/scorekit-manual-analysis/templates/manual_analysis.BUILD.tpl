# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: <package>/BUILD

load("@score_tooling//manual_analysis:context_from_cc_library.bzl", "manual_analysis_context_from_cc_library")
load("@score_tooling//manual_analysis:manual_analysis.bzl", "manual_analysis")

manual_analysis_context_from_cc_library(
    name = "my_unit_context",
    library = "//:my_unit_lib",
)

manual_analysis(
    name = "my_unit_review",
    analysis = "analysis.yaml",
    contexts = [":my_unit_context"],
    lock_file = "my_unit_review.lock",
    results_file = "results.json",
)
