#!/usr/bin/env bash
# Builds the Luanti engine in an isolated container.
#
# The binary is linked against Void Linux glibc, so it runs on the
# host system that this game is developed for.
#
# Environment:
#   CONTAINER_RUNTIME  container runtime to use (default: podman)
#   ENGINE_IMAGE       image name for the build environment
#   RUN_IN_PLACE       set to 1 to build a portable engine (data paths
#                      relative to the executable, for distribution)
set -euo pipefail
cd "$(dirname "$0")"

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${ENGINE_IMAGE:-betacraft-engine-builder}"

CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/install -DENABLE_GETTEXT=FALSE)
if [ "${RUN_IN_PLACE:-0}" = "1" ]; then
	echo "==> Building portable engine (RUN_IN_PLACE=TRUE)"
	CMAKE_ARGS+=(-DRUN_IN_PLACE=TRUE)
else
	echo "==> Building system-paths engine (RUN_IN_PLACE not set)"
fi

if ! "$CONTAINER_RUNTIME" image inspect "$IMAGE" >/dev/null 2>&1; then
	echo "==> Building image $IMAGE"
	"$CONTAINER_RUNTIME" build -t "$IMAGE" -f Containerfile .
else
	echo "==> Image $IMAGE already exists ($CONTAINER_RUNTIME rmi $IMAGE to force a rebuild)"
fi

mkdir -p build install build/bin

# Luanti builds its executable into <source>/bin (see src/CMakeLists.txt),
# so we redirect /src/bin to build/bin to keep the source tree pristine.
"$CONTAINER_RUNTIME" run --rm \
  -v "$PWD/luanti:/src" \
  -v "$PWD/build:/build" \
  -v "$PWD/build/bin:/src/bin" \
  -v "$PWD/install:/install" \
  "$IMAGE" \
  sh -c '
    set -eu
    cmake -S /src -B /build '"${CMAKE_ARGS[*]}"'
    cmake --build /build -j"$(nproc)"
    cmake --install /build
  '

echo "Done. Binary: $PWD/install/bin/luanti"
