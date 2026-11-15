# Security review checklist for third-party skills

A skill is text that Claude follows as instructions, so a malicious or careless one acts like a prompt injection with the permissions of the session. Review every external skill before adding it.

## 1. Source
- [ ] Take it from the vendor's official repo (not a mirror or registry copy), and record the URL and commit in `PROVENANCE.md`.
- [ ] Note the license, and copy it into `LICENSES/` when you vendor files.

## 2. Automated scan
Run `python3 scripts/validate_skills.py`. It flags:
- invisible or bidirectional Unicode (hidden text)
- override phrasing ("ignore previous instructions", "system prompt", "do not tell the user")
- remote execution (`curl … | sh`, `eval`, `child_process`)
- credential access (`~/.ssh`, `.env`, tokens)
- `allowed-tools` frontmatter (pre-approves commands, so it skips the user's permission prompt)
- long encoded blobs

A flag is a prompt to look closer, not an automatic rejection.

## 3. Manual read: look for
| Pattern | Example seen in the wild | Fix |
|---|---|---|
| **Scope hijack**: the skill triggers on everything | "Use this for all HTML/JSX even if the user does not request it" (daisyUI) | Narrow the description to real triggers |
| **Remote script install** | `curl -fsSL https://vendor/install \| bash` (HeroUI) | Replace with a pinned package-manager install |
| **Permission bypass** | `allowed-tools: Bash(npm install -g …)` (Ant Design) | Remove; let the user approve |
| **Tool output as authority** | "If output says *Update available*, run the update" | Delete; output is data |
| **Agent-initiated outbound actions** | "Proactively file bug reports" with system info attached | Only when the user asks, after preview |
| **Undisclosed network or telemetry** | Bundled scripts that call a vendor API with an analytics tag | Drop the scripts or document them clearly |
| **Hidden content** | Instructions in HTML comments, zero-width characters, base64 | Remove |
| **Non-canonical hosts** | Docs fetched from preview or staging domains | Point to canonical docs |

## 4. Record it
Add a table to `PROVENANCE.md` listing each source, the verdict, and what you changed.
