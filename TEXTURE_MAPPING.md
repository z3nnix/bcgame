# Betacraft texture mapping plan

How the engine resolves media (Luanti 5.16, `Server::fillMediaCache`):
builtin locale -> `~/.minetest/textures/server` -> **game-level `textures/`** -> mod media dirs.
The first file found for a basename wins. All mods reference textures by bare basename,
so dropping a file named exactly like the mod texture into `textures/` overrides it.

## Inventory

- central `textures/`: **3235** files.
- vanilla assets (`assets/minecraft/textures/`, untouched): **991** basenames.

## Match status

- **manual** (`tools/renames.csv`, hand-curated): 200
- **exact** (mod name == vanilla name): 27
- **prefix strip** (`mcl_<mod>_`, `mcl_core_`, `mclx_`, `mcl_`, `default_`, `farming_`): 345
- **token match** (same word set, one candidate): 2
- **excluded** (`tools/exclusions.csv`, not mapped): 2661
- **unmapped**: 0 -> `mapping_unmapped.txt`

Mapped: 574/3235 (17.7%); resolved to an existing asset: 574. Accounted: 3235/3235 (100.0%).

## How to apply

Copy the vanilla asset into `textures/` under the MOD texture name, e.g.:

```
cp assets/minecraft/textures/blocks/stone.png textures/mcl_core_stone.png
```

or run `python3 tools/gen_texture_map.py --apply` to auto-apply every mapped
entry (manual + exact + prefix-strip + token). Add entries to `tools/renames.csv`
for names the auto rules cannot derive, and to `tools/exclusions.csv` for names
that must never map (fonts, GUI, mod-only art).

Regenerate this file with `python3 tools/gen_texture_map.py`.

## Manual matches (tools/renames.csv)

| mod texture | vanilla asset | source |
|---|---|---|
| bucket.png | bucket_empty.png | items |
| bucket_river_water.png | bucket_water.png | items |
| character.png | entity/steve.png | entity |
| default_acacia_leaves.png | leaves_acacia.png | blocks |
| default_acacia_sapling.png | sapling_acacia.png | blocks |
| default_acacia_tree.png | log_acacia.png | blocks |
| default_acacia_tree_top.png | log_acacia_top.png | blocks |
| default_acacia_wood.png | log_acacia.png | blocks |
| default_book.png | items/book_normal.png | items |
| default_clay_brick.png | items/brick.png | items |
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
| default_wood.png | planks_oak.png | blocks |
| doors_trapdoor.png | trapdoor.png | blocks |
| doors_trapdoor_steel.png | iron_trapdoor.png | blocks |
| farming_carrot_1.png | carrots_stage_0.png | blocks |
| farming_carrot_2.png | carrots_stage_1.png | blocks |
| farming_carrot_3.png | carrots_stage_2.png | blocks |
| farming_carrot_4.png | carrots_stage_3.png | blocks |
| farming_carrot_gold.png | carrot_golden.png | items |
| farming_pumpkin_face.png | pumpkin_face_off.png | blocks |
| farming_pumpkin_face_light.png | pumpkin_face_on.png | blocks |
| farming_tool_diamondhoe.png | diamond_hoe.png | items |
| farming_tool_goldhoe.png | gold_hoe.png | items |
| farming_tool_steelhoe.png | iron_hoe.png | items |
| farming_tool_stonehoe.png | stone_hoe.png | items |
| farming_tool_woodhoe.png | wood_hoe.png | items |
| farming_wheat_harvested.png | wheat.png | items |
| hardened_clay_stained_grey.png | hardened_clay_stained_silver.png | blocks |
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
| mcl_core_andesite.png | stone_andesite.png | blocks |
| mcl_core_andesite_smooth.png | stone_andesite_smooth.png | blocks |
| mcl_core_diorite_smooth.png | stone_diorite_smooth.png | blocks |
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
| mcl_core_granite.png | stone_granite.png | blocks |
| mcl_core_granite_smooth.png | stone_granite_smooth.png | blocks |
| mcl_core_grass_block_side_overlay.png | grass_side_overlay.png | blocks |
| mcl_core_grass_block_top.png | grass_top.png | blocks |
| mcl_core_grass_path_side.png | grass_side.png | blocks |
| mcl_core_grass_path_top.png | grass_top.png | blocks |
| mcl_core_grass_side_snowed.png | grass_side_snowed.png | blocks |
| mcl_core_ice_blue.png | ice_packed.png | blocks |
| mcl_core_lapis.png | lapis_ore.png | blocks |
| mcl_core_papyrus.png | reeds.png | blocks |
| mcl_core_sapling_big_oak.png | sapling_roofed_oak.png | blocks |
| mcl_experience_bottle.png | experience_bottle.png | items |
| mcl_farming_hayblock_side.png | hay_block_side.png | blocks |
| mcl_farming_hayblock_top.png | hay_block_top.png | blocks |
| mcl_farming_melon_seeds.png | seeds_melon.png | items |
| mcl_farming_pumpkin_face.png | pumpkin_face_off.png | blocks |
| mcl_farming_pumpkin_face_light.png | pumpkin_face_on.png | blocks |
| mcl_farming_pumpkin_seeds.png | seeds_pumpkin.png | items |
| mcl_farming_wheat_seeds.png | seeds_wheat.png | items |
| mcl_heads_creeper.png | entity/creeper/creeper.png | entity/creeper |
| mcl_nether_netherbrick.png | nether_brick.png | blocks |
| mcl_nether_quartz_chiseled_side.png | quartz_block_chiseled.png | blocks |
| mcl_nether_quartz_chiseled_top.png | quartz_block_chiseled_top.png | blocks |
| mcl_nether_quartz_pillar_side.png | quartz_block_lines.png | blocks |
| mcl_nether_quartz_pillar_top.png | quartz_block_lines_top.png | blocks |
| mesecons_noteblock.png | noteblock.png | blocks |
| mesecons_piston_bottom.png | piston_bottom.png | blocks |
| mesecons_piston_on_front.png | piston_top_normal.png | blocks |
| mesecons_piston_pusher_front.png | piston_inner.png | blocks |
| mesecons_piston_pusher_front_sticky.png | piston_inner.png | blocks |
| mesecons_walllever_lever.png | lever.png | blocks |
| mesecons_walllever_lever_inv.png | lever.png | blocks |
| mobs_mc_horse_markings_blackdots.png | entity/horse/horse_markings_blackdots.png | entity/horse |
| mobs_mc_horse_markings_white.png | entity/horse/horse_markings_white.png | entity/horse |
| mobs_mc_horse_markings_whitedots.png | entity/horse/horse_markings_whitedots.png | entity/horse |
| mobs_mc_horse_markings_whitefield.png | entity/horse/horse_markings_whitefield.png | entity/horse |
| xpanes_pane_iron.png | iron_bars.png | blocks |
| xpanes_top_glass_black.png | glass_pane_top_black.png | blocks |
| xpanes_top_glass_blue.png | glass_pane_top_blue.png | blocks |
| xpanes_top_glass_brown.png | glass_pane_top_brown.png | blocks |
| xpanes_top_glass_cyan.png | glass_pane_top_cyan.png | blocks |
| xpanes_top_glass_gray.png | glass_pane_top_gray.png | blocks |
| xpanes_top_glass_green.png | glass_pane_top_green.png | blocks |
| xpanes_top_glass_light_blue.png | glass_pane_top_light_blue.png | blocks |
| xpanes_top_glass_lime.png | glass_pane_top_lime.png | blocks |
| xpanes_top_glass_magenta.png | glass_pane_top_magenta.png | blocks |
| xpanes_top_glass_natural.png | glass_pane_top.png | blocks |
| xpanes_top_glass_orange.png | glass_pane_top_orange.png | blocks |
| xpanes_top_glass_pink.png | glass_pane_top_pink.png | blocks |
| xpanes_top_glass_purple.png | glass_pane_top_purple.png | blocks |
| xpanes_top_glass_red.png | glass_pane_top_red.png | blocks |
| xpanes_top_glass_silver.png | glass_pane_top_silver.png | blocks |
| xpanes_top_glass_white.png | glass_pane_top_white.png | blocks |
| xpanes_top_glass_yellow.png | glass_pane_top_yellow.png | blocks |

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
| wool_dark_grey.png | wool_dark_grey.png | blocks |

## Prefix-stripped matches

