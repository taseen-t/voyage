#!/usr/bin/env python3
"""Check every wikilink in the Obsidian vault resolves to exactly one note.

A dangling wikilink is the one defect that is invisible until somebody clicks
it — Obsidian renders it in a slightly different colour and otherwise says
nothing. Duplicate note names are the other half of the same problem: Obsidian
links by name, so two notes called `Architecture` make every link to either
ambiguous.

Usage:  Tools/check-vault-links.py [vault-path]
"""
import collections
import pathlib
import re
import sys

DEFAULT = "~/Desktop/Obsidian/Claude Apps"

# Wikilinks inside code spans and fenced blocks are examples, not links.
FENCE = re.compile(r"```.*?```", re.S)
CODE = re.compile(r"`[^`\n]*`")
LINK = re.compile(r"\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]")


def main(argv: list[str]) -> int:
    root = pathlib.Path(argv[1] if len(argv) > 1 else DEFAULT).expanduser()
    if not root.is_dir():
        print(f"no vault at {root}", file=sys.stderr)
        return 2

    files = [p for p in root.rglob("*.md") if ".obsidian" not in p.parts]
    names = collections.Counter(p.stem for p in files)
    notes = {p.stem for p in files}

    failed = False
    for name, count in sorted(names.items()):
        if count > 1:
            print(f"DUPLICATE NAME: {name!r} used by {count} notes")
            failed = True

    checked = 0
    for p in sorted(files):
        body = CODE.sub("", FENCE.sub("", p.read_text()))
        missing = sorted({m.group(1).strip() for m in LINK.finditer(body)} - notes)
        checked += len(LINK.findall(body))
        if missing:
            failed = True
            print(f"DANGLING in {p.relative_to(root)}:")
            for t in missing:
                print(f"    [[{t}]]")

    print(f"{len(files)} notes, {checked} wikilinks checked — "
          f"{'FAILED' if failed else 'all resolve'}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
