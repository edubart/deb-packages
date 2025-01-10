# The following variables may need to be updated manually during a new release cycle
HOST_BASE_IMG=alpine:3.21.2
GUEST_BASE_IMG=alpine:3.21.2
LATEST_CARTESI_MACHINE_MAJMIN=0.18
APK_URL=https://edubart.github.io/linux-packages/apk

HOST_IMG=cartesi/host-apk-packages
GUEST_IMG=cartesi/guest-apk-packages
HOST_APK_REPO=host/stable/$(PLATFORM)
GUEST_APK_REPO=$(LATEST_CARTESI_MACHINE_MAJMIN)-guest/stable
PLATFORM?=$(shell uname -m)
CDN_PATH=$(abspath ../cdn)
KEY_PATH=$(abspath ../key)
APK_PATH=$(CDN_PATH)/apk

packages: host-packages guest-packages ## Build host (amd64/arm64) and guest (riscv64) packages

host-packages: ## Build host packages for amd64/arm64 platforms
	$(MAKE) copy-host-packages PLATFORM=x86_64
	$(MAKE) copy-host-packages PLATFORM=aarch64

guest-packages: copy-guest-packages ## Build guest packages for riscv64

copy-host-packages: host-image $(APK_PATH)/$(HOST_APK_REPO) ## Copy host packages built from Docker to apk directory for given PLATFORM
	$(MAKE) copy-image-files DOCKER_PLATFORM=$(PLATFORM) DOCKER_IMG=$(HOST_IMG) APK_REPO=$(HOST_APK_REPO) COPY_EXT="apk"

copy-guest-packages: guest-image $(APK_PATH)/$(GUEST_APK_REPO) ## Copy guest packages built from Docker to apk directory
	$(MAKE) copy-image-files DOCKER_PLATFORM=$(PLATFORM) DOCKER_IMG=$(GUEST_IMG) APK_REPO=$(GUEST_APK_REPO) COPY_EXT="apk"

copy-image-files:
	docker run --platform=linux/$(DOCKER_PLATFORM) \
		--user $(shell id -u):$(shell id -g) \
		--volume .:/mnt \
		--volume $(APK_PATH):/apk \
		--rm -it $(DOCKER_IMG) ash -c \
		"cp /work/apk/work/$$(uname -m)/* /apk/$(APK_REPO)"

host-image: ## Build Docker image containing the packages for host with given PLATFORM
	docker build --platform=linux/$(PLATFORM) --build-arg HOST_BASE_IMG=$(HOST_BASE_IMG) --tag=$(HOST_IMG) --progress=plain --file host.Dockerfile .

guest-image: ## Build Docker image containing the packages for riscv64 guest
	docker build --platform=linux/$(PLATFORM) --build-arg GUEST_BASE_IMG=$(GUEST_BASE_IMG) --tag=$(GUEST_IMG) --progress=plain --file guest.Dockerfile .

test: test-host	test-guest

test-host: ## Test if remote host APK is working properly for given PLATFORM
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg APK_URL=$(APK_URL) --build-arg HOST_BASE_IMG=$(HOST_BASE_IMG) --progress=plain --file test-host.Dockerfile .
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg APK_URL=$(APK_URL) --build-arg HOST_BASE_IMG=$(HOST_BASE_IMG) --progress=plain --file test-host.Dockerfile .

test-guest: ## Test if remote guest APK is working properly
	docker build --no-cache --platform=linux/riscv64 --build-arg APK_URL=$(APK_URL) --build-arg GUEST_BASE_IMG=$(GUEST_BASE_IMG) --build-arg CARTESI_MACHINE_MAJMIN=$(LATEST_CARTESI_MACHINE_MAJMIN) --progress=plain --file test-guest.Dockerfile .

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
