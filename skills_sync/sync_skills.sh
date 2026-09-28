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
# Syncs (or checks the sync status of) the Copilot assets that score_tooling
# ships under .github - the "score-*" skill directories under .github/skills,
# the "score-*.agent.md" agents under .github/agents and the
# "score-*.prompt.md" prompts under .github/prompts - into a downstream
# repository's own .github directory.
#
# Usage:
#   sync_skills.sh sync  <tooling-asset-files...>
#   sync_skills.sh check <tooling-asset-files...> -- <repo-asset-files...>
#
# "tooling-asset-files" are the runfiles paths of the files contained in
# @score_tooling//.github:copilot_assets (i.e. the upstream, canonical copies).
# "repo-asset-files" (check mode only) are the paths, relative to the
# downstream repository root, of the corresponding files currently committed
# in that repository.

set -euo pipefail

GITHUB_DIR=".github"
SKILLS_SUBDIR="skills"

# Asset directories holding individual files rather than skill directories,
# as "<subdir>:<glob marking a distributed file>".
FLAT_ASSETS=(
    "agents:score-*.agent.md"
    "prompts:score-*.prompt.md"
)

die() {
    echo "error: $*" >&2
    exit 2
}

# Given an absolute/runfiles path to a file inside a "*/.github/..." tree,
# prints the path relative to the .github directory, e.g.
# ".../external/score_tooling+/.github/skills/score-testing/SKILL.md"
# becomes "skills/score-testing/SKILL.md".
relative_asset_path() {
    local f="$1"
    case "$f" in
        *"${GITHUB_DIR}/"*)
            echo "${f#*${GITHUB_DIR}/}"
            ;;
        *)
            die "path '$f' does not contain '${GITHUB_DIR}/'"
            ;;
    esac
}

cmd_sync() {
    local dest_root="${BUILD_WORKSPACE_DIRECTORY:-}"
    [ -n "$dest_root" ] || die "must be run via 'bazel run', BUILD_WORKSPACE_DIRECTORY is not set"
    dest_root="${dest_root}/${GITHUB_DIR}"
    mkdir -p "$dest_root"

    declare -A upstream_skills=()
    declare -A upstream_flat=()

    local f rel rest name dest entry subdir pattern
    for f in "$@"; do
        rel="$(relative_asset_path "$f")"
        case "$rel" in
            "${SKILLS_SUBDIR}/"*)
                rest="${rel#${SKILLS_SUBDIR}/}"
                upstream_skills["${rest%%/*}"]=1
                ;;
            *)
                upstream_flat["$rel"]=1
                ;;
        esac

        dest="${dest_root}/${rel}"
        mkdir -p "$(dirname "$dest")"
        cp -f "$f" "$dest"
    done

    # Remove assets that score_tooling no longer ships, so stale copies do not
    # linger after an upstream removal/rename.
    local d
    for d in "$dest_root/${SKILLS_SUBDIR}"/score-*; do
        [ -d "$d" ] || continue
        name="$(basename "$d")"
        if [ -z "${upstream_skills[$name]:-}" ]; then
            echo "Removing stale score_tooling skill: ${name}"
            rm -rf "$d"
        fi
    done
    for entry in "${FLAT_ASSETS[@]}"; do
        subdir="${entry%%:*}"
        pattern="${entry#*:}"
        for f in "$dest_root/${subdir}"/$pattern; do
            [ -f "$f" ] || continue
            rel="${subdir}/$(basename "$f")"
            if [ -z "${upstream_flat[$rel]:-}" ]; then
                echo "Removing stale score_tooling asset: ${rel}"
                rm -f "$f"
            fi
        done
    done

    echo "Synced score_tooling skills: ${!upstream_skills[*]}"
    echo "Synced score_tooling agents and prompts: ${!upstream_flat[*]}"
}

cmd_check() {
    local tooling_files=()
    local repo_files=()
    local seen_separator=0

    local a
    for a in "$@"; do
        if [ "$a" = "--" ]; then
            seen_separator=1
            continue
        fi
        if [ "$seen_separator" -eq 0 ]; then
            tooling_files+=("$a")
        else
            repo_files+=("$a")
        fi
    done

    declare -A upstream_map=()
    local f rel
    for f in "${tooling_files[@]}"; do
        rel="$(relative_asset_path "$f")"
        upstream_map["$rel"]="$f"
    done

    declare -A repo_map=()
    for f in "${repo_files[@]}"; do
        case "$f" in
            "${GITHUB_DIR}/"*/score-*)
                rel="${f#${GITHUB_DIR}/}"
                repo_map["$rel"]="$f"
                ;;
        esac
    done

    local status=0
    local up cf
    for rel in "${!upstream_map[@]}"; do
        up="${upstream_map[$rel]}"
        cf="${repo_map[$rel]:-}"
        if [ -z "$cf" ]; then
            echo "MISSING:   ${GITHUB_DIR}/${rel}"
            status=1
        elif ! diff -q "$up" "$cf" >/dev/null 2>&1; then
            echo "OUT OF DATE: ${GITHUB_DIR}/${rel}"
            status=1
        fi
        unset "repo_map[$rel]"
    done

    for rel in "${!repo_map[@]}"; do
        echo "STALE (no longer provided by score_tooling): ${GITHUB_DIR}/${rel}"
        status=1
    done

    if [ "$status" -ne 0 ]; then
        echo ""
        echo "score_tooling Copilot assets are out of sync. Run: bazel run //:sync_skills"
        exit 1
    fi

    echo "score_tooling Copilot assets are up to date."
}

mode="${1:-}"
[ -n "$mode" ] || die "usage: sync_skills.sh <sync|check> ..."
shift

# Note: $(locations label) in the "args" attribute expands to one argv entry
# per file (not a single space-joined string), so remaining args can be used
# as-is (no manual blob-splitting needed).
case "$mode" in
    sync)
        cmd_sync "$@"
        ;;
    check)
        # Remaining args are the tooling files, a "--" separator, then the
        # repo's own committed files (from a plain glob(), not location-expanded).
        cmd_check "$@"
        ;;    *)
        die "unknown mode '$mode' (expected 'sync' or 'check')"
        ;;
esac
