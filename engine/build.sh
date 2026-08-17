#!/usr/bin/env bash
# Builds the Luanti engine in an isolated container.
#
# The binary is linked against Void Linux glibc, so it runs on the
# host system that this game is developed for.
#
# Environment:
#   CONTAINER_RUNTIME  container runtime to use (default: podman)
#   ENGINE_IMAGE       image name for the build environment
set -euo pipefail
cd "$(dirname "$0")"

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${ENGINE_IMAGE:-betacraft-engine-builder}"

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
    cmake -S /src -B /build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/install \
      -DENABLE_GETTEXT=FALSE
    cmake --build /build -j"$(nproc)"
    cmake --install /build
  '

echo "Done. Binary: $PWD/install/bin/luanti"
