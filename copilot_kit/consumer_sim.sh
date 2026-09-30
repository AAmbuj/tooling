#!/usr/bin/env bash

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
#
# Assembles the kit's templates into a throw-away consumer module that depends on
# this score_tooling checkout (local_path_override) and runs `bazel test //...`,
# proving the templates build outside score_tooling.
#
# Usage: consumer_sim.sh [workdir]   (default: a new temp dir; kept for inspection)

set -euo pipefail

KIT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TOOLING="$(cd "${KIT}/.." && pwd)"
SK="${KIT}/skills"
WS="${1:-$(mktemp -d /tmp/scorekit_consumer.XXXXXX)}"

mkdir -p "$WS"/{bazel/toolchains,design,docs,requirements,safety_analysis,src}

{
    echo 'module(name = "scorekit_consumer_sim", version = "0.0.0")'
    echo ""
    sed 's|version = "<score_tooling version>"|version = "0.0.0"|' "${SK}/scorekit-onboarding/templates/MODULE.bazel.snippet"
    echo ""
    echo "local_path_override(module_name = \"score_tooling\", path = \"${TOOLING}\")"
} >"${WS}/MODULE.bazel"
cp "${SK}/scorekit-onboarding/templates/bazelrc.snippet" "${WS}/.bazelrc"
cp "${TOOLING}/bazel/rules/rules_score/examples/minimal/.bazelversion" "${WS}/.bazelversion"
cp "${SK}/scorekit-onboarding/templates/toolchains.BUILD.tpl" "${WS}/bazel/toolchains/BUILD"

cp "${SK}/scorekit-seooc/templates/root.BUILD.tpl" "${WS}/BUILD"
cp "${SK}/scorekit-plantuml/templates/"{static_design,public_api,class_design}.puml "${WS}/design/"
cp "${SK}/scorekit-seooc/templates/my_unit."{h,cpp} "${WS}/src/"
cp "${SK}/scorekit-lobster-tracing/templates/my_unit_test.cpp" "${WS}/src/"
cp "${SK}/scorekit-lobster-tracing/templates/test_case_coverage.lock.yaml" "${WS}/"

cp "${SK}/scorekit-requirements/templates/"{asr,feature_requirements,component_requirements}.trlc "${WS}/requirements/"
cp "${SK}/scorekit-requirements/templates/requirements.BUILD.tpl" "${WS}/requirements/BUILD"

cp "${SK}/scorekit-aou/templates/aous.trlc" "${WS}/docs/"
cp "${SK}/scorekit-seooc/templates/glossary.rst" "${WS}/docs/"
cp "${SK}/scorekit-seooc/templates/docs.BUILD.tpl" "${WS}/docs/BUILD"

cp "${SK}/scorekit-fmea/templates/"{failure_modes,safetymeasures}.trlc "${WS}/safety_analysis/"
cp "${SK}/scorekit-fmea/templates/safety_analysis.BUILD.tpl" "${WS}/safety_analysis/BUILD"
cp "${SK}/scorekit-fta/templates/fta_template.puml" "${WS}/safety_analysis/fta_fm_dowork_loss.puml"

echo "Consumer module assembled in ${WS}"
cd "$WS"
bazel test //... --test_output=errors
