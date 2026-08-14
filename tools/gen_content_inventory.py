#!/usr/bin/env python3
"""Generate the betacraft content inventory (the "content slice").

Scans the mods tree for registered game content and classifies every item by
Minecraft era using `tools/eras.csv`, so it becomes easy to see -- and later
strip -- anything newer than a chosen cutoff (default: pre-1.13).

Produces:
  CONTENT_INVENTORY.csv   - every found itemstring: kind, mod, era, modern?
  CONTENT_ERAS.md         - human-readable summary grouped by era
  mods/CORE/mcl_slice/generated_slice.lua - lists consumed by the mcl_slice mod

Kind values: node, craftitem, tool, item, mob, entity, biome, ore, structure.

`modern` is true when era is 1.13 or newer (or the mod/era list says so).
Era resolution order: mob/structure/item rows in eras.csv > mod row > "unknown".
"""
import csv
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODS = os.path.join(BASE, "mods")
ERAS = os.path.join(BASE, "tools", "eras.csv")
OUT_CSV = os.path.join(BASE, "CONTENT_INVENTORY.csv")
OUT_MD = os.path.join(BASE, "CONTENT_ERAS.md")
OUT_LUA = os.path.join(BASE, "mods", "CORE", "mcl_slice", "generated_slice.lua")

# era -> True means "modern" for the pre-1.13 cutoff
MODERN_ERAS = {"1.13", "1.14-1.15", "1.16", "1.17-1.18", "1.19", "1.20", "1.21+"}

FIRST_ARG = re.compile(
    r"(?:core|minetest)\.(%s)\s*\(\s*[\"']([^\"']+)[\"']" % "|".join([
        "register_node", "register_item", "register_craftitem", "register_tool",
        "register_entity", "register_biome",
    ]), re.S)
MOB_CALL = re.compile(r"mcl_mobs\.register_mob\s*\(\s*[\"']([^\"']+)[\"']", re.S)
EGG_CALL = re.compile(r"mcl_mobs\.register_egg\s*\(\s*[\"']([^\"']+)[\"']", re.S)
STRUCT_CALL = re.compile(
    r"mcl_structures\.register_structure\s*\(\s*[\"']([^\"']+)[\"']", re.S)
# table-based registrations: capture their name-bearing field
ORE_FIELD = re.compile(r"register_ore\s*\([^)]*?ore\s*=\s*[\"']([^\"']+)[\"']", re.S)
BIOME_FIELD = re.compile(r"register_biome\s*\([^)]*?name\s*=\s*[\"']([^\"']+)[\"']", re.S)
DECO_CALL = re.compile(r"register_decoration\s*\(", re.S)

KIND_LABEL = {
    "register_node": "node",
    "register_item": "item",
    "register_craftitem": "craftitem",
    "register_tool": "tool",
    "register_entity": "entity",
    "register_biome": "biome",
}


def load_eras():
    """Returns (mod_eras, mob_eras, struct_eras, item_eras) dicts."""
    mod, mob, struct, item = {}, {}, {}, {}
    if not os.path.isfile(ERAS):
        return mod, mob, struct, item
    with open(ERAS, newline="", encoding="utf-8") as fh:
        for row in csv.reader(fh):
            if not row:
                continue
            key = (row[0] or "").strip()
            if not key or key.startswith("#") or len(row) < 2:
                continue
            era = (row[1] or "").strip()
            if not era:
                continue
            if key.startswith("mod:"):
                mod[key[4:]] = era
            elif key.startswith("mob:"):
                mob[key[4:]] = era
            elif key.startswith("structure:"):
                struct[key[10:]] = era
            elif key.startswith("item:"):
                item[key[5:]] = era
    return mod, mob, struct, item


