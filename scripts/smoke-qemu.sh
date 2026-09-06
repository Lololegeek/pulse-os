#!/usr/bin/env bash
set -euo pipefail
image="${1:?path to qcow2 required}"
[[ -f "$image" ]] || { echo "missing image: $image" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'qemu-system-x86_64 required' >&2; exit 1; }

exec qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 8 -m 8G \
  -device virtio-vga-gl -display gtk,gl=on \
  -device qemu-xhci -device usb-tablet \
  -drive "file=$image,if=virtio,format=qcow2" \
  -nic user,model=virtio-net-pci
