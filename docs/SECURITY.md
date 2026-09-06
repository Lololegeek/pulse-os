# Security model

Gaming performance does not justify silently removing platform security.

PulseOS keeps CPU mitigations enabled, does not globally enable unprivileged BPF,
does not ship GPU overclock permissions, and does not bypass anti-cheat systems.

## Trust boundaries

- The immutable OS image owns `/usr`.
- User applications should prefer Flatpak when they do not require host-level
  integration.
- Steam/Proton games remain normal user processes.
- `scx_lavd` is the only performance component intentionally running with the
  privileges necessary to attach a sched_ext BPF scheduler.
- `gamingd` is unprivileged and only requests documented GameMode behavior.

## Updates

OCI image signing should be enforced before public release. The GitHub release workflow demonstrates keyless signing, but the production bootc signature policy
must also be configured to verify your chosen identity/key.

## Anti-cheat

PulseOS does not patch or conceal the kernel to defeat anti-cheat. Games whose
publishers do not enable Linux/Proton support may remain unavailable.
