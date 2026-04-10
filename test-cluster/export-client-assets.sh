#!/usr/bin/env sh
set -eu

# This script exists for the ARM-based Vagrant test cluster.
#
# The app's frontend is an old Elm 0.18 build. That toolchain can still be
# executed in an amd64 build environment, but it does not provide linux-arm64
# binaries, so the frontend cannot be rebuilt inside the arm64 VMs used by the
# local test cluster.
#
# To keep the test cluster usable on Apple Silicon and other arm64 hosts, we:
# 1. build the full image once in an amd64-capable environment on the host
# 2. copy the generated static frontend bundle back into elm-client/client/
# 3. build a native arm64 runtime image that reuses those exported assets
#
# The exported elm-client/client/index.js file is therefore a generated build
# artifact, not handwritten source. It is needed only so the arm64 test-cluster
# image can serve the frontend without trying to run the legacy Elm compiler in
# the VM.
#
# This script documents and performs that export step.
IMAGE_TAG="${1:-swarm-dashboard:test-cluster-amd64}"
CONTAINER_ID="$(docker create "$IMAGE_TAG")"
cleanup() {
  docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p elm-client/client
docker cp "$CONTAINER_ID:/home/node/app/client/." elm-client/client/
echo "Exported frontend assets from $IMAGE_TAG to elm-client/client/"
