#!/usr/bin/env python3
"""Generate the mod-texture -> vanilla-asset mapping for betacraft.

Scans the centralized game-level `textures/` dir (the source of truth after
centralization) and the user's vanilla asset dump in `assets/minecraft/textures/`.
Produces:
  TEXTURE_MAPPING.md   - human-readable plan (overview + match tables)
  mapping.csv          - full machine-readable table (name,status,vanilla,applied)
  mapping_unmapped.txt - list of mod textures with no match yet

Match tiers (highest priority first):
  1. `tools/renames.csv`      hand-curated mod_texture -> vanilla_target
  2. exact                    mod name == vanilla basename
  3. prefix strip             mod name minus `mcl_core_`/`mclx_`/`mcl_`/`default_`/`farming_`
  4. token match              same underscore-token set, single vanilla candidate

`--apply` copies the resolved vanilla file into `textures/` under the MOD name
(idempotent; only differs-from-current files are written). Applied state is
persisted to mapping.csv so a later rerun can see what is still missing.
"""
import argparse
import csv
import os
import shutil

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEX = os.path.join(BASE, "textures")
ASSETS = os.path.join(BASE, "assets", "minecraft", "textures")
RENAMES = os.path.join(BASE, "tools", "renames.csv")

VANILLA_SUBDIRS = [
    "blocks", "items", "entity", "gui", "misc", "models",
    "painting", "particle", "environment",
]
PREFIXES = [
    "mcl_core_", "mcl_nether_", "mcl_end_", "mcl_blackstone_",
    "mclx_", "mcl_", "default_", "farming_",
]


def load_vanilla():
    """basename -> relative dir under ASSETS (first subdir wins)."""
    vanilla = {}
    for sub in VANILLA_SUBDIRS:
        root = os.path.join(ASSETS, sub)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root):
            for f in files:
                if f.endswith(".png"):
                    vanilla.setdefault(f, os.path.relpath(dirpath, ASSETS))
    return vanilla


def load_renames():
    """manual override: mod_texture -> vanilla_target (comments/skip blanks)."""
    renames = {}
    if not os.path.isfile(RENAMES):
        return renames
    with open(RENAMES, newline="") as fh:
        for row in csv.reader(fh):
            if not row or not row[0].strip() or row[0].startswith("#"):
                continue
            mod, target = row[0].strip(), row[1].strip()
            renames[mod] = target
    return renames


def strip_prefix(name):
    for p in PREFIXES:
        if name.startswith(p):
            return name[len(p):]
    return name


def tokens(name):
    return frozenset(name[:-4].split("_"))


def resolve(vanilla, target):
    """Find an actual asset file for a vanilla basename.

    A target of the form `subdir/name.png` pins the subdirectory (for names
    that exist in both blocks/ and items/, e.g. brick). Plain `name.png`
    resolves to the first subdir in VANILLA_SUBDIRS order.
    """
    if "/" in target:
        sub, name = target.split("/", 1)
        if vanilla.get(name) == sub:
            return sub
        return ""
    return vanilla.get(target, "")


def classify(mod_names, vanilla, renames):
    manual, exact, stripped, token, unmapped = [], [], [], [], []
    vt = {}
    for f in vanilla:
        vt.setdefault(tokens(f), []).append(f)
    for name in sorted(mod_names):
        if name in renames:
            manual.append((name, renames[name]))
        elif name in vanilla:
            exact.append((name, name))
        else:
            s = strip_prefix(name)
            if s in vanilla:
                stripped.append((name, s))
            else:
                cands = vt.get(tokens(name), [])
                if len(cands) == 1:
                    token.append((name, cands[0]))
                else:
                    unmapped.append(name)
    return manual, exact, stripped, token, unmapped


def md_table(rows, vanilla):
    lines = ["| mod texture | vanilla asset | source |", "|---|---|---|"]
    for mod_name, vanilla_name in rows:
        src = resolve(vanilla, vanilla_name)
        lines.append(f"| {mod_name} | {vanilla_name} | {src or '(asset missing)'} |")
    return "\n".join(lines)