def scan():
    rows = []  # (kind, itemstring, mod, file)
    dynamic = {}  # mod -> count of un-captured registration calls
    for dirpath, _dirs, files in os.walk(MODS):
        for fname in sorted(files):
            if not fname.endswith(".lua"):
                continue
            path = os.path.join(dirpath, fname)
            rel = os.path.relpath(path, BASE)
            mod = os.path.basename(dirpath)
            with open(path, encoding="utf-8", errors="replace") as fh:
                text = fh.read()

            for m in FIRST_ARG.finditer(text):
                fn, name = m.group(1), m.group(2)
                rows.append((KIND_LABEL[fn], name, mod, rel))
            for m in MOB_CALL.finditer(text):
                rows.append(("mob", m.group(1), mod, rel))
            for m in EGG_CALL.finditer(text):
                rows.append(("egg", m.group(1), mod, rel))
            for m in STRUCT_CALL.finditer(text):
                rows.append(("structure", m.group(1), mod, rel))
            for m in ORE_FIELD.finditer(text):
                rows.append(("ore", m.group(1), mod, rel))
            for m in BIOME_FIELD.finditer(text):
                rows.append(("biome", m.group(1), mod, rel))
            if DECO_CALL.search(text):
                rows.append(("deco", f"{mod}:<deco>", mod, rel))

            # count registration calls that used non-literal names
            for fn in KIND_LABEL:
                total = len(re.findall(r"(?:core|minetest)\.%s\s*\(" % fn, text))
                lit = len(re.findall(
                    r"(?:core|minetest)\.%s\s*\(\s*[\"']" % fn, text))
                if total > lit:
                    dynamic[mod] = dynamic.get(mod, 0) + (total - lit)
    return rows, dynamic


def resolve_era(kind, name, mod, mod_eras, mob_eras, struct_eras, item_eras):
    if kind in ("mob", "egg"):
        return mob_eras.get(name) or mod_eras.get(mod) or "unknown"
    if kind == "structure":
        return struct_eras.get(name) or mod_eras.get(mod) or "unknown"
    if kind in ("node", "item", "craftitem", "tool"):
        return item_eras.get(name) or mod_eras.get(mod) or "unknown"
    return mod_eras.get(mod) or "unknown"


def main():
    mod_eras, mob_eras, struct_eras, item_eras = load_eras()
    rows, dynamic = scan()

    enriched = []
    for kind, name, mod, rel in rows:
        era = resolve_era(kind, name, mod, mod_eras, mob_eras, struct_eras, item_eras)
        modern = era in MODERN_ERAS
        enriched.append({"kind": kind, "itemstring": name, "mod": mod,
                         "era": era, "modern": modern, "file": rel})

    # dedupe (same itemstring registered several times)
    seen = {}
    for r in enriched:
        key = (r["kind"], r["itemstring"])
        seen.setdefault(key, r)
    enriched = list(seen.values())
    enriched.sort(key=lambda r: (r["era"], r["mod"], r["itemstring"]))

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["kind", "itemstring", "mod", "era", "modern", "file"])
        for r in enriched:
            w.writerow([r["kind"], r["itemstring"], r["mod"], r["era"],
                        "yes" if r["modern"] else "no", r["file"]])

    write_md(enriched, dynamic)
    write_lua(enriched, mod_eras, item_eras)
    print(f"wrote {OUT_CSV} ({len(enriched)} entries)")
    print(f"wrote {OUT_MD}")
    print(f"wrote {OUT_LUA}")
    if dynamic:
        print("\nmods with dynamic (non-literal) registrations not fully captured:")
        for m, n in sorted(dynamic.items()):
            print(f"  {m}: {n} call(s)")


