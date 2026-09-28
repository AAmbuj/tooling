#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Installs the S-CORE Copilot pack. Run from inside the unpacked pack directory.
#
#   ./install.sh                           -> ~/.copilot/{agents,skills}, VS Code user prompts
#   ./install.sh --workspace /path/to/repo -> <repo>/.github/{agents,prompts,skills}

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -d "$src/agents" ] && [ -d "$src/skills" ] || {
    echo "error: run this script from inside the unpacked pack directory" >&2
    exit 1
}
case "${1:-}" in
    "")
        dest="${HOME}/.copilot"
        prompts_dest="${HOME}/.config/Code/User/prompts"
        scope="personal (all workspaces)"
        ;;
    --workspace)
        [ -n "${2:-}" ] || { echo "error: --workspace needs a repository path" >&2; exit 1; }
        [ -d "$2" ] || { echo "error: '$2' is not a directory" >&2; exit 1; }
        dest="$(cd "$2" && pwd)/.github"
        prompts_dest="$dest/prompts"
        scope="workspace $2"
        ;;
    -h | --help)
        sed -n '3,7p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
        exit 0
        ;;
    *)
        echo "error: unknown argument '$1' (expected --workspace <path>)" >&2
        exit 1
        ;;
esac

mkdir -p "$dest/agents" "$dest/skills" "$prompts_dest"

# Drop assets this pack no longer ships, so an older version does not linger.
for old in "$dest/agents"/score-*; do
    [ -f "$old" ] || continue
    [ -f "$src/agents/$(basename "$old")" ] || { echo "removing stale agents/$(basename "$old")"; rm -f "$old"; }
done
for old in "$prompts_dest"/score-*; do
        [ -f "$old" ] || continue
        [ -f "$src/prompts/$(basename "$old")" ] || { echo "removing stale prompts/$(basename "$old")"; rm -f "$old"; }
done
for old in "$dest/skills"/score-*; do
    [ -d "$old" ] || continue
    [ -d "$src/skills/$(basename "$old")" ] || { echo "removing stale $(basename "$old")"; rm -rf "$old"; }
done

cp -f "$src/agents"/*.agent.md "$dest/agents/"
[ -d "$src/prompts" ] && cp -f "$src/prompts"/*.prompt.md "$prompts_dest/"
for skill in "$src/skills"/*/; do
    name="$(basename "$skill")"
    rm -rf "${dest:?}/skills/$name"
    cp -R "$skill" "$dest/skills/$name"
done

echo "Installed into $scope:"
echo "  agents  -> $dest/agents"
echo "  prompts -> $prompts_dest"
echo "  skills  -> $dest/skills"
echo
echo "Reload the VS Code window, then pick the 'score-tooling' agent in Chat."
