#!/usr/bin/env python3
"""Generate the mod-texture -> vanilla-asset mapping for betacraft.

Scans the centralized game-level `textures/` dir (the source of truth after
centralization) and the user's vanilla asset dump in `assets/minecraft/textures/`.
Produces:
  TEXTURE_MAPPING.md   - human-readable plan (overview + match tables)
  mapping.csv          - full machine-readable table (name,status,vanilla)
  mapping_unmapped.txt - list of mod textures with no auto-match yet

Options:
  --apply   copy matched vanilla files into `textures/` under the MOD texture
            name so the engine picks them up (idempotent; overwrites only
            files that currently differ).
"""
import argparse
import os
import shutil
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEX = os.path.join(BASE, "textures")
ASSETS = os.path.join(BASE, "assets", "minecraft", "textures")

VANILLA_SUBDIRS = [
    "blocks", "items", "entity", "gui", "misc", "models",
    "painting", "particle", "environment",
]

# Mod-texture prefixes that map onto bare vanilla names.
PREFIXES = [
    "mcl_core_", "mclx_", "mcl_", "default_", "farming_",
]

# Vanilla prefixes (Minecraft 1.13+ splits some names) tried as a suffix
# fallback: e.g. "mcl_core_log_side" -> vanilla "log_side"/"oak_log".
# (kept minimal: advanced mapping is manual)


def load_vanilla():
    vanilla = {}  # basename -> source subdir (first wins)
    for sub in VANILLA_SUBDIRS:
        root = os.path.join(ASSETS, sub)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root):
            for f in files:
                if not f.endswith(".png"):
                    continue
                vanilla.setdefault(f, os.path.relpath(dirpath, ASSETS))
    return vanilla


def strip_prefix(name):
    for p in PREFIXES:
        if name.startswith(p):
            return name[len(p):]
    return name


def classify(mod_names, vanilla):
    exact, stripped, unmapped = [], [], []
    for name in sorted(mod_names):
        if name in vanilla:
            exact.append((name, name))
        else:
            s = strip_prefix(name)
            if s in vanilla:
                stripped.append((name, s))
            else:
                unmapped.append(name)
    return exact, stripped, unmapped


def md_table(rows, vanilla):
    lines = ["| mod texture | vanilla asset | source |", "|---|---|---|"]
    for mod_name, vanilla_name in rows:
        src = vanilla.get(vanilla_name, "")
        lines.append(f"| {mod_name} | {vanilla_name} | {src} |")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    vanilla = load_vanilla()
    mod_names = [
        f for f in os.listdir(TEX)
        if f.endswith(".png") and os.path.isfile(os.path.join(TEX, f))
    ]

    exact, stripped, unmapped = classify(mod_names, vanilla)

    if args.apply:
        n = 0
        for mod_name, vanilla_name in exact + stripped:
            dst = os.path.join(TEX, mod_name)
            for sub in (VANILLA_SUBDIRS if vanilla_name not in vanilla else
                        [vanilla[vanilla_name]]):
                src = os.path.join(ASSETS, sub, vanilla_name)
                if os.path.isfile(src):
                    if not (os.path.exists(dst) and
                            open(dst, "rb").read() == open(src, "rb").read()):
                        shutil.copy2(src, dst)
                        n += 1
                    break
        print(f"applied: {n} vanilla textures written to textures/")
        return

    with open(os.path.join(BASE, "mapping.csv"), "w") as fh:
        fh.write("name,status,vanilla\n")
        for name, v in exact:
            fh.write(f"{name},exact,{v}\n")
        for name, v in stripped:
            fh.write(f"{name},stripped,{v}\n")
        for name in unmapped:
            fh.write(f"{name},unmapped,\n")

    with open(os.path.join(BASE, "mapping_unmapped.txt"), "w") as fh:
        fh.write("\n".join(unmapped) + "\n")

    total = len(mod_names)
    lines = [
        "# Betacraft texture mapping plan",
        "",
        "How the engine resolves media (Luanti 5.16, `Server::fillMediaCache`):",
        "builtin locale -> `~/.minetest/textures/server` -> **game-level `textures/`** -> mod media dirs.",
        "The first file found for a basename wins. All mods reference textures by bare basename,",
        "so dropping a file named exactly like the mod texture into `textures/` overrides it.",
        "",
        "## Inventory",
        "",
        f"- central `textures/`: **{total}** files (3233 moved + 2 model textures; 3 identical-content",
        "  duplicates were dropped; `MAPGEN/mcl_villages/textures/src/farming_pumpkin_side_small.png`",
        "  stays in the mod (only used by `textures/src/gen_images.sh`)).",
        f"- vanilla assets (`assets/minecraft/textures/`, untouched): **{len(vanilla)}** files across",
        f"  {', '.join(VANILLA_SUBDIRS)}.",
        "",
        "## Match status",
        "",
        f"- **exact** (mod name == vanilla name): {len(exact)}",
        f"- **auto after prefix strip** (`mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): {len(stripped)}",
        f"- **unmapped** (need manual work): {len(unmapped)} -> see `mapping_unmapped.txt`",
        "",
        f"Coverage: {(len(exact) + len(stripped)) / total * 100:.1f}% of {total} mod textures.",
        "",
        "## How to apply",
        "",
        "Copy the vanilla asset into `textures/` under the MOD texture name, e.g.:",
        "",
        "```",
        "cp assets/minecraft/textures/blocks/stone.png textures/mcl_core_stone.png",
        "```",
        "",
        "or run `python3 tools/gen_texture_map.py --apply` to auto-apply the exact and",
        "prefix-stripped matches. The unmapped set needs a hand-written `assets -> textures`",
        "remap table; the obvious next step is stripping prefixes from both sides and",
        "renaming vanilla files (e.g. `log_oak` -> `oak_log`) until coverage rises.",
        "",
        "Regenerate this file with `python3 tools/gen_texture_map.py`.",
        "",
        "## Exact matches",
        "",
        md_table(exact, vanilla),
        "",
        "## Prefix-stripped matches",
        "",
        md_table(stripped, vanilla),
        "",
    ]
    with open(os.path.join(BASE, "TEXTURE_MAPPING.md"), "w") as fh:
        fh.write("\n".join(lines))
    print(f"wrote TEXTURE_MAPPING.md, mapping.csv, mapping_unmapped.txt "
          f"(exact={len(exact)}, stripped={len(stripped)}, unmapped={len(unmapped)})")


if __name__ == "__main__":
    main()
