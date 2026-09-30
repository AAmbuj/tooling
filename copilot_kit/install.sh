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
# Installs the score_tooling Copilot kit (skills, agents, prompts, instructions)
# into a consumer repository (.github/) and/or the user-level Copilot folders.

set -euo pipefail

KIT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
VERSION="$(tr -d '[:space:]' <"${KIT_DIR}/VERSION")"
MARK_BEGIN="<!-- BEGIN scorekit -->"
MARK_END="<!-- END scorekit -->"
CATEGORIES=(skills agents prompts instructions)
FULL_ONLY_SKILLS=(
    scorekit-onboarding
    scorekit-docs
    scorekit-coverage
    scorekit-manual-analysis
    scorekit-ai-checks
    scorekit-ci
)
FULL_ONLY_PROMPTS=(scorekit-onboard-repo.prompt.md)

usage() {
    cat <<EOF
score_tooling Copilot kit installer (version ${VERSION})

Usage: install.sh [options]

Targets (default: --repo \$PWD, or the workspace when run via 'bazel run'):
  --repo <path>          Install into <path>/.github/{skills,agents,prompts}
                         and a marker block in .github/copilot-instructions.md
  --user                 Install into ~/.copilot/skills and the VS Code user
                         prompts folder (agents, prompts, instructions)

Selection:
  --profile core|full    core = requirements/architecture/safety/tracing skills;
                         full = core + onboarding/docs/coverage/manual-analysis/
                         ai-checks/ci (default: full)
  --overlay <name>       Add an optional overlay (available: $(overlay_names))
  --only <category>      Restrict to one of: ${CATEGORIES[*]}
  --mcp-codebeamer <n>   MCP server name for Codebeamer (overlay alm)
  --mcp-jira <n>         MCP server name for Jira (overlay alm)
  --mcp-github <n>       MCP server name for GitHub (overlay alm)

Modes:
  (default)              Install or update
  --check                Exit 1 if installed files are missing, outdated or stale
  --uninstall            Remove every file recorded in the install manifest
  --list                 Print the files that would be installed
  --dry-run              Print actions without changing anything

Other:
  --symlink              Symlink files instead of copying (templated files are
                         always copied)
  --force                Overwrite locally modified or foreign files
  -h, --help             Show this help
EOF
}

