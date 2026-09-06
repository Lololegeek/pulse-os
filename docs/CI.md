# CI/CD

PulseOS uses GitHub Actions so the complete OS can be built without requiring every contributor to run Linux locally.

## Verify workflow

`.github/workflows/verify.yml` runs on pushes and pull requests. It performs:

- Bash syntax validation;
- Python bytecode compilation;
- ShellCheck;
- required-file validation;
- the PulseOS unsafe-tuning scan;
- a fixed-credential scan.

## Build PulseOS workflow

`.github/workflows/build-image.yml` runs on:

- pushes to `main`;
- version tags matching `v*`;
- manual `workflow_dispatch` runs.

It builds the base bootc image with rootful Podman, builds the Anaconda installer environment, generates an installer ISO with osbuild Image Builder, calculates SHA-256, and uploads the ISO/checksum as workflow artifacts.

### OCI channels

A successful `main` build publishes:

```text
ghcr.io/lololegeek/pulse-os:<full-git-sha>
ghcr.io/lololegeek/pulse-os:edge
```

A successful version-tag build additionally publishes:

```text
ghcr.io/lololegeek/pulse-os:<version>
ghcr.io/lololegeek/pulse-os:stable
```

Release images are signed keylessly with Cosign using GitHub Actions OIDC.

## GitHub Releases

A `vX.Y.Z` tag causes the build workflow to create/update the corresponding GitHub Release and attach:

- the installer ISO;
- the SHA-256 checksum file.

## Package visibility

GHCR container packages may require a one-time visibility configuration in GitHub Packages. Before telling users to install from an ISO that tracks `edge` or `stable`, verify that an unauthenticated client can pull the corresponding image.

## Why the ISO job uses privileged containers

osbuild/Image Builder must create filesystems, loop devices and bootable image structures. The CI therefore executes Image Builder in its documented privileged-container pattern and shares the rootful Podman container store so the locally-built bootc payload can be embedded in the ISO.
