SHELL := /usr/bin/bash
PODMAN ?= sudo podman
IMAGE ?= localhost/pulse-os:dev
INSTALLER_IMAGE ?= localhost/pulse-os-installer:dev
UPDATE_REF ?= ghcr.io/lololegeek/pulse-os:edge
OUTPUT ?= $(CURDIR)/output
NATIVE_BUILD ?= $(CURDIR)/build/native

.PHONY: native image nvidia-image installer-image iso wsl-iso qcow2 raw verify clean

native:
	cmake -S src -B $(NATIVE_BUILD) -G Ninja -DCMAKE_BUILD_TYPE=Release
	cmake --build $(NATIVE_BUILD) --parallel

image:
	$(PODMAN) build --pull=newer -t $(IMAGE) -f Containerfile .

nvidia-image: image
	$(PODMAN) build --pull=newer --build-arg BASE_IMAGE=$(IMAGE) -t $(IMAGE)-nvidia -f Containerfile.nvidia .

installer-image: image
	$(PODMAN) build \
	  --build-arg PULSEOS_SOURCE_REF=$(IMAGE) \
	  --build-arg PULSEOS_UPDATE_REF=$(UPDATE_REF) \
	  -t $(INSTALLER_IMAGE) -f installer/Containerfile .

iso: installer-image
	mkdir -p $(OUTPUT)
	./scripts/build-iso.sh $(INSTALLER_IMAGE) $(IMAGE) $(OUTPUT)

wsl-iso:
	IMAGE=$(IMAGE) INSTALLER_IMAGE=$(INSTALLER_IMAGE) UPDATE_REF=$(UPDATE_REF) OUTPUT=$(OUTPUT) bash ./scripts/build-wsl-iso.sh

qcow2: image
	mkdir -p $(OUTPUT)
	./scripts/build-disk.sh $(IMAGE) qcow2 $(OUTPUT)

raw: image
	mkdir -p $(OUTPUT)
	./scripts/build-disk.sh $(IMAGE) raw $(OUTPUT)

verify:
	./scripts/verify.sh

clean:
	rm -rf $(OUTPUT) $(NATIVE_BUILD)