overlay_names() {
    local names=() d
    for d in "${KIT_DIR}"/overlays/*/; do
        [[ -d "$d" ]] && names+=("$(basename "$d")")
    done
    echo "${names[*]:-none}"
}

die() {
    echo "error: $*" >&2
    exit 2
}

log() {
    echo "$*"
}

mode="install"
want_repo=0
want_user=0
repo_dir=""
profile="full"
overlay=""
only=""
symlink=0
force=0
dry_run=0
mcp_codebeamer=""
mcp_jira=""
mcp_github=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    --repo)
        [[ $# -ge 2 ]] || die "--repo needs a path"
        want_repo=1
        repo_dir="$2"
        shift 2
        ;;
    --user)
        want_user=1
        shift
        ;;
    --profile)
        [[ $# -ge 2 ]] || die "--profile needs a value"
        profile="$2"
        shift 2
        ;;
    --overlay)
        [[ $# -ge 2 ]] || die "--overlay needs a value"
        overlay="$2"
        shift 2
        ;;
    --only)
        [[ $# -ge 2 ]] || die "--only needs a value"
        only="$2"
        shift 2
        ;;
    --mcp-codebeamer)
        mcp_codebeamer="${2:-}"
        shift 2
        ;;
    --mcp-jira)
        mcp_jira="${2:-}"
        shift 2
        ;;
    --mcp-github)
        mcp_github="${2:-}"
        shift 2
        ;;
    --check) mode="check" && shift ;;
    --uninstall) mode="uninstall" && shift ;;
    --list) mode="list" && shift ;;
    --dry-run) dry_run=1 && shift ;;
    --symlink) symlink=1 && shift ;;
    --force) force=1 && shift ;;
    -h | --help)
        usage
        exit 0
        ;;
    *) die "unknown option '$1' (see --help)" ;;
    esac
done

[[ "$profile" == "core" || "$profile" == "full" ]] || die "--profile must be 'core' or 'full'"
if [[ -n "$only" ]]; then
    [[ " ${CATEGORIES[*]} " == *" $only "* ]] || die "--only must be one of: ${CATEGORIES[*]}"
fi
if [[ -n "$overlay" && ! -d "${KIT_DIR}/overlays/${overlay}" ]]; then
    die "unknown overlay '${overlay}' (available: $(overlay_names))"
fi
if [[ "$want_repo" -eq 0 && "$want_user" -eq 0 ]]; then
    want_repo=1
fi
if [[ "$want_repo" -eq 1 && -z "$repo_dir" ]]; then
    repo_dir="${BUILD_WORKSPACE_DIRECTORY:-$PWD}"
fi
if [[ "$want_repo" -eq 1 ]]; then
    [[ -d "$repo_dir" ]] || die "repository directory '${repo_dir}' does not exist"
    repo_dir="$(cd "$repo_dir" && pwd)"
fi

vscode_user_dir() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "${HOME}/Library/Application Support/Code/User"
    else
        echo "${XDG_CONFIG_HOME:-${HOME}/.config}/Code/User"
    fi
}

# Prints the first MCP server name (from repo/user mcp.json) matching $1.
detect_mcp_server() {
    local pattern="$1" f
    command -v python3 >/dev/null 2>&1 || return 0
    for f in "${repo_dir:-/nonexistent}/.vscode/mcp.json" "$(vscode_user_dir)/mcp.json"; do
        [[ -f "$f" ]] || continue
        python3 - "$f" "$pattern" <<'PY' 2>/dev/null && return 0
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"^\s*//.*$", "", text, flags=re.M)
text = re.sub(r",(\s*[}\]])", r"\1", text)
data = json.loads(text)
servers = data.get("servers") or data.get("mcpServers") or {}
for name in servers:
    if re.search(sys.argv[2], name, re.I):
        print(name)
        sys.exit(0)
sys.exit(1)
PY
    done
}

