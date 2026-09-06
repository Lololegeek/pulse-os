ARG FEDORA_VERSION=44
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION}

ARG FEDORA_VERSION=44

# RPM Fusion is required for Steam and selected multimedia/gaming packages.
RUN dnf5 -y install \
      https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
      https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm && \
    dnf5 -y install 'dnf5-command(copr)' && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

# Core graphics, gaming, audio, desktop and diagnostics stack.
RUN dnf5 -y install \
      NetworkManager-wifi NetworkManager-bluetooth \
      bluez bluez-tools \
      gamescope gamemode mangohud vkBasalt \
      steam steam-devices protontricks lutris winetricks \
      mesa-dri-drivers mesa-vulkan-drivers vulkan-loader vulkan-tools \
      mesa-dri-drivers.i686 mesa-vulkan-drivers.i686 vulkan-loader.i686 \
      libva libva-utils mesa-va-drivers mesa-vdpau-drivers \
      pipewire pipewire-alsa pipewire-pulseaudio wireplumber rtkit \
      xorg-x11-server-Xwayland \
      plasma-desktop plasma-workspace kwin sddm \
      plasma-nm plasma-pa powerdevil kscreen tuned tuned-ppd \
      dolphin konsole ark \
      flatpak xdg-desktop-portal xdg-desktop-portal-kde \
      scx-scheds \
      lm_sensors pciutils usbutils nvme-cli smartmontools \
      btop htop jq curl wget git rsync \
      polkit dbus-daemon util-linux \
      zram-generator && \
    dnf5 clean all

# PulseOS configuration and services.
COPY rootfs/ /

# Branding. Keep Fedora identity in ID_LIKE for compatibility.
RUN printf '%s\n' \
      'NAME="PulseOS Gaming"' \
      'PRETTY_NAME="PulseOS Gaming 0.1 (Fedora 44)"' \
      'ID=pulseos' \
      'ID_LIKE="fedora"' \
      'VERSION_ID="0.1"' \
      'VERSION_CODENAME="ignition"' \
      'HOME_URL="https://github.com/Lololegeek/pulse-os"' \
      > /usr/lib/os-release && \
    ln -sf ../usr/lib/os-release /etc/os-release

# Enable the services that are safe to run on all supported machines.
RUN systemctl enable NetworkManager.service bluetooth.service sddm.service tuned.service tuned-ppd.service \
      pulseos-firstboot.service pulseos-idle-update.timer pulseos-scx.service pulseos-performance-agent.service && \
    systemctl set-default graphical.target

# bootc image contract check catches common image construction mistakes.
RUN bootc container lint

LABEL containers.bootc=1 \
      ostree.bootable=1 \
      org.opencontainers.image.title="PulseOS Gaming" \
      org.opencontainers.image.description="Gaming-first Fedora bootc OS with Gamescope, Proton and scx_lavd" \
      org.opencontainers.image.source="https://github.com/Lololegeek/pulse-os" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"
