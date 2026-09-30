# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: BUILD (root package; design/ holds only .puml files, no BUILD)

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "architectural_design",
    "unit_design",
)

architectural_design(
    name = "my_arch",
    static = ["design/static_design.puml"],
    public_api = ["design/public_api.puml"],
    # dynamic = ["design/dynamic_design.puml"],
    # internal_api = ["design/internal_api.puml"],
    # maturity = "development",  # findings become warnings
    visibility = ["//visibility:public"],
)

unit_design(
    name = "my_unit_design",
    static = ["design/class_design.puml"],
)
