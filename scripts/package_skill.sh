#!/usr/bin/env bash
# Zip a skill folder for upload to claude.ai (Settings → Capabilities → Skills).
# Usage: scripts/package_skill.sh skills/<area>/<skill-name> [out-dir]
set -euo pipefail
src="${1:?usage: $0 skills/<area>/<skill-name> [out-dir]}"
out="${2:-dist}"
[ -f "$src/SKILL.md" ] || { echo "no SKILL.md in $src" >&2; exit 1; }
name="$(basename "$src")"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
rm -f "$out/$name.zip"
(cd "$(dirname "$src")" && zip -qr "$out/$name.zip" "$name" -x '*/.DS_Store')
echo "$out/$name.zip"
