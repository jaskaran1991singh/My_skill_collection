#!/bin/sh
# Lemo-Opuscar, pinned edition (my_skill_collection). Adapted from upstream plugin/skills/lemo-opuscar/scripts/setup.sh
# (MIT, Lemomo/LemoLab, https://github.com/lemomo-ai/lemo-opuscar). Changes from upstream:
#   - the library is checked out at ONE audited commit (PIN), never at moving `main`; no auto-update on each run
#   - the repository URL cannot be overridden by an environment variable (upstream: LEMO_OPUSCAR_REPO)
#   - its own folder (~/.lemo-opuscar-pinned), so the upstream plugin's auto-updating clone is never reused
#   - the clone is NOT marked lemo.managed, so the library's own copy of setup.sh never resets it to `main`
#   - `npm ci` (exact lockfile) instead of `npm install`
# To move to a newer upstream version: audit it, then change PIN below (and PROVENANCE.md).
#
#   sh setup.sh                    library ready? → which package tiers are installed, LIB=<path>
#   sh setup.sh deps [voice] [music]
#   sh setup.sh demo <slug>        add one style's demo source and poster to the library (reference only)
set -e
REPO=https://github.com/lemomo-ai/lemo-opuscar.git
PIN=00a7f9ec99c8686265a8ca4ed9a3fdaaf27ea6f4          # upstream main, audited 2026-11-19

