# PulseOS Roadmap

This roadmap describes direction, not guaranteed dates.

## 0.1 — Foundation

- [x] Fedora bootc/OCI base image
- [x] Gamescope + Steam Gaming Mode
- [x] KDE Plasma desktop mode
- [x] Steam/Proton, Lutris and Winetricks stack
- [x] GameMode integration
- [x] `sched_ext` / `scx_lavd`
- [x] reversible TuneD gaming profile
- [x] PipeWire low-latency defaults
- [x] atomic update/rollback model
- [x] Anaconda-based installer image source
- [x] base GitHub Actions build pipeline
- [ ] prove installer ISO boots in CI on every supported release
- [ ] public hardware test matrix

## 0.2 — Hardware confidence

- [ ] AMD RDNA2/RDNA3/RDNA4 desktop validation
- [ ] Intel Arc Xe/Alchemist/Battlemage validation
- [ ] NVIDIA Turing/Ampere/Ada/Blackwell validation
- [ ] AMD X3D single/dual-CCD scheduling tests
- [ ] Intel P-core/E-core scheduling tests
- [ ] laptop hybrid-GPU handling
- [ ] common Xbox/PlayStation/Nintendo controller matrix
- [ ] VRR, HDR and multi-monitor test matrix
- [ ] Wi-Fi/Bluetooth controller latency tests

## 0.3 — Release engineering

- [ ] fully automated signed stable/edge OCI channels
- [ ] public GHCR update stream and documented rollback policy
- [ ] ISO SBOM/provenance artifacts
- [ ] NVIDIA module signing / Secure Boot enrollment design
- [ ] recovery media workflow
- [ ] update failure telemetry that is opt-in and privacy-preserving, if the community wants it

## 0.4 — Gaming UX

- [ ] PulseOS settings UI for refresh rate, VRR, HDR and performance mode
- [ ] per-game performance profile UI
- [ ] controller-first Wi-Fi/Bluetooth onboarding
- [ ] clean first-boot wizard
- [ ] game-mode diagnostics overlay
- [ ] one-click logs bundle with secrets redaction

## 1.0 criteria

PulseOS should not call itself 1.0 until it has:

- repeatable install/upgrade/rollback testing;
- a documented supported hardware baseline;
- stable AMD/Intel and practical NVIDIA installation paths;
- Secure Boot guidance appropriate for distributed images;
- benchmark results against major gaming Linux alternatives using a published methodology;
- no known critical data-loss or update-chain issues;
- a clear security response process.
