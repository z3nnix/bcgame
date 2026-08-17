#!/bin/sh
# Betacraft launcher (Linux)
# Runs the bundled Luanti engine with the starter world.
# The game folder must stay a direct child of its parent directory so that
# LUANTI_GAME_PATH (the parent) can find this game.
set -e
cd "$(dirname "$0")"

# Keep world.mt's gameid in sync with the folder name, so renaming the
# folder does not break game discovery.
GAMEID="$(basename "$PWD")"
sed -i "s/^gameid = .*/gameid = $GAMEID/" worlds/default/world.mt

export LUANTI_GAME_PATH="$PWD/.."
exec ./bin/luanti --go --world "$PWD/worlds/default"