#!/usr/bin/env python3
"""Report the vault's link islands, and assert Sonder is one of its own.

Sonder is deliberately unattached: nothing in /Sonder links out and nothing
links in, so its cluster reads as a separate project at a glance instead of
being pulled into Uplink's web through a shared hub. That property is invisible
in the note text — one stray pair of brackets silently joins the two clusters
and only a graph view would show it.

Usage:  Tools/check-vault-islands.py [vault-path]
"""
import collections
import pathlib
import re
import sys

DEFAULT = "~/Desktop/Obsidian/Claude Apps"
FENCE = re.compile(r"```.*?```", re.S)
CODE = re.compile(r"`[^`\n]*`")
LINK = re.compile(r"\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]")
ISOLATED = "Sonder"          # the folder that must stand alone


def main(argv: list[str]) -> int:
    root = pathlib.Path(argv[1] if len(argv) > 1 else DEFAULT).expanduser()
    files = [p for p in root.rglob("*.md") if ".obsidian" not in p.parts]
    folder = {p.stem: (p.relative_to(root).parts[0] if len(p.relative_to(root).parts) > 1
                       else "/") for p in files}

    # Undirected adjacency: the graph view does not care about direction.
    edges = collections.defaultdict(set)
    for p in files:
        body = CODE.sub("", FENCE.sub("", p.read_text()))
        for m in LINK.finditer(body):
            target = m.group(1).strip()
            if target in folder and target != p.stem:
                edges[p.stem].add(target)
                edges[target].add(p.stem)

    seen, islands = set(), []
    for name in sorted(folder):
        if name in seen:
            continue
        stack, group = [name], []
        seen.add(name)
        while stack:
            cur = stack.pop()
            group.append(cur)
            for nxt in edges[cur] - seen:
                seen.add(nxt)
                stack.append(nxt)
        islands.append(sorted(group))

    print(f"{len(files)} notes in {len(islands)} island(s):")
    for group in sorted(islands, key=len, reverse=True):
        folders = sorted({folder[n] for n in group})
        print(f"  {len(group):2d} notes  {', '.join(folders)}")

    leaks = sorted(
        {(a, b) for a in edges for b in edges[a]
         if (folder[a] == ISOLATED) != (folder[b] == ISOLATED)}
    )
    if leaks:
        print(f"\n{ISOLATED} is attached to the rest of the graph:")
        for a, b in leaks:
            print(f"    {a}  <->  {b}")
        return 1

    print(f"\n{ISOLATED} is its own island — nothing links in or out.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
