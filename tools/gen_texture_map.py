#!/usr/bin/env python3
"""Generate the mod-texture -> vanilla-asset mapping for betacraft.

Scans the centralized game-level `textures/` dir (the source of truth after
centralization) and the user's vanilla asset dump in `assets/minecraft/textures/`.
Produces:
  TEXTURE_MAPPING.md   - human-readable plan (overview + match tables)
  mapping.csv          - full machine-readable table (name,status,vanilla,applied,reason)
  mapping_unmapped.txt - list of mod textures with no match yet
  vanilla_unused.txt   - reverse report: vanilla assets no mod texture references

Every mod texture must end up in exactly one state:
  manual / exact / stripped / token  (mapped, applied on `--apply`)
  excluded                          (deliberately not mapped, see tools/exclusions.csv)
  unmapped                          (no match and no exclusion yet)

Match tiers (highest priority first):
  1. `tools/renames.csv`      hand-curated mod_texture -> vanilla_target
  2. `tools/exclusions.csv`   hand-curated name -> reason (not mapped)
  3. exact                    mod name == vanilla basename
  4. prefix strip             mod name minus `mcl_<mod>_`/`mcl_core_`/`mclx_`/`mcl_`/`default_`/`farming_`
  5. token match              same underscore-token set, single vanilla candidate

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
EXCLUSIONS = os.path.join(BASE, "tools", "exclusions.csv")

VANILLA_SUBDIRS = [
    "blocks", "items", "entity", "gui", "misc", "models", "models/armor",
    "painting", "particle", "environment", "font", "map", "colormap", "effect",
]
PREFIXES = [
    "mcl_core_", "mcl_nether_", "mcl_end_", "mcl_blackstone_",
    "mclx_", "mcl_", "default_", "farming_",
]


def load_vanilla():
    """basename -> ordered list of subdirs under ASSETS (VANILLA_SUBDIRS order)."""
    vanilla = {}
    for sub in VANILLA_SUBDIRS:
        root = os.path.join(ASSETS, sub)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root):
            rel = os.path.relpath(dirpath, ASSETS)
            for f in files:
                if f.endswith(".png"):
                    vanilla.setdefault(f, []).append(rel)
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


def load_exclusions():
    """hand-curated not-mapped list: mod_texture -> reason."""
    exclusions = {}
    if not os.path.isfile(EXCLUSIONS):
        return exclusions
    with open(EXCLUSIONS, newline="") as fh:
        for row in csv.reader(fh):
            if not row or not row[0].strip() or row[0].startswith("#"):
                continue
            name = row[0].strip()
            exclusions[name] = row[1].strip() if len(row) > 1 else ""
    return exclusions


def strip_candidates(name):
    """All prefix-stripped variants of a mod texture name, most specific first.

    `mcl_<mod>_<rest>` (two tokens) is tried before the generic single-token
    prefixes, so `mcl_bamboo_flower_pot.png` prefers `flower_pot.png` but
    `mcl_enchanting_table_bottom.png` still falls back to `enchanting_table_bottom.png`.
    """
    cands = []
    if name.startswith("mcl_"):
        parts = name[:-4].split("_")
        if len(parts) >= 3:
            cands.append("_".join(parts[2:]) + ".png")
        cands.append("_".join(parts[1:]) + ".png")
    for p in PREFIXES:
        if name.startswith(p):
            cands.append(name[len(p):])
    return cands


def strip_prefix(name, vanilla):
    """First strip candidate present in the vanilla pool, else None."""
    for cand in strip_candidates(name):
        if cand in vanilla:
            return cand
    return None


def tokens(name):
    return frozenset(name[:-4].split("_"))


def resolve(vanilla, target):
    """Find an actual asset subdir for a vanilla basename.

    A target of the form `subdir/name.png` pins the subdirectory (for names
    that exist in several places, e.g. brick in blocks/ and items/). Plain
    `name.png` resolves to the first subdir in VANILLA_SUBDIRS order.
    """
    if "/" in target:
        sub, name = target.rsplit("/", 1)
        if sub in vanilla.get(name, []):
            return sub
        return ""
    dirs = vanilla.get(target, [])
    return dirs[0] if dirs else ""


def classify(mod_names, vanilla, renames, exclusions):
    manual, exact, stripped, token, excluded, unmapped = [], [], [], [], [], []
    vt = {}
    for f in vanilla:
        vt.setdefault(tokens(f), []).append(f)
    for name in sorted(mod_names):
        if name in renames:
            manual.append((name, renames[name]))
        elif name in vanilla:
            exact.append((name, name))
        elif name in exclusions:
            excluded.append((name, exclusions[name]))
        else:
            s = strip_prefix(name, vanilla)
            if s is not None:
                stripped.append((name, s))
            else:
                cands = vt.get(tokens(name), [])
                if len(cands) == 1:
                    token.append((name, cands[0]))
                else:
                    unmapped.append(name)
    return manual, exact, stripped, token, excluded, unmapped


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
        src = os.path.join(ASSETS, src, os.path.basename(vanilla_name))
        dst = os.path.join(TEX, mod_name)
        if not os.path.isfile(src):
            continue
        same = os.path.exists(dst) and open(dst, "rb").read() == open(src, "rb").read()
        if not same:
            shutil.copy2(src, dst)
            n += 1
    return n


def unused_vanilla(vanilla, rows):
    """Reverse report: vanilla basenames no mapping row references."""
    used = set()
    for _mod, vanilla_name in rows:
        name = vanilla_name.split("/", 1)[-1]
        used.add(name)
    return [f for f in sorted(vanilla) if f not in used]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    vanilla = load_vanilla()
    renames = load_renames()
    exclusions = load_exclusions()
    mod_names = [
        f for f in os.listdir(TEX)
        if f.endswith(".png") and os.path.isfile(os.path.join(TEX, f))
    ]

    manual, exact, stripped, token, excluded, unmapped = classify(
        mod_names, vanilla, renames, exclusions)
    all_rows = manual + exact + stripped + token

    if args.apply:
        n = apply(all_rows, vanilla)
        print(f"applied: {n} vanilla textures written to textures/ "
              f"(mapped={len(all_rows)}, excluded={len(excluded)}, "
              f"unmapped={len(unmapped)})")
        return

    with open(os.path.join(BASE, "mapping.csv"), "w") as fh:
        w = csv.writer(fh)
        w.writerow(["name", "status", "vanilla", "resolved", "applied", "reason"])
        for rows, status in ((manual, "manual"), (exact, "exact"),
                             (stripped, "stripped"), (token, "token")):
            for mod_name, vanilla_name in rows:
                src = resolve(vanilla, vanilla_name)
                dst = os.path.join(TEX, mod_name)
                resolved = vanilla_name if "/" in vanilla_name \
                    else (f"{src}/{vanilla_name}" if src else "")
                applied = src and os.path.exists(dst) and open(dst, "rb").read() == \
                    open(os.path.join(ASSETS, src, os.path.basename(vanilla_name)), "rb").read()
                w.writerow([mod_name, status, vanilla_name,
                            resolved, "yes" if applied else "", ""])
        for mod_name, reason in excluded:
            w.writerow([mod_name, "excluded", "", "", "", reason])
        for name in unmapped:
            w.writerow([name, "unmapped", "", "", "", ""])

    with open(os.path.join(BASE, "mapping_unmapped.txt"), "w") as fh:
        fh.write("\n".join(unmapped) + "\n")

    unused = unused_vanilla(vanilla, all_rows)
    with open(os.path.join(BASE, "vanilla_unused.txt"), "w") as fh:
        for name in unused:
            fh.write(f"{vanilla[name][0]}/{name}\n")

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
        f"- central `textures/`: **{total}** files.",
        f"- vanilla assets (`assets/minecraft/textures/`, untouched): **{len(vanilla)}** basenames.",
        "",
        "## Match status",
        "",
        f"- **manual** (`tools/renames.csv`, hand-curated): {len(manual)}",
        f"- **exact** (mod name == vanilla name): {len(exact)}",
        f"- **prefix strip** (`mcl_<mod>_`, `mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): {len(stripped)}",
        f"- **token match** (same word set, one candidate): {len(token)}",
        f"- **excluded** (`tools/exclusions.csv`, not mapped): {len(excluded)}",
        f"- **unmapped**: {len(unmapped)} -> `mapping_unmapped.txt`",
        "",
        f"Mapped: {mapped}/{total} ({mapped / total * 100:.1f}%); "
        f"resolved to an existing asset: {resolved}. "
        f"Accounted: {mapped + len(excluded)}/{total} "
        f"({(mapped + len(excluded)) / total * 100:.1f}%).",
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
        "for names the auto rules cannot derive, and to `tools/exclusions.csv` for names",
        "that must never map (fonts, GUI, mod-only art).",
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
        "## Excluded (tools/exclusions.csv)",
        "",
        "| mod texture | reason |",
        "|---|---|",
    ]
    for name, reason in excluded:
        lines.append(f"| {name} | {reason or '(no reason)'} |")
    lines += [
        "",
        "## Unused vanilla assets (reverse report)",
        "",
        f"**{len(unused)}** vanilla assets are not referenced by any mapped mod texture",
        f"(see `vanilla_unused.txt`).",
        "",
    ]
    with open(os.path.join(BASE, "TEXTURE_MAPPING.md"), "w") as fh:
        fh.write("\n".join(lines))
    print(f"wrote TEXTURE_MAPPING.md, mapping.csv, mapping_unmapped.txt, "
          f"vanilla_unused.txt (manual={len(manual)}, exact={len(exact)}, "
          f"stripped={len(stripped)}, token={len(token)}, "
          f"excluded={len(excluded)}, unmapped={len(unmapped)}, "
          f"resolved={resolved})")


if __name__ == "__main__":
    main()
