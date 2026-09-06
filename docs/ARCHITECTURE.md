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

## Native PulseOS control plane

PulseOS-specific low-level policy is implemented in C++20 under `src/` rather
than hidden in shell tweaks. `pulse-perfd` runs as a system service and uses the
small `libpulseos` native library to inspect real Steam/Proton processes and
apply reversible Linux scheduling/I/O policy.

```text
Steam / Proton game
  -> SteamAppId / SteamGameId process metadata
  -> pulse-perfd (C++20)
       |-> setpriority(2): conservative nice=-5
       |-> ioprio_set: best-effort class, priority 0
       |-> TuneD latency-performance while gaming
       `-> restore previous TuneD profile after exit
```

The daemon uses an eight-second hysteresis across launcher/process hand-offs. It
does not use executable-name-only heuristics, realtime scheduling, arbitrary CPU
pinning, overclocking or global security-disable flags.

## Scheduling and kernel policy

`scx_lavd` remains the production sched_ext scheduler and runs in autopilot mode.
It can dynamically choose power behavior based on load and safely falls back to
the normal Linux scheduler if the BPF scheduler exits.

PulseOS also contains an experimental C/BPF scheduler core under
`scheduler/pulse-scx`. It is deliberately disabled by default until it has a
userspace-marked game-task map, topology-aware policy, starvation coverage and
repeatable gaming benchmarks. The required BPF/sched_ext kernel capabilities are
tracked in `kernel/config/pulseos-x86_64.fragment`.

The default image uses Fedora's maintained kernel. `kernel/patches/` is reserved
for small benchmark-backed downstream changes only when upstream interfaces,
sched_ext or configuration cannot provide the desired behavior.

A small user daemon (`gamingd`) still requests Feral GameMode only while a real
game is running. GameMode and `pulse-perfd` therefore complement each other:
GameMode handles its standard platform/governor integrations while the native
PulseOS daemon owns PulseOS-specific process and host policy.

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
