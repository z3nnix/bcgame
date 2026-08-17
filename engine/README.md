# engine

The engine is a vendored fork of [Luanti](https://www.luanti.org) 5.16.1 with a
small custom patch (see `patches/`). This repository is a monorepo, so the
whole engine source tree lives here at `luanti/`.

## Layout

- `luanti/` — full Luanti 5.16.1 source with the custom patch applied
- `patches/pause_menu.patch` — the delta against vanilla 5.16.1
- `Containerfile` — build environment (Void Linux) for the engine binary
- `build.sh` — one-shot build script
- `build/`  — CMake build directory (generated, git-ignored)
- `install/` — install prefix: `install/bin/luanti` is the runnable engine
  (generated, git-ignored)

## What the patch does

Adds `core.register_on_pause_menu(callback)` and lets a game ship a
`menu/pause_menu.lua` to override the in-game pause menu. When the player opens
the pause menu (Esc), the callback is run and its returned formspec string is
shown instead of the hardcoded default. If no callback is registered or it
returns an empty string, the default pause menu is shown. It only applies in
singleplayer and locally-hosted games, because the client does not have the
game's files otherwise.

This is what Betacraft's own `menu/pause_menu.lua` uses to render the dark
pause screen with the three centered buttons.

## Building

Requires `podman` (or `docker`) and network access. The binary is linked
against Void Linux glibc so that it runs on the development host.

```sh
./build.sh
```

Result: `./install/bin/luanti`.

Environment variables:

- `CONTAINER_RUNTIME` — runtime to use (`podman` by default, use `docker` in CI)
- `ENGINE_IMAGE` — container image name

The build environment image is reused between runs; remove it to force a
rebuild (`podman rmi betacraft-engine-builder`).

## Regenerating the patch

```sh
git clone --depth 1 --branch 5.16.1 https://github.com/luanti-org/luanti VANILLA
git diff --no-index -- VANILLA luanti > patches/pause_menu.patch
rm -rf VANILLA
```

## Running

```sh
./install/bin/luanti --go --world ~/.minetest/worlds/main --port 30007
```