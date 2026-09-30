# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: BUILD (root package, next to dependable_element)

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "dependability_analysis",
)

dependability_analysis(
    name = "dependability_analysis",
    arch_design = ":my_arch",
    fmea = ["//safety_analysis:fmea"],
    # maturity = "development",  # missing traceability links become warnings
)

# dependable_element(..., dependability_analysis = [":dependability_analysis"], ...)
