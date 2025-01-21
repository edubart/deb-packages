# List of packages that doesn't depend on the architecture it's built on
PACKAGES_ALLARCH=\
cartesi-machine-linux-image \
cartesi-machine-rootfs-image

# List of packages to targeting any architecture
PACKAGES_ANYARCH=\
cartesi-machine-emulator \
xgenext2fs

# List of packages to compile for riscv64
PACKAGES_RISCV64=\
cartesi-machine-guest-linux-headers \
cartesi-machine-guest-tools

# Target architecture to compile packages
TARGET_ARCH=$(shell dpkg --print-architecture)

# Docker base images used for building packages
BASE_IMAGE_amd64=debian:bookworm-slim
BASE_IMAGE_arm64=debian:bookworm-slim
BASE_IMAGE_riscv64=ubuntu:noble
BASE_IMAGE=$(BASE_IMAGE_$(TARGET_ARCH))
IMAGE=cartesi/deb-builder-$(TARGET_ARCH)

# Repository path to save built packages
REPO_PATH=$(abspath ../cdn)/apt
REPO_NAME=stable
REPO_URL=https://edubart.github.io/linux-packages/apt
KEY_NAME=cartesi-deb-key

# Package list to build
ifeq ($(TARGET_ARCH),$(shell dpkg --print-architecture))
PACKAGES+=$(PACKAGES_ALLARCH)
endif
PACKAGES+=$(PACKAGES_ANYARCH)
ifeq ($(TARGET_ARCH),riscv64)
PACKAGES+=$(PACKAGES_RISCV64)
endif

all: ## Generate a key (if needed) and build all packages
	@$(MAKE) --no-print-directory image
	@$(MAKE) --no-print-directory key
	@$(MAKE) --no-print-directory packages-all

packages-all: ## Build packages for all architectures (amd64/arm64/riscv64)
	@$(MAKE) --no-print-directory image TARGET_ARCH=amd64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=amd64
	@$(MAKE) --no-print-directory image TARGET_ARCH=arm64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=arm64
	@$(MAKE) --no-print-directory image TARGET_ARCH=riscv64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=riscv64

packages: $(patsubst %,%.deb,$(PACKAGES)) ## Build packages for given TARGET_ARCH

%.deb: ## Build a package for given TARGET_ARCH
	@mkdir -p $(REPO_PATH)/$(REPO_NAME)
	@$(MAKE) --no-print-directory exec COMMAND="\
	mkdir -p /builder/$* && \
 	cd /builder/$* && \
	cp -a /work/$*/* . && \
	REPO_NAME=$(REPO_NAME) REPO_URL=$(REPO_URL) /work/build-deb.sh && \
	chown -R $(shell id -u):$(shell id -g) /apt/$(REPO_NAME)"

key: ## Generate package signature key
	echo "NOTICE: Generating new key!"
	@mkdir -p $(REPO_PATH)/keys key
	@$(MAKE) --no-print-directory exec COMMAND="\
	gpg --batch --gen-key </work/gen-key-batch.txt && \
    gpg --armor --export > /apt/keys/$(KEY_NAME).gpg && \
    gpg --export > /apt/keys/$(KEY_NAME).gpg.bin && \
	chown -R $(shell id -u):$(shell id -g) /root/.gnupg /apt/keys"
	@$(MAKE) --no-print-directory index

index: ## Generate package index
	@mkdir -p $(REPO_PATH)/$(REPO_NAME)
	@$(MAKE) --no-print-directory exec COMMAND="\
	REPO_NAME=$(REPO_NAME) REPO_URL=$(REPO_URL) /work/gen-index.sh && \
	chown -R $(shell id -u):$(shell id -g) /apt/$(REPO_NAME)"

shell: ## Spawn an image shell for given TARGET_ARCH
	@$(MAKE) --no-print-directory DOCKER_FLAGS="-it" exec COMMAND="bash"

exec: ## Execute a COMMAND inside an image for given TARGET_ARCH
	docker run --platform=linux/$(TARGET_ARCH) \
		--volume $(REPO_PATH):/apt \
		--volume ./key:/root/.gnupg \
		--volume .:/work \
		--workdir /work \
		$(DOCKER_FLAGS) --rm $(IMAGE) \
		bash -c "\
	([ -f /apt/$(REPO_NAME)/Packages ] && \
		echo 'deb file:///apt stable/' > /etc/apt/sources.list.d/cartesi-deb-apt.list && \
		gpg --dearmor -o /etc/apt/trusted.gpg.d/$(KEY_NAME).gpg < /apt/keys/$(KEY_NAME).gpg && \
		apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/cartesi-deb-apt.list -o Dir::Etc::sourceparts=- -o APT::Get::List-Cleanup=0 || true) && \
	$(COMMAND)"

image: ## Build Docker image for building packages for given TARGET_ARCH
	docker build --platform=linux/$(TARGET_ARCH) \
		--build-arg=BASE_IMAGE=$(BASE_IMAGE) \
		--tag=$(IMAGE) \
		--progress=plain \
		--file Dockerfile .

test: ## Test built packages for all architectures (amd64/arm64/riscv64)
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=amd64
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=arm64
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=riscv64

ifeq ($(TARGET_ARCH),riscv64)
test-packages:
	@$(MAKE) --no-print-directory exec COMMAND="\
	apt-get install --no-install-recommends -y $(PACKAGES_ANYARCH) $(PACKAGES_ALLARCH) $(PACKAGES_RISCV64) && \
	rollup --help && \
	cartesi-machine"
else
test-packages: ## Test built packages for given TARGET_ARCH
	@$(MAKE) --no-print-directory exec COMMAND="\
	apt-get install --no-install-recommends -y $(PACKAGES_ANYARCH) $(PACKAGES_ALLARCH) && \
	cartesi-machine"
endif

distclean: ## Remove everything from APT repository directory
	rm -rf $(REPO_PATH)/$(REPO_NAME)

help: ## Show this help
	@sed \
		-e '/^[a-zA-Z0-9_\-]*:.*##/!d' \
		-e 's/:.*##\s*/:/' \
		-e 's/^\(.\+\):\(.*\)/$(shell tput setaf 6)\1$(shell tput sgr0):\2/' \
		$(MAKEFILE_LIST) | column -c2 -t -s :

.PHONY: all packages-all packages shell index exec image test test-packages distclean help
