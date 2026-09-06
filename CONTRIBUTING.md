# Contributing to PulseOS

Thank you for helping build PulseOS. Contributions are welcome from first-time contributors and experienced Linux developers alike.

## What we value

PulseOS is performance-focused, but a change is not considered an optimization simply because it sounds low-level. Good changes are measurable, maintainable, reversible where possible, and do not quietly reduce security or compatibility.

Useful contributions include:

- reproducible performance and latency measurements;
- AMD, Intel, NVIDIA, laptop, desktop and handheld hardware testing;
- Proton/game compatibility fixes;
- Gamescope, PipeWire, scheduler and GameMode integration;
- installer and recovery improvements;
- accessibility and controller UX;
- CI/release engineering;
- documentation and troubleshooting.

## Development flow

1. Create an issue for large behavioral changes so the design can be discussed first.
2. Fork the repository and create a focused branch.
3. Make the smallest coherent change that solves the problem.
4. Run the validation suite:

```bash
make verify
```

5. If you changed the image composition, build it when possible:

```bash
make image
```

6. If you changed installer or boot behavior, build an ISO/QCOW2 and test it.
7. Open a pull request using the repository template.

## Performance changes

Performance PRs should include:

- exact CPU, GPU, RAM, display and storage hardware;
- kernel, Mesa/NVIDIA driver and Proton versions;
- game/build version and graphics settings;
- baseline and modified results from the same machine;
- average FPS plus 1% lows or p99 frametime at minimum;
- at least three comparable runs where practical;
- thermal/power behavior when the tweak can change clocks;
- known regressions or workloads that become worse.

A global tweak that improves one benchmark but regresses other hardware will normally be rejected or made opt-in.

## Safety rules

Default configurations must not:

- disable Spectre/Meltdown or similar CPU mitigations;
- grant broad unsafe kernel capabilities to normal users;
- automatically overclock GPUs/CPUs or raise hardware power limits;
- bypass anti-cheat or conceal kernel modifications from third parties;
- embed passwords, signing keys, API tokens, private certificates or other secrets;
- make destructive storage changes without explicit installer/user interaction.

The automated safety scan enforces some of these rules, but review is still required.

## Shell and Python

- Shell scripts should use `#!/usr/bin/env bash` and `set -euo pipefail` when appropriate.
- Keep scripts shellcheck-clean.
- Quote expansions unless intentional word splitting is required.
- Python should target the Python version shipped by the current Fedora base.
- Prefer readable systemd units and config files over opaque shell hacks.

## Commit and PR style

Use clear, imperative commit subjects, for example:

```text
gamescope: enable adaptive sync only when supported
installer: preserve selected LUKS layout across retry
ci: upload ISO checksums with build artifacts
```

A PR should solve one main problem. Explain *why* the change is needed, not only what the diff does.

## Licensing

By contributing, you agree that your contribution may be distributed under the repository's GPL-3.0-or-later license unless the file clearly carries another compatible license. Do not submit code you do not have the right to redistribute.

## Conduct

All project spaces are governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
