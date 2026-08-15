#!/usr/bin/env python3
"""Draft `tools/exclusions.csv` for every currently-unmapped mod texture.

Assigns each name a category reason so the whole `textures/` set is accounted
for (mapped + excluded, unmapped=0). Runs purely on `mapping_unmapped.txt`
produced by `gen_texture_map.py`; writes a NEW `tools/exclusions.csv`
(previous content is overwritten - keep edits in git).
"""
import csv
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNMAPPED = os.path.join(BASE, "mapping_unmapped.txt")
OUT = os.path.join(BASE, "tools", "exclusions.csv")

GUI_TOKENS = {
    "gui", "formspec", "inventory", "hotbar", "button", "slot", "scroll",
    "tooltip", "icon", "arrow", "cross", "hammer", "fill", "bar", "craft",
    "creative", "marker", "trash", "search", "zoom", "shapeless", "page",
    "tab", "background", "bg", "frame", "selection", "progress", "experience",
    "achievement", "bossbar", "unknown", "wiki", "guide", "logo", "press",
    "checkbox", "slider", "hud", "bgicon", "slots",
}

MODERN_TOKENS = {
    "copper", "netherite", "amethyst", "calcite", "tuff", "sculk", "deepslate",
    "mangrove", "cherry", "bamboo", "pale", "warped", "crimson", "nylium",
    "blackstone", "basalt", "gilded", "crying", "soul", "lodestone", "respawn",
    "smithing", "target", "powder", "beehive", "honey", "candle", "lantern",
    "chain", "anchor", "conduit", "trident", "shield", "spyglass", "bundle",
    "glow", "echo", "reinforced", "vault", "trial", "pottery", "brush",
    "recovery", "warden", "allay", "frog", "tadpole", "camel", "sniffer",
    "armadillo", "breeze", "bogged", "piglin", "hoglin", "strider", "goat",
    "axolotl", "sentry", "vex", "ward", "snout", "rib", "spire", "wayfinder",
    "shaper", "silence", "tide", "coast", "dune", "flow", "bolt", "wild",
    "sus", "pointed", "dripstone", "oxidized", "waxed", "raw", "smoker",
    "blast", "cartography", "fletching", "grindstone", "loom", "composter",
    "observer", "sprouts", "twisting", "weeping", "fungus", "quartz_bricks",
    "scaffolding", "bee", "honeycomb", "dripstone",
}

PARTICLE_TOKENS = {
    "particle", "particles", "flame", "flames", "smoke", "puff", "spark",
    "snowflake", "raindrop", "lightning", "cloud", "bubble", "footprint",
    "crack", "heart", "splash", "shock", "explosion", "spell",
}


def tokens(name):
    return set(name[:-4].split("_"))


def family(name):
    """mcl_<mod>_<rest> -> (mod, rest-tokens); other -> (None, all tokens)."""
    parts = name[:-4].split("_")
    if parts and parts[0] == "mcl" and len(parts) >= 3:
        return parts[1], set(parts[2:])
    return None, set(parts)


def classify(name):
    if name.startswith("_"):
        return "font glyph (not content)"
    if name.startswith("mobs_"):
        return "mobs: custom skins (no 1.12 entity texture)"
    if name.startswith("extra_"):
        return "mod-specific"
    mod, tok = family(name)
    all_tok = tokens(name)
    if tok & GUI_TOKENS or mod in {"base", "inventory", "crafting", "craftguide",
                                   "experience", "achievements", "enchanting"}:
        return "GUI/formspec (not content)"
    if all_tok & MODERN_TOKENS:
        return "modern 1.13+ content (absent from 1.12.2 dump)"
    if all_tok & PARTICLE_TOKENS:
        return "particles/effects (not content)"
    if name.startswith(("mcl_", "default_", "farming_", "doors_", "wool_",
                        "crimson_", "warped_", "nether_", "pointed_",
                        "xpanes_", "mescons_")):
        return "no vanilla asset in dump (partial 1.12.2 pool)"
    return "mod-specific"


def main():
    names = [l for l in open(UNMAPPED).read().split() if l]
    with open(OUT, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["name", "reason"])
        for name in sorted(names):
            w.writerow([name, classify(name)])
    print(f"wrote {OUT} ({len(names)} entries)")


if __name__ == "__main__":
    main()
