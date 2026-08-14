# Betacraft texture mapping plan

How the engine resolves media (Luanti 5.16, `Server::fillMediaCache`):
builtin locale -> `~/.minetest/textures/server` -> **game-level `textures/`** -> mod media dirs.
The first file found for a basename wins. All mods reference textures by bare basename,
so dropping a file named exactly like the mod texture into `textures/` overrides it.

## Inventory

- central `textures/`: **3235** files (3233 moved + 2 model textures; 3 identical-content
  duplicates were dropped; `MAPGEN/mcl_villages/textures/src/farming_pumpkin_side_small.png`
  stays in the mod (only used by `textures/src/gen_images.sh`)).
- vanilla assets (`assets/minecraft/textures/`, untouched): **797** files.

## Match status

- **manual** (`tools/renames.csv`, hand-curated): 147
- **exact** (mod name == vanilla name): 26
- **prefix strip** (`mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): 139
- **token match** (same word set, one candidate): 2
- **unmapped**: 2921 -> `mapping_unmapped.txt`

Mapped: 314/3235 (9.7%); resolved to an existing asset: 311.

## How to apply

Copy the vanilla asset into `textures/` under the MOD texture name, e.g.:

```
cp assets/minecraft/textures/blocks/stone.png textures/mcl_core_stone.png
```

or run `python3 tools/gen_texture_map.py --apply` to auto-apply every mapped
entry (manual + exact + prefix-strip + token). Add entries to `tools/renames.csv`
for names the auto rules cannot derive.

Regenerate this file with `python3 tools/gen_texture_map.py`.

## Manual matches (tools/renames.csv)

| mod texture | vanilla asset | source |
|---|---|---|
| default_acacia_tree.png | log_acacia.png | blocks |
| default_acacia_tree_top.png | log_acacia_top.png | blocks |
| default_acacia_wood.png | log_acacia.png | blocks |
| default_clay_brick.png | items/brick.png | (asset missing) |
| default_clay_lump.png | clay_ball.png | items |
| default_coal_lump.png | coal.png | items |
| default_cobble.png | cobblestone.png | blocks |
| default_diamond.png | diamond.png | items |
| default_diamond_block.png | diamond_block.png | blocks |
| default_dry_shrub.png | deadbush.png | blocks |
| default_furnace_bottom.png | furnace_top.png | blocks |
| default_furnace_front.png | furnace_front_off.png | blocks |
| default_furnace_front_active.png | furnace_front_on.png | blocks |
| default_glass_detail.png | glass.png | blocks |
| default_jungleleaves.png | leaves_jungle.png | blocks |
| default_junglesapling.png | sapling_jungle.png | blocks |
| default_jungletree.png | log_jungle.png | blocks |
| default_jungletree_top.png | log_jungle_top.png | blocks |
| default_junglewood.png | log_jungle.png | blocks |
| default_lava_flowing_animated.png | lava_flow.png | blocks |
| default_lava_source_animated.png | lava_still.png | blocks |
| default_leaves.png | leaves_oak.png | blocks |
| default_mossycobble.png | cobblestone_mossy.png | blocks |
| default_rail.png | rail_normal.png | blocks |
| default_rail_crossing.png | rail_normal.png | blocks |
| default_rail_curved.png | rail_normal_turned.png | blocks |
| default_rail_t_junction.png | rail_normal.png | blocks |
| default_river_water_flowing_animated.png | water_flow.png | blocks |
| default_river_water_source_animated.png | water_still.png | blocks |
| default_sapling.png | sapling_oak.png | blocks |
| default_snow.png | snow.png | blocks |
| default_steel_block.png | iron_block.png | blocks |
| default_steel_ingot.png | iron_ingot.png | items |
| default_stone_brick.png | stonebrick.png | blocks |
| default_tnt_bottom.png | tnt_bottom.png | blocks |
| default_tnt_side.png | tnt_side.png | blocks |
| default_tnt_top.png | tnt_top.png | blocks |
| default_tool_diamondaxe.png | diamond_axe.png | items |
| default_tool_diamondpick.png | diamond_pickaxe.png | items |
| default_tool_diamondshovel.png | diamond_shovel.png | items |
| default_tool_diamondsword.png | diamond_sword.png | items |
| default_tool_goldaxe.png | gold_axe.png | items |
| default_tool_goldpick.png | gold_pickaxe.png | items |
| default_tool_goldshovel.png | gold_shovel.png | items |
| default_tool_goldsword.png | gold_sword.png | items |
| default_tool_shears.png | shears.png | items |
| default_tool_steelaxe.png | iron_axe.png | items |
| default_tool_steelpick.png | iron_pickaxe.png | items |
| default_tool_steelshovel.png | iron_shovel.png | items |
| default_tool_steelsword.png | iron_sword.png | items |
| default_tool_stoneaxe.png | stone_axe.png | items |
| default_tool_stonepick.png | stone_pickaxe.png | items |
| default_tool_stoneshovel.png | stone_shovel.png | items |
| default_tool_stonesword.png | stone_sword.png | items |
| default_tool_woodaxe.png | wood_axe.png | items |
| default_tool_woodpick.png | wood_pickaxe.png | items |
| default_tool_woodshovel.png | wood_shovel.png | items |
| default_tool_woodsword.png | wood_sword.png | items |
| default_torch_on_floor.png | torch_on.png | blocks |
| default_torch_on_floor_animated.png | torch_on.png | blocks |
| default_tree.png | log_oak.png | blocks |
| default_tree_top.png | log_oak_top.png | blocks |
| default_water_flowing_animated.png | water_flow.png | blocks |
| default_water_source_animated.png | water_still.png | blocks |
| farming_carrot_1.png | carrots_stage_0.png | blocks |
| farming_carrot_2.png | carrots_stage_1.png | blocks |
| farming_carrot_3.png | carrots_stage_2.png | blocks |
| farming_carrot_4.png | carrots_stage_3.png | blocks |
| farming_carrot_gold.png | carrot_golden.png | items |
| farming_pumpkin_face.png | pumpkin_face.png | (asset missing) |
| farming_pumpkin_face_light.png | pumpkin_face.png | (asset missing) |
| farming_tool_diamondhoe.png | diamond_hoe.png | items |
| farming_tool_goldhoe.png | gold_hoe.png | items |
| farming_tool_steelhoe.png | iron_hoe.png | items |
| farming_tool_stonehoe.png | stone_hoe.png | items |
| farming_tool_woodhoe.png | wood_hoe.png | items |
| farming_wheat_harvested.png | wheat.png | items |
| mcl_armor_boots_chain.png | chainmail_boots.png | items |
| mcl_armor_boots_diamond.png | diamond_boots.png | items |
| mcl_armor_boots_gold.png | gold_boots.png | items |
| mcl_armor_boots_iron.png | iron_boots.png | items |
| mcl_armor_boots_leather.png | leather_boots.png | items |
| mcl_armor_chestplate_chain.png | chainmail_chestplate.png | items |
| mcl_armor_chestplate_diamond.png | diamond_chestplate.png | items |
| mcl_armor_chestplate_gold.png | gold_chestplate.png | items |
| mcl_armor_chestplate_iron.png | iron_chestplate.png | items |
| mcl_armor_chestplate_leather.png | leather_chestplate.png | items |
| mcl_armor_helmet_chain.png | chainmail_helmet.png | items |
| mcl_armor_helmet_diamond.png | diamond_helmet.png | items |
| mcl_armor_helmet_gold.png | gold_helmet.png | items |
| mcl_armor_helmet_iron.png | iron_helmet.png | items |
| mcl_armor_helmet_leather.png | leather_helmet.png | items |
| mcl_armor_inv_boots_chain.png | chainmail_boots.png | items |
| mcl_armor_inv_boots_diamond.png | diamond_boots.png | items |
| mcl_armor_inv_boots_gold.png | gold_boots.png | items |
| mcl_armor_inv_boots_iron.png | iron_boots.png | items |
| mcl_armor_inv_boots_leather.png | leather_boots.png | items |
| mcl_armor_inv_chestplate_chain.png | chainmail_chestplate.png | items |
| mcl_armor_inv_chestplate_diamond.png | diamond_chestplate.png | items |
| mcl_armor_inv_chestplate_gold.png | gold_chestplate.png | items |
| mcl_armor_inv_chestplate_iron.png | iron_chestplate.png | items |
| mcl_armor_inv_chestplate_leather.png | leather_chestplate.png | items |
| mcl_armor_inv_helmet_chain.png | chainmail_helmet.png | items |
| mcl_armor_inv_helmet_diamond.png | diamond_helmet.png | items |
| mcl_armor_inv_helmet_gold.png | gold_helmet.png | items |
| mcl_armor_inv_helmet_iron.png | iron_helmet.png | items |
| mcl_armor_inv_helmet_leather.png | leather_helmet.png | items |
| mcl_armor_inv_leggings_chain.png | chainmail_leggings.png | items |
| mcl_armor_inv_leggings_diamond.png | diamond_leggings.png | items |
| mcl_armor_inv_leggings_gold.png | gold_leggings.png | items |
| mcl_armor_inv_leggings_iron.png | iron_leggings.png | items |
| mcl_armor_inv_leggings_leather.png | leather_leggings.png | items |
| mcl_armor_leggings_chain.png | chainmail_leggings.png | items |
| mcl_armor_leggings_diamond.png | diamond_leggings.png | items |
| mcl_armor_leggings_gold.png | gold_leggings.png | items |
| mcl_armor_leggings_iron.png | iron_leggings.png | items |
| mcl_armor_leggings_leather.png | leather_leggings.png | items |
| mcl_core_glass_black_detail.png | glass_black.png | blocks |
| mcl_core_glass_blue_detail.png | glass_blue.png | blocks |
| mcl_core_glass_brown_detail.png | glass_brown.png | blocks |
| mcl_core_glass_cyan_detail.png | glass_cyan.png | blocks |
| mcl_core_glass_gray_detail.png | glass_gray.png | blocks |
| mcl_core_glass_green_detail.png | glass_green.png | blocks |
| mcl_core_glass_light_blue_detail.png | glass_light_blue.png | blocks |
| mcl_core_glass_lime_detail.png | glass_lime.png | blocks |
| mcl_core_glass_magenta_detail.png | glass_magenta.png | blocks |
| mcl_core_glass_orange_detail.png | glass_orange.png | blocks |
| mcl_core_glass_pink_detail.png | glass_pink.png | blocks |
| mcl_core_glass_purple_detail.png | glass_purple.png | blocks |
| mcl_core_glass_red_detail.png | glass_red.png | blocks |
| mcl_core_glass_silver_detail.png | glass_silver.png | blocks |
| mcl_core_glass_white_detail.png | glass_white.png | blocks |
| mcl_core_glass_yellow_detail.png | glass_yellow.png | blocks |
| mcl_core_grass_block_side_overlay.png | grass_side_overlay.png | blocks |
| mcl_core_grass_block_top.png | grass_top.png | blocks |
| mcl_core_grass_path_side.png | grass_side.png | blocks |
| mcl_core_grass_path_top.png | grass_top.png | blocks |
| mcl_core_grass_side_snowed.png | grass_side_snowed.png | blocks |
| mcl_core_ice_blue.png | ice_packed.png | blocks |
| mcl_core_lapis.png | lapis_ore.png | blocks |
| mcl_core_papyrus.png | reeds.png | blocks |
| mcl_core_sapling_big_oak.png | sapling_roofed_oak.png | blocks |
| mcl_nether_netherbrick.png | nether_brick.png | blocks |
| mcl_nether_quartz_chiseled_side.png | quartz_block_chiseled.png | blocks |
| mcl_nether_quartz_chiseled_top.png | quartz_block_chiseled_top.png | blocks |
| mcl_nether_quartz_pillar_side.png | quartz_block_lines.png | blocks |
| mcl_nether_quartz_pillar_top.png | quartz_block_lines_top.png | blocks |

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
| default_stick.png | stick.png | items |
| default_stone.png | stone.png | blocks |
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
| mcl_end_dragon_egg.png | dragon_egg.png | blocks |
| mcl_end_end_stone.png | end_stone.png | blocks |
| mcl_end_ender_eye.png | ender_eye.png | items |
| mcl_end_endframe_eye.png | endframe_eye.png | blocks |
| mcl_end_endframe_side.png | endframe_side.png | blocks |
| mcl_end_endframe_top.png | endframe_top.png | blocks |
| mcl_experience_bottle.png | experience_bottle.png | items |
| mcl_experience_orb.png | experience_orb.png | entity |
| mcl_jukebox_side.png | jukebox_side.png | blocks |
| mcl_jukebox_top.png | jukebox_top.png | blocks |
| mcl_nether_glowstone.png | glowstone.png | blocks |
| mcl_nether_glowstone_dust.png | glowstone_dust.png | items |
| mcl_nether_gold_ore.png | gold_ore.png | blocks |
| mcl_nether_nether_brick.png | nether_brick.png | blocks |
| mcl_nether_nether_wart.png | nether_wart.png | items |
| mcl_nether_nether_wart_stage_0.png | nether_wart_stage_0.png | blocks |
| mcl_nether_nether_wart_stage_1.png | nether_wart_stage_1.png | blocks |
| mcl_nether_nether_wart_stage_2.png | nether_wart_stage_2.png | blocks |
| mcl_nether_netherrack.png | netherrack.png | blocks |
| mcl_nether_quartz.png | quartz.png | items |
| mcl_nether_quartz_block_bottom.png | quartz_block_bottom.png | blocks |
| mcl_nether_quartz_block_side.png | quartz_block_side.png | blocks |
| mcl_nether_quartz_block_top.png | quartz_block_top.png | blocks |
| mcl_nether_quartz_ore.png | quartz_ore.png | blocks |
| mcl_nether_soul_sand.png | soul_sand.png | blocks |

## Token matches

| mod texture | vanilla asset | source |
|---|---|---|
| redstone_redstone_block.png | redstone_block.png | blocks |
| redstone_redstone_dust.png | redstone_dust.png | items |
