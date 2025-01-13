# The following variables may need to be updated manually during a new release cycle
APK_URL=https://edubart.github.io/linux-packages/apk

# Target architecture to compile packages for (x86_64/aarch64/riscv64)
TARGET_ARCH?=$(shell uname -m)

# List of packages to compile for any architecture
PACKAGES_ANYARCH=\
cartesi-machine-linux-image \
cartesi-machine-rootfs-image \
cartesi-machine-emulator

# List of packages to compile for riscv64
PACKAGES_RISCV64=\
cartesi-machine-guest-linux-headers \
cartesi-machine-guest-tools

# APK docker image used for building packages
BASE_IMAGE=alpine:3.21.2
IMAGE=cartesi/apk-builder-$(TARGET_ARCH)

# APK repository path to save built packages
APK_PATH=$(abspath ../cdn)/apk
APK_REPO_PATH=$(APK_PATH)/stable
KEY_NAME=cartesi-apk-key

# Package list to build
PACKAGES=$(PACKAGES_ANYARCH)
ifeq ($(TARGET_ARCH),riscv64)
PACKAGES+=$(PACKAGES_RISCV64)
endif

all: ## Generate a key (if needed) and build all packages
	@$(MAKE) --no-print-directory image
	@$(MAKE) --no-print-directory abuild-key
	@$(MAKE) --no-print-directory packages-all

packages-all: ## Build packages for all architectures (x86_64/aarch64/riscv64)
	@$(MAKE) --no-print-directory image TARGET_ARCH=x86_64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=x86_64
	@$(MAKE) --no-print-directory image TARGET_ARCH=aarch64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=aarch64
	@$(MAKE) --no-print-directory image TARGET_ARCH=riscv64
	@$(MAKE) --no-print-directory packages TARGET_ARCH=riscv64

packages: $(patsubst %,%.apk,$(PACKAGES)) ## Build packages for given TARGET_ARCH

%.apk: ## Build a package for given TARGET_ARCH
	@$(MAKE) --no-print-directory image-exec \
		COMMAND="cd $* && \
				 export SOURCE_DATE_EPOCH=\\\`stat -c %Y APKBUILD\\\` && \
				 abuild -rF && \
				 chown -R $(shell id -u):$(shell id -g) /root/packages/work"

image-shell: ## Spawn an image shell for given TARGET_ARCH
	@$(MAKE) --no-print-directory image-exec \
		COMMAND="ash" DOCKER_FLAGS="-it"

image-exec: ## Execute a COMMAND inside an image for given TARGET_ARCH
	docker run --platform=linux/$(TARGET_ARCH) \
		--volume $(APK_REPO_PATH):/root/packages/work \
		--volume ./abuild-key:/abuild-key \
		--volume .:/work \
		--workdir /work/$* \
		$(DOCKER_FLAGS) --rm $(IMAGE) \
		ash -c "cp /abuild-key/*.rsa.pub /etc/apk/keys/ && \
				cp -a /abuild-key /root/.abuild && \
				chown -R root:root /root/.abuild && \
				$(COMMAND)"

image: ## Build Docker image for building packages for given TARGET_ARCH
	docker build --platform=linux/$(TARGET_ARCH) \
		--build-arg=BASE_IMAGE=$(BASE_IMAGE) \
		--tag=$(IMAGE) \
		--progress=plain \
		--file Dockerfile .

abuild-key: ## Generate package signature key
	mkdir -p $(APK_PATH)/keys abuild-key
	echo "PACKAGER_PRIVKEY=\"/root/.abuild/$(KEY_NAME).rsa\"" > abuild-key/abuild.conf
	docker run --platform=linux/$(TARGET_ARCH) \
		--volume ./abuild-key:/root/.abuild \
		--volume $(APK_PATH):/apk \
		--rm $(IMAGE) \
		ash -c "abuild-keygen -n && \
				mv /root/.abuild/*.rsa.pub /root/.abuild/$(KEY_NAME).rsa.pub && \
				mv /root/.abuild/*.rsa /root/.abuild/$(KEY_NAME).rsa && \
				cp /root/.abuild/$(KEY_NAME).rsa.pub /apk/keys/$(KEY_NAME).rsa.pub && \
				chown -R $(shell id -u):$(shell id -g) /root/.abuild /apk/keys"

test: ## Test built packages for all architectures (x86_64/aarch64/riscv64)
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=x86_64
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=aarch64
	@$(MAKE) --no-print-directory test-packages TARGET_ARCH=riscv64

ifeq ($(TARGET_ARCH),riscv64)
test-packages:
	@$(MAKE) --no-print-directory image-exec \
		COMMAND="apk add $(PACKAGES) && rollup --help && cartesi-machine"
else
test-packages: ## Test built packages for given TARGET_ARCH
	@$(MAKE) --no-print-directory image-exec \
		COMMAND="apk add $(PACKAGES) && cartesi-machine"
endif

distclean: ## Remove everything from APK repository directory
	rm -rf $(APK_REPO_PATH)

help: ## Show this help
	@sed \
		-e '/^[a-zA-Z0-9_\-]*:.*##/!d' \
		-e 's/:.*##\s*/:/' \
		-e 's/^\(.\+\):\(.*\)/$(shell tput setaf 6)\1$(shell tput sgr0):\2/' \
		$(MAKEFILE_LIST) | column -c2 -t -s :

.PHONY: all packages-all packages image-shell image-exec image test test-packages distclean help
