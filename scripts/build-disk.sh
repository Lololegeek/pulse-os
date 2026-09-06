#!/usr/bin/env bash
set -euo pipefail
image="${1:?image ref required}"
type="${2:-qcow2}"
out="${3:-output}"
mkdir -p "$out"

case "$type" in qcow2|raw) ;; *) echo "unsupported disk type: $type" >&2; exit 2;; esac

sudo podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(realpath "$out"):/output" \
  ghcr.io/osbuild/image-builder-cli:latest \
  build \
  --bootc-ref "$image" \
  --bootc-default-fs btrfs \
  --output-dir /output \
  "$type"