| mod texture | vanilla asset | source |
|---|---|---|
| default_apple.png | apple.png | items |
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
| mcl_anvils_anvil_base.png | anvil_base.png | blocks |
| mcl_anvils_anvil_top_damaged_0.png | anvil_top_damaged_0.png | blocks |
| mcl_anvils_anvil_top_damaged_1.png | anvil_top_damaged_1.png | blocks |
| mcl_anvils_anvil_top_damaged_2.png | anvil_top_damaged_2.png | blocks |
| mcl_bamboo_flower_pot.png | flower_pot.png | blocks |
| mcl_banners_base.png | base.png | entity/banner |
| mcl_banners_border.png | border.png | entity/banner |
| mcl_banners_bricks.png | bricks.png | entity/banner |
| mcl_banners_circle.png | circle.png | entity/banner |
| mcl_banners_creeper.png | creeper.png | entity/banner |
| mcl_banners_cross.png | cross.png | entity/banner |
| mcl_banners_curly_border.png | curly_border.png | entity/banner |
| mcl_banners_diagonal_left.png | diagonal_left.png | entity/banner |
| mcl_banners_diagonal_right.png | diagonal_right.png | entity/banner |
| mcl_banners_diagonal_up_left.png | diagonal_up_left.png | entity/banner |
| mcl_banners_diagonal_up_right.png | diagonal_up_right.png | entity/banner |
| mcl_banners_flower.png | flower.png | entity/banner |
| mcl_banners_gradient.png | gradient.png | entity/banner |
| mcl_banners_gradient_up.png | gradient_up.png | entity/banner |
| mcl_banners_half_horizontal.png | half_horizontal.png | entity/banner |
| mcl_banners_half_horizontal_bottom.png | half_horizontal_bottom.png | entity/banner |
| mcl_banners_half_vertical.png | half_vertical.png | entity/banner |
| mcl_banners_half_vertical_right.png | half_vertical_right.png | entity/banner |
| mcl_banners_rhombus.png | rhombus.png | entity/banner |
| mcl_banners_skull.png | skull.png | entity/banner |
| mcl_banners_small_stripes.png | small_stripes.png | entity/banner |
| mcl_banners_square_bottom_left.png | square_bottom_left.png | entity/banner |
| mcl_banners_square_bottom_right.png | square_bottom_right.png | entity/banner |
| mcl_banners_square_top_left.png | square_top_left.png | entity/banner |
| mcl_banners_square_top_right.png | square_top_right.png | entity/banner |
| mcl_banners_straight_cross.png | straight_cross.png | entity/banner |
| mcl_banners_stripe_bottom.png | stripe_bottom.png | entity/banner |
| mcl_banners_stripe_center.png | stripe_center.png | entity/banner |
| mcl_banners_stripe_downleft.png | stripe_downleft.png | entity/banner |
| mcl_banners_stripe_downright.png | stripe_downright.png | entity/banner |
| mcl_banners_stripe_left.png | stripe_left.png | entity/banner |
| mcl_banners_stripe_middle.png | stripe_middle.png | entity/banner |
| mcl_banners_stripe_right.png | stripe_right.png | entity/banner |
| mcl_banners_stripe_top.png | stripe_top.png | entity/banner |
| mcl_banners_triangle_bottom.png | triangle_bottom.png | entity/banner |
| mcl_banners_triangle_top.png | triangle_top.png | entity/banner |
| mcl_banners_triangles_bottom.png | triangles_bottom.png | entity/banner |
| mcl_banners_triangles_top.png | triangles_top.png | entity/banner |
| mcl_books_book_writable.png | book_writable.png | items |
| mcl_books_book_written.png | book_written.png | items |
| mcl_bows_arrow.png | arrow.png | items |
| mcl_brewing_stand.png | brewing_stand.png | blocks |
| mcl_cauldrons_cauldron.png | cauldron.png | items |
| mcl_cauldrons_cauldron_bottom.png | cauldron_bottom.png | blocks |
| mcl_cauldrons_cauldron_inner.png | cauldron_inner.png | blocks |
| mcl_cauldrons_cauldron_side.png | cauldron_side.png | blocks |
| mcl_cauldrons_cauldron_top.png | cauldron_top.png | blocks |
| mcl_chests_ender.png | ender.png | entity/chest |
| mcl_cocoas_cocoa_stage_0.png | cocoa_stage_0.png | blocks |
| mcl_cocoas_cocoa_stage_1.png | cocoa_stage_1.png | blocks |
| mcl_cocoas_cocoa_stage_2.png | cocoa_stage_2.png | blocks |
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
| mcl_dispensers_dispenser_front_horizontal.png | dispenser_front_horizontal.png | blocks |
| mcl_dispensers_dispenser_front_vertical.png | dispenser_front_vertical.png | blocks |
| mcl_doors_door_birch.png | door_birch.png | items |
| mcl_doors_door_dark_oak.png | door_dark_oak.png | items |
| mcl_doors_door_dark_oak_lower.png | door_dark_oak_lower.png | blocks |
| mcl_doors_door_dark_oak_upper.png | door_dark_oak_upper.png | blocks |
| mcl_doors_door_iron_lower.png | door_iron_lower.png | blocks |
| mcl_doors_door_iron_upper.png | door_iron_upper.png | blocks |
| mcl_doors_door_jungle.png | door_jungle.png | items |
| mcl_doors_door_jungle_lower.png | door_jungle_lower.png | blocks |
| mcl_doors_door_jungle_upper.png | door_jungle_upper.png | blocks |
| mcl_doors_door_spruce.png | door_spruce.png | items |
| mcl_doors_door_spruce_lower.png | door_spruce_lower.png | blocks |
| mcl_doors_door_spruce_upper.png | door_spruce_upper.png | blocks |
| mcl_droppers_dropper_front_horizontal.png | dropper_front_horizontal.png | blocks |
| mcl_droppers_dropper_front_vertical.png | dropper_front_vertical.png | blocks |
| mcl_enchanting_book_enchanted.png | book_enchanted.png | items |
| mcl_enchanting_table_bottom.png | enchanting_table_bottom.png | blocks |
| mcl_enchanting_table_side.png | enchanting_table_side.png | blocks |
| mcl_enchanting_table_top.png | enchanting_table_top.png | blocks |
| mcl_end_dragon_egg.png | dragon_egg.png | blocks |
| mcl_end_end_stone.png | end_stone.png | blocks |
| mcl_end_ender_eye.png | ender_eye.png | items |
| mcl_end_endframe_eye.png | endframe_eye.png | blocks |
| mcl_end_endframe_side.png | endframe_side.png | blocks |
| mcl_end_endframe_top.png | endframe_top.png | blocks |
| mcl_experience_orb.png | experience_orb.png | entity |
| mcl_farming_farmland_dry.png | farmland_dry.png | blocks |
| mcl_farming_farmland_wet.png | farmland_wet.png | blocks |
| mcl_farming_melon_stem_connected.png | melon_stem_connected.png | blocks |
| mcl_farming_melon_stem_disconnected.png | melon_stem_disconnected.png | blocks |
| mcl_farming_potatoes_stage_0.png | potatoes_stage_0.png | blocks |
| mcl_farming_potatoes_stage_1.png | potatoes_stage_1.png | blocks |
| mcl_farming_potatoes_stage_2.png | potatoes_stage_2.png | blocks |
| mcl_farming_potatoes_stage_3.png | potatoes_stage_3.png | blocks |
| mcl_farming_pumpkin_pie.png | pumpkin_pie.png | items |
| mcl_farming_pumpkin_stem_connected.png | pumpkin_stem_connected.png | blocks |
| mcl_farming_pumpkin_stem_disconnected.png | pumpkin_stem_disconnected.png | blocks |
| mcl_farming_wheat_stage_0.png | wheat_stage_0.png | blocks |
| mcl_farming_wheat_stage_1.png | wheat_stage_1.png | blocks |
| mcl_farming_wheat_stage_2.png | wheat_stage_2.png | blocks |
| mcl_farming_wheat_stage_3.png | wheat_stage_3.png | blocks |
| mcl_farming_wheat_stage_4.png | wheat_stage_4.png | blocks |
| mcl_farming_wheat_stage_5.png | wheat_stage_5.png | blocks |
| mcl_farming_wheat_stage_6.png | wheat_stage_6.png | blocks |
| mcl_farming_wheat_stage_7.png | wheat_stage_7.png | blocks |
| mcl_flowers_double_plant_fern_bottom.png | double_plant_fern_bottom.png | blocks |
| mcl_flowers_double_plant_fern_top.png | double_plant_fern_top.png | blocks |
| mcl_flowers_double_plant_grass_bottom.png | double_plant_grass_bottom.png | blocks |
| mcl_flowers_double_plant_grass_top.png | double_plant_grass_top.png | blocks |
| mcl_flowers_double_plant_paeonia_bottom.png | double_plant_paeonia_bottom.png | blocks |
| mcl_flowers_double_plant_paeonia_top.png | double_plant_paeonia_top.png | blocks |
| mcl_flowers_double_plant_rose_bottom.png | double_plant_rose_bottom.png | blocks |
| mcl_flowers_double_plant_rose_top.png | double_plant_rose_top.png | blocks |
| mcl_flowers_double_plant_sunflower_back.png | double_plant_sunflower_back.png | blocks |
| mcl_flowers_double_plant_sunflower_bottom.png | double_plant_sunflower_bottom.png | blocks |
| mcl_flowers_double_plant_sunflower_front.png | double_plant_sunflower_front.png | blocks |
| mcl_flowers_double_plant_sunflower_top.png | double_plant_sunflower_top.png | blocks |
| mcl_flowers_double_plant_syringa_bottom.png | double_plant_syringa_bottom.png | blocks |
| mcl_flowers_double_plant_syringa_top.png | double_plant_syringa_top.png | blocks |
| mcl_flowers_fern.png | fern.png | blocks |
| mcl_flowers_tallgrass.png | tallgrass.png | blocks |
| mcl_heads_dragon.png | dragon.png | entity/enderdragon |
| mcl_heads_skeleton.png | skeleton.png | entity/skeleton |
| mcl_heads_steve.png | steve.png | entity |
| mcl_heads_wither_skeleton.png | wither_skeleton.png | entity/skeleton |
| mcl_heads_zombie.png | zombie.png | entity/zombie |
| mcl_hoppers_hopper_inside.png | hopper_inside.png | blocks |
| mcl_hoppers_hopper_outside.png | hopper_outside.png | blocks |
| mcl_hoppers_hopper_top.png | hopper_top.png | blocks |
| mcl_inventory_empty_armor_slot_boots.png | empty_armor_slot_boots.png | items |
| mcl_inventory_empty_armor_slot_chestplate.png | empty_armor_slot_chestplate.png | items |
| mcl_inventory_empty_armor_slot_helmet.png | empty_armor_slot_helmet.png | items |
| mcl_inventory_empty_armor_slot_leggings.png | empty_armor_slot_leggings.png | items |
| mcl_itemframes_item_frame.png | item_frame.png | items |
| mcl_itemframes_itemframe_background.png | itemframe_background.png | blocks |
| mcl_jukebox_record_11.png | record_11.png | items |
| mcl_jukebox_record_13.png | record_13.png | items |
| mcl_jukebox_record_blocks.png | record_blocks.png | items |
| mcl_jukebox_record_cat.png | record_cat.png | items |
| mcl_jukebox_record_chirp.png | record_chirp.png | items |
| mcl_jukebox_record_far.png | record_far.png | items |
| mcl_jukebox_record_mall.png | record_mall.png | items |
| mcl_jukebox_record_mellohi.png | record_mellohi.png | items |
| mcl_jukebox_record_stal.png | record_stal.png | items |
| mcl_jukebox_record_strad.png | record_strad.png | items |
| mcl_jukebox_record_wait.png | record_wait.png | items |
| mcl_jukebox_record_ward.png | record_ward.png | items |
| mcl_jukebox_side.png | jukebox_side.png | blocks |
| mcl_jukebox_top.png | jukebox_top.png | blocks |
| mcl_maps_map_background.png | map_background.png | map |
| mcl_maps_map_empty.png | map_empty.png | items |
| mcl_maps_map_filled.png | map_filled.png | items |
| mcl_minecarts_minecart.png | minecart.png | entity |
| mcl_minecarts_minecart_chest.png | minecart_chest.png | items |
| mcl_minecarts_minecart_command_block.png | minecart_command_block.png | items |
| mcl_minecarts_minecart_furnace.png | minecart_furnace.png | items |
| mcl_minecarts_minecart_hopper.png | minecart_hopper.png | items |
| mcl_minecarts_minecart_normal.png | minecart_normal.png | items |
| mcl_minecarts_minecart_tnt.png | minecart_tnt.png | items |
| mcl_minecarts_rail_activator.png | rail_activator.png | blocks |
| mcl_minecarts_rail_activator_powered.png | rail_activator_powered.png | blocks |
| mcl_minecarts_rail_detector.png | rail_detector.png | blocks |
| mcl_minecarts_rail_detector_powered.png | rail_detector_powered.png | blocks |
| mcl_minecarts_rail_golden.png | rail_golden.png | blocks |
| mcl_minecarts_rail_golden_powered.png | rail_golden_powered.png | blocks |
| mcl_mobitems_beef_cooked.png | beef_cooked.png | items |
| mcl_mobitems_beef_raw.png | beef_raw.png | items |
| mcl_mobitems_blaze_powder.png | blaze_powder.png | items |
| mcl_mobitems_blaze_rod.png | blaze_rod.png | items |
| mcl_mobitems_bone.png | bone.png | items |
| mcl_mobitems_bucket_milk.png | bucket_milk.png | items |
| mcl_mobitems_carrot_on_a_stick.png | carrot_on_a_stick.png | items |
| mcl_mobitems_chicken_cooked.png | chicken_cooked.png | items |
| mcl_mobitems_chicken_raw.png | chicken_raw.png | items |
| mcl_mobitems_diamond_horse_armor.png | diamond_horse_armor.png | items |
| mcl_mobitems_feather.png | feather.png | items |
| mcl_mobitems_ghast_tear.png | ghast_tear.png | items |
| mcl_mobitems_gold_horse_armor.png | gold_horse_armor.png | items |
| mcl_mobitems_horse_armor_diamond.png | horse_armor_diamond.png | entity/horse/armor |
| mcl_mobitems_horse_armor_gold.png | horse_armor_gold.png | entity/horse/armor |
| mcl_mobitems_horse_armor_iron.png | horse_armor_iron.png | entity/horse/armor |
| mcl_mobitems_iron_horse_armor.png | iron_horse_armor.png | items |
| mcl_mobitems_leather.png | leather.png | items |
| mcl_mobitems_magma_cream.png | magma_cream.png | items |
| mcl_mobitems_mutton_cooked.png | mutton_cooked.png | items |
| mcl_mobitems_mutton_raw.png | mutton_raw.png | items |
| mcl_mobitems_nether_star.png | nether_star.png | items |
| mcl_mobitems_porkchop_cooked.png | porkchop_cooked.png | items |
| mcl_mobitems_porkchop_raw.png | porkchop_raw.png | items |
| mcl_mobitems_rabbit_cooked.png | rabbit_cooked.png | items |
| mcl_mobitems_rabbit_foot.png | rabbit_foot.png | items |
| mcl_mobitems_rabbit_hide.png | rabbit_hide.png | items |
| mcl_mobitems_rabbit_raw.png | rabbit_raw.png | items |
| mcl_mobitems_rabbit_stew.png | rabbit_stew.png | items |
| mcl_mobitems_rotten_flesh.png | rotten_flesh.png | items |
| mcl_mobitems_saddle.png | saddle.png | items |
| mcl_mobitems_slimeball.png | slimeball.png | items |
| mcl_mobitems_spider_eye.png | spider_eye.png | items |
| mcl_mobitems_string.png | string.png | items |
| mcl_moon_moon_phases.png | moon_phases.png | environment |
| mcl_mushrooms_mushroom_block_inside.png | mushroom_block_inside.png | blocks |
| mcl_mushrooms_mushroom_block_skin_brown.png | mushroom_block_skin_brown.png | blocks |
| mcl_mushrooms_mushroom_block_skin_red.png | mushroom_block_skin_red.png | blocks |
| mcl_mushrooms_mushroom_block_skin_stem.png | mushroom_block_skin_stem.png | blocks |
| mcl_nether_glowstone.png | glowstone.png | blocks |
| mcl_nether_glowstone_dust.png | glowstone_dust.png | items |
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
| mcl_ocean_prismarine_bricks.png | prismarine_bricks.png | blocks |
| mcl_ocean_prismarine_crystals.png | prismarine_crystals.png | items |
| mcl_ocean_prismarine_dark.png | prismarine_dark.png | blocks |
| mcl_ocean_prismarine_shard.png | prismarine_shard.png | items |
| mcl_ocean_sea_lantern.png | sea_lantern.png | blocks |
| mcl_paintings_painting.png | painting.png | items |
| mcl_playerplus_end_sky.png | end_sky.png | environment |
| mcl_portals_end_portal.png | end_portal.png | entity |
| mcl_portals_endframe_eye.png | endframe_eye.png | blocks |
| mcl_portals_endframe_side.png | endframe_side.png | blocks |
| mcl_portals_endframe_top.png | endframe_top.png | blocks |
| mcl_portals_portal.png | portal.png | blocks |
| mcl_potions_melon_speckled.png | melon_speckled.png | items |
| mcl_potions_potion_overlay.png | potion_overlay.png | items |
| mcl_potions_spider_eye_fermented.png | spider_eye_fermented.png | items |
| mcl_sponges_sponge.png | sponge.png | blocks |
| mcl_sponges_sponge_wet.png | sponge_wet.png | blocks |
| mcl_stairs_stone_slab_side.png | stone_slab_side.png | blocks |
| mcl_stairs_stone_slab_top.png | stone_slab_top.png | blocks |
| mcl_throwing_egg.png | egg.png | items |
| mcl_throwing_ender_pearl.png | ender_pearl.png | items |
| mcl_throwing_snowball.png | snowball.png | items |

