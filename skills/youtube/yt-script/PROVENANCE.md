# Provenance and security audit: YouTube skill pack (2026-11-26)

This file covers all 11 `yt-*` skills in `skills/youtube/`: yt-audit, yt-chapters, yt-comment, yt-edit, yt-package, yt-plan, yt-retention, yt-script, yt-seo, yt-shorts and yt-viral.

**Upstream:** https://github.com/Jakeschincariol/youtube-agent-skill, by Jake Schincariol. MIT licence, copied into each skill's `LICENSES/`.
**Vendored commit:** `a2feb2104981a375ffd4f87ee04f4f5344ac43c6` (2026-09-16, plugin version 1.0.0).

## What was checked
- All 24 files, read by hand: the 11 SKILL.md files, the 6 Python tools, `hooks.json`, `templates/voice.md`, the README and the plugin manifests.
- Every file was scanned for:
  - invisible or bidirectional Unicode
  - hidden HTML comments
  - override phrasing
  - remote execution
  - encoded blobs

## Findings
| Check | Result |
|---|---|
| Prompt injection or hidden text | **None.** |
| Scope hijack | **None.** Each description triggers only on its own YouTube task. |
| Permission bypass (`allowed-tools`, hooks, MCP) | **None.** |
| Outward actions | **None.** Every skill ends with "Nothing here publishes… ship it, or change it?" The user publishes. |
| Python tools (`hookscore`, `title`, `deadair`, `chapters`, `retention`, `swipe`) | Standard library only (json, re, csv, os, sys, statistics). They read the file passed to them, plus `hooks.json`, and print a report. There is no network access, no subprocess, no file writes and no deletion. |
| Data collection | `yt-viral` suggests `yt-dlp` on **public** channel listings and says: "never a logged-in session, never the user's own account credentials". |
| Files outside the project | Skills read `~/.claude/youtube/voice.md`, and write it once when it is missing, from videos the user supplies. That file is the user's own voice profile. A blank template is at `yt-script/voice-template.md`. |
| Honesty guardrails | Every writing skill says: "Never invent a number, a result or a source." |

Tested 2026-11-26 on sample input. hookscore, title, deadair, chapters and swipe all ran correctly. retention correctly rejected a sample with fewer than 8 data points.

## Changes
**None** to skill content: the 11 skill folders match upstream exactly.
- Added: `LICENSES/MIT.txt` in each skill.
- Moved: `templates/voice.md` to `yt-script/voice-template.md`.
- Not copied:
  - README
  - `.claude-plugin/` (this repo's marketplace replaces it)

The skills call each other's tools by relative path (`../yt-script/hookscore.py`), so all 11 must stay together in the same area folder.

## Upgrading
1. Diff a newer upstream commit against `a2feb21`, especially the `.py` imports and any new files.
2. Re-run the tools on sample input.
3. Update the commit above.
