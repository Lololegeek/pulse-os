# Building PulseOS

PulseOS can be built either on a Linux host or entirely through GitHub Actions. **Windows users do not need a local VM when using the GitHub build workflow.**

## Build with GitHub Actions (recommended from Windows)

1. Push the PulseOS source to GitHub.
2. Open the repository's **Actions** tab.
3. Select **Build PulseOS**.
4. Choose **Run workflow**.
5. When the job completes, download the `PulseOS-Gaming-ISO-*` artifact.

Pushes to `main` also build automatically. A version tag (`v0.1.0`, for example) additionally creates a GitHub Release.

See [CI.md](CI.md) for channel and artifact details.

## Local Linux build requirements

Recommended host: Fedora 44 x86_64.

```bash
sudo dnf install podman make git shellcheck
```

The scripts use the current `ghcr.io/osbuild/image-builder-cli` container, so a host installation of Image Builder is not required.

## 1. Verify the source tree

```bash
make verify
```

## 2. Build the OS image

```bash
make image
```

The default image is `localhost/pulse-os:dev` in **rootful** Podman storage. Rootful storage is intentional because Image Builder needs privileged access to the same container store while embedding the payload in an installer ISO.

## 3. Choose the update image reference

The installer embeds the local image as installation payload, but an installed bootc OS needs a reachable OCI image reference for future upgrades.

The repository defaults development builds to:

```text
ghcr.io/lololegeek/pulse-os:edge
```

For a stable release use:

```text
ghcr.io/lololegeek/pulse-os:stable
```

Override locally when needed:

```bash
make iso UPDATE_REF=ghcr.io/example/pulse-os:test
```

The chosen package must be publicly pullable (or the installed system must have registry credentials) for unattended `bootc` upgrades to work.

## 4. Build the graphical installer ISO

```bash
make iso
```

The installer uses Anaconda. Disk selection, encryption, locale and the first human user are chosen interactively rather than hard-coded into the image.

## 5. Test a disk image in QEMU

```bash
make qcow2
./scripts/smoke-qemu.sh output/<generated-image>.qcow2
```

A virtual GPU does not represent gaming performance. QEMU is useful for boot, login, update and session-switch smoke tests only.

## NVIDIA variant

After the base image succeeds:

```bash
make nvidia-image
```

This compiles the RPM Fusion NVIDIA kernel module against the exact kernel present in the Fedora bootc image. Read [NVIDIA.md](NVIDIA.md), especially the Secure Boot section, before distributing that image.
