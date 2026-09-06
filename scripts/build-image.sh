#!/usr/bin/env bash
set -euo pipefail
image="${1:-localhost/pulse-os:dev}"
exec sudo podman build --pull=newer -t "$image" -f Containerfile .
