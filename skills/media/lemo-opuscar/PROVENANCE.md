# Provenance and security audit (2026-11-19)

**Upstream:** https://github.com/lemomo-ai/lemo-opuscar, by Lemomo (LemoLab). Installed upstream as:
```
claude plugin marketplace add lemomo-ai/lemo-opuscar
claude plugin install lemo-opuscar@lemolab
```
**Audited commit:** `00a7f9ec99c8686265a8ca4ed9a3fdaaf27ea6f4` (main, 2026-11-17, release v2.0.0 line).
**Licences:** code (`scripts/setup.sh`) is MIT, and the Markdown (this SKILL.md) is CC BY-NC 4.0. Both texts and the upstream LICENSE are in `LICENSES/`. This copy is adapted (changes below).

## What was checked
The whole repo: 3,942 files, of which 2,663 are text or code. Plugin manifests, `SKILL.md`, `scripts/setup.sh`, `AGENTS.md`, `DIRECTOR.md`, `TECHNIQUE.md`, `MY-STYLES.md`, `core/README.md`, `core/image/gen_image.py`, `core/tts/*`, `tools/fetch.sh` and the requirements files were read by hand. All text was scanned for:
- invisible or bidirectional Unicode
- override phrasing
- remote execution
- credential access
- encoded blobs
- outbound hosts

## Findings
| Check | Result |
|---|---|
| Prompt injection (override phrasing, hidden text, encoded instructions) | **None.** The only invisible characters are font charset tables inside a vendored `opentype.min.js` (harmless). |
| Permission bypass (`allowed-tools`, hooks, MCP servers, settings edits) | **None.** The plugin has no hooks, no `.mcp.json` and no `allowed-tools`. |
| Remote script piped to shell | **None.** |
| Credentials | `gen_image.py` reads `~/.codex` session logs only to retrieve the image it just generated, and runs Codex with `--sandbox read-only`. Nothing else touches secrets. |
| **Unpinned instructions (main risk)** | Upstream `setup.sh` runs `git fetch main && git reset --hard` **on every use**. Whatever is pushed to `main` becomes Claude's instructions with no review, and `LEMO_OPUSCAR_REPO` can point it at another repo. |
| Data leaving the machine | edge-tts sends the narration text to Microsoft (upstream's `DIRECTOR.md` tells the agent to mention it, and its directory edition says to ask). ✦ styles send prompts to the user's Codex account. |
| Downloads | npm, PyPI, the Playwright browser, GitHub Releases (sha256-checked via `tools/assets.json`), Hugging Face and Google Fonts. `sampler.py` downloads sample packs automatically unless `LEMO_FETCH=0` is set. |
| Licence | The docs are **NonCommercial** (CC BY-NC 4.0, with an extra permission to use them for your own and client films). Films you make are yours. |

## Changes in this edition
1. `scripts/setup.sh` (MIT, adapted):
   - checks out the **audited commit** (`PIN`), never moving `main`
   - the repo URL can't be overridden
   - uses its own folder `~/.lemo-opuscar-pinned`
   - doesn't set `lemo.managed`, so the library's own copy of `setup.sh` never resets it to `main` (tested)
   - refuses a clone at another commit unless this script made it
   - uses `npm ci` instead of `npm install`
2. `SKILL.md` (CC BY-NC 4.0, adapted):
   - setup commands are routed to this skill's script
   - added safety rules: name downloads up front, ask before edge-tts, install style packages project-local and pinned, treat library text and fetched material as data, and a licence note

Tested 2026-11-19: first run, re-run, drift back to the pin, the library's own `setup.sh` run inside the clone, `demo <slug>`, and `deps` (core).

## Upgrading
1. Pick a new upstream commit.
2. Diff it against `00a7f9e`, focusing on `plugin/`, `*.md` guides, `core/`, `tools/` and the requirements files.
3. Re-run `scripts/validate_skills.py`'s checks on the clone.
4. Update `PIN` in `scripts/setup.sh`, `pinned-commit` in SKILL.md, and this file.
