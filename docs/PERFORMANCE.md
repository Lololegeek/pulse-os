# Performance policy

PulseOS optimizes for smoothness and latency, but refuses to treat random sysctl
lists as evidence. Every default needs one of these reasons:

1. It is required for game compatibility.
2. It is reversible and active only while gaming.
3. It is an upstream mechanism specifically intended for latency/interactivity.
4. It can be validated through frametime/latency measurements.

## Defaults that matter

### `scx_lavd`

LAVD is a sched_ext scheduler designed around latency-critical workloads and was
initially motivated by gaming. PulseOS uses its **autopilot** mode globally. At
high system load it can favor performance; at low load it can avoid needlessly
burning power and thermal headroom.

### GameMode + TuneD

When a game is detected:

- GameMode requests CPU/platform performance policy.
- I/O priority is raised.
- Game process nice/I/O priority is best-effort adjusted by `gamingd`.
- `pulseos-performance-agent` temporarily selects TuneD's `latency-performance`
  profile, then restores the previous TuneD profile when gaming ends.

GPU overclock controls are explicitly disabled.

### Gamescope

Gaming Mode launches Steam inside Gamescope rather than under Plasma. Gamescope
can use DRM/KMS direct flips when possible and Vulkan async compute when it must
compose. Adaptive sync is requested by default. HDR is opt-in with
`PULSEOS_HDR=1`, because forcing HDR on unsupported/misconfigured displays is not
an optimization.

### Proton and ntsync

PulseOS ships a modern Fedora kernel and loads `ntsync`. Proton remains supplied
by Steam. If the selected Proton build can use ntsync, `/dev/ntsync` is already
available; otherwise Proton falls back to its supported synchronization path.

### Memory

- `vm.max_map_count` is increased for compatibility with games/launchers that use
  very many mappings.
- swappiness is lowered to 10.
- compressed zram is kept as an emergency buffer against disk-swap stalls.

PulseOS does **not** disable swap entirely: an out-of-memory kill during a game is
worse than occasional compressed-memory pressure.

### Audio

PipeWire uses 256 frames by default at 48 kHz (~5.3 ms quantum) with 128 as the
minimum (~2.7 ms). Lower values can be selected per device after measurement.

## Intentionally not enabled

PulseOS does not ship these as defaults:

- `mitigations=off` / Spectre or Meltdown mitigation disabling;
- `nohz_full`, `isolcpus`, `rcu_nocbs` on arbitrary desktops;
- global CPU core pinning;
- global `performance` governor 24/7;
- forced GPU power limits or overclocking;
- AMD `ppfeaturemask` hacks;
- NMI watchdog disabling;
- arbitrary TCP congestion-control changes marketed as "ping tweaks";
- Vulkan/DXVK environment flags applied to every game.

They either reduce security, depend heavily on hardware/workload, or can cause
regressions that disappear from a cherry-picked FPS average.

## How PulseOS should be benchmarked

A release should compare the same BIOS, firmware, game version, driver version
and graphics settings against SteamOS/Bazzite/Fedora/Windows where applicable.
Measure at least:

- average FPS;
- 1% and 0.1% lows;
- p95/p99 frametime;
- frametime variance and stutter count;
- click-to-photon latency when equipment is available;
- audio XRUNs;
- CPU/GPU power and temperature;
- shader-compilation first-run and warm-cache runs.

At least three runs per configuration should be recorded, with outliers retained
and explained rather than silently discarded.
