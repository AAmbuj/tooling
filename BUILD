# *******************************************************************************
# Copyright (c) 2025 Contributors to the Eclipse Foundation
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
load("//cr_checker:cr_checker.bzl", "copyright_checker")
load("//third_party/format:macros.bzl", "use_format_targets")

package(default_visibility = ["//visibility:public"])

exports_files([
    "pyproject.toml",
])

copyright_checker(
    name = "copyright",
    # Whole-repo scope via a git exclude-magic pathspec: every file tracked
    # by git is checked except .github/skills and the copilot_kit payload
    # (skills/agents/prompts/instructions/overlays). Those files are
    # distributed verbatim to downstream repos (//:sync_skills,
    # //copilot_kit:install); YAML frontmatter must stay first and templates
    # carry the consumer's own header placeholder.
    srcs = [
        ":(exclude).github/skills/**",
        ":(exclude)copilot_kit/agents/**",
        ":(exclude)copilot_kit/instructions/**",
        ":(exclude)copilot_kit/overlays/**",
        ":(exclude)copilot_kit/prompts/**",
        ":(exclude)copilot_kit/skills/**",
    ],
    config = "//cr_checker/resources:config",
    exclusion = "//cr_checker/resources:exclusion",
    template = "//cr_checker/resources:templates",
    visibility = ["//visibility:public"],
)

use_format_targets()
