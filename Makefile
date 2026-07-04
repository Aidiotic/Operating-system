# NexusOS build and install helpers

VERSION := $(shell cat VERSION)
SUDO    := $(shell if [ "$$(id -u)" = 0 ]; then echo; else echo sudo; fi)

.PHONY: help install validate sync-version build-debs publish-repo build-x86_64 build-aarch64 build-iso build-utm build-kernel clean

help:
	@echo "NexusOS $(VERSION) — available targets:"
	@echo "  make install        Run platform installer"
	@echo "  make validate       Sync versions, lint, healthcheck"
	@echo "  make sync-version   Update os-release + installer JSON from VERSION"
	@echo "  make build-debs     Build NexusOS .deb packages"
	@echo "  make publish-repo   Publish APT repo to docs/repo/"
	@echo "  make build-kernel   Build/fetch Asahi kernel .deb"
	@echo "  make build-x86_64   Build x86_64 rootfs (requires root)"
	@echo "  make build-aarch64  Build aarch64 rootfs (requires root)"
	@echo "  make build-iso      Build dual-boot ISO (requires root)"
	@echo "  make build-utm      Build Mac UTM bundle"
	@echo "  make clean          Remove build artifacts (keeps submodules)"

install:
	./install.sh

sync-version:
	./scripts/sync-version.sh

validate: sync-version
	./scripts/healthcheck.sh

build-debs:
	./build/packages/build-debs.sh

publish-repo: build-debs
	./build/repo/publish-repo.sh

build-kernel:
	./build/kernel/build-asahi-kernel.sh

build-x86_64:
	$(SUDO) env NEXUSOS_CI_MINIMAL=0 ./build/rootfs/build-x86_64.sh

build-aarch64:
	$(SUDO) env NEXUSOS_CI_MINIMAL=0 ASAHI_KERNEL_USE_PREBUILT=1 ./build/rootfs/build-aarch64.sh

build-iso:
	$(SUDO) ./build/iso/build-iso.sh

build-utm:
	./build/utm/build-utm.sh

clean:
	rm -rf releases/ build/rootfs/work/ build/iso/work/ build/utm/work/ \
		build/kernel/work/ build/packages/stage/ installer/releases/ installer/stage/
