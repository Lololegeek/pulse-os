# Native PulseOS performance layer

PulseOS is a Linux distribution, so it does not duplicate the Linux kernel, Mesa, Wine/Proton or Gamescope source trees. PulseOS-specific low-level behavior lives in this repository instead.

## pulse-perfd

`src/pulse-perfd` is a root system daemon written in C++20 and linked against the small `libpulseos` static library.

It currently:

- scans `/proc` for real Steam/Proton application processes using `SteamAppId` / `SteamGameId` from the process environment;
- excludes the Steam client, Wine infrastructure and container helper processes;
- applies a conservative `nice=-5` policy directly with `setpriority(2)`;
- applies best-effort I/O class 2 / priority 0 through the Linux `ioprio_set` syscall;
- watches the PulseOS/GameMode gaming marker;
- changes TuneD to `latency-performance` only while a game is active;
- restores the exact previous TuneD profile when gaming ends;
- uses an eight-second exit hysteresis so launcher/process hand-offs do not repeatedly change host power policy;
- logs state changes to the system journal.

It intentionally does **not** pin games to arbitrary CPU cores, disable SMT, force realtime scheduling, overclock hardware or change security mitigations. Those changes are highly hardware/workload-dependent and can make frame pacing worse.

## Kernel policy

`kernel/config/pulseos-x86_64.fragment` records the kernel capabilities PulseOS expects, especially BPF and `sched_ext` support. The default image continues to use Fedora's maintained kernel rather than carrying a large downstream fork.

`kernel/patches/` is reserved for small benchmark-backed patches when an upstream interface cannot provide the required behavior.

## pulse-scx

`scheduler/pulse-scx` contains the C/BPF starting point for a PulseOS-specific `sched_ext` scheduler. It is deliberately experimental and not loaded by default. The production default remains `scx_lavd` until `pulse-scx` has a userspace task-marking map, topology-aware policy, starvation tests and repeatable gaming benchmarks.

The intended design is for `pulse-perfd` to mark known game TGIDs in a BPF map. The scheduler can then make latency-sensitive decisions for actual game tasks rather than using executable-name heuristics.

## Build

The default OS image uses a multi-stage container build. A Fedora build stage compiles the native C++ code with CMake/Ninja, and only the resulting `pulse-perfd` binary is copied into the final bootc image.

The Verify workflow independently builds the native tree on Ubuntu with GCC, CMake and Ninja so pull requests cannot merge obviously uncompilable native code.