## Token matches

| mod texture | vanilla asset | source |
|---|---|---|
| redstone_redstone_block.png | redstone_block.png | blocks |
| redstone_redstone_dust.png | redstone_dust.png | items |

## Excluded (tools/exclusions.csv)

| mod texture | reason |
|---|---|
| 3d_armor_stand_item.png | mod-specific |
| _0.png | font glyph (not content) |
| _1.png | font glyph (not content) |
| _1_2.png | font glyph (not content) |
| _1_4.png | font glyph (not content) |
| _1_sup.png | font glyph (not content) |
| _2.png | font glyph (not content) |
| _2_sup.png | font glyph (not content) |
| _3.png | font glyph (not content) |
| _3_4.png | font glyph (not content) |
| _3_sup.png | font glyph (not content) |
| _4.png | font glyph (not content) |
| _5.png | font glyph (not content) |
| _6.png | font glyph (not content) |
| _7.png | font glyph (not content) |
| _8.png | font glyph (not content) |
| _9.png | font glyph (not content) |
| _a.png | font glyph (not content) |
| _a_.png | font glyph (not content) |
| _a_acute.png | font glyph (not content) |
| _a_acute_.png | font glyph (not content) |
| _a_breve.png | font glyph (not content) |
| _a_breve_.png | font glyph (not content) |
| _a_circumflex.png | font glyph (not content) |
| _a_circumflex_.png | font glyph (not content) |
| _a_grave.png | font glyph (not content) |
| _a_grave_.png | font glyph (not content) |
| _a_macron.png | font glyph (not content) |
| _a_macron_.png | font glyph (not content) |
| _a_ogonek.png | font glyph (not content) |
| _a_ogonek_.png | font glyph (not content) |
| _a_ring.png | font glyph (not content) |
| _a_ring_.png | font glyph (not content) |
| _a_sup.png | font glyph (not content) |
| _a_tilde.png | font glyph (not content) |
| _a_tilde_.png | font glyph (not content) |
| _acute.png | font glyph (not content) |
| _ae.png | font glyph (not content) |
| _ae_.png | font glyph (not content) |
| _ae_lig.png | font glyph (not content) |
| _ae_lig_.png | font glyph (not content) |
| _am.png | font glyph (not content) |
| _ap.png | font glyph (not content) |
| _as.png | font glyph (not content) |
| _at.png | font glyph (not content) |
| _b.png | font glyph (not content) |
| _b_.png | font glyph (not content) |
| _bl.png | font glyph (not content) |
| _br.png | font glyph (not content) |
| _broken_bar.png | font glyph (not content) |
| _c.png | font glyph (not content) |
| _c_.png | font glyph (not content) |
| _c_acute.png | font glyph (not content) |
| _c_acute_.png | font glyph (not content) |
| _c_caron.png | font glyph (not content) |
| _c_caron_.png | font glyph (not content) |
| _c_cedille.png | font glyph (not content) |
| _c_cedille_.png | font glyph (not content) |
| _c_circumflex.png | font glyph (not content) |
| _c_circumflex_.png | font glyph (not content) |
| _c_overdot.png | font glyph (not content) |
| _c_overdot_.png | font glyph (not content) |
| _ca.png | font glyph (not content) |
| _cedille.png | font glyph (not content) |
| _cent.png | font glyph (not content) |
| _cl.png | font glyph (not content) |
| _cm.png | font glyph (not content) |
| _co.png | font glyph (not content) |
| _copyright.png | font glyph (not content) |
| _cr.png | font glyph (not content) |
| _currency.png | font glyph (not content) |
| _cyr_ae.png | font glyph (not content) |
| _cyr_ae_.png | font glyph (not content) |
| _cyr_b.png | font glyph (not content) |
| _cyr_b_.png | font glyph (not content) |
| _cyr_c.png | font glyph (not content) |
| _cyr_c_.png | font glyph (not content) |
| _cyr_ch.png | font glyph (not content) |
| _cyr_ch_.png | font glyph (not content) |
| _cyr_d_.png | font glyph (not content) |
| _cyr_dje.png | font glyph (not content) |
| _cyr_dje_.png | font glyph (not content) |
| _cyr_dzhe.png | font glyph (not content) |
| _cyr_dzhe_.png | font glyph (not content) |
| _cyr_e.png | font glyph (not content) |
| _cyr_e_.png | font glyph (not content) |
| _cyr_f.png | font glyph (not content) |
| _cyr_f_.png | font glyph (not content) |
| _cyr_g.png | font glyph (not content) |
| _cyr_g_.png | font glyph (not content) |
| _cyr_g_stroke.png | font glyph (not content) |
| _cyr_g_stroke_.png | font glyph (not content) |
| _cyr_ge.png | font glyph (not content) |
| _cyr_ge_.png | font glyph (not content) |
| _cyr_gje.png | font glyph (not content) |
| _cyr_gje_.png | font glyph (not content) |
| _cyr_h_.png | font glyph (not content) |
| _cyr_i_.png | font glyph (not content) |
| _cyr_i_breve_.png | font glyph (not content) |
| _cyr_i_circumflex_.png | font glyph (not content) |
| _cyr_i_diaresis_.png | font glyph (not content) |
| _cyr_i_grave_.png | font glyph (not content) |
| _cyr_i_macron_.png | font glyph (not content) |
| _cyr_k.png | font glyph (not content) |
| _cyr_kh.png | font glyph (not content) |
| _cyr_kh_.png | font glyph (not content) |
| _cyr_kje.png | font glyph (not content) |
| _cyr_kje_.png | font glyph (not content) |
| _cyr_l.png | font glyph (not content) |
| _cyr_l_.png | font glyph (not content) |
| _cyr_lje_.png | font glyph (not content) |
| _cyr_m.png | font glyph (not content) |
| _cyr_n.png | font glyph (not content) |
| _cyr_ng.png | font glyph (not content) |
| _cyr_ng_.png | font glyph (not content) |
| _cyr_nje.png | font glyph (not content) |
| _cyr_nje_.png | font glyph (not content) |
| _cyr_oo.png | font glyph (not content) |
| _cyr_oo_.png | font glyph (not content) |
| _cyr_p.png | font glyph (not content) |
| _cyr_p_.png | font glyph (not content) |
| _cyr_sh.png | font glyph (not content) |
| _cyr_sh_.png | font glyph (not content) |
| _cyr_shch.png | font glyph (not content) |
| _cyr_shch_.png | font glyph (not content) |
| _cyr_t.png | font glyph (not content) |
| _cyr_tshe.png | font glyph (not content) |
| _cyr_tshe_.png | font glyph (not content) |
| _cyr_u_.png | font glyph (not content) |
| _cyr_u_breve_.png | font glyph (not content) |
| _cyr_u_diaresis_.png | font glyph (not content) |
| _cyr_u_macron_.png | font glyph (not content) |
| _cyr_ue.png | font glyph (not content) |
| _cyr_ue_.png | font glyph (not content) |
| _cyr_uu.png | font glyph (not content) |
| _cyr_v.png | font glyph (not content) |
| _cyr_ya.png | font glyph (not content) |
| _cyr_ya_.png | font glyph (not content) |
| _cyr_yat.png | font glyph (not content) |
| _cyr_yat_.png | font glyph (not content) |
| _cyr_ye.png | font glyph (not content) |
| _cyr_ye_.png | font glyph (not content) |
| _cyr_ye_acute.png | font glyph (not content) |
| _cyr_ye_acute_.png | font glyph (not content) |
| _cyr_yer.png | font glyph (not content) |
| _cyr_yer_.png | font glyph (not content) |
| _cyr_yerj.png | font glyph (not content) |
| _cyr_yerj_.png | font glyph (not content) |
| _cyr_yery.png | font glyph (not content) |
| _cyr_yery_.png | font glyph (not content) |
| _cyr_yi.png | font glyph (not content) |
| _cyr_yi_.png | font glyph (not content) |
| _cyr_yu.png | font glyph (not content) |
| _cyr_yu_.png | font glyph (not content) |
| _cyr_z.png | font glyph (not content) |
| _cyr_z_.png | font glyph (not content) |
| _cyr_zh.png | font glyph (not content) |
| _cyr_zh_.png | font glyph (not content) |
| _cyr_zh_breve.png | font glyph (not content) |
| _cyr_zh_breve_.png | font glyph (not content) |
| _cyr_zje.png | font glyph (not content) |
| _cyr_zje_.png | font glyph (not content) |
| _d.png | font glyph (not content) |
| _d_.png | font glyph (not content) |
| _d_caron.png | font glyph (not content) |
| _d_caron_.png | font glyph (not content) |
| _d_dash.png | font glyph (not content) |
| _d_dash_.png | font glyph (not content) |
| _degree.png | font glyph (not content) |
| _diaresis.png | font glyph (not content) |
| _div.png | font glyph (not content) |
| _dl.png | font glyph (not content) |
| _dt.png | font glyph (not content) |
| _dv.png | font glyph (not content) |
| _e.png | font glyph (not content) |
| _e_.png | font glyph (not content) |
| _e_acute.png | font glyph (not content) |
| _e_acute_.png | font glyph (not content) |
| _e_caron.png | font glyph (not content) |
| _e_caron_.png | font glyph (not content) |
| _e_circumflex.png | font glyph (not content) |
| _e_circumflex_.png | font glyph (not content) |
| _e_grave.png | font glyph (not content) |
| _e_grave_.png | font glyph (not content) |
| _e_macron.png | font glyph (not content) |
| _e_macron_.png | font glyph (not content) |
| _e_ogonek.png | font glyph (not content) |
| _e_ogonek_.png | font glyph (not content) |
| _e_overdot.png | font glyph (not content) |
| _e_overdot_.png | font glyph (not content) |
| _ee.png | font glyph (not content) |
| _ee_.png | font glyph (not content) |
| _ellipsis.png | font glyph (not content) |
| _eng.png | font glyph (not content) |
| _eng_.png | font glyph (not content) |
| _eq.png | font glyph (not content) |
| _euro.png | font glyph (not content) |
| _ex.png | font glyph (not content) |
| _ex_inv.png | font glyph (not content) |
| _f.png | font glyph (not content) |
| _f_.png | font glyph (not content) |
| _g.png | font glyph (not content) |
| _g_.png | font glyph (not content) |
| _g_breve.png | font glyph (not content) |
| _g_breve_.png | font glyph (not content) |
| _g_cedille.png | font glyph (not content) |
| _g_cedille_.png | font glyph (not content) |
| _g_circumflex.png | font glyph (not content) |
| _g_circumflex_.png | font glyph (not content) |
| _g_overdot.png | font glyph (not content) |
| _g_overdot_.png | font glyph (not content) |
| _gr.png | font glyph (not content) |
| _grk_a.png | font glyph (not content) |
| _grk_a_tonos.png | font glyph (not content) |
| _grk_a_tonos_.png | font glyph (not content) |
| _grk_b.png | font glyph (not content) |
| _grk_c.png | font glyph (not content) |
| _grk_ch.png | font glyph (not content) |
| _grk_d.png | font glyph (not content) |
| _grk_d_.png | font glyph (not content) |
| _grk_e.png | font glyph (not content) |
| _grk_e_tonos.png | font glyph (not content) |
| _grk_e_tonos_.png | font glyph (not content) |
| _grk_eta.png | font glyph (not content) |
| _grk_eta_tonos.png | font glyph (not content) |
| _grk_eta_tonos_.png | font glyph (not content) |
| _grk_f.png | font glyph (not content) |
| _grk_i_dtonos.png | font glyph (not content) |
| _grk_i_tonos.png | font glyph (not content) |
| _grk_i_tonos_.png | font glyph (not content) |
| _grk_kai.png | font glyph (not content) |
| _grk_kai_.png | font glyph (not content) |
| _grk_l.png | font glyph (not content) |
| _grk_l_.png | font glyph (not content) |
| _grk_o_tonos.png | font glyph (not content) |
| _grk_o_tonos_.png | font glyph (not content) |
| _grk_om.png | font glyph (not content) |
| _grk_om_.png | font glyph (not content) |
| _grk_om_tonos.png | font glyph (not content) |
| _grk_om_tonos_.png | font glyph (not content) |
| _grk_pi.png | font glyph (not content) |
| _grk_ps.png | font glyph (not content) |
| _grk_ps_.png | font glyph (not content) |
| _grk_r.png | font glyph (not content) |
| _grk_s.png | font glyph (not content) |
| _grk_s_.png | font glyph (not content) |
| _grk_t.png | font glyph (not content) |
| _grk_th.png | font glyph (not content) |
| _grk_ths.png | font glyph (not content) |
| _grk_u_dtonos.png | font glyph (not content) |
| _grk_u_tonos.png | font glyph (not content) |
| _grk_u_tonos_.png | font glyph (not content) |
| _grk_xi.png | font glyph (not content) |
| _grk_xi_.png | font glyph (not content) |
| _grk_z.png | font glyph (not content) |
| _gt.png | font glyph (not content) |
| _guill_left.png | font glyph (not content) |
| _guill_right.png | font glyph (not content) |
| _h.png | font glyph (not content) |
| _h_.png | font glyph (not content) |
| _h_circumflex.png | font glyph (not content) |
| _h_circumflex_.png | font glyph (not content) |
| _h_stroke.png | font glyph (not content) |
| _h_stroke_.png | font glyph (not content) |
| _ha.png | font glyph (not content) |
| _hs.png | font glyph (not content) |
| _hyphen.png | font glyph (not content) |
| _i.png | font glyph (not content) |
| _i_.png | font glyph (not content) |
| _i_acute.png | font glyph (not content) |
| _i_acute_.png | font glyph (not content) |
| _i_circumflex.png | font glyph (not content) |
| _i_circumflex_.png | font glyph (not content) |
| _i_dotless.png | font glyph (not content) |
| _i_grave.png | font glyph (not content) |
| _i_grave_.png | font glyph (not content) |
| _i_macron.png | font glyph (not content) |
| _i_macron_.png | font glyph (not content) |
| _i_ogonek.png | font glyph (not content) |
| _i_ogonek_.png | font glyph (not content) |
| _i_overdot_.png | font glyph (not content) |
| _i_tilde.png | font glyph (not content) |
| _i_tilde_.png | font glyph (not content) |
| _j.png | font glyph (not content) |
| _j_.png | font glyph (not content) |
| _j_circumflex.png | font glyph (not content) |
| _j_circumflex_.png | font glyph (not content) |
| _k.png | font glyph (not content) |
| _k_.png | font glyph (not content) |
| _k_cedille.png | font glyph (not content) |
| _k_cedille_.png | font glyph (not content) |
| _l.png | font glyph (not content) |
| _l_.png | font glyph (not content) |
| _l_acute.png | font glyph (not content) |
| _l_acute_.png | font glyph (not content) |
| _l_caron.png | font glyph (not content) |
| _l_caron_.png | font glyph (not content) |
| _l_cedille.png | font glyph (not content) |
| _l_cedille_.png | font glyph (not content) |
| _l_stroke.png | font glyph (not content) |
| _l_stroke_.png | font glyph (not content) |
| _lt.png | font glyph (not content) |
| _m.png | font glyph (not content) |
| _m_.png | font glyph (not content) |
| _macron.png | font glyph (not content) |
| _mn.png | font glyph (not content) |
| _mu.png | font glyph (not content) |
| _n.png | font glyph (not content) |
| _n_.png | font glyph (not content) |
| _n_acute.png | font glyph (not content) |
| _n_acute_.png | font glyph (not content) |
| _n_caron.png | font glyph (not content) |
| _n_caron_.png | font glyph (not content) |
| _n_cedille.png | font glyph (not content) |
| _n_cedille_.png | font glyph (not content) |
| _n_tilde.png | font glyph (not content) |
| _n_tilde_.png | font glyph (not content) |
| _not.png | font glyph (not content) |
| _o.png | font glyph (not content) |
| _o_.png | font glyph (not content) |
| _o_2acute.png | font glyph (not content) |
| _o_2acute_.png | font glyph (not content) |
| _o_acute.png | font glyph (not content) |
| _o_acute_.png | font glyph (not content) |
| _o_circumflex.png | font glyph (not content) |
| _o_circumflex_.png | font glyph (not content) |
| _o_dash.png | font glyph (not content) |
| _o_dash_.png | font glyph (not content) |
| _o_grave.png | font glyph (not content) |
| _o_grave_.png | font glyph (not content) |
| _o_macron.png | font glyph (not content) |
| _o_macron_.png | font glyph (not content) |
| _o_sup.png | font glyph (not content) |
| _o_tilde.png | font glyph (not content) |
| _o_tilde_.png | font glyph (not content) |
| _oe.png | font glyph (not content) |
| _oe_.png | font glyph (not content) |
| _p.png | font glyph (not content) |
| _p_.png | font glyph (not content) |
| _paragraph.png | font glyph (not content) |
| _pilcrow.png | font glyph (not content) |
| _plus_minus.png | font glyph (not content) |
| _pound.png | font glyph (not content) |
| _pr.png | font glyph (not content) |
| _ps.png | font glyph (not content) |
| _q.png | font glyph (not content) |
| _q_.png | font glyph (not content) |
| _qo.png | font glyph (not content) |
| _qu.png | font glyph (not content) |
| _qu_inv.png | font glyph (not content) |
| _r.png | font glyph (not content) |
| _r_.png | font glyph (not content) |
| _r_acute.png | font glyph (not content) |
| _r_acute_.png | font glyph (not content) |
| _r_caron.png | font glyph (not content) |
| _r_caron_.png | font glyph (not content) |
| _r_cedille.png | font glyph (not content) |
| _r_cedille_.png | font glyph (not content) |
| _rc.png | font glyph (not content) |
| _re.png | font glyph (not content) |
| _registered.png | font glyph (not content) |
| _return.png | font glyph (not content) |
| _s.png | font glyph (not content) |
| _s_.png | font glyph (not content) |
| _s_acute.png | font glyph (not content) |
| _s_acute_.png | font glyph (not content) |
| _s_caron.png | font glyph (not content) |
| _s_caron_.png | font glyph (not content) |
| _s_cedille.png | font glyph (not content) |
| _s_cedille_.png | font glyph (not content) |
| _s_circumflex.png | font glyph (not content) |
| _s_circumflex_.png | font glyph (not content) |
| _s_comma.png | font glyph (not content) |
| _s_comma_.png | font glyph (not content) |
| _sl.png | font glyph (not content) |
| _sm.png | font glyph (not content) |
| _sp.png | font glyph (not content) |
| _sr.png | font glyph (not content) |
| _sz.png | font glyph (not content) |
| _t.png | font glyph (not content) |
| _t_.png | font glyph (not content) |
| _t_caron.png | font glyph (not content) |
| _t_caron_.png | font glyph (not content) |
| _t_cedille.png | font glyph (not content) |
| _t_cedille_.png | font glyph (not content) |
| _t_comma.png | font glyph (not content) |
| _t_comma_.png | font glyph (not content) |
| _t_stroke.png | font glyph (not content) |
| _t_stroke_.png | font glyph (not content) |
| _thorn.png | font glyph (not content) |
| _thorn_.png | font glyph (not content) |
| _times_cross.png | font glyph (not content) |
| _times_dot.png | font glyph (not content) |
| _tl.png | font glyph (not content) |
| _u.png | font glyph (not content) |
| _u_.png | font glyph (not content) |
| _u_acute.png | font glyph (not content) |
| _u_acute_.png | font glyph (not content) |
| _u_breve.png | font glyph (not content) |
| _u_breve_.png | font glyph (not content) |
| _u_circumflex.png | font glyph (not content) |
| _u_circumflex_.png | font glyph (not content) |
| _u_grave.png | font glyph (not content) |
| _u_grave_.png | font glyph (not content) |
| _u_macron.png | font glyph (not content) |
| _u_macron_.png | font glyph (not content) |
| _u_ogonek.png | font glyph (not content) |
| _u_ogonek_.png | font glyph (not content) |
| _u_ring.png | font glyph (not content) |
| _u_ring_.png | font glyph (not content) |
| _u_tilde.png | font glyph (not content) |
| _u_tilde_.png | font glyph (not content) |
| _ue.png | font glyph (not content) |
| _ue_.png | font glyph (not content) |
| _un.png | font glyph (not content) |
| _uo.png | font glyph (not content) |
| _uo_.png | font glyph (not content) |
| _v.png | font glyph (not content) |
| _v_.png | font glyph (not content) |
| _vb.png | font glyph (not content) |
| _w.png | font glyph (not content) |
| _w_.png | font glyph (not content) |
| _x.png | font glyph (not content) |
| _x_.png | font glyph (not content) |
| _y.png | font glyph (not content) |
| _y_.png | font glyph (not content) |
| _y_acute.png | font glyph (not content) |
| _y_acute_.png | font glyph (not content) |
| _y_breve.png | font glyph (not content) |
| _y_diaresis.png | font glyph (not content) |
| _y_diaresis_.png | font glyph (not content) |
| _y_macron.png | font glyph (not content) |
| _yen.png | font glyph (not content) |
| _z.png | font glyph (not content) |
| _z_.png | font glyph (not content) |
| _z_acute.png | font glyph (not content) |
| _z_acute_.png | font glyph (not content) |
| _z_caron.png | font glyph (not content) |
| _z_caron_.png | font glyph (not content) |
| _z_overdot.png | font glyph (not content) |
| _z_overdot_.png | font glyph (not content) |
| awards_bg_default.png | GUI/formspec (not content) |
| awards_progress_gray.png | GUI/formspec (not content) |
| awards_progress_green.png | GUI/formspec (not content) |
| awards_unknown.png | GUI/formspec (not content) |
| axolotl_bucket.png | modern 1.13+ content (absent from 1.12.2 dump) |
| beacon_UV.png | mod-specific |
| beacon_achievement_icon.png | GUI/formspec (not content) |
| beacon_beam_palette.png | mod-specific |
| blast_furnace_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| blast_furnace_front_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| blast_furnace_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| blast_furnace_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bolt_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bolt_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bolt_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bolt_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bolt_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| boots_trim.png | mod-specific |
| bubble.png | particles/effects (not content) |
| bucket_powder_snow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| bush_1.png | mod-specific |
| bush_2.png | mod-specific |
| bush_3.png | mod-specific |
| bush_4.png | mod-specific |
| bush_5.png | mod-specific |
| bush_6.png | mod-specific |
| bush_7.png | mod-specific |
| bush_8.png | mod-specific |
| cactus_flower.png | mod-specific |
| cartography_table_side1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| cartography_table_side2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| cartography_table_side3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| cartography_table_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| chestplate_trim.png | mod-specific |
| coast_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| coast_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| coast_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| coast_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| coast_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| cod_bucket.png | mod-specific |
| crack_anylength.png | particles/effects (not content) |
| craftguide_arrow.png | GUI/formspec (not content) |
| craftguide_book.png | mod-specific |
| craftguide_clear_icon.png | GUI/formspec (not content) |
| craftguide_furnace.png | mod-specific |
| craftguide_next_icon.png | GUI/formspec (not content) |
| craftguide_prev_icon.png | GUI/formspec (not content) |
| craftguide_search_icon.png | GUI/formspec (not content) |
| craftguide_shapeless.png | GUI/formspec (not content) |
| craftguide_zoomin_icon.png | GUI/formspec (not content) |
| craftguide_zoomout_icon.png | GUI/formspec (not content) |
| crafting_creative_active.png | GUI/formspec (not content) |
| crafting_creative_active_down.png | GUI/formspec (not content) |
| crafting_creative_bg.png | GUI/formspec (not content) |
| crafting_creative_bg_dark.png | GUI/formspec (not content) |
| crafting_creative_inactive.png | GUI/formspec (not content) |
| crafting_creative_inactive_down.png | GUI/formspec (not content) |
| crafting_creative_marker.png | GUI/formspec (not content) |
| crafting_creative_next.png | GUI/formspec (not content) |
| crafting_creative_prev.png | GUI/formspec (not content) |
| crafting_creative_trash.png | GUI/formspec (not content) |
| crafting_formspec_arrow.png | GUI/formspec (not content) |
| crafting_formspec_bg.png | GUI/formspec (not content) |
| crafting_workbench_front.png | mod-specific |
| crafting_workbench_side.png | mod-specific |
| crafting_workbench_top.png | mod-specific |
| credits_bg.png | GUI/formspec (not content) |
| crimson_hyphae.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_hyphae_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_hyphae_wood.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_nylium.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_nylium_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_roots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_stem_stripped_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crimson_stem_stripped_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| crosshair.png | mod-specific |
| custom_beacon_symbol_1.png | mod-specific |
| custom_beacon_symbol_2.png | mod-specific |
| custom_beacon_symbol_3.png | mod-specific |
| custom_beacon_symbol_4.png | mod-specific |
| default_furnace_fire_bg.png | GUI/formspec (not content) |
| default_furnace_fire_fg.png | no vanilla asset in dump (partial 1.12.2 pool) |
| default_tool_netheriteaxe.png | no vanilla asset in dump (partial 1.12.2 pool) |
| default_tool_netheritepick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| default_tool_netheriteshovel.png | no vanilla asset in dump (partial 1.12.2 pool) |
| default_tool_netheritesword.png | no vanilla asset in dump (partial 1.12.2 pool) |
| doc_basics_build.png | mod-specific |
| doc_basics_craft_grid.png | GUI/formspec (not content) |
| doc_basics_hotbar.png | GUI/formspec (not content) |
| doc_basics_inventory_detail.png | GUI/formspec (not content) |
| doc_basics_items_dropped.png | mod-specific |
| doc_basics_light_test.png | mod-specific |
| doc_basics_light_torch.png | mod-specific |
| doc_basics_liquids_nonrenewable.png | mod-specific |
| doc_basics_liquids_range.png | mod-specific |
| doc_basics_liquids_renewable_1.png | mod-specific |
| doc_basics_liquids_renewable_2.png | mod-specific |
| doc_basics_liquids_types.png | mod-specific |
| doc_basics_minimap_map.png | mod-specific |
| doc_basics_minimap_radar.png | mod-specific |
| doc_basics_minimap_round.png | mod-specific |
| doc_basics_nodes.png | mod-specific |
| doc_basics_players_sam.png | mod-specific |
| doc_basics_pointing.png | mod-specific |
| doc_basics_tools.png | mod-specific |
| doc_basics_tools_mining.png | mod-specific |
| doc_button_icon_lores.png | GUI/formspec (not content) |
| doc_identifier_identifier.png | mod-specific |
| doc_identifier_identifier_liquid.png | mod-specific |
| doors_item_steel.png | no vanilla asset in dump (partial 1.12.2 pool) |
| doors_item_wood.png | no vanilla asset in dump (partial 1.12.2 pool) |
| doors_trapdoor_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| doors_trapdoor_steel_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| dripstone_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| dune_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| dune_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| dune_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| dune_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| dune_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| extra_mobs_cod.png | mod-specific |
| extra_mobs_dolphin.png | mod-specific |
| extra_mobs_glow_ink_sac.png | mod-specific |
| extra_mobs_glow_squid.png | mod-specific |
| extra_mobs_glow_squid_glint1.png | mod-specific |
| extra_mobs_glow_squid_glint2.png | mod-specific |
| extra_mobs_glow_squid_glint3.png | mod-specific |
| extra_mobs_glow_squid_glint4.png | mod-specific |
| extra_mobs_hoglin.png | mod-specific |
| extra_mobs_piglin.png | mod-specific |
| extra_mobs_piglin_brute.png | mod-specific |
| extra_mobs_salmon.png | mod-specific |
| extra_mobs_strider.png | mod-specific |
| extra_mobs_strider_cold.png | mod-specific |
| extra_mobs_tropical_fish_a.png | mod-specific |
| extra_mobs_tropical_fish_b.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_1.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_2.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_3.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_4.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_5.png | mod-specific |
| extra_mobs_tropical_fish_pattern_a_6.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_1.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_2.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_3.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_4.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_5.png | mod-specific |
| extra_mobs_tropical_fish_pattern_b_6.png | mod-specific |
| extra_mobs_zoglin.png | mod-specific |
| extra_mobs_zombified_piglin.png | mod-specific |
| eye_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| eye_boots.png | mod-specific |
| eye_chestplate.png | mod-specific |
| eye_helmet.png | mod-specific |
| eye_leggings.png | mod-specific |
| farming_crimson_fungus.png | modern 1.13+ content (absent from 1.12.2 dump) |
| farming_potato_poison.png | no vanilla asset in dump (partial 1.12.2 pool) |
| farming_tool_netheritehoe.png | no vanilla asset in dump (partial 1.12.2 pool) |
| farming_warped_fungus.png | modern 1.13+ content (absent from 1.12.2 dump) |
| fire_basic_flame.png | particles/effects (not content) |
| fire_basic_flame_animated.png | particles/effects (not content) |
| fletching_table_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| fletching_table_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| fletching_table_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| fletching_table_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flow_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flow_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flow_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flow_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flow_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| flower_1.png | mod-specific |
| flower_2.png | mod-specific |
| flower_3.png | mod-specific |
| flower_4.png | mod-specific |
| flower_5.png | mod-specific |
| flower_6.png | mod-specific |
| flower_7.png | mod-specific |
| flower_8.png | mod-specific |
| flowers_dandelion_yellow.png | mod-specific |
| flowers_tulip.png | mod-specific |
| flowers_waterlily.png | mod-specific |
| freezing_1.png | mod-specific |
| freezing_2.png | mod-specific |
| freezing_3.png | mod-specific |
| frozen_heart.png | particles/effects (not content) |
| gourd_1.png | mod-specific |
| gourd_2.png | mod-specific |
| gourd_3.png | mod-specific |
| gourd_4.png | mod-specific |
| gourd_5.png | mod-specific |
| gourd_6.png | mod-specific |
| gourd_7.png | mod-specific |
| gourd_8.png | mod-specific |
| grain_1.png | mod-specific |
| grain_2.png | mod-specific |
| grain_3.png | mod-specific |
| grain_4.png | mod-specific |
| grain_5.png | mod-specific |
| grain_6.png | mod-specific |
| grain_7.png | mod-specific |
| grain_8.png | mod-specific |
| grindstone_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| grindstone_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| grindstone_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| gui_crafting_arrow.png | GUI/formspec (not content) |
| gui_furnace_arrow_bg.png | GUI/formspec (not content) |
| gui_furnace_arrow_fg.png | GUI/formspec (not content) |
| hbarmor_bar.png | GUI/formspec (not content) |
| hbarmor_bgicon.png | GUI/formspec (not content) |
| hbarmor_icon.png | GUI/formspec (not content) |
| hbhunger_bar.png | GUI/formspec (not content) |
| hbhunger_bar_health_poison.png | GUI/formspec (not content) |
| hbhunger_bgicon.png | GUI/formspec (not content) |
| hbhunger_icon.png | GUI/formspec (not content) |
| hbhunger_icon_health_poison.png | GUI/formspec (not content) |
| hbhunger_icon_regen_poison.png | GUI/formspec (not content) |
| heart.png | particles/effects (not content) |
| helmet_trim.png | mod-specific |
| hudbars_bar_background.png | GUI/formspec (not content) |
| hudbars_bar_breath.png | GUI/formspec (not content) |
| hudbars_bar_health.png | GUI/formspec (not content) |
| hudbars_bgicon_breath.png | GUI/formspec (not content) |
| hudbars_bgicon_health.png | GUI/formspec (not content) |
| hudbars_icon_breath.png | GUI/formspec (not content) |
| hudbars_icon_health.png | GUI/formspec (not content) |
| hudbars_icon_regenerate.png | GUI/formspec (not content) |
| jeija_commandblock_off.png | mod-specific |
| jeija_commandblock_on.png | mod-specific |
| jeija_lightstone_gray_off.png | mod-specific |
| jeija_lightstone_gray_on.png | mod-specific |
| jeija_solar_panel.png | mod-specific |
| jeija_solar_panel_inverted.png | mod-specific |
| jeija_solar_panel_side.png | mod-specific |
| jeija_torches_off.png | mod-specific |
| jeija_torches_on.png | mod-specific |
| leggings_trim.png | mod-specific |
| lightning_lightning_1.png | particles/effects (not content) |
| lightning_lightning_2.png | particles/effects (not content) |
| lightning_lightning_3.png | particles/effects (not content) |
| lodestone_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| lodestone_side1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| lodestone_side2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| lodestone_side3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| lodestone_side4.png | modern 1.13+ content (absent from 1.12.2 dump) |
| lodestone_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| loom_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| loom_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| loom_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| loom_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_achievements_button.png | GUI/formspec (not content) |
| mcl_amethyst_amethyst_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_amethyst_bud_large.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_amethyst_bud_medium.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_amethyst_bud_small.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_amethyst_cluster.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_amethyst_shard.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_budding_amethyst.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_calcite_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_amethyst_tinted_glass.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_anvils_anvil_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_anvils_inventory.png | GUI/formspec (anvil container |
| mcl_anvils_inventory_arrow.png | GUI/formspec (not content) |
| mcl_anvils_inventory_cross.png | GUI/formspec (not content) |
| mcl_anvils_inventory_hammer.png | GUI/formspec (not content) |
| mcl_armor_boots_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_boots_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_boots_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_broken_elytra.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_chestplate_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_chestplate_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_chestplate_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_elytra.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_helmet_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_helmet_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_helmet_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_boots_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_boots_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_inv_boots_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_chestplate_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_chestplate_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_inv_chestplate_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_elytra.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_inv_helmet_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_helmet_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_inv_helmet_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_leggings_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_inv_leggings_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_inv_leggings_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_leggings_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_armor_leggings_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_armor_leggings_netherite.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_backstone_quartz_bricks.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bamboo_bamboo.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_block_stripped.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_bottom_stripped.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_fpm.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_plank.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_plank_mosaic.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_sign.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_bamboo_sign_wield.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_door_bottom_alt.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_door_top_alt.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_door_wield.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_endcap.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_fence_bamboo.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_fence_gate_bamboo.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_leaf_big.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_leaf_small.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_scaffolding_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_scaffolding_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bamboo_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_banners_banner_base.png | no vanilla asset in dump (ambiguous banner base) |
| mcl_banners_base_inverted.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_fallback_wood.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_flow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_banners_globe.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_guster.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_item_base_48.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_item_overlay_48.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_bricks.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_creeper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_curly_border.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_flow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_banners_pattern_flower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_globe.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_guster.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_piglin.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_banners_pattern_skull.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_pattern_thing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_banners_piglin.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_banners_thing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_barrels_barrel_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_barrels_barrel_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_barrels_barrel_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_barrels_barrel_top_open.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_base_textures_background.png | GUI/formspec (not content) |
| mcl_base_textures_background9.png | GUI/formspec (not content) |
| mcl_base_textures_button9.png | GUI/formspec (not content) |
| mcl_base_textures_button9_pressed.png | GUI/formspec (not content) |
| mcl_beds_bed_black.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_black_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_blue_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_brown.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_brown_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_cyan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_cyan_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_green_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_grey.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_grey_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_light_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_light_blue_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_lime.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_lime_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_magenta.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_magenta_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_orange.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_orange_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_pink_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_purple.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_purple_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_red_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_silver.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_silver_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_white_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beds_bed_yellow_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_beehives_bee_nest_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_bee_nest_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_bee_nest_front_honey.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_bee_nest_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_bee_nest_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_beehive_end.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_beehive_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_beehive_front_honey.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_beehives_beehive_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_bells_bell.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_ceiling.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_floor_front.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_floor_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_floor_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_uv_bell.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bells_bell_wall.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_biome_dispatch_transition_bkg.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_blackstone_basalt_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_basalt_side_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_basalt_smooth.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_basalt_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_basalt_top_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_chiseled_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_gilded.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_gilded_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_polished_bricks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_polished_bricks_cracked.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_soul_soil.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_blackstone_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_acacia_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_acacia_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_bamboo_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_bamboo_chest_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_birch_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_birch_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_cherry_blossom_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_cherry_blossom_chest_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_dark_oak_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_dark_oak_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_jungle_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_jungle_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_mangrove_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_mangrove_chest_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_oak_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_oak_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_obsidian_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_pale_oak_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_pale_oak_chest_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_spruce_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_spruce_chest_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_acacia_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_bamboo_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_texture_birch_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_cherry_blossom_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_texture_dark_oak_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_jungle_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_mangrove_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_texture_oak_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_obsidian_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_boats_texture_pale_oak_boat.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_boats_texture_spruce_boat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bone_meal_bone_meal.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_book_book_empty_slot.png | GUI/formspec (not content) |
| mcl_books_book_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_book_bg.png | GUI/formspec (not content) |
| mcl_books_bookshelf_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_button9.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_button9_pressed.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_chiseled_bookshelf_empty.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_chiseled_bookshelf_full.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_chiseled_bookshelf_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_books_chiseled_bookshelf_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bossbars.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bossbars_empty.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_arrow_back.png | GUI/formspec (not content) |
| mcl_bows_arrow_front.png | GUI/formspec (not content) |
| mcl_bows_arrow_inv.png | GUI/formspec (not content) |
| mcl_bows_arrow_overlay.png | GUI/formspec (not content) |
| mcl_bows_bow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_bow_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_bow_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_bow_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_crossbow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_crossbow_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_crossbow_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_crossbow_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_crossbow_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_firework_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_firework_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_firework_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_firework_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_firework_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_rocket.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_bows_rocket_particle.png | particles/effects (not content) |
| mcl_brewing_bottle_bg.png | GUI/formspec (not content) |
| mcl_brewing_bubble_sprite.png | particles/effects (not content) |
| mcl_brewing_bubbles.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_bubbles_active.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_burner.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_burner_active.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_fuel_bg.png | GUI/formspec (not content) |
| mcl_brewing_inventory.png | GUI/formspec (brewing container |
| mcl_brewing_rack.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_rack_bottle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_brewing_stand_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_burning_entity_flame_animated.png | particles/effects (not content) |
| mcl_burning_hud_flame_animated.png | GUI/formspec (not content) |
| mcl_campfires_campfire_fire.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_campfires_campfire_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_campfires_campfire_log_lit.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_campfires_log.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_campfires_particle_1.png | particles/effects (not content) |
| mcl_campfires_particle_10.png | particles/effects (not content) |
| mcl_campfires_particle_11.png | particles/effects (not content) |
| mcl_campfires_particle_12.png | particles/effects (not content) |
| mcl_campfires_particle_2.png | particles/effects (not content) |
| mcl_campfires_particle_3.png | particles/effects (not content) |
| mcl_campfires_particle_4.png | particles/effects (not content) |
| mcl_campfires_particle_5.png | particles/effects (not content) |
| mcl_campfires_particle_6.png | particles/effects (not content) |
| mcl_campfires_particle_7.png | particles/effects (not content) |
| mcl_campfires_particle_8.png | particles/effects (not content) |
| mcl_campfires_particle_9.png | particles/effects (not content) |
| mcl_campfires_soul_campfire_fire.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_campfires_soul_campfire_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_campfires_soul_campfire_log_lit.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_candles_candle.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_candles_flames.png | particles/effects (not content) |
| mcl_candles_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_black.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_brown.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_cyan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_grey.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_light_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_lime.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_magenta.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_orange.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_purple.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_silver.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_item_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_candles_palette.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_charges_wind_burst_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_charges_wind_burst_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_charges_wind_charge.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_charges_wind_charge_entity.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_cherry_blossom_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_bottom_bottompart.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_bottom_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_top_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_door_top_toppart.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_leaves.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_log.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_log_stripped.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_log_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_log_top_stripped.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_particle.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_particle_1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_particle_2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_particle_3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_pink_petals.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_pink_petals_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_planks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_sapling.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_trapdoor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_cherry_blossom_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_chests_ender_present.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_noise.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_noise_double.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_normal.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_normal_double.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_normal_double_present.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_normal_present.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_trapped.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_trapped_double.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_trapped_double_present.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_chests_trapped_present.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_00.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_01.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_02.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_03.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_04.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_05.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_06.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_07.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_08.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_09.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_11.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_12.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_13.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_14.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_15.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_16.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_17.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_18.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_19.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_20.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_21.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_22.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_23.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_24.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_25.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_26.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_27.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_28.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_29.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_30.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_31.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_32.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_33.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_34.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_35.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_36.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_37.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_38.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_39.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_40.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_41.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_42.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_43.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_44.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_45.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_46.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_47.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_48.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_49.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_50.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_51.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_52.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_53.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_54.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_55.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_56.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_57.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_58.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_59.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_60.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_61.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_62.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_clock_clock_63.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_cocoas_cocoa_beans.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_black.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_brown.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_cyan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_grey.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_light_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_lime.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_magenta.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_orange.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_powder_black.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_blue.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_brown.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_cyan.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_green.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_grey.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_light_blue.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_lime.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_magenta.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_orange.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_pink.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_purple.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_red.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_silver.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_white.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_powder_yellow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_colorblocks_concrete_purple.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_silver.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_concrete_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_black.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_brown.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_cyan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_grey.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_light_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_lime.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_magenta.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_orange.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_purple.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_silver.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_colorblocks_glazed_terracotta_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_comp.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_ends_comp.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_ends_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_ends_on.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_ends_sub.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_on.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_sides_comp.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_sides_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_sides_on.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_sides_sub.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_comparators_sub.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_00.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_01.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_02.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_03.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_04.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_05.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_06.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_07.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_08.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_09.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_11.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_12.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_13.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_14.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_15.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_16.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_17.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_18.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_19.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_20.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_21.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_22.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_23.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_24.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_25.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_26.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_27.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_28.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_29.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_30.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_compass_31.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_compass_recovery_compass_00.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_01.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_02.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_03.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_04.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_05.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_06.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_07.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_08.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_09.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_10.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_11.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_12.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_13.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_14.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_15.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_16.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_17.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_18.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_19.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_20.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_21.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_22.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_23.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_24.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_25.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_26.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_27.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_28.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_29.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_30.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_compass_recovery_compass_31.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_composter_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_composter_compost.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_composter_ready.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_composter_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_composter_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_conduit_conduit.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_conduit_conduit_node.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_anti_oxidation_particle.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_bulb_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_bulb_off_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_bulb_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_bulb_on_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_cut.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_grate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_block_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_exposed_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_oxidized_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chain_weathered_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_chestplate_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_exposed_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_exposed_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_oxidized_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_oxidized_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_weathered_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_door_weathered_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_bulb_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_bulb_off_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_bulb_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_bulb_on_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_cut.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_exposed_grate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_helmet_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_ingot.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_inv_boots_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_inv_chestplate_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_inv_helmet_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_inv_leggings_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_exposed_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_oxidized_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_lantern_weathered_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_leggings_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_nugget.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_ore.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_bulb_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_bulb_off_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_bulb_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_bulb_on_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_cut.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_oxidized_grate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_top_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_top_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_top_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_pane_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_tool_axe.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_tool_hoe.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_tool_pick.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_tool_shovel.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_tool_sword.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_top_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_top_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_top_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_torch.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_torch_animated.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor.png | modern 1.13+ content (copper trapdoor |
| mcl_copper_trapdoor_exposed.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_exposed_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_oxidized_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_trapdoor_weathered_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_bulb_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_bulb_off_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_bulb_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_bulb_on_powered.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_cut.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_copper_weathered_grate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_bone_block_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_bone_block_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_crying_obsidian.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_crying_obsidian_tear.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_crying_obsidian_tear2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_crying_obsidian_tear3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_diorite.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_frosted_ice_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_frosted_ice_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_frosted_ice_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_frosted_ice_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_glow_lichen.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_core_iron_nugget.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_11.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_12.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_13.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_14.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_8.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_light_9.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_mycelium_particle.png | particles/effects (not content) |
| mcl_core_palette_grass.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_palette_grass_levelgen.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_palette_leaves.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_acacia_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_acacia_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_birch_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_birch_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_dark_oak_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_dark_oak_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_jungle_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_jungle_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_oak_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_oak_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_spruce_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_stripped_spruce_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_core_void.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_craftguide_fuel.png | GUI/formspec (not content) |
| mcl_crafting_guide_craft.png | GUI/formspec (not content) |
| mcl_crafting_table_inv_fill.png | GUI/formspec (not content) |
| mcl_crimson_crimson_door.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_fence.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_fence_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_fence_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_trapdoor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_crimson_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_door.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_fence.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_fence_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_fence_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_trapdoor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_warped_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_crimson_weeping_vines.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_bricks.png | modern 1.13+ content (deepslate bricks |
| mcl_deepslate_bricks_cracked.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_coal_ore.png | modern 1.13+ content (deepslate coal ore |
| mcl_deepslate_cobbled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_copper_ore.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_diamond_ore.png | modern 1.13+ content (deepslate diamond ore |
| mcl_deepslate_emerald_ore.png | modern 1.13+ content (deepslate emerald ore |
| mcl_deepslate_gold_ore.png | modern 1.13+ content (deepslate gold ore |
| mcl_deepslate_iron_ore.png | modern 1.13+ content (deepslate iron ore |
| mcl_deepslate_lapis_ore.png | modern 1.13+ content (deepslate lapis ore |
| mcl_deepslate_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_redstone_ore.png | modern 1.13+ content (deepslate redstone ore |
| mcl_deepslate_reinforced.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_reinforced_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_reinforced_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tiles.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tiles_cracked.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_bricks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_chiseled.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_chiseled_bricks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_chiseled_bricks_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_chiseled_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_deepslate_tuff_polished.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_dirt_grass_shadow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_acacia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_acacia_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_acacia_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_acacia_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_acacia_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_birch_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_birch_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_birch_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_birch_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_crimson_side_lower.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_doors_door_crimson_side_upper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_doors_door_dark_oak_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_dark_oak_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_iron_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_iron_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_jungle_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_jungle_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_spruce_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_spruce_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_warped_side_lower.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_doors_door_warped_side_upper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_doors_door_wood_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_wood_side_lower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_wood_side_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_door_wood_upper.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_acacia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_acacia_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_birch.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_birch_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_dark_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_dark_oak_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_jungle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_jungle_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_spruce.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_doors_trapdoor_spruce_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_dye.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_dye_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_dyes_palette.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_enchanting_book_closed.png | GUI/formspec (not content) |
| mcl_enchanting_book_entity.png | GUI/formspec (not content) |
| mcl_enchanting_book_open.png | GUI/formspec (not content) |
| mcl_enchanting_button.png | GUI/formspec (not content) |
| mcl_enchanting_button_background.png | GUI/formspec (not content) |
| mcl_enchanting_button_hovered.png | GUI/formspec (not content) |
| mcl_enchanting_button_off.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_1.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_10.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_11.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_12.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_13.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_14.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_15.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_16.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_17.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_18.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_2.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_3.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_4.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_5.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_6.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_7.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_8.png | GUI/formspec (not content) |
| mcl_enchanting_glyph_9.png | GUI/formspec (not content) |
| mcl_enchanting_lapis_background.png | GUI/formspec (not content) |
| mcl_enchanting_number_1.png | GUI/formspec (not content) |
| mcl_enchanting_number_1_off.png | GUI/formspec (not content) |
| mcl_enchanting_number_2.png | GUI/formspec (not content) |
| mcl_enchanting_number_2_off.png | GUI/formspec (not content) |
| mcl_enchanting_number_3.png | GUI/formspec (not content) |
| mcl_enchanting_number_3_off.png | GUI/formspec (not content) |
| mcl_end_chorus_flower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_8.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_9.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_flower_dead.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_fruit.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_fruit_popped.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_chorus_plant.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_crystal.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_crystal_beam.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_crystal_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_end_bricks.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_end_rod_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_end_rod_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_end_rod_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_purpur_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_purpur_pillar.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_end_purpur_pillar_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_experience_bar.png | GUI/formspec (not content) |
| mcl_experience_bar_background.png | GUI/formspec (not content) |
| mcl_farming_beetroot.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_seeds.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_beetroot_soup.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_pumpkin_hud.png | GUI/formspec (not content) |
| mcl_farming_sweet_berry.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_sweet_berry_bush_0.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_sweet_berry_bush_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_sweet_berry_bush_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_farming_sweet_berry_bush_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_acacia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_big_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_birch.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_acacia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_big_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_birch.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_jungle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_nether_brick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_red_nether_brick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_gate_spruce.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_jungle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_nether_brick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_red_nether_brick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fences_fence_spruce.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fire_fire_charge.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fire_flint_and_steel.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fireworks_rocket.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fishing_bobber.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fishing_clownfish_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_fishing_fish_cooked.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fishing_fish_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_fishing_fishing_rod.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fishing_pufferfish_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_fishing_salmon_cooked.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_fishing_salmon_raw.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_flowerpots_cactus.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowerpots_flowerpot.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowerpots_flowerpot_inventory.png | GUI/formspec (not content) |
| mcl_flowers_allium.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_azure_bluet.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_blue_orchid.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_bush.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_cornflower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_double_plant_fern_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_double_plant_grass_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_dry_vegetation_palette.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_fern_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_firefly_bush.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_firefly_bush_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_leaf_litter.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_lily_of_the_valley.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_oxeye_daisy.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_poppy.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_short_dry_grass.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_tall_dry_grass.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_tallgrass_inv.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_tulip_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_tulip_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_tulip_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_wildflower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_wildflower_stem.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_flowers_wither_rose.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_formspec_itemslot.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_heads_piglin.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_block_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_block_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_block_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_honey_bottle.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_honeycomb.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_honey_honeycomb_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_hoppers_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_hunger_bar_exhaustion.png | GUI/formspec (not content) |
| mcl_hunger_bar_foodpoison.png | GUI/formspec (not content) |
| mcl_hunger_bar_saturation.png | GUI/formspec (not content) |
| mcl_hunger_bgicon_exhaustion.png | GUI/formspec (not content) |
| mcl_hunger_bgicon_saturation.png | GUI/formspec (not content) |
| mcl_hunger_icon_exhaustion.png | GUI/formspec (not content) |
| mcl_hunger_icon_foodpoison.png | GUI/formspec (not content) |
| mcl_hunger_icon_saturation.png | GUI/formspec (not content) |
| mcl_inventory_background9.png | GUI/formspec (not content) |
| mcl_inventory_bar.png | GUI/formspec (not content) |
| mcl_inventory_bar_fill.png | GUI/formspec (not content) |
| mcl_inventory_button9.png | GUI/formspec (not content) |
| mcl_inventory_button9_pressed.png | GUI/formspec (not content) |
| mcl_inventory_empty_armor_slot_shield.png | GUI/formspec (not content) |
| mcl_inventory_hotbar.png | GUI/formspec (not content) |
| mcl_inventory_hotbar_selected.png | GUI/formspec (not content) |
| mcl_itemframes_glow_item_frame.png | GUI/formspec (not content) |
| mcl_itemframes_glow_item_frame_border.png | GUI/formspec (not content) |
| mcl_itemframes_invisible_glow_item_frame.png | GUI/formspec (not content) |
| mcl_itemframes_invisible_item_frame.png | GUI/formspec (not content) |
| mcl_lanterns_chain.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lanterns_chain_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lanterns_lantern.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lanterns_lantern_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lanterns_soul_lantern.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lanterns_soul_lantern_inv.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lectern_lectern.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_jigsaw_block_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_jigsaw_block_side_north.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_jigsaw_block_side_south.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_jigsaw_block_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_schematic_border_checkers.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_corner_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_corner_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_data_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_data_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_load_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_load_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_save_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_save_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_block_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_levelgen_structure_void.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lightning_rods_rod.png | particles/effects (not content) |
| mcl_lightning_rods_rod_exposed.png | particles/effects (not content) |
| mcl_lightning_rods_rod_oxidized.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lightning_rods_rod_weathered.png | particles/effects (not content) |
| mcl_loom_itemslot_bg_banner.png | GUI/formspec (not content) |
| mcl_loom_itemslot_bg_dye.png | GUI/formspec (not content) |
| mcl_loom_itemslot_bg_pattern.png | GUI/formspec (not content) |
| mcl_lush_caves_azalea_flowering_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_flowering_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_leaves.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_leaves_flowering.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_plant.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_azalea_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_big_dripleaf_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_big_dripleaf_stem.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_big_dripleaf_tip.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_big_dripleaf_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_cave_vines.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_cave_vines_lit.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_cave_vines_plant.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_cave_vines_plant_lit.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_dripleaf_big.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_dripleaf_small.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_dripleaf_stem.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_glow_berries.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_lush_caves_hanging_roots.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_moss.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_moss_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_moss_carpet.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_moss_carpet_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_rooted_dirt.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_small_dripleaf_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_small_dripleaf_stem_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_small_dripleaf_stem_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_small_dripleaf_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_spore_blossom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_spore_blossom_base.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_lush_caves_spore_blossom_particle.png | particles/effects (not content) |
| mcl_mangrove_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_doors.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_fence.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_fence_gate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_leaves.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_log.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_log_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_planks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_propagule.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_propagule_hanging.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_propagule_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_roots_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_roots_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mangrove_trapdoor.png | modern 1.13+ content (mangrove trapdoor |
| mcl_mangrove_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_maps_map_filled_markings.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_maps_player_arrow.png | GUI/formspec (not content) |
| mcl_maps_player_dot.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_crossing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_crossing_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_curved.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_curved_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_t_junction.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_activator_t_junction_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_crossing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_crossing_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_curved.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_curved_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_t_junction.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_detector_t_junction_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_crossing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_crossing_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_curved.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_curved_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_t_junction.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_minecarts_rail_golden_t_junction_powered.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_breeze_rod.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mobitems_copper_horse_armor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mobitems_heart_of_the_sea.png | particles/effects (not content) |
| mcl_mobitems_heart_of_the_sea_split.png | particles/effects (not content) |
| mcl_mobitems_horse_armor_copper.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mobitems_horse_armor_leather.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_horse_armor_leather_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_ink_sac.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_leather_horse_armor.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_leather_horse_armor_desat.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_nametag.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_nautilus_shell.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_shulker_shell.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mobitems_warped_fungus_on_a_stick.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_mobs_hud_vehicle_container.png | GUI/formspec (not content) |
| mcl_mobs_hud_vehicle_full.png | GUI/formspec (not content) |
| mcl_mobs_hud_vehicle_half.png | GUI/formspec (not content) |
| mcl_mud.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_mud_bricks.png | modern 1.13+ content (mud bricks |
| mcl_mud_packed_mud.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_ancient_debris_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_ancient_debris_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_chiseled_nether_bricks.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_cracked_nether_bricks.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_gold_ore.png | modern 1.13+ content (nether gold ore |
| mcl_nether_magma.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_nether_wart_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_netherite_ingot.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_nether_netherite_scrap.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_nether_netherite_upgrade_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_nether_netheriteblock.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_nether_red_nether_brick.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_observers_observer_back.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_observers_observer_back_lit.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_observers_observer_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_observers_observer_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_observers_observer_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_ocean_brain_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_brain_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_brain_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_bubble_coral.png | particles/effects (not content) |
| mcl_ocean_bubble_coral_block.png | particles/effects (not content) |
| mcl_ocean_bubble_coral_fan.png | particles/effects (not content) |
| mcl_ocean_dead_brain_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_brain_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_brain_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_bubble_coral.png | particles/effects (not content) |
| mcl_ocean_dead_bubble_coral_block.png | particles/effects (not content) |
| mcl_ocean_dead_bubble_coral_fan.png | particles/effects (not content) |
| mcl_ocean_dead_fire_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_fire_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_fire_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_horn_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_horn_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_horn_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_tube_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_tube_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dead_tube_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dried_kelp.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dried_kelp_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dried_kelp_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_dried_kelp_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_fire_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_fire_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_fire_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_horn_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_horn_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_horn_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_kelp_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_kelp_plant.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_prismarine_anim.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_1_anim.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_1_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_2_anim.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_2_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_3_anim.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_3_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_4_anim.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_4_off.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_sea_pickle_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_seagrass.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_seagrass_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_tube_coral.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_tube_coral_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_ocean_tube_coral_fan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_offhand_slot.png | GUI/formspec (not content) |
| mcl_paintings_frame.png | GUI/formspec (not content) |
| mcl_paintings_painting_ancient_octopus.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_balding_man.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_battle_axe.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_blue_banner.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_butcher_knives.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_cooking_utensils.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_decorative_swords.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_dense_jungle_forest.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_desert_castle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_elf_utopia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_endless_dunes.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_froggy_pond.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_gloom_mountain.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_green_banner.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_green_bottles.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_moonshine_tundra.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_mountain_tower.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_notes.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_poster.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_quest_board.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_sarmatian_decoration.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_snowy_mountain.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_support_truss.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_viking_shield.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_paintings_painting_volendam_costume.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_paintings_painting_waterfall_bridge.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_pale_oak_chiseled_resin_bricks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_door_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_door_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_door_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_eyeblossom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_eyeblossom_open.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_hanging_moss.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_hanging_moss_tip.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_leaves.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_log.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_log_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_moss.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_planks.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_resin_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_resin_brick.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_resin_brick_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_resin_clump.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_sapling_pale_oak.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_trapdoor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pale_oak_trapdoor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_particles_angry_villager.png | particles/effects (not content) |
| mcl_particles_bonemeal.png | particles/effects (not content) |
| mcl_particles_bubble.png | particles/effects (not content) |
| mcl_particles_crit.png | particles/effects (not content) |
| mcl_particles_dragon_breath_1.png | particles/effects (not content) |
| mcl_particles_dragon_breath_2.png | particles/effects (not content) |
| mcl_particles_dragon_breath_3.png | particles/effects (not content) |
| mcl_particles_droplet_bottle.png | particles/effects (not content) |
| mcl_particles_effect.png | particles/effects (not content) |
| mcl_particles_fire_flame.png | particles/effects (not content) |
| mcl_particles_instant_effect.png | particles/effects (not content) |
| mcl_particles_lava.png | particles/effects (not content) |
| mcl_particles_mob_death.png | particles/effects (not content) |
| mcl_particles_nether_dust1.png | particles/effects (not content) |
| mcl_particles_nether_dust2.png | particles/effects (not content) |
| mcl_particles_nether_dust3.png | particles/effects (not content) |
| mcl_particles_nether_portal.png | particles/effects (not content) |
| mcl_particles_nether_portal_t.png | particles/effects (not content) |
| mcl_particles_note.png | particles/effects (not content) |
| mcl_particles_smoke.png | particles/effects (not content) |
| mcl_particles_smoke_anim.png | particles/effects (not content) |
| mcl_particles_soul_fire_flame.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_particles_sponge1.png | particles/effects (not content) |
| mcl_particles_sponge2.png | particles/effects (not content) |
| mcl_particles_sponge3.png | particles/effects (not content) |
| mcl_particles_sponge4.png | particles/effects (not content) |
| mcl_particles_sponge5.png | particles/effects (not content) |
| mcl_particles_squid_ink.png | particles/effects (not content) |
| mcl_particles_squid_ink_1.png | particles/effects (not content) |
| mcl_particles_squid_ink_2.png | particles/effects (not content) |
| mcl_particles_teleport.png | particles/effects (not content) |
| mcl_particles_totem1.png | particles/effects (not content) |
| mcl_particles_totem2.png | particles/effects (not content) |
| mcl_particles_totem3.png | particles/effects (not content) |
| mcl_particles_totem4.png | particles/effects (not content) |
| mcl_player_settings.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_endframe_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_particle1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_particle2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_particle3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_particle4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_portals_particle5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_arrow_inv.png | GUI/formspec (not content) |
| mcl_potions_blindness_hud.png | GUI/formspec (not content) |
| mcl_potions_dragon_breath.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_absorbtion.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_absorption.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_bad_luck.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_bad_omen.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_blindness.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_conduit_power.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_potions_effect_darkness.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_dolphin_grace.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_fatigue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_fire_proof.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_food_poisoning.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_glowing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_haste.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_health_boost.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_hero_of_village.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_infested.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_invisible.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_leaping.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_levitation.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_luck.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_nausea.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_night_vision.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_oozing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_poisoned.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_regenerating.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_regeneration.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_resistance.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_saturation.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_slow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_slow_falling.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_strong.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_swift.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_trial_omen.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_potions_effect_water_breathing.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_weak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_weaving.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_wind_charged.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_effect_withering.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_glow_waypoint.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_potions_icon_absorb.png | GUI/formspec (not content) |
| mcl_potions_icon_regen_wither.png | GUI/formspec (not content) |
| mcl_potions_icon_wither.png | GUI/formspec (not content) |
| mcl_potions_lingering_bottle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_ominous_potion.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_potion_bottle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_potions_splash_bottle.png | particles/effects (not content) |
| mcl_potions_splash_overlay.png | particles/effects (not content) |
| mcl_pottery_sherds.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_angler.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_archer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_arms_up.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_blade.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_brewer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_burn.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_danger.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_explorer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_flow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_friend.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_guster.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_heart.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_heartbreak.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_howl.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_miner.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_mourner.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_angler.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_archer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_arms_up.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_blade.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_brewer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_burn.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_danger.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_explorer.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_flow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_friend.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_guster.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_heart.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_heartbreak.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_howl.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_miner.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_mourner.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_plenty.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_prize.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_scrape.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_sheaf.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_shelter.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_skull.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pattern_snort.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_plenty.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_10.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_4.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_5.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_6.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_7.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_8.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_9.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_pot_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_prize.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_scrape.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_sheaf.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_shelter.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_skull.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_pottery_sherds_snort.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_raids_hero_of_the_village_icon.png | GUI/formspec (not content) |
| mcl_raw_ores_raw_gold.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_raw_ores_raw_gold_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_raw_ores_raw_iron.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_raw_ores_raw_iron_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_redstone_palette_power.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_sculk_catalyst_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_catalyst_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_catalyst_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_echo_shard.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_sculk.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_sensor_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_sensor_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_sensor_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_shrieker_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_shrieker_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_shrieker_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sculk_vein.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_shield_48.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_shield_base_nopattern.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_shield_hud.png | GUI/formspec (not content) |
| mcl_shield_pattern_base.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_default_sign_greyscale.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_acacia.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_acacia_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_bamboo.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_bamboo_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_birch.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_birch_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_cherry_blossom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_cherry_blossom_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_crimson.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_crimson_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_dark_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_dark_oak_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_jungle.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_jungle_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_mangrove.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_mangrove_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_oak.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_oak_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_pale_oak.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_pale_oak_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_spruce.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_spruce_item.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_signs_hanging_sign_warped.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hanging_sign_warped_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_hangljg_sign_pale_oak.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_signs_sign_greyscale.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_arrow.png | GUI/formspec (skins menu cursor |
| mcl_skins_base_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_base_1_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_1_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_2_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_3_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_4_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_bottom_5_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_button.png | GUI/formspec (not content) |
| mcl_skins_character_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_eye_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_footwear_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_footwear_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_footwear_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_10_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_11.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_11_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_1_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_2_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_3_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_4_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_5_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_6_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_7_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_8.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_8_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_9.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_hair_9_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_headwear_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_icons.png | GUI/formspec (skins menu icons |
| mcl_skins_mouth_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_mouth_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_select_overlay.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_slim_arms.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_thick_arms.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_1.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_10.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_10_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_1_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_2.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_2_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_3.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_3_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_4.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_4_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_5.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_5_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_6.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_6_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_7.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_7_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_8.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_8_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_9.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_skins_top_9_mask.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_smithing_table_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_smithing_table_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_smithing_table_inventory.png | GUI/formspec (not content) |
| mcl_smithing_table_inventory_hammer.png | GUI/formspec (not content) |
| mcl_smithing_table_inventory_trim_bg.png | GUI/formspec (not content) |
| mcl_smithing_table_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_smithing_table_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sponges_sponge_wet_river_water.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_spyglass.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_spyglass_scope.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_stacksize_button.png | GUI/formspec (not content) |
| mcl_stairs_andesite_smooth_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_diorite_smooth_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_gold_block_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_granite_smooth_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_iron_block_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_lapis_block_slab.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stairs_turntexture.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stonecutter_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stonecutter_saw.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stonecutter_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stonecutter_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_stripped_mangrove_log_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_stripped_mangrove_log_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_stripped_pale_oak_log_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_stripped_pale_oak_log_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sus_nodes_brush.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sus_nodes_suspicious_overlay.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sus_nodes_suspicious_overlay_1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sus_nodes_suspicious_overlay_2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_sus_nodes_suspicious_overlay_3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_target_target_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_target_target_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_tnt_blink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_tools_heavy_core_bottom.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_tools_heavy_core_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_tools_heavy_core_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_tools_mace.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_totems_totem.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_totems_totem_wieldview.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_tridents_trident_entity.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_tridents_trident_entity_clip.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_tridents_trident_item.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_unknown.png | GUI/formspec (not content) |
| mcl_vaults_ominous_trial_key.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_trial_key.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_front_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_front_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_front_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_front_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_front_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_front_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_side_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_side_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_side_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_top_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_top_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_ominous_top_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_side_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_side_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_side_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_top_ejecting.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_top_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_top_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_vaults_vault_top_unlock.png | modern 1.13+ content (absent from 1.12.2 dump) |
| mcl_walls_cobble_mossy_wall_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_walls_cobble_mossy_wall_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_walls_cobble_wall_side.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_walls_cobble_wall_top.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_wear_bar.png | GUI/formspec (not content) |
| mcl_wool_light_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mcl_wool_lime.png | no vanilla asset in dump (partial 1.12.2 pool) |
| mesecons_button_wield_mask.png | GUI/formspec (not content) |
| mesecons_delayer_end_locked_off.png | mod-specific |
| mesecons_delayer_end_locked_on.png | mod-specific |
| mesecons_delayer_ends_off.png | mod-specific |
| mesecons_delayer_ends_on.png | mod-specific |
| mesecons_delayer_front_locked_off.png | mod-specific |
| mesecons_delayer_front_locked_on.png | mod-specific |
| mesecons_delayer_item.png | mod-specific |
| mesecons_delayer_locked_off.png | mod-specific |
| mesecons_delayer_locked_on.png | mod-specific |
| mesecons_delayer_off.png | mod-specific |
| mesecons_delayer_on.png | mod-specific |
| mesecons_delayer_sides_locked_off.png | mod-specific |
| mesecons_delayer_sides_locked_on.png | mod-specific |
| mesecons_delayer_sides_off.png | mod-specific |
| mesecons_delayer_sides_on.png | mod-specific |
| mesecons_piston_back.png | mod-specific |
| mesecons_piston_pusher_back.png | mod-specific |
| mesecons_piston_pusher_bottom.png | mod-specific |
| mesecons_piston_pusher_left.png | mod-specific |
| mesecons_piston_pusher_right.png | mod-specific |
| mesecons_piston_pusher_top.png | mod-specific |
| mineclonia_icon.png | GUI/formspec (not content) |
| mineclonia_logo.png | GUI/formspec (not content) |
| mobs_blood.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_chicken_egg.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_TEMP_wither_projectile.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_arrow_particle.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_green.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_pink.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_purple.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_axolotl_yellow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_bat.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_blaze.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_all_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_british_shorthair.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_calico.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_collar.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_jellie.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_ocelot.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_persian.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_ragdoll.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_red.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_siamese.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_tabby.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cat_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cave_spider.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_chicken.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_cow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_creeper.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_creeper_charge.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_diamond.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_donkey.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_dragon.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_dragon_fireball.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_drowned.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_drowned_overlay.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_emerald.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_empty.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_endergolem.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_enderman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_enderman_cactus_background.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_enderman_eyes.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_endermite.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_evoker.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_evoker_fangs.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_ghast.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_ghast_firing.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_gold.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_guardian.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_guardian_elder.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_helmet_mask.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_chestnut.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_creamy.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_darkbrown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_gray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_skeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_horse_zombie.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_husk.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_illusionist.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_iron.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_iron_golem.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_iron_golem_crack_high.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_iron_golem_crack_low.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_iron_golem_crack_medium.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_creamy.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_cyan.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_gray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_green.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_light_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_light_gray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_lime.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_magenta.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_orange.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_pink.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_purple.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_red.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_wandering_trader.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_decor_yellow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_gray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_spit.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_llama_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_magmacube.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_mooshroom.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_mooshroom_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_mule.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_mushroom_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_mushroom_red.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_parrot_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_parrot_green.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_parrot_grey.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_parrot_red_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_parrot_yellow_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_pig.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_pig_saddle.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_pillager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_polarbear.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_pufferfish.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_caerbannog.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_gold.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_salt.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_toast.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_rabbit_white_splotched.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_ravager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_sheep.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_sheep_fur.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_sheep_sheared.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_brown.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_cyan.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_gray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_green.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_light_blue.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_lime.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_magenta.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_orange.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_pink.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_purple.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_red.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_silver.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_white.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulker_yellow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_shulkerbullet.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_silverfish.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_skeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_slime.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_snowman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_bat.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_blaze.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_cat.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_cave_spider.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_chicken.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_cod.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_cow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_creeper.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_donkey.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_dragon.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_enderman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_endermite.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_evoker.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_ghast.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_guardian.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_guardian_elder.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_horse.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_horse_skeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_horse_zombie.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_husk.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_illusioner.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_iron_golem.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_killer_bunny.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_llama.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_magmacube.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_mooshroom.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_mule.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_parrot.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_pig.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_polarbear.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_rabbit.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_salmon.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_sheep.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_shulker.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_silverfish.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_skeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_slime.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_snowman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_spider.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_squid.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_stray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_vex.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_villager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_vindicator.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_witch.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_wither.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_witherskeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_wolf.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_zombie.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_zombie_pigman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spawn_icon_zombie_villager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spider.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_spider_eyes.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_squid.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_stone.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_stray.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_stray_overlay.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_trading_formspec_bg.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_trading_formspec_disabled.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_vex.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_vex_charging.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_base.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_desert.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_jungle.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_plains.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_armorer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_butcher.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_cartographer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_cleric.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_farmer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_fisherman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_fletcher.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_leatherworker.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_librarian.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_mason.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_nitwit.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_shepherd.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_toolsmith.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_profession_weaponsmith.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_savanna.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_snow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_swamp.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_taiga.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_villager_wandering_trader.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_vindicator.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_witch.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither_armor.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither_invulnerable.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither_projectile.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither_projectile_strong.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wither_skeleton.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_ashen.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_ashen_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_ashen_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_black.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_black_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_black_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_chestnut.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_chestnut_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_chestnut_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_collar.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_icon_roam.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_icon_sit.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_rusty.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_rusty_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_rusty_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_snowy.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_snowy_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_snowy_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_splash_0.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_splash_1.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_splash_2.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_splash_3.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_spotted.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_spotted_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_spotted_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_striped.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_striped_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_striped_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_woods.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_woods_angry.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_wolf_woods_tame.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_base.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_desert.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_jungle.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_plains.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_armorer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_butcher.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_cartographer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_cleric.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_farmer.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_fisherman.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_fletcher.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_leatherworker.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_librarian.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_mason.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_nitwit.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_shepherd.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_toolsmith.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_profession_weaponsmith.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_savanna.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_snow.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_swamp.png | mobs: custom skins (no 1.12 entity texture) |
| mobs_mc_zombie_villager_taiga.png | mobs: custom skins (no 1.12 entity texture) |
| nether_sprouts.png | modern 1.13+ content (absent from 1.12.2 dump) |
| nether_wart_block.png | no vanilla asset in dump (partial 1.12.2 pool) |
| object_crosshair.png | mod-specific |
| pointed_dripstone_base.png | modern 1.13+ content (absent from 1.12.2 dump) |
| pointed_dripstone_frustum.png | modern 1.13+ content (absent from 1.12.2 dump) |
| pointed_dripstone_middle.png | modern 1.13+ content (absent from 1.12.2 dump) |
| pointed_dripstone_tip.png | modern 1.13+ content (absent from 1.12.2 dump) |
| pointed_dripstone_tip_merge.png | modern 1.13+ content (absent from 1.12.2 dump) |
| powder_snow.png | modern 1.13+ content (absent from 1.12.2 dump) |
| pufferfish_bucket.png | mod-specific |
| redstone_redstone_dust_dot.png | mod-specific |
| redstone_redstone_dust_line0.png | mod-specific |
| redstone_redstone_dust_line1.png | mod-specific |
| respawn_anchor_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_side0.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_side1.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_side2.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_side3.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_side4.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_top_off.png | modern 1.13+ content (absent from 1.12.2 dump) |
| respawn_anchor_top_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| rib_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| rib_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| rib_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| rib_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| rib_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| root_1.png | mod-specific |
| root_2.png | mod-specific |
| root_3.png | mod-specific |
| root_4.png | mod-specific |
| root_5.png | mod-specific |
| root_6.png | mod-specific |
| root_7.png | mod-specific |
| root_8.png | mod-specific |
| salmon_bucket.png | mod-specific |
| screwdriver.png | mod-specific |
| sentry_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| sentry_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| sentry_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| sentry_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| sentry_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| shroomlight.png | mod-specific |
| silence_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| silence_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| silence_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| silence_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| silence_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| smoke_puff.png | particles/effects (not content) |
| smoker_bottom.png | modern 1.13+ content (absent from 1.12.2 dump) |
| smoker_front.png | modern 1.13+ content (absent from 1.12.2 dump) |
| smoker_front_on.png | modern 1.13+ content (absent from 1.12.2 dump) |
| smoker_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| smoker_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| snout_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| snout_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| snout_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| snout_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| snout_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| soul_fire_basic_flame.png | modern 1.13+ content (absent from 1.12.2 dump) |
| soul_fire_basic_flame_animated.png | modern 1.13+ content (absent from 1.12.2 dump) |
| soul_torch_on_floor.png | modern 1.13+ content (absent from 1.12.2 dump) |
| soul_torch_on_floor_animated.png | modern 1.13+ content (absent from 1.12.2 dump) |
| spire_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| spire_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| spire_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| spire_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| spire_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_crimson_stem.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_crimson_stem_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_crimson_stem_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_warped_stem.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_warped_stem_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| stripped_warped_stem_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| sus_stew.png | modern 1.13+ content (absent from 1.12.2 dump) |
| testpathfinder_waypoint.png | mod-specific |
| testpathfinder_waypoint_end.png | mod-specific |
| testpathfinder_waypoint_start.png | mod-specific |
| tide_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| tide_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| tide_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| tide_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| tide_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| tree_1.png | mod-specific |
| tree_2.png | mod-specific |
| tree_3.png | mod-specific |
| tree_4.png | mod-specific |
| tree_5.png | mod-specific |
| tree_6.png | mod-specific |
| tree_7.png | mod-specific |
| tree_8.png | mod-specific |
| trialspawner_blue_bar_particles.1.png | GUI/formspec (not content) |
| trialspawner_blue_bar_particles.2.png | GUI/formspec (not content) |
| trialspawner_blue_dot_particle.png | particles/effects (not content) |
| trialspawner_bottom.png | mod-specific |
| trialspawner_bottom_ominous.png | mod-specific |
| trialspawner_bottom_on.png | mod-specific |
| trialspawner_orange_bar_particles.1.png | GUI/formspec (not content) |
| trialspawner_orange_bar_particles.2.png | GUI/formspec (not content) |
| trialspawner_side.png | mod-specific |
| trialspawner_side_ominous.png | mod-specific |
| trialspawner_side_on.png | mod-specific |
| trialspawner_top.png | mod-specific |
| trialspawner_top_ominous.png | mod-specific |
| trialspawner_top_on.png | mod-specific |
| tropical_fish_bucket.png | mod-specific |
| twisting_vines.png | modern 1.13+ content (absent from 1.12.2 dump) |
| twisting_vines_plant.png | modern 1.13+ content (absent from 1.12.2 dump) |
| vex_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| vex_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| vex_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| vex_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| vex_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| ward_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| ward_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| ward_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| ward_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| ward_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_hyphae.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_hyphae_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_hyphae_wood.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_nylium.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_nylium_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_roots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_stem_stripped_side.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_stem_stripped_top.png | modern 1.13+ content (absent from 1.12.2 dump) |
| warped_wart_block.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wayfinder_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wayfinder_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wayfinder_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wayfinder_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wayfinder_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| weather_pack_rain_raindrop_1.png | particles/effects (not content) |
| weather_pack_rain_raindrop_2.png | particles/effects (not content) |
| weather_pack_rain_raindrop_3.png | particles/effects (not content) |
| weather_pack_snow_snowflake1.png | mod-specific |
| weather_pack_snow_snowflake10.png | mod-specific |
| weather_pack_snow_snowflake11.png | mod-specific |
| weather_pack_snow_snowflake2.png | mod-specific |
| weather_pack_snow_snowflake3.png | mod-specific |
| weather_pack_snow_snowflake4.png | mod-specific |
| weather_pack_snow_snowflake5.png | mod-specific |
| weather_pack_snow_snowflake6.png | mod-specific |
| weather_pack_snow_snowflake7.png | mod-specific |
| weather_pack_snow_snowflake8.png | mod-specific |
| weather_pack_snow_snowflake9.png | mod-specific |
| wild_armor_trim_smithing_template.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wild_boots.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wild_chestplate.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wild_helmet.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wild_leggings.png | modern 1.13+ content (absent from 1.12.2 dump) |
| wool_black.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_blue.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_brown.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_cyan.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_dark_green.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_grey.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_magenta.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_orange.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_pink.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_red.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_violet.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_white.png | no vanilla asset in dump (partial 1.12.2 pool) |
| wool_yellow.png | no vanilla asset in dump (partial 1.12.2 pool) |
| xpanes_top_iron.png | no vanilla asset in dump (partial 1.12.2 pool) |

## Unused vanilla assets (reverse report)

**483** vanilla assets are not referenced by any mapped mod texture
(see `vanilla_unused.txt`).
