#!/bin/sh
# Build the Discord Rich Presence companion for Betacraft.
# Produces binaries for Linux and Windows (amd64) into
# mods/CORE/mcl_discord_rpc/bin, where the mcl_discord_rpc mod picks them up.
#
# Requirements: Go 1.21+ (https://go.dev/dl/)
#
#   Windows build (cross-compile from anywhere):
#     ./build.sh
#   Linux-only build:
#     ./build.sh linux
#   Windows-only build (also usable from cmd/PowerShell via build.bat):
#     ./build.sh windows
set -e
cd "$(dirname "$0")"

OUT="../../mods/CORE/mcl_discord_rpc/bin"
mkdir -p "$OUT"

build() {
	os="$1"
	name="$2"
	echo "Building for ${os} (amd64)..."
	GOOS="${os}" GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" \
		-o "${OUT}/${name}" .
}

case "$1" in
	linux)   build linux discord_rpc ;;
	windows) build windows discord_rpc.exe ;;
	*)
		build linux discord_rpc
		build windows discord_rpc.exe
		;;
esac

echo "Done. Binaries in ${OUT}"