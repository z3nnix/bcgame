#!/usr/bin/env bash
# Cross-compiles the Luanti engine for Windows (MinGW) on this Linux host.
#
# Uses the vendored Luanti buildbot scripts: a self-contained llvm-mingw
# toolchain plus prebuilt dependency archives. No Windows/MSVC/vcpkg needed.
#
# Environment:
#   TOOLCHAIN_DIR  where the llvm-mingw toolchain is kept (default: ./.toolchain-win64)
#   BUILDDIR       build directory + dependency cache (default: ./build-win64)
#   OUTDIR         run-in-place install tree (default: ./install-win64)
set -euo pipefail
cd "$(dirname "$0")"

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$PWD/.toolchain-win64}"
BUILDDIR="${BUILDDIR:-$PWD/build-win64}"
OUTDIR="${OUTDIR:-$PWD/install-win64}"

for c in cmake ninja wget unzip sha256sum; do
	command -v "$c" >/dev/null || { echo "Missing dependency: $c (xbps-install $c)"; exit 1; }
done

# Self-contained llvm-mingw toolchain (cached across runs).
if [ ! -x "$TOOLCHAIN_DIR/bin/x86_64-w64-mingw32-clang" ]; then
	command -v xz >/dev/null || { echo "Missing dependency: xz (xbps-install xz)"; exit 1; }
	echo "==> Downloading llvm-mingw toolchain to $TOOLCHAIN_DIR"
	mkdir -p "$TOOLCHAIN_DIR"
	./luanti/util/buildbot/download_toolchain.sh "$TOOLCHAIN_DIR"
else
	echo "==> Toolchain already present: $TOOLCHAIN_DIR"
fi
export PATH="$TOOLCHAIN_DIR/bin:$PATH"

mkdir -p "$BUILDDIR"

# Build with the vendored buildbot script. NO_PACKAGE skips cpack (we install
# the tree ourselves below, so no external `zip` is required).
echo "==> Building Windows engine"
EXISTING_MINETEST_DIR="$PWD/luanti" NO_PACKAGE=1 \
	./luanti/util/buildbot/buildwin64.sh "$BUILDDIR" \
	-G Ninja \
	-DENABLE_GETTEXT=FALSE \
	-DENABLE_LEVELDB=FALSE

# RUN_IN_PLACE defaults to TRUE on Windows, so the install tree is portable:
# data lands at the prefix root, binary + DLLs in bin/.
echo "==> Installing engine tree to $OUTDIR"
rm -rf "$OUTDIR"
cmake --install "$BUILDDIR/build" --prefix "$OUTDIR"

# The build drops luanti.exe into the vendored source's bin/; remove it to
# keep the tree clean (engine/luanti/bin is gitignored anyway).
rm -f luanti/bin/luanti.exe

echo "Done. Engine: $OUTDIR/bin/luanti.exe"