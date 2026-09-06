# PulseOS kernel patch policy

PulseOS deliberately starts from the Fedora kernel instead of maintaining a large downstream fork. The kernel already provides the hardware enablement, security work, sched_ext infrastructure, graphics interfaces and compatibility that a gaming distribution needs.

This directory is reserved for small, reviewable PulseOS-specific patches when a measurable gaming benefit cannot be achieved through an upstream interface, a kernel configuration option or sched_ext.

## Rules

A patch is accepted only when it:

- has a reproducible benchmark showing an improvement in frame-time consistency, latency, compatibility or power behavior;
- does not disable security mitigations or weaken isolation to win benchmarks;
- is narrowly scoped and easy to rebase;
- includes a rollback path and a test plan;
- is intended for upstream submission when generally useful.

No downstream kernel patch is enabled in the default image yet. The current performance strategy is to use upstream Linux facilities (`sched_ext`, cgroup v2, nice/ioprio, TuneD, ntsync) first.