def apply(rows, vanilla):
    """Copy resolved vanilla files into textures/ under the mod name."""
    n = 0
    for mod_name, vanilla_name in rows:
        src = resolve(vanilla, vanilla_name)
        if not src:
            continue
        src = os.path.join(ASSETS, src, vanilla_name)
        dst = os.path.join(TEX, mod_name)
        if not os.path.isfile(src):
            continue
        same = os.path.exists(dst) and open(dst, "rb").read() == open(src, "rb").read()
        if not same:
            shutil.copy2(src, dst)
            n += 1
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    vanilla = load_vanilla()
    renames = load_renames()
    mod_names = [
        f for f in os.listdir(TEX)
        if f.endswith(".png") and os.path.isfile(os.path.join(TEX, f))
    ]

    manual, exact, stripped, token, unmapped = classify(mod_names, vanilla, renames)
    all_rows = manual + exact + stripped + token

    if args.apply:
        n = apply(all_rows, vanilla)
        print(f"applied: {n} vanilla textures written to textures/ "
              f"(mapped={len(all_rows)}, unmapped={len(unmapped)})")
        return

    with open(os.path.join(BASE, "mapping.csv"), "w") as fh:
        w = csv.writer(fh)
        w.writerow(["name", "status", "vanilla", "resolved", "applied"])
        for rows, status in ((manual, "manual"), (exact, "exact"),
                             (stripped, "stripped"), (token, "token")):
            for mod_name, vanilla_name in rows:
                src = resolve(vanilla, vanilla_name)
                dst = os.path.join(TEX, mod_name)
                applied = os.path.exists(dst) and src and open(dst, "rb").read() == \
                    open(os.path.join(ASSETS, src, vanilla_name), "rb").read()
                w.writerow([mod_name, status, vanilla_name,
                            f"{src}/{vanilla_name}" if src else "", "yes" if applied else ""])
        for name in unmapped:
            w.writerow([name, "unmapped", "", "", ""])

    with open(os.path.join(BASE, "mapping_unmapped.txt"), "w") as fh:
        fh.write("\n".join(unmapped) + "\n")

    total = len(mod_names)
    mapped = len(all_rows)
    resolved = sum(1 for m, v in all_rows if resolve(vanilla, v))
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
        f"- vanilla assets (`assets/minecraft/textures/`, untouched): **{len(vanilla)}** files.",
        "",
        "## Match status",
        "",
        f"- **manual** (`tools/renames.csv`, hand-curated): {len(manual)}",
        f"- **exact** (mod name == vanilla name): {len(exact)}",
        f"- **prefix strip** (`mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): {len(stripped)}",
        f"- **token match** (same word set, one candidate): {len(token)}",
        f"- **unmapped**: {len(unmapped)} -> `mapping_unmapped.txt`",
        "",
        f"Mapped: {mapped}/{total} ({mapped / total * 100:.1f}%); "
        f"resolved to an existing asset: {resolved}.",
        "",
        "## How to apply",
        "",
        "Copy the vanilla asset into `textures/` under the MOD texture name, e.g.:",
        "",
        "```",
        "cp assets/minecraft/textures/blocks/stone.png textures/mcl_core_stone.png",
        "```",
        "",
        "or run `python3 tools/gen_texture_map.py --apply` to auto-apply every mapped",
        "entry (manual + exact + prefix-strip + token). Add entries to `tools/renames.csv`",
        "for names the auto rules cannot derive.",
        "",
        "Regenerate this file with `python3 tools/gen_texture_map.py`.",
        "",
        "## Manual matches (tools/renames.csv)",
        "",
        md_table(manual, vanilla),
        "",
        "## Exact matches",
        "",
        md_table(exact, vanilla),
        "",
        "## Prefix-stripped matches",
        "",
        md_table(stripped, vanilla),
        "",
        "## Token matches",
        "",
        md_table(token, vanilla),
        "",
    ]
    with open(os.path.join(BASE, "TEXTURE_MAPPING.md"), "w") as fh:
        fh.write("\n".join(lines))
    print(f"wrote TEXTURE_MAPPING.md, mapping.csv, mapping_unmapped.txt "
          f"(manual={len(manual)}, exact={len(exact)}, stripped={len(stripped)}, "
          f"token={len(token)}, unmapped={len(unmapped)}, resolved={resolved})")


if __name__ == "__main__":
    main()