LIB=${LEMO_OPUSCAR_HOME:-$HOME/.lemo-opuscar-pinned}
case "$LIB" in /*|[A-Za-z]:[/\\]*) ;; *) LIB=$(pwd)/$LIB ;; esac
is_lib() { [ -f "$1/AGENTS.md" ] && [ -d "$1/core/render" ]; }

sparse() { (cd "$LIB" && MSYS_NO_PATHCONV=1 git sparse-checkout "$@"); }
apply_sparse() {
  set -- '/*' '!/styles/*/demo/' '!/styleboard/' '!/docs/readme/' '!/docs/cover.jpg' '!/styles/*/poster.jpg' \
    $(git -C "$LIB" sparse-checkout list 2>/dev/null | grep -E '^/styles/[^/*]+/(demo/|poster\.jpg)$' || true)
  sparse set --no-cone "$@" 2>/dev/null || git -C "$LIB" sparse-checkout disable || true
}
checkout_pin() {
  git -C "$LIB" fetch --quiet --depth 1 --filter=blob:none origin "$PIN" &&
  git -C "$LIB" -c advice.detachedHead=false checkout --quiet --force "$PIN"
}

if is_lib "$LIB" || [ -d "$LIB/.git" ]; then
  head=$(git -C "$LIB" rev-parse HEAD 2>/dev/null || echo none)
  if [ "$head" != "$PIN" ]; then
    if [ "$(git -C "$LIB" config --get lemo.pinned 2>/dev/null)" = true ]; then
      echo "↻ moving $LIB to the audited commit ${PIN%"${PIN#???????}"}"
      [ "$(git -C "$LIB" remote get-url origin 2>/dev/null)" = "$REPO" ] || git -C "$LIB" remote set-url origin "$REPO"
      checkout_pin || { echo "✗ could not fetch the audited commit (offline?)"; exit 1; }
    else
      echo "✗ $LIB is at $head, not the audited commit $PIN, and was not made by this skill."
      echo "  Set LEMO_OPUSCAR_HOME to an empty folder (or remove $LIB) and run again."; exit 1
    fi
  fi
else
  [ -e "$LIB" ] && [ -n "$(ls -A "$LIB" 2>/dev/null)" ] && { echo "✗ $LIB exists but is not the Lemo-Opuscar library. Set LEMO_OPUSCAR_HOME to another folder."; exit 1; }
  command -v git >/dev/null || { echo "✗ git is needed to download the library"; exit 1; }
  echo "↓ downloading the style library (audited commit ${PIN%"${PIN#???????}"}) into $LIB"
  mkdir -p "$LIB"
  { git -C "$LIB" init --quiet && git -C "$LIB" remote add origin "$REPO" && git -C "$LIB" config lemo.pinned true &&
    sparse init --no-cone 2>/dev/null; apply_sparse; checkout_pin; } || { rm -rf "$LIB"; echo "✗ download failed (offline?)"; exit 1; }
fi
[ "$(git -C "$LIB" rev-parse HEAD)" = "$PIN" ] || { echo "✗ $LIB is not at the audited commit"; exit 1; }
LIB=$(cd "$LIB" && pwd -P)

# Installed packages are tracked by content: a marker holds a checksum of the files they came from (and the Python
# version), so a changed package.json or requirements file triggers a reinstall.
sig() { cat "$@" 2>/dev/null | cksum | cut -d' ' -f1; }
pysig() { echo "$(sig "$1")-$("$LIB/.venv/bin/python" -V 2>&1 | cut -d. -f1,2)"; }
req() { [ "$1" = core ] && echo "$LIB/requirements.txt" || echo "$LIB/requirements-$1.txt"; }
node_ok() { [ "$(cat "$LIB/node_modules/.lemo-ok" 2>/dev/null)" = "$(sig "$LIB/package.json" "$LIB/package-lock.json")" ]; }
py_ok() { [ "$(cat "$LIB/.venv/.lemo-$1" 2>/dev/null)" = "$(pysig "$(req "$1")")" ]; }
# a Python 3.11+ for the venv when uv is absent; kokoro-onnx (voice tier) needs < 3.14, so those come first
find_py() {
  for c in python3.12 python3.13 python3.11 python3 python; do
    "$c" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null && { echo "$c"; return 0; }
  done
  return 1
}
# Windows (Git Bash): a venv keeps its Python in Scripts/python.exe. Give it the .venv/bin/python every tool calls,
# a shim that also forces UTF-8 (a Chinese Windows defaults to GBK, which can't print ✓ or read our UTF-8 files).
win_shim() {
  [ -f .venv/Scripts/python.exe ] && [ ! -e .venv/bin/python ] || return 0
  mkdir -p .venv/bin
  printf '#!/bin/sh\nPYTHONUTF8=1 PYTHONIOENCODING=utf-8 exec "$(dirname "$0")/../Scripts/python.exe" "$@"\n' > .venv/bin/python
  chmod +x .venv/bin/python
}
# One deps run per library at a time (#23): two sessions sharing a library would otherwise half-install, or remove,
# each other's packages. A lock folder holds the run's pid; a lock whose run is gone is taken over.
lock_deps() {
  lock=$LIB/.lemo-deps.lock; n=0
  until mkdir "$lock" 2>/dev/null; do
    p=$(cat "$lock/pid" 2>/dev/null || true)
    if [ -n "$p" ] && ! kill -0 "$p" 2>/dev/null; then rm -rf "$lock"; continue; fi
    [ $n -gt 0 ] || echo "… another '$1 deps' is installing into $LIB; waiting for it to finish"
    n=$((n + 1)); [ $n -lt 1800 ] || { echo "✗ $lock is still there after 30 minutes: remove it if no install is running"; exit 1; }
    sleep 1
  done
  echo $$ > "$lock/pid"
  trap 'rm -rf "$lock"' EXIT; trap 'exit 1' INT TERM HUP
}

case "$1" in
  deps)
    shift; tiers=core
    for t in "$@"; do case $t in voice|music) tiers="$tiers $t" ;; *) echo "usage: sh setup.sh deps [voice] [music]"; exit 1 ;; esac; done
    cd "$LIB"; lock_deps "sh setup.sh"
    command -v npm >/dev/null || { echo "✗ npm not found: install Node 20+ first"; exit 1; }
    if ! node_ok; then
      npm ci --no-audit --no-fund --loglevel=error
      sig package.json package-lock.json > node_modules/.lemo-ok
    fi
    node node_modules/playwright-core/cli.js install chromium-headless-shell   # the renderer's browser (a no-op when present)
    # a venv whose Python is gone (after a Python upgrade) can't be repaired in place: make it again
    win_shim
    [ ! -e .venv ] || .venv/bin/python -c pass 2>/dev/null || { echo "! $LIB/.venv is broken; making it again"; rm -rf .venv; }
    if [ ! -x .venv/bin/python ]; then
      if command -v uv >/dev/null; then uv venv --quiet --python 3.12 .venv
      else py=$(find_py) || { echo "✗ Python 3.11+ is needed (or install uv, which fetches it)"; exit 1; }; "$py" -m venv .venv; fi
      win_shim
    fi
    # uv is a native program: on Windows it needs the venv's Scripts/python.exe, not a bin/python meant for sh
    upy=.venv/bin/python; [ ! -f .venv/Scripts/python.exe ] || upy=.venv/Scripts/python.exe
    for t in $tiers; do
      py_ok "$t" && continue
      if command -v uv >/dev/null; then uv pip install --quiet --python "$upy" -r "$(req "$t")"
      else .venv/bin/python -m pip install --quiet --disable-pip-version-check -r "$(req "$t")"; fi
      pysig "$(req "$t")" > ".venv/.lemo-$t"
    done
    case " $tiers " in *" voice "*) [ -f core/tts/kokoro-v1.0.onnx ] && [ -f core/tts/voices-v1.0.bin ] || sh tools/fetch.sh voice ;; esac
    ;;
  demo)
    [ -n "$2" ] && [ -f "$LIB/styles/$2/STYLE.md" ] || { echo "usage: sh setup.sh demo <slug>  (slugs: $LIB/styles/README.md)"; exit 1; }
    if git -C "$LIB" sparse-checkout list >/dev/null 2>&1 && ! git -C "$LIB" sparse-checkout list | grep -qx "/styles/$2/demo/"; then
      sparse add "/styles/$2/demo/" "/styles/$2/poster.jpg"
    fi
    echo "demo source: $LIB/styles/$2/demo"
    echo "demo poster: $LIB/styles/$2/poster.jpg"
    ;;
esac

# 2. Tools the pipeline needs (report only; installing them is up to the user)
miss=""
if command -v node >/dev/null; then
  [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] || miss="$miss node20+(found $(node -v))"
else miss="$miss node20+"; fi
if command -v ffmpeg >/dev/null; then
  ffv=$(ffmpeg -version 2>/dev/null | sed -n '1s/^ffmpeg version n\{0,1\}\([0-9][0-9]*\)\..*/\1/p')
  [ -z "$ffv" ] || [ "$ffv" -ge 7 ] || miss="$miss ffmpeg7+(found $ffv.x)"
