#!/bin/sh
# Build the Betacraft launcher for Linux and Windows (amd64).
#
# Native Wails window: Linux uses webkit2gtk-4.1, Windows uses WebView2
# (built into Windows 10/11; no C compiler needed).
#
#   ./build.sh          native binaries (default)
#   ./build.sh web      browser-mode fallback binaries (no webkit2gtk needed)
#   ./build.sh linux
#   ./build.sh windows
#
# Linux native build needs webkit2gtk-4.1 dev headers, e.g. on Void:
#   sudo xbps-install libwebkit2gtk41-devel
set -e
cd "$(dirname "$0")"

OUT="$PWD/bin"
mkdir -p "$OUT"

build_linux() {
	echo "Building launcher for linux/amd64 (native window, webkit2gtk-4.1)..."
	CGO_ENABLED=1 go build -tags "wails production webkit2_41" -trimpath -ldflags="-s -w" \
		-o "$OUT/launcher" .
}

build_linux_web() {
	echo "Building launcher-web for linux/amd64 (browser mode)..."
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o "$OUT/launcher-web" .
}

build_windows() {
	echo "Building launcher.exe for windows/amd64 (native window, WebView2)..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 \
		go build -tags "wails production" -trimpath -ldflags="-s -w" -o "$OUT/launcher.exe" .
}

build_windows_web() {
	echo "Building launcher-web.exe for windows/amd64 (browser mode)..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 \
		go build -trimpath -ldflags="-s -w" -o "$OUT/launcher-web.exe" .
}

case "$1" in
	linux)   build_linux ;;
	windows) build_windows ;;
	web)
		build_linux_web
		build_windows_web
		;;
	*)
		build_linux
		build_windows
		;;
esac

echo "Done. Binaries in ${OUT}"