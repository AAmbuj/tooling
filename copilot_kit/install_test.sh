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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
INSTALL="${SCRIPT_DIR}/install.sh"
KIT="$SCRIPT_DIR"
WORK="$(mktemp -d "${TEST_TMPDIR:-/tmp}/scorekit_test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
pass() { echo "PASS: $*"; }
fail() {
    echo "FAIL: $*"
    failures=$((failures + 1))
}
expect_ok() {
    local desc="$1"
    shift
    if "$@" >"${WORK}/out.log" 2>&1; then pass "$desc"; else
        fail "$desc"
        cat "${WORK}/out.log"
    fi
}
expect_fail() {
    local desc="$1"
    shift
    if "$@" >"${WORK}/out.log" 2>&1; then
        fail "$desc (unexpected success)"
        cat "${WORK}/out.log"
    else pass "$desc"; fi
}

# Isolate user-level paths.
export HOME="${WORK}/home"
export XDG_CONFIG_HOME="${WORK}/home/.config"
unset VSCODE_USER_PROMPTS_FOLDER BUILD_WORKSPACE_DIRECTORY
mkdir -p "$HOME"

# --- frontmatter lint ---------------------------------------------------------
lint_frontmatter() {
    local ok=0 d name f agent
    for d in "$KIT"/skills/scorekit-*/ "$KIT"/overlays/*/skills/scorekit-*/; do
        [[ -d "$d" ]] || continue
        name="$(basename "$d")"
        head -1 "${d}SKILL.md" | grep -qx -- '---' || {
            echo "no frontmatter: ${d}SKILL.md"
            ok=1
        }
        grep -qx "name: ${name}" "${d}SKILL.md" || {
            echo "name mismatch: ${d}SKILL.md"
            ok=1
        }
        grep -q '^description: "' "${d}SKILL.md" || {
            echo "missing description: ${d}SKILL.md"
            ok=1
        }
    done
    for f in "$KIT"/agents/*.agent.md "$KIT"/overlays/*/agents/*.agent.md "$KIT"/prompts/*.prompt.md "$KIT"/overlays/*/prompts/*.prompt.md; do
        [[ -f "$f" ]] || continue
        grep -q '^description: "' "$f" || {
            echo "missing description: $f"
            ok=1
        }
    done
    for f in "$KIT"/prompts/*.prompt.md "$KIT"/overlays/*/prompts/*.prompt.md; do
        agent="$(sed -n 's/^agent: "\(.*\)"$/\1/p' "$f")"
        [[ -z "$agent" || -f "${KIT}/agents/${agent}.agent.md" ]] || {
            echo "unknown agent '${agent}' in $f"
            ok=1
        }
    done
    return "$ok"
}
expect_ok "frontmatter lint" lint_frontmatter

no_workspace_leaks() {
    ! grep -rnE '/home/|bazel/rules/rules_score/private|\]\(\.\./\.\./\.\./' "$KIT"/skills "$KIT"/agents "$KIT"/prompts "$KIT"/instructions "$KIT"/overlays
}
expect_ok "no workspace-internal paths in kit" no_workspace_leaks

# --- repo install -------------------------------------------------------------
REPO="${WORK}/repo"
mkdir -p "${REPO}/.github"
printf '# Team rules\n\nKeep this line.\n' >"${REPO}/.github/copilot-instructions.md"

expect_ok "repo install (full)" "$INSTALL" --repo "$REPO"
expect_ok "all full skills installed" test -f "${REPO}/.github/skills/scorekit-coverage/SKILL.md"
expect_ok "agents installed" test -f "${REPO}/.github/agents/scorekit-seooc-engineer.agent.md"
expect_ok "prompts installed" test -f "${REPO}/.github/prompts/scorekit-implement-seooc.prompt.md"
expect_ok "marker block written" grep -qF "<!-- BEGIN scorekit -->" "${REPO}/.github/copilot-instructions.md"
expect_ok "user content preserved" grep -qF "Keep this line." "${REPO}/.github/copilot-instructions.md"
expect_ok "version rendered in block" grep -qF "scorekit $(tr -d '[:space:]' <"${KIT}/VERSION")" "${REPO}/.github/copilot-instructions.md"
expect_fail "no vendor/MCP content without overlay" grep -rqiE 'codebeamer|bmw|\{\{MCP' "${REPO}/.github/skills" "${REPO}/.github/agents" "${REPO}/.github/prompts"
expect_fail "no unrendered placeholders" grep -rqE '\{\{[A-Z_]+\}\}' "${REPO}/.github"

"$INSTALL" --repo "$REPO" >"${WORK}/second.log"
expect_ok "idempotent re-install" grep -q " 0 written" "${WORK}/second.log"
expect_ok "single marker block" test "$(grep -cF '<!-- BEGIN scorekit -->' "${REPO}/.github/copilot-instructions.md")" -eq 1
expect_ok "check passes" "$INSTALL" --repo "$REPO" --check

echo "local edit" >>"${REPO}/.github/skills/scorekit-fta/SKILL.md"
expect_fail "check detects modification" "$INSTALL" --repo "$REPO" --check
expect_fail "install refuses to overwrite modified file" "$INSTALL" --repo "$REPO"
expect_ok "install --force overwrites" "$INSTALL" --repo "$REPO" --force
expect_ok "check passes after force" "$INSTALL" --repo "$REPO" --check

echo "foreign" >"${REPO}/.github/prompts/scorekit-trace-tests.prompt.md.tmp"
mv "${REPO}/.github/prompts/scorekit-trace-tests.prompt.md.tmp" "${REPO}/.github/prompts/scorekit-trace-tests.prompt.md"
expect_fail "modified managed prompt blocks install" "$INSTALL" --repo "$REPO"
"$INSTALL" --repo "$REPO" --force >/dev/null

# --- profile switch removes stale files ---------------------------------------
expect_ok "switch to core profile" "$INSTALL" --repo "$REPO" --profile core
expect_fail "full-only skill removed" test -e "${REPO}/.github/skills/scorekit-coverage"
expect_fail "full-only prompt removed" test -e "${REPO}/.github/prompts/scorekit-onboard-repo.prompt.md"
expect_ok "core check passes" "$INSTALL" --repo "$REPO" --profile core --check
expect_fail "full check reports missing" "$INSTALL" --repo "$REPO" --check

# --- overlay ------------------------------------------------------------------
expect_ok "overlay install" "$INSTALL" --repo "$REPO" --overlay alm --mcp-codebeamer cbx --mcp-jira jx --mcp-github ghx
AGENT="${REPO}/.github/agents/scorekit-seooc-engineer.agent.md"
expect_ok "overlay agent replaces base agent" grep -qF '"cbx/*"' "$AGENT"
expect_ok "overlay jira tool" grep -qF '"jx/*"' "$AGENT"
expect_ok "overlay skill installed" test -f "${REPO}/.github/skills/scorekit-alm-intake/SKILL.md"
expect_fail "overlay placeholders rendered" grep -rqE '\{\{[A-Z_]+\}\}' "${REPO}/.github"
expect_ok "overlay check passes" "$INSTALL" --repo "$REPO" --overlay alm --mcp-codebeamer cbx --mcp-jira jx --mcp-github ghx --check
expect_fail "invalid MCP name rejected" "$INSTALL" --repo "$REPO" --overlay alm --mcp-jira 'bad name'
expect_ok "overlay removal restores base agent" "$INSTALL" --repo "$REPO"
expect_fail "base agent has no MCP tools" grep -qF '/*"' "$AGENT"
expect_fail "overlay skill removed" test -e "${REPO}/.github/skills/scorekit-alm-intake"

# --- foreign file protection --------------------------------------------------
REPO2="${WORK}/repo2"
mkdir -p "${REPO2}/.github/agents"
echo "mine" >"${REPO2}/.github/agents/scorekit-router.agent.md"
expect_fail "foreign file blocks install" "$INSTALL" --repo "$REPO2"
expect_ok "foreign file untouched" grep -qx "mine" "${REPO2}/.github/agents/scorekit-router.agent.md"

# --- dry run / list -----------------------------------------------------------
REPO3="${WORK}/repo3"
mkdir -p "$REPO3"
expect_ok "list" "$INSTALL" --repo "$REPO3" --list
expect_ok "dry run" "$INSTALL" --repo "$REPO3" --dry-run
expect_fail "dry run writes nothing" test -e "${REPO3}/.github"

# --- only ---------------------------------------------------------------------
expect_ok "only prompts" "$INSTALL" --repo "$REPO3" --only prompts
expect_fail "only prompts: no skills" test -e "${REPO3}/.github/skills"
expect_ok "then skills" "$INSTALL" --repo "$REPO3" --only skills
expect_ok "prompts kept after --only skills" test -f "${REPO3}/.github/prompts/scorekit-new-fta.prompt.md"

# --- uninstall ----------------------------------------------------------------
expect_ok "uninstall" "$INSTALL" --repo "$REPO" --uninstall
expect_fail "no scorekit skills left" compgen -G "${REPO}/.github/skills/scorekit-*"
expect_fail "no scorekit agents left" compgen -G "${REPO}/.github/agents/scorekit-*"
expect_fail "manifest removed" test -e "${REPO}/.github/.scorekit-manifest"
expect_fail "marker block removed" grep -qF "scorekit" "${REPO}/.github/copilot-instructions.md"
expect_ok "user content kept on uninstall" grep -qF "Keep this line." "${REPO}/.github/copilot-instructions.md"

# --- relocatable manifest -----------------------------------------------------
mkdir -p "${WORK}/repo5"
"$INSTALL" --repo "${WORK}/repo5" >/dev/null
expect_fail "manifest has no absolute paths" grep -qF "${WORK}" "${WORK}/repo5/.github/.scorekit-manifest"
mv "${WORK}/repo5" "${WORK}/repo6"
expect_ok "check passes after moving repo" "$INSTALL" --repo "${WORK}/repo6" --check
expect_ok "uninstall after moving repo" "$INSTALL" --repo "${WORK}/repo6" --uninstall
expect_fail "moved repo cleaned" compgen -G "${WORK}/repo6/.github/skills/scorekit-*"

# --- user install + symlink ---------------------------------------------------
expect_ok "user install (symlink)" "$INSTALL" --user --symlink
PROMPTS="${XDG_CONFIG_HOME}/Code/User/prompts"
expect_ok "user skill is symlink" test -L "${HOME}/.copilot/skills/scorekit-fmea/SKILL.md"
expect_ok "user agent installed" test -e "${PROMPTS}/scorekit-router.agent.md"
expect_ok "user instructions rendered as file" test -f "${PROMPTS}/scorekit.instructions.md"
expect_fail "user instructions not a symlink" test -L "${PROMPTS}/scorekit.instructions.md"
expect_ok "user check" "$INSTALL" --user --check
expect_ok "user uninstall" "$INSTALL" --user --uninstall
expect_fail "user skills removed" compgen -G "${HOME}/.copilot/skills/scorekit-*"

echo ""
if [[ "$failures" -ne 0 ]]; then
    echo "${failures} check(s) failed"
    exit 1
fi
echo "All checks passed"