resolve_mcp_names() {
    [[ "$overlay" == "alm" ]] || return 0
    [[ -n "$mcp_codebeamer" ]] || mcp_codebeamer="$(detect_mcp_server codebeamer)"
    [[ -n "$mcp_jira" ]] || mcp_jira="$(detect_mcp_server jira)"
    [[ -n "$mcp_github" ]] || mcp_github="$(detect_mcp_server github)"
    mcp_codebeamer="${mcp_codebeamer:-codebeamer}"
    mcp_jira="${mcp_jira:-jira}"
    mcp_github="${mcp_github:-github}"
    local n
    for n in "$mcp_codebeamer" "$mcp_jira" "$mcp_github"; do
        [[ "$n" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid MCP server name '${n}'"
    done
}

render() {
    sed \
        -e "s|{{SCOREKIT_VERSION}}|${VERSION}|g" \
        -e "s|{{MCP_CODEBEAMER}}|${mcp_codebeamer:-codebeamer}|g" \
        -e "s|{{MCP_JIRA}}|${mcp_jira:-jira}|g" \
        -e "s|{{MCP_GITHUB}}|${mcp_github:-github}|g" \
        "$1"
}

needs_render() {
    grep -q '{{[A-Z_]*}}' "$1"
}

in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

category_selected() {
    [[ -z "$only" || "$only" == "$1" ]]
}

# Target-specific destinations; set by setup_target.
SK_DIR=""
AG_DIR=""
PR_DIR=""
MANIFEST=""
INSTR_BLOCK_FILE=""
INSTR_FILE=""
TARGET_LABEL=""
MANIFEST_BASE=""

setup_target() {
    if [[ "$1" == "repo" ]]; then
        SK_DIR="${repo_dir}/.github/skills"
        AG_DIR="${repo_dir}/.github/agents"
        PR_DIR="${repo_dir}/.github/prompts"
        MANIFEST="${repo_dir}/.github/.scorekit-manifest"
        INSTR_BLOCK_FILE="${repo_dir}/.github/copilot-instructions.md"
        INSTR_FILE=""
        TARGET_LABEL="repo ${repo_dir}"
        MANIFEST_BASE="$repo_dir"
    else
        local prompts="${VSCODE_USER_PROMPTS_FOLDER:-$(vscode_user_dir)/prompts}"
        SK_DIR="${HOME}/.copilot/skills"
        AG_DIR="$prompts"
        PR_DIR="$prompts"
        MANIFEST="${HOME}/.copilot/.scorekit-manifest"
        INSTR_BLOCK_FILE=""
        INSTR_FILE="${prompts}/scorekit.instructions.md"
        TARGET_LABEL="user ${HOME}"
        MANIFEST_BASE="$HOME"
    fi
}

# PLAN_DEST[i] / PLAN_SRC[i] / PLAN_CAT[i] describe every file to install.
declare -a PLAN_DEST PLAN_SRC PLAN_CAT
declare -A PLAN_INDEX

plan_add() {
    local cat="$1" src="$2" dest="$3"
    category_selected "$cat" || return 0
    if [[ -n "${PLAN_INDEX[$dest]:-}" ]]; then
        # Overlay files replace base files with the same destination.
        PLAN_SRC[${PLAN_INDEX[$dest]}]="$src"
        return 0
    fi
    PLAN_INDEX[$dest]="${#PLAN_DEST[@]}"
    PLAN_DEST+=("$dest")
    PLAN_SRC+=("$src")
    PLAN_CAT+=("$cat")
}

plan_tree() {
    local root="$1" skill_dir name f
    for skill_dir in "${root}"/skills/scorekit-*/; do
        [[ -d "$skill_dir" ]] || continue
        name="$(basename "$skill_dir")"
        if [[ "$profile" == "core" ]] && in_list "$name" "${FULL_ONLY_SKILLS[@]}"; then
            continue
        fi
        while IFS= read -r f; do
            plan_add skills "$f" "${SK_DIR}/${name}/${f#"${skill_dir}"}"
        done < <(find "$skill_dir" -type f | sort)
    done
    for f in "${root}"/agents/scorekit-*.agent.md; do
        [[ -f "$f" ]] && plan_add agents "$f" "${AG_DIR}/$(basename "$f")"
    done
    for f in "${root}"/prompts/scorekit-*.prompt.md; do
        [[ -f "$f" ]] || continue
        if [[ "$profile" == "core" ]] && in_list "$(basename "$f")" "${FULL_ONLY_PROMPTS[@]}"; then
            continue
        fi
        plan_add prompts "$f" "${PR_DIR}/$(basename "$f")"
    done
}

build_plan() {
    PLAN_DEST=()
    PLAN_SRC=()
    PLAN_CAT=()
    PLAN_INDEX=()
    plan_tree "$KIT_DIR"
    [[ -z "$overlay" ]] || plan_tree "${KIT_DIR}/overlays/${overlay}"
    if [[ -n "$INSTR_FILE" ]]; then
        plan_add instructions "${KIT_DIR}/instructions/scorekit.instructions.md" "$INSTR_FILE"
    fi
}

# OLD_HASH[path] / OLD_CAT[path] come from the previous manifest.
declare -A OLD_HASH OLD_CAT
OLD_BLOCK=0

load_manifest() {
    OLD_HASH=()
    OLD_CAT=()
    OLD_BLOCK=0
    [[ -f "$MANIFEST" ]] || return 0
    local cat hash path
    while IFS=$'\t' read -r cat hash path; do
        [[ -z "$cat" || "$cat" == \#* ]] && continue
        if [[ "$cat" == "block" ]]; then
            OLD_BLOCK=1
            continue
        fi
        [[ "$path" == /* ]] || path="${MANIFEST_BASE}/${path}"
        OLD_HASH[$path]="$hash"
        OLD_CAT[$path]="$cat"
    done <"$MANIFEST"
}

hash_of() {
    sha256sum "$1" | cut -d' ' -f1
}

# Manifest paths are stored relative to MANIFEST_BASE when possible.
manifest_path() {
    if [[ "$1" == "${MANIFEST_BASE}/"* ]]; then
        echo "${1#"${MANIFEST_BASE}/"}"
    else
        echo "$1"
    fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Writes the expected content of plan entry $1 to a temp file and prints its path.
expected_file() {
    local i="$1" src="${PLAN_SRC[$1]}"
    if needs_render "$src"; then
        render "$src" >"${TMP_DIR}/expected.${i}"
        echo "${TMP_DIR}/expected.${i}"
    else
        echo "$src"
    fi
}

snippet_expected() {
    render "${KIT_DIR}/instructions/copilot-instructions.snippet.md" >"${TMP_DIR}/snippet"
    echo "${TMP_DIR}/snippet"
}

block_current() {
    [[ -f "$INSTR_BLOCK_FILE" ]] || return 1
    grep -qF "$MARK_BEGIN" "$INSTR_BLOCK_FILE" || return 1
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
        $0 == b { inside = 1; next }
        $0 == e { inside = 0; next }
        inside { print }
    ' "$INSTR_BLOCK_FILE"
}

block_write() {
    local snippet="$1" tmp="${TMP_DIR}/block.out"
    mkdir -p "$(dirname "$INSTR_BLOCK_FILE")"
    if [[ -f "$INSTR_BLOCK_FILE" ]] && grep -qF "$MARK_BEGIN" "$INSTR_BLOCK_FILE"; then
        awk -v b="$MARK_BEGIN" -v e="$MARK_END" -v s="$snippet" '
            $0 == b { print; while ((getline line < s) > 0) print line; skip = 1; next }
            $0 == e { skip = 0 }
            !skip { print }
        ' "$INSTR_BLOCK_FILE" >"$tmp"
        cat "$tmp" >"$INSTR_BLOCK_FILE"
    else
        {
            if [[ -s "$INSTR_BLOCK_FILE" ]]; then
                echo ""
            fi
            echo "$MARK_BEGIN"
            cat "$snippet"
            echo "$MARK_END"
        } >>"$INSTR_BLOCK_FILE"
    fi
}

block_remove() {
    [[ -f "$INSTR_BLOCK_FILE" ]] || return 0
    grep -qF "$MARK_BEGIN" "$INSTR_BLOCK_FILE" || return 0
    local tmp="${TMP_DIR}/block.out"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip { print }
    ' "$INSTR_BLOCK_FILE" >"$tmp"
    if grep -q '[^[:space:]]' "$tmp"; then
        cat "$tmp" >"$INSTR_BLOCK_FILE"
    else
        rm -f "$INSTR_BLOCK_FILE"
    fi
}

block_planned() {
    [[ -n "$INSTR_BLOCK_FILE" ]] && category_selected instructions
}

remove_empty_dirs() {
    local d
    for d in "$SK_DIR" "$AG_DIR" "$PR_DIR"; do
        [[ -d "$d" ]] || continue
        find "$d" -mindepth 1 -type d -path "*/scorekit-*" -empty -delete 2>/dev/null || true
    done
}

do_list() {
    local i
    for i in "${!PLAN_DEST[@]}"; do
        printf '%-12s %s\n' "${PLAN_CAT[$i]}" "${PLAN_DEST[$i]}"
    done
    if block_planned; then
        printf '%-12s %s (marker block)\n' instructions "$INSTR_BLOCK_FILE"
    fi
}

do_check() {
    local status=0 i dest exp path
    for i in "${!PLAN_DEST[@]}"; do
        dest="${PLAN_DEST[$i]}"
        exp="$(expected_file "$i")"
        if [[ ! -e "$dest" ]]; then
            log "MISSING:     ${dest}"
            status=1
        elif ! cmp -s "$exp" "$dest"; then
            log "OUT OF DATE: ${dest}"
            status=1
        fi
    done
    for path in "${!OLD_HASH[@]}"; do
        category_selected "${OLD_CAT[$path]}" || continue
        if [[ -z "${PLAN_INDEX[$path]:-}" && -e "$path" ]]; then
            log "STALE:       ${path}"
            status=1
        fi
    done
    if block_planned; then
        local current
        if ! current="$(block_current)"; then
            log "MISSING:     ${INSTR_BLOCK_FILE} (scorekit block)"
            status=1
        elif [[ "$current" != "$(cat "$(snippet_expected)")" ]]; then
            log "OUT OF DATE: ${INSTR_BLOCK_FILE} (scorekit block)"
            status=1
        fi
    fi
    if [[ "$status" -ne 0 ]]; then
        log ""
        log "scorekit ${VERSION} is not in sync for ${TARGET_LABEL}. Re-run install.sh."
        return 1
    fi
    log "scorekit ${VERSION} is up to date for ${TARGET_LABEL}."
}

do_install() {
    local i dest exp conflicts=() path
    for i in "${!PLAN_DEST[@]}"; do
        dest="${PLAN_DEST[$i]}"
        [[ -e "$dest" || -L "$dest" ]] || continue
        exp="$(expected_file "$i")"
        cmp -s "$exp" "$dest" && continue
        if [[ -n "${OLD_HASH[$dest]:-}" && -e "$dest" && "$(hash_of "$dest")" == "${OLD_HASH[$dest]}" ]]; then
            continue
        fi
        conflicts+=("$dest")
    done
    if [[ "${#conflicts[@]}" -gt 0 && "$force" -eq 0 ]]; then
        log "Refusing to overwrite locally modified or foreign files:"
        printf '  %s\n' "${conflicts[@]}"
        log "Re-run with --force to overwrite them."
        return 1
    fi

    local written=0 unchanged=0
    for i in "${!PLAN_DEST[@]}"; do
        dest="${PLAN_DEST[$i]}"
        exp="$(expected_file "$i")"
        if [[ -e "$dest" ]] && cmp -s "$exp" "$dest" && { [[ "$symlink" -eq 1 ]] || [[ ! -L "$dest" ]]; }; then
            unchanged=$((unchanged + 1))
            continue
        fi
        written=$((written + 1))
        if [[ "$dry_run" -eq 1 ]]; then
            log "write   ${dest}"
            continue
        fi
        mkdir -p "$(dirname "$dest")"
        rm -f "$dest"
        if [[ "$symlink" -eq 1 && "$exp" == "${PLAN_SRC[$i]}" ]]; then
            ln -s "${PLAN_SRC[$i]}" "$dest"
        else
            cp "$exp" "$dest"
        fi
    done

    local removed=0
    for path in "${!OLD_HASH[@]}"; do
        category_selected "${OLD_CAT[$path]}" || continue
        [[ -z "${PLAN_INDEX[$path]:-}" ]] || continue
        [[ -e "$path" || -L "$path" ]] || continue
        if [[ "$force" -eq 0 && -e "$path" && "$(hash_of "$path")" != "${OLD_HASH[$path]}" ]]; then
            log "keeping modified stale file: ${path}"
            continue
        fi
        removed=$((removed + 1))
        if [[ "$dry_run" -eq 1 ]]; then
            log "remove  ${path}"
        else
            rm -f "$path"
        fi
    done

    if block_planned; then
        if [[ "$dry_run" -eq 1 ]]; then
            log "update  ${INSTR_BLOCK_FILE} (scorekit block)"
        else
            block_write "$(snippet_expected)"
        fi
    fi

    [[ "$dry_run" -eq 1 ]] && return 0
    remove_empty_dirs
    write_manifest
    log "scorekit ${VERSION} (${profile}${overlay:+, overlay ${overlay}}) -> ${TARGET_LABEL}: ${written} written, ${unchanged} unchanged, ${removed} removed."
}

write_manifest() {
    local tmp="${TMP_DIR}/manifest" i path block=0
    {
        printf '# scorekit version=%s profile=%s overlay=%s\n' "$VERSION" "$profile" "${overlay:-none}"
        # Entries of categories not selected with --only are preserved.
        for path in "${!OLD_HASH[@]}"; do
            category_selected "${OLD_CAT[$path]}" && continue
            printf '%s\t%s\t%s\n' "${OLD_CAT[$path]}" "${OLD_HASH[$path]}" "$(manifest_path "$path")"
        done
        for i in "${!PLAN_DEST[@]}"; do
            printf '%s\t%s\t%s\n' "${PLAN_CAT[$i]}" "$(hash_of "${PLAN_DEST[$i]}")" "$(manifest_path "${PLAN_DEST[$i]}")"
        done
        if block_planned || { [[ "$OLD_BLOCK" -eq 1 ]] && ! category_selected instructions; }; then
            block=1
        fi
        [[ "$block" -eq 0 ]] || printf 'block\t-\t%s\n' "$(manifest_path "$INSTR_BLOCK_FILE")"
    } >"$tmp"
    mkdir -p "$(dirname "$MANIFEST")"
    cp "$tmp" "$MANIFEST"
}

do_uninstall() {
    if [[ ! -f "$MANIFEST" ]]; then
        log "scorekit is not installed for ${TARGET_LABEL} (no manifest)."
        return 0
    fi
    local path removed=0 kept=0
    for path in "${!OLD_HASH[@]}"; do
        category_selected "${OLD_CAT[$path]}" || continue
        [[ -e "$path" || -L "$path" ]] || continue
        if [[ "$force" -eq 0 && -e "$path" && "$(hash_of "$path")" != "${OLD_HASH[$path]}" ]]; then
            log "keeping modified file (use --force): ${path}"
            kept=$((kept + 1))
            continue
        fi
        removed=$((removed + 1))
        if [[ "$dry_run" -eq 1 ]]; then
            log "remove  ${path}"
        else
            rm -f "$path"
        fi
    done
    if [[ "$OLD_BLOCK" -eq 1 && -n "$INSTR_BLOCK_FILE" ]] && category_selected instructions; then
        if [[ "$dry_run" -eq 1 ]]; then
            log "remove  ${INSTR_BLOCK_FILE} (scorekit block)"
        else
            block_remove
        fi
    fi
    [[ "$dry_run" -eq 1 ]] && return 0
    remove_empty_dirs
    if [[ -z "$only" && "$kept" -eq 0 ]]; then
        rm -f "$MANIFEST"
    else
        # Keep manifest entries that still exist so a later uninstall can finish.
        local tmp="${TMP_DIR}/manifest"
        {
            head -n1 "$MANIFEST"
            for path in "${!OLD_HASH[@]}"; do
                [[ -e "$path" ]] || continue
                printf '%s\t%s\t%s\n' "${OLD_CAT[$path]}" "${OLD_HASH[$path]}" "$(manifest_path "$path")"
            done
            if [[ "$OLD_BLOCK" -eq 1 ]] && ! category_selected instructions; then
                printf 'block\t-\t%s\n' "$(manifest_path "$INSTR_BLOCK_FILE")"
            fi
        } >"$tmp"
        cp "$tmp" "$MANIFEST"
    fi
    log "scorekit removed from ${TARGET_LABEL}: ${removed} files removed, ${kept} kept."
}

resolve_mcp_names

targets=()
[[ "$want_repo" -eq 0 ]] || targets+=(repo)
[[ "$want_user" -eq 0 ]] || targets+=(user)

rc=0
for t in "${targets[@]}"; do
    setup_target "$t"
    build_plan
    load_manifest
    case "$mode" in
    list) do_list ;;
    check) do_check || rc=1 ;;
    uninstall) do_uninstall || rc=1 ;;
    install) do_install || rc=1 ;;
    esac
done
exit "$rc"
