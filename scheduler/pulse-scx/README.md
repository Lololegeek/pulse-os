# pulse-scx (experimental)

`pulse-scx` is the PulseOS research scheduler built on Linux `sched_ext` and BPF. It is **not enabled by default**. PulseOS currently ships `scx_lavd` because it is substantially more mature and already targets latency-sensitive workloads.

The first BPF core deliberately mirrors conservative sched_ext placement. The project will only add gaming-specific scheduling decisions after the userspace control plane can explicitly mark game TGIDs and benchmarks prove a benefit in 1% lows, frame-time tails or input-to-frame latency.

## Why not replace LAVD immediately?

`sched_ext` intentionally has no stable scheduler ABI. A scheduler can also perform worse than the normal Linux scheduler on a topology or workload it was not designed for. PulseOS therefore treats custom scheduling as an experiment with automatic fallback, not a marketing toggle.

## Build model

The source is intended to build against the current upstream Linux `tools/sched_ext` / `sched-ext/scx-c-examples` BPF headers and generated `vmlinux.h`. It is kept out of the default image build until its loader and compatibility matrix are ready.

Required kernel capabilities are tracked in `kernel/config/pulseos-x86_64.fragment`.

## Planned control path

```text
pulse-perfd
  -> identifies real Steam/Proton game processes
  -> writes gaming TGIDs to a BPF map
  -> pulse-scx reads the map
  -> latency-sensitive policy only for explicitly marked game tasks
```

This avoids heuristics based on executable names and prevents Steam UI/background processes from receiving gaming policy.
