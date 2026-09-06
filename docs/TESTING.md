# Testing and benchmarking PulseOS

Performance claims must be reproducible. PulseOS prioritizes frame pacing and tail latency, not only average FPS.

## Minimum functional test

Before a release candidate:

1. build the bootc image and installer ISO;
2. boot the installer on UEFI hardware/VM;
3. complete an install with a normal user;
4. boot Gaming Mode;
5. switch to Desktop Mode and back;
6. verify networking, audio and controller input;
7. run `pulseosctl doctor`;
8. stage an OS update and reboot into it;
9. verify the previous deployment remains selectable/rollback-capable.

## Gaming benchmark methodology

Keep constant:

- BIOS/UEFI version and settings;
- CPU/RAM clocks;
- GPU firmware/VBIOS;
- game version and save/benchmark scene;
- graphics settings and resolution;
- display refresh/VRR configuration;
- ambient/thermal starting conditions where practical.

Record:

- average FPS;
- 1% low FPS or p99 frametime;
- 0.1% low/p99.9 when the tool is reliable enough;
- frametime plot and stutter count;
- CPU/GPU utilization and clocks;
- CPU/GPU temperatures and power;
- shader-cache state (cold vs warm);
- Proton version for Windows games.

Use at least three comparable runs for normal benchmark claims. Do not silently discard an inconvenient run; explain an outlier and the rule used to exclude it.

## Comparing distributions

A fair SteamOS/Bazzite/CachyOS/Fedora/Windows comparison should use the closest practical kernel/driver/game versions and identical firmware/BIOS/game settings. When exact parity is impossible, document the difference rather than hiding it.

## Latency

Software frametime is not the same as end-to-end input latency. When making click-to-photon claims, use appropriate external measurement hardware or clearly label software-only proxies.
