#!/usr/bin/env bash
set -euo pipefail

installer="${1:?installer image ref required}"
payload="${2:?payload image ref required}"
out="${3:-output}"
mkdir -p "$out"

if ! command -v podman >/dev/null 2>&1; then
  echo "podman is required" >&2
  exit 1
fi

# image-builder must see the same rootful container storage as the locally built
# installer and payload images.
sudo podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(realpath "$out"):/output" \
  ghcr.io/osbuild/image-builder-cli:latest \
  build \
  --bootc-ref "$installer" \
  --bootc-installer-payload-ref "$payload" \
  --bootc-default-fs btrfs \
  --output-dir /output \
  bootc-generic-iso
