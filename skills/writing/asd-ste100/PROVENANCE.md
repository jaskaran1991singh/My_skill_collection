# Provenance and security audit (2026-11-22)

**Upstream:** https://github.com/danyuchn/asd-ste100-skill, by Dustin Yuchen Teng (danyuchn). MIT licence; see `LICENSES/MIT.txt`.
Upstream install command: `git clone https://github.com/danyuchn/asd-ste100-skill ~/.claude/skills/asd-ste100`
**Vendored commit:** `65c8ab6ef5fcb3619c8e6daca43e68627f3d7b4a` (2026-11-20, skill version 0.4.0).

## What was checked
- All 9 files, read by hand: `SKILL.md`, `references/writing-rules.md`, `examples/*`, `README.md`, the plugin manifests, and `scripts/ste-lint.py` (192 KB).
- Every file was scanned for:
  - invisible or bidirectional Unicode
  - hidden HTML comments
  - override phrasing
  - remote execution
  - credential access
  - encoded blobs

## Findings
| Check | Result |
|---|---|
| Prompt injection | **None.** The words "system prompts" appear only as a kind of text the skill rewrites. |
| Scope hijack | **None.** The description triggers only on rewrite or disambiguation requests, and excludes creative or marketing copy. |
| Permission bypass (`allowed-tools`, hooks, MCP) | **None.** |
| `scripts/ste-lint.py` | Standard library only: argparse, re, json, os, tempfile, unicodedata… There is no network, subprocess, `eval`/`exec` or encoded data. It reads the files given as arguments or stdin, and writes only inside a `TemporaryDirectory` during `--selftest`. |
| Runtime downloads | **None.** The skill is self-contained. |
| Licensing | MIT. The skill deliberately does not include ASD's copyrighted STE dictionary. It paraphrases the rule categories. |

Tested on 2026-11-22: `python3 -I scripts/ste-lint.py --selftest` prints "selftest OK", and a sample sentence was flagged correctly.

## Changes
**None** to the skill content: `SKILL.md`, `references/`, `examples/` and `scripts/` are identical to upstream.
Not copied:
- `README.md` (install docs)
- `.claude-plugin/` (this repo's marketplace replaces it)

## Upgrading
1. Diff a newer upstream commit against `65c8ab6`, especially `scripts/ste-lint.py` imports and any new files.
2. Re-run the self-test.
3. Update the commit above.
