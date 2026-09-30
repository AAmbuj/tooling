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

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

filegroup(
    name = "kit",
    srcs = ["VERSION"] + glob([
        "agents/**",
        "instructions/**",
        "overlays/**",
        "prompts/**",
        "skills/**",
    ]),
    visibility = ["//visibility:public"],
)

# bazel run @score_tooling//copilot_kit:install -- --repo "$PWD" [options]
sh_binary(
    name = "install",
    srcs = ["install.sh"],
    data = [":kit"],
    visibility = ["//visibility:public"],
)

sh_test(
    name = "install_test",
    size = "small",
    srcs = ["install_test.sh"],
    data = [
        "install.sh",
        ":kit",
    ],
)
