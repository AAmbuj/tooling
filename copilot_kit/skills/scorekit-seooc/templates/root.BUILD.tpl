# Copyright (c) <YEAR> <COPYRIGHT HOLDER>
# SPDX-License-Identifier: Apache-2.0
# Destination: BUILD (root package)
#
# Names below must equal the aliases in design/static_design.puml:
#   my_element <<SEooC>>  >  my_component <<component>>  >  my_unit <<unit>>

load(
    "@score_tooling//bazel/rules/rules_score:rules_score.bzl",
    "architectural_design",
    "component",
    "dependability_analysis",
    "dependable_element",
    "unit",
    "unit_design",
)

architectural_design(
    name = "my_arch",
    public_api = ["design/public_api.puml"],
    static = ["design/static_design.puml"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "my_unit_lib",
    srcs = ["src/my_unit.cpp"],
    hdrs = ["src/my_unit.h"],
)

cc_test(
    name = "my_unit_test",
    srcs = ["src/my_unit_test.cpp"],
    deps = [
        ":my_unit_lib",
        "@googletest//:gtest_main",
    ],
)

unit_design(
    name = "my_unit_design",
    static = ["design/class_design.puml"],
)

unit(
    name = "my_unit",
    implementation = [":my_unit_lib"],
    scope = ["//:my_unit_lib"],
    tests = [":my_unit_test"],
    unit_design = [":my_unit_design"],
)

component(
    name = "my_component",
    components = [":my_unit"],
    requirements = [
        "//requirements:component_requirements",
        "//requirements:feature_requirements",
    ],
    test_case_coverage_lock = "test_case_coverage.lock.yaml",
    tests = [],
)

dependability_analysis(
    name = "dependability_analysis",
    arch_design = ":my_arch",
    fmea = ["//safety_analysis:fmea"],
)

dependable_element(
    name = "my_element",
    architectural_design = [":my_arch"],
    assumptions_of_use = ["//docs:assumptions_of_use"],
    components = [":my_component"],
    dependability_analysis = [":dependability_analysis"],
    glossary = ["//docs:glossary"],
    integrity_level = "B",
    maturity = "development",  # switch to "release" before certification
    requirements = ["//requirements:feature_requirements"],
    tests = [],
    # deps = ["@other_module//:other_element"],
    # aou_forwarding = "aou_forwarding.yaml",
)
