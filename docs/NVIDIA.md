# NVIDIA image

NVIDIA is kept separate from the AMD/Intel image because immutable systems must
ship a kernel module that matches the image's exact kernel.

`Containerfile.nvidia` performs a multi-stage build:

1. reads the kernel version from Fedora bootc;
2. installs the matching kernel-devel tree in a disposable builder;
3. builds the RPM Fusion NVIDIA kmod with akmods;
4. copies only the built kmod RPM into the final PulseOS image;
5. installs NVIDIA user-space Vulkan/OpenGL libraries, including 32-bit libs;
6. injects persistent bootc kernel arguments for NVIDIA DRM modesetting and
   nouveau blacklisting.

For Turing/RTX and newer hardware:

```bash
make image
sudo podman build \
  --build-arg BASE_IMAGE=localhost/pulse-os:dev \
  --build-arg NVIDIA_OPEN=1 \
  -t localhost/pulse-os-nvidia:dev \
  -f Containerfile.nvidia .
```

For hardware that still requires the closed kernel module, set
`NVIDIA_OPEN=0`.

## Secure Boot

The source tree does not embed a private module-signing key. Therefore a local
NVIDIA image built with RPM Fusion kmods should **not** be advertised as Secure
Boot-ready until your release pipeline signs those exact modules with a key that
the target machine trusts.

A production distribution should:

- keep the private signing key outside the repository;
- sign kmods in CI/HSM-backed infrastructure;
- provide a controlled MOK/key-enrollment flow;
- verify module signatures before image promotion;
- rebuild and re-sign whenever either the kernel or NVIDIA driver changes.

Disabling Secure Boot is a development workaround, not the desired final design.
