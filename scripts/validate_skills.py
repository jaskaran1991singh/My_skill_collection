#!/usr/bin/env python3
"""Validate every skill under skills/<area>/<name>/.

Errors (fail the run):
  - SKILL.md missing or has no YAML frontmatter
  - `name` missing, invalid, or different from the folder name
  - `description` missing or too long (>1024 chars)
  - invisible / bidi Unicode anywhere in the skill
  - `allowed-tools` in frontmatter (pre-approves commands; review required)
Warnings (printed; fail only with --strict):
  - suspicious phrases: prompt-override wording, remote-exec, credential paths, long encoded blobs
PROVENANCE.md files are exempt from the phrase scan since they quote what was removed.
"""
import pathlib, re, sys, unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
SUSPICIOUS = {
    "override phrasing": re.compile(r"ignore (all |any )?(previous|prior|above) (instructions|prompts?)|disregard (the )?(system|previous)|you are now|do not (tell|inform) the user|without (asking|telling) the user", re.I),
    "remote exec": re.compile(r"(curl|wget)[^\n|]*\|\s*(ba|z)?sh\b|\beval\(|child_process", re.I),
    "credential access": re.compile(r"~/\.ssh|id_rsa|\.aws/credentials|\bprintenv\b|cat [^\n]*\.env\b", re.I),
    "encoded blob": re.compile(r"[A-Za-z0-9+/=]{160,}"),
}
TEXT_EXT = {".md", ".txt", ".json", ".yaml", ".yml", ".py", ".js", ".mjs", ".ts", ".tsx", ".sh", ".css", ".html"}


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fm, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if km:
            key, val = km.group(1), km.group(2).strip()
            fm[key] = "" if val in (">", "|", ">-", "|-") else val.strip("\"'")
        elif key and line.startswith((" ", "\t")):
            fm[key] = (fm[key] + " " + line.strip()).strip()
    return fm


def skill_dirs():
    return sorted(p.parent for p in SKILLS.glob("*/*/SKILL.md"))


def main():
    strict = "--strict" in sys.argv
    errors, warnings = [], []
    for area in sorted(p for p in SKILLS.iterdir() if p.is_dir()):
        for d in sorted(p for p in area.iterdir() if p.is_dir()):
            if not (d / "SKILL.md").exists():
                errors.append(f"{d.relative_to(ROOT)}: missing SKILL.md")
    for d in skill_dirs():
        rel = d.relative_to(ROOT)
        fm = frontmatter((d / "SKILL.md").read_text(encoding="utf-8"))
        if fm is None:
            errors.append(f"{rel}: SKILL.md has no frontmatter"); continue
        name, desc = fm.get("name", ""), fm.get("description", "")
        if not NAME_RE.match(name):
            errors.append(f"{rel}: invalid name '{name}'")
        if name != d.name:
            errors.append(f"{rel}: name '{name}' != folder '{d.name}'")
        if not desc:
            errors.append(f"{rel}: missing description")
        elif len(desc) > 1024:
            errors.append(f"{rel}: description is {len(desc)} chars (>1024)")
        if "allowed-tools" in fm:
            errors.append(f"{rel}: has allowed-tools (pre-approves commands) - remove or justify")
        for f in d.rglob("*"):
            if not f.is_file() or f.suffix.lower() not in TEXT_EXT:
                continue
            frel = f.relative_to(ROOT)
            try:
                text = f.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                warnings.append(f"{frel}: not UTF-8"); continue
            hidden = [c for c in text if unicodedata.category(c) in ("Cf", "Co") or 0xE0000 <= ord(c) <= 0xE007F]
            if hidden:
                errors.append(f"{frel}: {len(hidden)} invisible/bidi characters (e.g. U+{ord(hidden[0]):04X})")
            if f.name == "PROVENANCE.md":
                continue
            for i, line in enumerate(text.splitlines(), 1):
                for label, rx in SUSPICIOUS.items():
                    if rx.search(line):
                        warnings.append(f"{frel}:{i}: {label}: {line.strip()[:120]}")
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"\n{len(skill_dirs())} skill(s), {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1 if errors or (strict and warnings) else 0)


if __name__ == "__main__":
    main()
