# Building PulseOS

PulseOS can be built on a Linux host, from Windows through WSL2 + Podman Desktop, or remotely through GitHub Actions.

## Build locally from Windows with Ubuntu WSL2

PulseOS has a dedicated `wsl-iso` target. Ubuntu WSL is used as the development shell while the privileged image build runs in Podman Desktop's rootful WSL2 Podman Machine. This is preferable to running Image Builder directly against the generic Microsoft WSL kernel because disk/image-builder operations can depend on kernel block-device features that are not consistently available there.

### 1. Prepare Windows

Install or update WSL2 and install Podman Desktop. In Windows PowerShell:

```powershell
wsl --update
podman machine list
```

If no Podman machine exists yet, create a rootful machine with enough resources for the OS build:

```powershell
podman machine init --rootful --memory 8192 --disk-size 100 --now
```

If `podman-machine-default` already exists, switch it to rootful mode:

```powershell
podman machine stop podman-machine-default
podman machine set --rootful=true podman-machine-default
podman machine start podman-machine-default
```

### 2. Prepare Ubuntu WSL

Open Ubuntu WSL and install the build-side tools. Use a recent Podman client when possible.

```bash
sudo apt update
sudo apt install -y podman git make tar shellcheck
```

Clone or update PulseOS:

```bash
git clone https://github.com/Lololegeek/pulse-os.git
cd pulse-os
```

### 3. Build the ISO

```bash
make verify
make wsl-iso
```

The WSL helper automatically connects to the rootful Podman Desktop socket at:

```text
/mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock
```

It builds the PulseOS bootc image, builds the installer image, runs Image Builder in the Podman Machine, stores the result in a temporary remote Podman volume, and streams the generated files back into the local WSL `output/` directory.

The repository may live under the WSL Linux filesystem (`~/pulse-os`); it does not have to be placed under `/mnt/c`.

Find the completed installer with:

```bash
find output -type f -name '*.iso' -ls
```

To use a differently named Podman Machine:

```bash
PULSEOS_PODMAN_MACHINE=my-machine make wsl-iso
```

## Build with GitHub Actions

1. Push the PulseOS source to GitHub.
2. Open the repository's **Actions** tab.
3. Select **Build PulseOS**.
4. Choose **Run workflow**.
5. When the job completes, download the `PulseOS-Gaming-ISO-*` artifact.

Pushes to `main` also build automatically. A version tag (`v0.1.0`, for example) additionally creates a GitHub Release.

See [CI.md](CI.md) for channel and artifact details.

## Local native Linux build requirements

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