else miss="$miss ffmpeg"; fi
command -v uv >/dev/null || find_py >/dev/null || miss="$miss python3.11+(or uv)"
[ -n "$miss" ] && echo "! missing:$miss"
# packages never installed, or installed from a package.json or requirements file that has changed since (a marker is there)
if ! { node_ok && py_ok core; }; then
  if [ -f "$LIB/node_modules/.lemo-ok" ] || [ -f "$LIB/.venv/.lemo-core" ]; then
    echo "! packages changed: run 'sh setup.sh deps' to update them before the next render"
  else echo "! packages not installed yet: run 'sh setup.sh deps' (a few minutes) before the first render"; fi
fi
# Package tiers: core renders; voice (TTS + speech check) and music (pluck.py) are added when a film needs them
mark() { if "$@"; then printf '✓'; else printf '✗'; fi; }
core_ok() { node_ok && py_ok core; }
voice_ok() { py_ok voice && [ -f "$LIB/core/tts/kokoro-v1.0.onnx" ] && [ -f "$LIB/core/tts/voices-v1.0.bin" ]; }
add=""; voice_ok || add="$add voice"; py_ok music || add="$add music"
tline="packages: core $(mark core_ok) · voice $(mark voice_ok) · music $(mark py_ok music)"
core_ok && [ -n "$add" ] && tline="$tline  (when a film needs them: sh setup.sh deps$add)"
echo "$tline"
echo "LIB=$LIB"
