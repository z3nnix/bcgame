# Betacraft texture mapping plan

How the engine resolves media (Luanti 5.16, `Server::fillMediaCache`):
builtin locale -> `~/.minetest/textures/server` -> **game-level `textures/`** -> mod media dirs.
The first file found for a basename wins. All mods reference textures by bare basename,
so dropping a file named exactly like the mod texture into `textures/` overrides it.

## Inventory

- central `textures/`: **3235** files (3233 moved + 2 model textures; 3 identical-content
  duplicates were dropped; `MAPGEN/mcl_villages/textures/src/farming_pumpkin_side_small.png`
  stays in the mod (only used by `textures/src/gen_images.sh`)).
- vanilla assets (`assets/minecraft/textures/`, untouched): **797** files across
  blocks, items, entity, gui, misc, models, painting, particle, environment.

## Match status

- **exact** (mod name == vanilla name): 26
- **auto after prefix strip** (`mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): 125
- **unmapped** (need manual work): 3084 -> see `mapping_unmapped.txt`

Coverage: 4.7% of 3235 mod textures.

## How to apply

Copy the vanilla asset into `textures/` under the MOD texture name, e.g.:

```
cp assets/minecraft/textures/blocks/stone.png textures/mcl_core_stone.png
```

or run `python3 tools/gen_texture_map.py --apply` to auto-apply the exact and
prefix-stripped matches. The unmapped set needs a hand-written `assets -> textures`
remap table; the obvious next step is stripping prefixes from both sides and
renaming vanilla files (e.g. `log_oak` -> `oak_log`) until coverage rises.

Regenerate this file with `python3 tools/gen_texture_map.py`.

## Exact matches

| mod texture | vanilla asset | source |
|---|---|---|
| bucket_lava.png | bucket_lava.png | items |
| bucket_water.png | bucket_water.png | items |
| cake.png | cake.png | items |
| cake_bottom.png | cake_bottom.png | blocks |
| cake_inner.png | cake_inner.png | blocks |
| cake_side.png | cake_side.png | blocks |
| cake_top.png | cake_top.png | blocks |
| hardened_clay.png | hardened_clay.png | blocks |
| hardened_clay_stained_black.png | hardened_clay_stained_black.png | blocks |
| hardened_clay_stained_blue.png | hardened_clay_stained_blue.png | blocks |
| hardened_clay_stained_brown.png | hardened_clay_stained_brown.png | blocks |
| hardened_clay_stained_cyan.png | hardened_clay_stained_cyan.png | blocks |
| hardened_clay_stained_green.png | hardened_clay_stained_green.png | blocks |
| hardened_clay_stained_light_blue.png | hardened_clay_stained_light_blue.png | blocks |
| hardened_clay_stained_lime.png | hardened_clay_stained_lime.png | blocks |
| hardened_clay_stained_magenta.png | hardened_clay_stained_magenta.png | blocks |
| hardened_clay_stained_orange.png | hardened_clay_stained_orange.png | blocks |
| hardened_clay_stained_pink.png | hardened_clay_stained_pink.png | blocks |
| hardened_clay_stained_purple.png | hardened_clay_stained_purple.png | blocks |
| hardened_clay_stained_red.png | hardened_clay_stained_red.png | blocks |
| hardened_clay_stained_silver.png | hardened_clay_stained_silver.png | blocks |
| hardened_clay_stained_white.png | hardened_clay_stained_white.png | blocks |
| hardened_clay_stained_yellow.png | hardened_clay_stained_yellow.png | blocks |
| mob_spawner.png | mob_spawner.png | blocks |
| spawn_egg.png | spawn_egg.png | items |
| spawn_egg_overlay.png | spawn_egg_overlay.png | items |

## Prefix-stripped matches

| mod texture | vanilla asset | source |
|---|---|---|
| default_apple.png | apple.png | items |
| default_book.png | book.png | gui |
| default_bookshelf.png | bookshelf.png | blocks |
| default_brick.png | brick.png | blocks |
| default_clay.png | clay.png | blocks |
| default_coal_block.png | coal_block.png | blocks |
| default_diamond.png | diamond.png | items |
| default_diamond_block.png | diamond_block.png | blocks |
| default_dirt.png | dirt.png | blocks |
| default_flint.png | flint.png | items |
| default_furnace_side.png | furnace_side.png | blocks |
| default_furnace_top.png | furnace_top.png | blocks |
| default_glass.png | glass.png | blocks |
| default_gold_block.png | gold_block.png | blocks |
| default_gold_ingot.png | gold_ingot.png | items |
| default_gravel.png | gravel.png | blocks |
| default_gunpowder.png | gunpowder.png | items |
| default_ice.png | ice.png | blocks |
| default_ladder.png | ladder.png | blocks |
| default_obsidian.png | obsidian.png | blocks |
| default_paper.png | paper.png | items |
| default_sand.png | sand.png | blocks |
| default_snow.png | snow.png | blocks |
| default_stick.png | stick.png | items |
| default_stone.png | stone.png | blocks |
| default_tnt_bottom.png | tnt_bottom.png | blocks |
| default_tnt_side.png | tnt_side.png | blocks |
| default_tnt_top.png | tnt_top.png | blocks |
| default_wood.png | wood.png | entity/armorstand |
| farming_bread.png | bread.png | items |
| farming_carrot.png | carrot.png | items |
| farming_cookie.png | cookie.png | items |
| farming_melon.png | melon.png | items |
| farming_melon_side.png | melon_side.png | blocks |
| farming_melon_top.png | melon_top.png | blocks |
| farming_mushroom_brown.png | mushroom_brown.png | blocks |
| farming_mushroom_red.png | mushroom_red.png | blocks |
| farming_mushroom_stew.png | mushroom_stew.png | items |
| farming_potato.png | potato.png | items |
| farming_potato_baked.png | potato_baked.png | items |
| farming_pumpkin_side.png | pumpkin_side.png | blocks |
| farming_pumpkin_top.png | pumpkin_top.png | blocks |
| mcl_brewing_stand.png | brewing_stand.png | blocks |
| mcl_core_apple_golden.png | apple_golden.png | items |
| mcl_core_barrier.png | barrier.png | items |
| mcl_core_bedrock.png | bedrock.png | blocks |
| mcl_core_bowl.png | bowl.png | items |
| mcl_core_cactus_bottom.png | cactus_bottom.png | blocks |
| mcl_core_cactus_side.png | cactus_side.png | blocks |
| mcl_core_cactus_top.png | cactus_top.png | blocks |
| mcl_core_charcoal.png | charcoal.png | items |
| mcl_core_coal_ore.png | coal_ore.png | blocks |
| mcl_core_coarse_dirt.png | coarse_dirt.png | blocks |
| mcl_core_diamond_ore.png | diamond_ore.png | blocks |
| mcl_core_dirt_podzol_side.png | dirt_podzol_side.png | blocks |
| mcl_core_dirt_podzol_top.png | dirt_podzol_top.png | blocks |
| mcl_core_emerald.png | emerald.png | items |
| mcl_core_emerald_block.png | emerald_block.png | blocks |
| mcl_core_emerald_ore.png | emerald_ore.png | blocks |
| mcl_core_glass_black.png | glass_black.png | blocks |
| mcl_core_glass_blue.png | glass_blue.png | blocks |
| mcl_core_glass_brown.png | glass_brown.png | blocks |
| mcl_core_glass_cyan.png | glass_cyan.png | blocks |
| mcl_core_glass_gray.png | glass_gray.png | blocks |
| mcl_core_glass_green.png | glass_green.png | blocks |
| mcl_core_glass_light_blue.png | glass_light_blue.png | blocks |
| mcl_core_glass_lime.png | glass_lime.png | blocks |
| mcl_core_glass_magenta.png | glass_magenta.png | blocks |
| mcl_core_glass_orange.png | glass_orange.png | blocks |
| mcl_core_glass_pink.png | glass_pink.png | blocks |
| mcl_core_glass_purple.png | glass_purple.png | blocks |
| mcl_core_glass_red.png | glass_red.png | blocks |
| mcl_core_glass_silver.png | glass_silver.png | blocks |
| mcl_core_glass_white.png | glass_white.png | blocks |
| mcl_core_glass_yellow.png | glass_yellow.png | blocks |
| mcl_core_gold_nugget.png | gold_nugget.png | items |
| mcl_core_gold_ore.png | gold_ore.png | blocks |
| mcl_core_grass_side_snowed.png | grass_side_snowed.png | blocks |
| mcl_core_ice_packed.png | ice_packed.png | blocks |
| mcl_core_iron_ore.png | iron_ore.png | blocks |
| mcl_core_lapis_block.png | lapis_block.png | blocks |
| mcl_core_lapis_ore.png | lapis_ore.png | blocks |
| mcl_core_leaves_big_oak.png | leaves_big_oak.png | blocks |
| mcl_core_leaves_birch.png | leaves_birch.png | blocks |
| mcl_core_leaves_spruce.png | leaves_spruce.png | blocks |
| mcl_core_log_big_oak.png | log_big_oak.png | blocks |
| mcl_core_log_big_oak_top.png | log_big_oak_top.png | blocks |
| mcl_core_log_birch.png | log_birch.png | blocks |
| mcl_core_log_birch_top.png | log_birch_top.png | blocks |
| mcl_core_log_spruce.png | log_spruce.png | blocks |
| mcl_core_log_spruce_top.png | log_spruce_top.png | blocks |
| mcl_core_mycelium_side.png | mycelium_side.png | blocks |
| mcl_core_mycelium_top.png | mycelium_top.png | blocks |
| mcl_core_planks_big_oak.png | planks_big_oak.png | blocks |
| mcl_core_planks_birch.png | planks_birch.png | blocks |
| mcl_core_planks_spruce.png | planks_spruce.png | blocks |
| mcl_core_red_sand.png | red_sand.png | blocks |
| mcl_core_red_sandstone_bottom.png | red_sandstone_bottom.png | blocks |
| mcl_core_red_sandstone_carved.png | red_sandstone_carved.png | blocks |
| mcl_core_red_sandstone_normal.png | red_sandstone_normal.png | blocks |
| mcl_core_red_sandstone_smooth.png | red_sandstone_smooth.png | blocks |
| mcl_core_red_sandstone_top.png | red_sandstone_top.png | blocks |
| mcl_core_redstone_ore.png | redstone_ore.png | blocks |
| mcl_core_reeds.png | reeds.png | blocks |
| mcl_core_sandstone_bottom.png | sandstone_bottom.png | blocks |
| mcl_core_sandstone_carved.png | sandstone_carved.png | blocks |
| mcl_core_sandstone_normal.png | sandstone_normal.png | blocks |
| mcl_core_sandstone_smooth.png | sandstone_smooth.png | blocks |
| mcl_core_sandstone_top.png | sandstone_top.png | blocks |
| mcl_core_sapling_birch.png | sapling_birch.png | blocks |
| mcl_core_sapling_spruce.png | sapling_spruce.png | blocks |
| mcl_core_slime.png | slime.png | blocks |
| mcl_core_stonebrick_carved.png | stonebrick_carved.png | blocks |
| mcl_core_stonebrick_cracked.png | stonebrick_cracked.png | blocks |
| mcl_core_stonebrick_mossy.png | stonebrick_mossy.png | blocks |
| mcl_core_sugar.png | sugar.png | items |
| mcl_core_vine.png | vine.png | blocks |
| mcl_core_web.png | web.png | blocks |
| mcl_enchanting_table_bottom.png | enchanting_table_bottom.png | blocks |
| mcl_enchanting_table_side.png | enchanting_table_side.png | blocks |
| mcl_enchanting_table_top.png | enchanting_table_top.png | blocks |
| mcl_experience_bottle.png | experience_bottle.png | items |
| mcl_experience_orb.png | experience_orb.png | entity |
| mcl_jukebox_side.png | jukebox_side.png | blocks |
| mcl_jukebox_top.png | jukebox_top.png | blocks |
