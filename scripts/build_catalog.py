#!/usr/bin/env python3
"""Regenerate the README catalog table and .claude-plugin/marketplace.json.

Each area folder under skills/ becomes one plugin named `my-<area>` (prefixed so it never clashes with other marketplaces' plugins).
Use --check to fail (without writing) when either file is out of date (CI).
"""
import json, pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from validate_skills import ROOT, SKILLS, frontmatter, skill_dirs  # noqa: E402

OWNER = "jaskaran1991singh"
REPO = "my-skill-collection"


def first_sentence(desc):
    m = re.match(r"(.+?(?<!\be\.g)(?<!\bi\.e)(?<!\betc)\.)(\s|$)", desc)   # skip e.g. / i.e. / etc.
    return (m.group(1) if m else desc).replace("|", "\\|")


def build():
    rows, by_area = [], {}
    for d in skill_dirs():
        fm = frontmatter((d / "SKILL.md").read_text(encoding="utf-8"))
        area = d.parent.name
        rows.append(f"| {area} | [{fm['name']}]({d.relative_to(ROOT).as_posix()}) | {first_sentence(fm['description'])} |")
        by_area.setdefault(area, []).append("./" + d.relative_to(ROOT).as_posix())
    table = "| Area | Skill | Description |\n|---|---|---|\n" + "\n".join(rows)
    readme_path = ROOT / "README.md"
    readme = re.sub(
        r"(<!-- CATALOG:START[^\n]*-->\n).*?(\n<!-- CATALOG:END -->)",
        lambda m: m.group(1) + table + m.group(2),
        readme_path.read_text(encoding="utf-8"),
        flags=re.S,
    )
    market = {
        "name": REPO,
        "owner": {"name": OWNER},
        "metadata": {"description": "Personal collection of reviewed Claude Agent Skills, grouped by area.", "version": "1.0.0"},
        "plugins": [
            {
                "name": f"my-{area}",
                "description": f"{area.capitalize()} skills from {REPO}",
                "source": "./",
                "strict": False,
                "skills": paths,
            }
            for area, paths in sorted(by_area.items())
        ],
    }
    return readme_path, readme, ROOT / ".claude-plugin" / "marketplace.json", json.dumps(market, indent=2) + "\n"


def main():
    rp, readme, mp, market = build()
    stale = [p for p, new in ((rp, readme), (mp, market)) if not p.exists() or p.read_text(encoding="utf-8") != new]
    if "--check" in sys.argv:
        for p in stale:
            print(f"out of date: {p.relative_to(ROOT)} (run scripts/build_catalog.py)")
        sys.exit(1 if stale else 0)
    rp.write_text(readme, encoding="utf-8")
    mp.parent.mkdir(exist_ok=True)
    mp.write_text(market, encoding="utf-8")
    print(f"updated {len(stale)} file(s)")


if __name__ == "__main__":
    main()
