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
# Builds the offline "score-copilot-pack" archive: a self-contained tarball of
# score_tooling's Copilot agents and skills that a user can unpack and install
# without Bazel, a network, or a dependency on score_tooling.
#
# Usage:
#   make_pack.sh <output.tar.gz> <INSTALL.md> <install.sh> <asset-files...>
#
# "asset-files" are the paths of the files contained in
# @score_tooling//.github:copilot_assets; each is staged at its path relative
# to the .github directory (e.g. "skills/score-trlc/SKILL.md").

set -euo pipefail

PACK_NAME="score-copilot-pack"
GITHUB_DIR=".github"

out="$1"
install_md="$2"
install_sh="$3"
shift 3

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

root="${stage}/${PACK_NAME}"
mkdir -p "$root"

cp "$install_md" "${root}/INSTALL.md"
cp "$install_sh" "${root}/install.sh"
chmod +x "${root}/install.sh"

for f in "$@"; do
    case "$f" in
        *"${GITHUB_DIR}/"*) rel="${f#*${GITHUB_DIR}/}" ;;
        *)
            echo "error: path '$f' does not contain '${GITHUB_DIR}/'" >&2
            exit 2
            ;;
    esac
    dest="${root}/${rel}"
    mkdir -p "$(dirname "$dest")"
    cp -f "$f" "$dest"
done

# Deterministic archive so rebuilds are byte-identical.
tar --sort=name \
    --mtime="UTC 2020-01-01" \
    --owner=0 --group=0 --numeric-owner \
    -czf "$out" \
    -C "$stage" "$PACK_NAME"
