# PulseOS Gaming

[![Verify](https://github.com/Lololegeek/pulse-os/actions/workflows/verify.yml/badge.svg)](https://github.com/Lololegeek/pulse-os/actions/workflows/verify.yml)
[![Build PulseOS](https://github.com/Lololegeek/pulse-os/actions/workflows/build-image.yml/badge.svg)](https://github.com/Lololegeek/pulse-os/actions/workflows/build-image.yml)
[![License: GPL-3.0-or-later](https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg)](LICENSE)

**PulseOS is a gaming-first Linux operating system focused on smooth frame pacing, low latency, Windows-game compatibility, and console-like reliability.**

PulseOS is built as a Fedora 44 `bootc`/OCI operating-system image. Gaming Mode launches a dedicated Gamescope + Steam session instead of keeping a full desktop compositor behind the game, while KDE Plasma remains available as a normal desktop mode.

> [!IMPORTANT]
> PulseOS is currently **alpha software (0.1.x)**. The source tree is buildable and produces an installable image/ISO, but it has not yet completed the hardware-matrix, upgrade, Secure Boot, and benchmark validation required for a stable end-user release. Do not install it on a machine that contains data you cannot afford to lose.

## Why PulseOS?

PulseOS is not a collection of random "gaming tweaks". Its default policy is deliberately conservative: performance changes should be measurable, reversible, hardware-aware, and safe.

| Area | PulseOS approach |
| --- | --- |
| Windows games | Steam Proton, DXVK, VKD3D-Proton and Linux `ntsync` |
| Frame pacing | `sched_ext` + `scx_lavd` autopilot, designed around latency-sensitive workloads |
| Display path | Gamescope embedded session, adaptive sync, direct scan-out when available |
| Per-game tuning | Feral GameMode plus a reversible TuneD `latency-performance` profile |
| Audio | PipeWire with conservative low-latency defaults |
| Desktop | KDE Plasma Wayland, separate from Gaming Mode |
| Updates | Atomic `bootc` deployments with rollback |
| Recovery | Previous deployment remains available after an update |
| GPU safety | No automatic overclocking or unsafe power-limit modifications |
| Security | No `mitigations=off`, anti-cheat bypasses, or benchmark-cheat defaults |

The goal is not to claim a magical universal FPS advantage. PulseOS targets **high 1% lows, low tail latency, predictable frame times, and a gaming experience that stays reliable after updates**.

## Architecture

```text
UEFI
  -> Linux + systemd
     -> SDDM
        -> pulseos-session
           |-> Gaming Mode
           |    -> Gamescope (DRM/KMS)
           |       -> Steam Gamepad UI
           |          -> Proton / native game
           |
           `-> Desktop Mode
                -> KDE Plasma Wayland
```

Windows-game graphics flow:

```text
Windows game
  -> Proton / Wine
     |-> D3D8/9/10/11 -> DXVK -> Vulkan
     `-> D3D12         -> VKD3D-Proton -> Vulkan
  -> Mesa or NVIDIA driver
  -> Linux kernel
```

See [Architecture](docs/ARCHITECTURE.md) and [Performance Policy](docs/PERFORMANCE.md) for details.

## Build PulseOS from Windows — no local VM required

The repository contains a GitHub Actions pipeline that performs the Linux-only build remotely.

1. Fork or clone this repository on Windows.
2. Push your changes to GitHub.
3. Open **Actions -> Build PulseOS -> Run workflow**.
4. When the job finishes, download the `PulseOS-Gaming-ISO-*` artifact from the workflow run.

A push to `main` also runs the build automatically. Release tags such as `v0.1.0` create a GitHub Release with the ISO and checksum attached.

The workflow publishes OCI images to:

```text
ghcr.io/lololegeek/pulse-os:<commit-sha>
ghcr.io/lololegeek/pulse-os:edge       # main branch
ghcr.io/lololegeek/pulse-os:stable     # tagged releases
```

> [!NOTE]
> After the first GHCR publication, make sure the `pulse-os` package is public in GitHub Packages before distributing an installer that uses it for `bootc` updates.

See [Building PulseOS](docs/BUILDING.md) and [CI/CD](docs/CI.md).

## Build locally on Linux

Recommended host: Fedora 44 x86_64.

```bash
git clone https://github.com/Lololegeek/pulse-os.git
cd pulse-os
make verify
make image
make iso
```

Artifacts are written under `output/`.

For a QEMU disk image:

```bash
make qcow2
./scripts/smoke-qemu.sh output/<generated-image>.qcow2
```

## Runtime modes

```bash
pulseosctl gaming
pulseosctl desktop
```

Gaming Mode launches Gamescope + Steam. Desktop Mode launches KDE Plasma Wayland. Lutris and Winetricks are included for non-Steam games; optional Heroic and ProtonUp-Qt can be installed with:

```bash
pulseosctl extras
```

## GPU support

**AMD and Intel** use the Mesa/Vulkan path and are the primary build target.

**NVIDIA** requires kernel modules built against the exact kernel shipped in the immutable OS image. PulseOS therefore keeps NVIDIA as a separate image target rather than compiling drivers on the player's PC. Read [NVIDIA support](docs/NVIDIA.md) before building or distributing it.

## Anti-cheat

Anti-cheat compatibility is controlled by game publishers and anti-cheat vendors. PulseOS does not attempt to conceal, patch, or weaken the kernel to bypass unsupported anti-cheat systems. A game that refuses Linux/Proton may remain unavailable until its publisher enables support.

## Project principles

- Measure first; tune second.
- Optimize frame time, not screenshots of peak FPS.
- Prefer upstream Linux, Mesa, Wine/Proton and Gamescope mechanisms.
- Never trade security for an unverified benchmark gain by default.
- Make performance changes reversible.
- Keep the base OS reproducible and recoverable.
- Treat AMD, Intel and NVIDIA behavior separately when the hardware requires it.
- Be honest about regressions and publish benchmark methodology.

## Contributing

Contributions are welcome: performance traces, game compatibility reports, hardware testing, installer work, documentation, UX, CI and code.

Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- [SECURITY.md](SECURITY.md)
- [ROADMAP.md](ROADMAP.md)
- [GOVERNANCE.md](GOVERNANCE.md)

Performance claims need reproducible evidence. See [Testing and benchmarking](docs/TESTING.md).

## License and third-party software

PulseOS-authored source code and configuration in this repository are licensed under **GPL-3.0-or-later**. See [LICENSE](LICENSE).

PulseOS assembles many independent upstream projects. Linux, Fedora, Steam, Proton, Gamescope, Mesa, GameMode, NVIDIA software and every other packaged component retain their own licenses and trademarks. See [NOTICE.md](NOTICE.md) and [Upstream sources](docs/SOURCES.md).

PulseOS is an independent community project and is not affiliated with or endorsed by Valve, Fedora/Red Hat, NVIDIA, AMD, Intel, Microsoft, or other upstream vendors.
