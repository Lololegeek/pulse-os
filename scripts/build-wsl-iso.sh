#!/usr/bin/env bash
set -euo pipefail

# Build PulseOS from an Ubuntu WSL distribution while using the rootful
# Podman Desktop WSL2 machine as the actual container/image-builder host.
# This avoids relying on block-device features of the generic Microsoft WSL
# kernel that image-builder may require.

if ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  echo "This helper is intended to run inside WSL2." >&2
  exit 1
fi

for command in podman tar; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required inside Ubuntu WSL." >&2
    exit 1
  fi
done

machine="${PULSEOS_PODMAN_MACHINE:-podman-machine-default}"
socket="/mnt/wsl/podman-sockets/${machine}/podman-root.sock"

if [[ ! -S "$socket" ]]; then
  cat >&2 <<EOF
The rootful Podman Desktop socket was not found at:
  $socket

From Windows PowerShell, run:
  podman machine stop $machine
  podman machine set --rootful=true $machine
  podman machine start $machine

Then retry this command from Ubuntu WSL.
EOF
  exit 1
fi

# A Linux Podman client can talk directly to the Podman Desktop machine via
# the cross-distro WSL socket. No local podman daemon is needed in Ubuntu.
export CONTAINER_HOST="unix://${socket}"

if ! podman info >/dev/null 2>&1; then
  echo "Unable to connect to the rootful Podman machine through $socket" >&2
  exit 1
fi

image="${IMAGE:-localhost/pulse-os:dev}"
installer_image="${INSTALLER_IMAGE:-localhost/pulse-os-installer:dev}"
update_ref="${UPDATE_REF:-ghcr.io/lololegeek/pulse-os:edge}"
out="${OUTPUT:-$(pwd)/output}"

mkdir -p "$out"

echo "==> Connected to Podman Desktop rootful WSL2 machine"
podman version

echo "==> Building PulseOS bootc image: $image"
podman build --pull=newer -t "$image" -f Containerfile .

echo "==> Building installer image: $installer_image"
podman build \
  --pull=newer \
  --build-arg "PULSEOS_SOURCE_REF=$image" \
  --build-arg "PULSEOS_UPDATE_REF=$update_ref" \
  -t "$installer_image" \
  -f installer/Containerfile .

# The image-builder runs on the remote Podman machine. A named volume keeps the
# generated ISO on that machine, then we stream it through the remote Podman API
# into the Ubuntu WSL filesystem. This works even when the repo lives in ~/.
volume="pulseos-iso-output-${USER:-wsl}-$$"
cleanup() {
  podman volume rm -f "$volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT

podman volume create "$volume" >/dev/null

echo "==> Building bootable installer ISO"
podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$volume:/output" \
  ghcr.io/osbuild/image-builder-cli:latest \
  build \
  --bootc-ref "$installer_image" \
  --bootc-installer-payload-ref "$image" \
  --bootc-default-fs btrfs \
  --output-dir /output \
  bootc-generic-iso

echo "==> Copying build artifacts back into $out"
podman run --rm \
  -v "$volume:/from:ro" \
  docker.io/library/alpine:latest \
  sh -c 'cd /from && tar -cf - .' | tar -C "$out" -xf -

iso="$(find "$out" -type f -name '*.iso' -print -quit)"
if [[ -z "$iso" ]]; then
  echo "Image Builder completed but no ISO was found in $out" >&2
  find "$out" -maxdepth 4 -type f -ls >&2 || true
  exit 1
fi

printf '\nPulseOS ISO created successfully:\n  %s\n' "$iso"
ls -lh "$iso"
