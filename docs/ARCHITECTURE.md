# PulseOS architecture

## System image

PulseOS is delivered as a bootable OCI image (`bootc`). `/usr` is image-owned;
local state lives in `/etc` and `/var`. Updating stages a new deployment and the
previous deployment remains available for rollback.

## Display/session topology

```text
UEFI
  -> Linux / systemd
     -> SDDM autologin
        -> pulseos-session
           |-> gaming: Gamescope (DRM/KMS) -> Steam Gamepad UI -> game
           `-> desktop: KDE Plasma Wayland
```

Plasma is not intentionally left compositing underneath Gaming Mode. Gamescope
can direct-scan-out on supported paths and uses Vulkan composition when it has to
compose.

## Windows compatibility

```text
Windows game
  -> Proton (Wine)
     |-> D3D8/9/10/11 -> DXVK -> Vulkan
     `-> D3D12 -> VKD3D-Proton -> Vulkan
  -> Linux kernel / ntsync when supported by Proton
  -> Mesa or NVIDIA Vulkan driver
```

PulseOS does not fork Proton. Steam's own Proton builds are preferred so known
per-game compatibility settings remain aligned with Valve's client.

## Scheduling and power

`scx_lavd` runs in autopilot mode as the system scheduler. It can dynamically
choose power behavior based on load and safely falls back to the normal Linux
scheduler if the BPF scheduler exits.

A small user daemon (`gamingd`) detects real Steam application processes using
`SteamAppId`/`SteamGameId`. It requests Feral GameMode only while a game is
running. GameMode applies its documented governor/I/O policy, while the root
`pulseos-performance-agent` watches the reversible gaming marker and switches
TuneD to `latency-performance`. When the last game exits, it restores the TuneD
profile that was active before gaming.

This stack deliberately avoids CPU isolation, static core pinning and permanently
forcing the performance governor. Those settings can improve one benchmark and
hurt another, especially on hybrid Intel and multi-CCD Ryzen systems.

## Audio

PipeWire stays at 48 kHz with a default 256-frame quantum and a minimum 128-frame
quantum. That is a low-latency desktop configuration without assuming every USB
headset/DAC can sustain 32/64-frame buffers without XRUNs.

## Update behavior

`pulseos-idle-update.timer` checks daily. It does not stage a bootc update while
a GameMode request is active or while a laptop battery is below 40% and not
charging. Updates are staged, not forced-rebooted.
