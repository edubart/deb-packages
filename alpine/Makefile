# The following variables may need to be updated manually during a new release cycle
HOST_BASE_IMG=alpine:3.21.2
GUEST_BASE_IMG=alpine:3.21.2
LATEST_CARTESI_MACHINE_MAJMIN=0.18
APK_URL=https://edubart.github.io/linux-packages/apk

# List of all packages to compile inside a guest
HOST_PACKAGES=\
cartesi-machine-emulator \
cartesi-machine-linux-image \
cartesi-machine-rootfs-image

# List of all packages to compile inside a guest
GUEST_PACKAGES=\
cartesi-machine-guest-linux-headers \
cartesi-machine-guest-tools \
$(HOST_PACKAGES)

HOST_IMG=cartesi/$(HOST_PLATFORM)-apk-packages
GUEST_IMG=cartesi/riscv64-apk-packages
HOST_APK_REPO=host/stable/$(HOST_PLATFORM)
GUEST_APK_REPO=$(LATEST_CARTESI_MACHINE_MAJMIN)-guest/stable
HOST_PLATFORM?=$(shell uname -m)
GUEST_PLATFORM=riscv64
CDN_PATH=$(abspath ../cdn)
APK_PATH=$(CDN_PATH)/apk

GUEST_PACKAGES_TARGETS=$(patsubst %,%.apk-guest,$(GUEST_PACKAGES))
HOST_PACKAGES_TARGETS=$(patsubst %,%.apk-host,$(HOST_PACKAGES))

all: ## Build docker images, then generate a key and finally build all packages
	@$(MAKE) --no-print-directory host-image
	@$(MAKE) --no-print-directory guest-image
	@$(MAKE) --no-print-directory abuild-key
	@$(MAKE) --no-print-directory packages

packages: host-packages-all guest-packages ## Build host (amd64/arm64) and guest (riscv64) packages
host-packages-all: ## Build host packages for amd64/arm64 platforms
	@$(MAKE) --no-print-directory host-packages HOST_PLATFORM=x86_64
	@$(MAKE) --no-print-directory host-packages HOST_PLATFORM=aarch64
host-packages: host-image $(HOST_PACKAGES_TARGETS) ## Build host packages for given HOST_PLATFORM
guest-packages: guest-image $(GUEST_PACKAGES_TARGETS) ## Build guest packages for riscv64

%.apk-host: $(APK_PATH)/$(HOST_APK_REPO) ## Build a host package
	@$(MAKE) --no-print-directory host-exec \
		COMMAND="cd $* && \
				 export SOURCE_DATE_EPOCH=\\\`stat -c %Y APKBUILD\\\` && \
				 abuild -rF && \
				 chown -R $(shell id -u):$(shell id -g) /root/packages/work"

%.apk-guest: $(APK_PATH)/$(GUEST_APK_REPO) ## Build a guest package
	@$(MAKE) --no-print-directory guest-exec \
		COMMAND="cd $* && \
				 export SOURCE_DATE_EPOCH=\\\`stat -c %Y APKBUILD\\\` && \
				 abuild -rF && \
				 chown -R $(shell id -u):$(shell id -g) /root/packages/work"

host-shell: ## Spawn a host image shell
	@$(MAKE) --no-print-directory host-exec \
		COMMAND="ash" DOCKER_FLAGS="-it"

guest-shell: ## Spawn a guest image shell
	@$(MAKE) --no-print-directory guest-exec \
		COMMAND="ash" DOCKER_FLAGS="-it"

host-exec: ## Execute a COMMAND in a host image for given HOST_PLATFORM
	docker run --platform=linux/$(HOST_PLATFORM) \
		--volume $(APK_PATH)/$(HOST_APK_REPO):/root/packages/work \
		--volume ./abuild-key:/abuild-key \
		--volume .:/work \
		--workdir /work/$* \
		$(DOCKER_FLAGS) \
		--rm $(HOST_IMG) \
		ash -c "cp /abuild-key/*.rsa.pub /etc/apk/keys/ && \
				cp -a /abuild-key /root/.abuild && \
				chown -R root:root /root/.abuild && \
				$(COMMAND)"

guest-exec: ## Execute a COMMAND in guest image (riscv64)
	docker run --platform=linux/$(GUEST_PLATFORM) \
		--volume $(APK_PATH)/$(GUEST_APK_REPO):/root/packages/work \
		--volume ./abuild-key:/abuild-key \
		--volume .:/work \
		--workdir /work \
		--rm $(GUEST_IMG) $(DOCKER_FLAGS) \
		ash -c "cp /abuild-key/*.rsa.pub /etc/apk/keys/ && \
				cp -a /abuild-key /root/.abuild && \
				chown -R root:root /root/.abuild && \
				$(COMMAND)"

host-image: ## Build Docker image for building host packages for given HOST_PLATFORM
	docker build --platform=linux/$(HOST_PLATFORM) \
		--build-arg HOST_BASE_IMG=$(HOST_BASE_IMG) \
		--tag=$(HOST_IMG) \
		--progress=plain \
		--file host.Dockerfile .

guest-image: ## Build Docker image for building guest packages for riscv64
	docker build --platform=linux/$(GUEST_PLATFORM) \
		--build-arg GUEST_BASE_IMG=$(GUEST_BASE_IMG) \
		--tag=$(GUEST_IMG) \
		--progress=plain \
		--file guest.Dockerfile .

abuild-key: ## Generate package signature key
	docker run --platform=linux/$(GUEST_PLATFORM) \
		--volume ./abuild-key:/root/.abuild \
		--rm $(GUEST_IMG) \
		ash -c "abuild-keygen -a -n && chown -R $(shell id -u):$(shell id -g) /root/.abuild"

test-host: ## Test host packages
	@$(MAKE) --no-print-directory host-exec \
		COMMAND="apk add $(HOST_PACKAGES) &&
				cartesi-machine"

test-guest: ## Test guest packages
	@$(MAKE) --no-print-directory guest-exec \
		COMMAND="apk add $(GUEST_PACKAGES) && \
				rollup --help && \
				rollup-http-server --help \
				cartesi-machine"

$(APK_PATH)/%:
	mkdir -p $@

distclean: ## Remove everything from APK directories
	rm -rf $(APK_PATH)/host
	rm -rf $(APK_PATH)/*-guest

help: ## Show this help
	@sed \
		-e '/^[a-zA-Z0-9_\-]*:.*##/!d' \
		-e 's/:.*##\s*/:/' \
		-e 's/^\(.\+\):\(.*\)/$(shell tput setaf 6)\1$(shell tput sgr0):\2/' \
		$(MAKEFILE_LIST) | column -c2 -t -s :