def write_md(enriched, dynamic):
    by_era = {}
    for r in enriched:
        by_era.setdefault(r["era"], []).append(r)

    era_order = ["beta", "1.0-1.7", "1.8-1.12", "1.13", "1.14-1.15", "1.16",
                 "1.17-1.18", "1.19", "1.20", "1.21+", "extra", "engine", "unknown"]
    order = [e for e in era_order if e in by_era]
    order += [e for e in by_era if e not in era_order]

    total = len(enriched)
    modern = [r for r in enriched if r["modern"]]
    lines = [
        "# Betacraft content inventory (content slice)",
        "",
        f"Total entries: {total}  |  Modern (1.13+): {len(modern)}",
        "",
        "Cutoff: **pre-1.13** (everything from `1.13` onward counts as modern).",
        "",
    ]
    for era in order:
        rs = by_era[era]
        n_mod = len(set(r["mod"] for r in rs))
        lines.append(f"## {era}  ({len(rs)} entries, {n_mod} mods)")
        kinds = {}
        for r in rs:
            kinds.setdefault(r["kind"], 0)
            kinds[r["kind"]] += 1
        lines.append("")
        lines.append("Kinds: " + ", ".join(f"{k}={v}" for k, v in sorted(kinds.items())))
        lines.append("")
        for r in rs:
            lines.append(f"- `{r['itemstring']}` [{r['kind']}] ({r['mod']})")
        lines.append("")
    if dynamic:
        lines.append("## Not fully captured (dynamic registration calls)")
        lines.append("")
        for m, n in sorted(dynamic.items()):
            lines.append(f"- {m}: {n} call(s) with non-literal names")
        lines.append("")
    with open(OUT_MD, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


VALID_ITEM = re.compile(r"^[a-z0-9_]+:[a-z0-9_]+$")


def is_valid_item(name):
    return bool(VALID_ITEM.match(name)) and not name.endswith("_")


def write_lua(enriched, mod_eras, item_eras):
    modern_mods = sorted(m for m, e in mod_eras.items() if e in MODERN_ERAS)
    explicit = {r["itemstring"] for r in enriched
                if r["modern"] and r["kind"] in ("node", "item", "craftitem",
                                                 "tool", "egg", "mob")
                and is_valid_item(r["itemstring"])}
    # Item-level era overrides from eras.csv (e.g. dynamically-registered
    # modern items inside otherwise old mods) are always sliced.
    explicit.update(name for name, era in item_eras.items() if era in MODERN_ERAS)
    explicit = sorted(explicit)
    keep = sorted({r["itemstring"] for r in enriched
                   if r["kind"] in ("node", "item", "craftitem", "tool")
                   and not r["modern"] and r["mod"] in mod_eras
                   and mod_eras.get(r["mod"]) in MODERN_ERAS
                   and is_valid_item(r["itemstring"])})
    mobs = sorted({r["itemstring"] for r in enriched
                   if r["modern"] and r["kind"] in ("mob", "egg")})
    structures = sorted({r["itemstring"] for r in enriched
                         if r["modern"] and r["kind"] == "structure"})
    lines = [
        "-- Generated by tools/gen_content_inventory.py -- do not edit by hand.",
        "-- Modern (1.13+) content consumed by mcl_slice.",
        "",
        "MCL_SLICE = {}",
        "",
        "-- Itemstrings explicitly known to be modern (literal registrations).",
        "MCL_SLICE.items = {",
    ]
    lines += [f'\t"{i}",' for i in explicit]
    lines += ["}", "",
              "-- Modern mod prefixes: hide every item from these mods",
              "-- (catches dynamically-registered items) unless in `keep`.",
              "MCL_SLICE.mod_prefixes = {"]
    lines += [f'\t"{m}",' for m in modern_mods]
    lines += ["}", "",
              "-- Pre-1.13 items that live inside otherwise-modern mods",
              "-- (must stay visible).",
              "MCL_SLICE.keep = {"]
    lines += [f'\t"{k}",' for k in keep]
    lines += ["}", "", "MCL_SLICE.mobs = {"]
    lines += [f'\t"{m}",' for m in mobs]
    lines += ["}", "", "MCL_SLICE.structures = {"]
    lines += [f'\t"{s}",' for s in structures]
    lines += ["}", ""]
    os.makedirs(os.path.dirname(OUT_LUA), exist_ok=True)
    with open(OUT_LUA, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    main()
