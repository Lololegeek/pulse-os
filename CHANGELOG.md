# Changelog

All notable PulseOS changes are documented here.

The project follows semantic versioning once interfaces become stable enough for it to be meaningful. Pre-1.0 releases may still make breaking changes.

## [Unreleased]

### Added

- Public open-source project scaffolding and contribution policies.
- GitHub Actions ISO/OCI build and release pipeline.
- Native C++20 `pulse-perfd` performance daemon and `libpulseos` process-policy library.
- Multi-stage native build integrated into the bootc image and CI verification.
- PulseOS x86_64 kernel capability fragment for BPF and `sched_ext`.
- Experimental `pulse-scx` C/BPF scheduler core with a benchmark-first rollout policy.
- Native architecture and kernel/scheduler documentation.

### Changed

- The system performance service now runs `pulse-perfd` instead of the shell implementation.
- Removed the unavailable Fedora 44 `mesa-vdpau-drivers` package from the image definition.

## [0.1.0] - 2026-09-06

### Added

- Fedora 44 bootc operating-system image.
- Gamescope + Steam Gaming Mode and KDE Plasma desktop mode.
- Proton, GameMode, `scx_lavd`, PipeWire, zram and gaming configuration.
- Atomic update helper and reversible gaming performance agent.
- Anaconda/image-builder installer source.
- Separate NVIDIA image build definition.
