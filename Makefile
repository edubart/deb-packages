LATEST_CARTESI_MACHINE_MAJMIN=0.18
HOST_IMG=cartesi/host-deb-packages
GUEST_IMG=cartesi/guest-deb-packages
HOST_APT_REPO=host/stable
GUEST_APT_REPO=$(LATEST_CARTESI_MACHINE_MAJMIN)-guest/stable
PLATFORM?=$(shell dpkg --print-architecture)
APT_URL=https://edubart.github.io/deb-packages

packages: host-packages guest-packages ## Build host (amd64/arm64) and guest (riscv64) packages

host-packages: ## Build host packages for amd64/arm64 platforms
	$(MAKE) copy-host-packages-source PLATFORM=amd64
	$(MAKE) copy-host-packages PLATFORM=amd64
	$(MAKE) copy-host-packages PLATFORM=arm64

guest-packages: copy-guest-packages ## Build guest packages for riscv64

copy-host-packages: host-image apt/$(HOST_APT_REPO) ## Copy host packages built from Docker to apt directory for given PLATFORM
	$(MAKE) copy-image-files DOCKER_PLATFORM=$(PLATFORM) DOCKER_IMG=$(HOST_IMG) APT_REPO=$(HOST_APT_REPO) \
		COPY_EXT="deb"

copy-host-packages-source: host-image apt/$(HOST_APT_REPO) ## Copy host package sources from Docker to apt directory for given PLATFORM
	$(MAKE) copy-image-files DOCKER_PLATFORM=$(PLATFORM) DOCKER_IMG=$(HOST_IMG) APT_REPO=$(HOST_APT_REPO) \
		COPY_EXT="{orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes}"

copy-guest-packages: guest-image apt/$(GUEST_APT_REPO) ## Copy guest packages built from Docker to apt directory
	$(MAKE) copy-image-files DOCKER_PLATFORM=$(PLATFORM) DOCKER_IMG=$(GUEST_IMG) APT_REPO=$(GUEST_APT_REPO) \
		COPY_EXT="{deb,orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes}"

copy-image-files:
	docker run --user $(shell id -u):$(shell id -g) --volume .:/mnt --rm -it --platform=linux/$(DOCKER_PLATFORM) $(DOCKER_IMG) bash -c \
		"cp *.$(COPY_EXT) /mnt/apt/$(APT_REPO)"

host-image: ## Build Docker image containing the packages for host with given PLATFORM
	docker build --platform=linux/$(PLATFORM) --tag=$(HOST_IMG) --progress=plain --file host.Dockerfile .

guest-image: ## Build Docker image containing the packages for riscv64 guest
	docker build --platform=linux/$(PLATFORM) --tag=$(GUEST_IMG) --progress=plain --file guest.Dockerfile .

update-apt: ## Update APT package list and sign packages
	$(MAKE) update-apt-repo APT_REPO=$(HOST_APT_REPO)
	$(MAKE) update-apt-repo APT_REPO=$(GUEST_APT_REPO)

update-apt-repo: apt/$(APT_REPO) ## Update APT package list and sign packages for given APT_REPO
	cd apt && dpkg-scanpackages --multiversion $(APT_REPO) > $(APT_REPO)/Packages
	gzip -k -f apt/$(APT_REPO)/Packages
	cd apt && apt-ftparchive release $(APT_REPO) > $(APT_REPO)/Release
	gpg --default-key "$(APT_SIGN_EMAIL)" -abs -o - apt/$(APT_REPO)/Release > apt/$(APT_REPO)/Release.gpg
	gpg --default-key "$(APT_SIGN_EMAIL)" --clearsign -o - apt/$(APT_REPO)/Release > apt/$(APT_REPO)/InRelease
	echo "deb $(APT_URL) ./$(APT_REPO)/" > apt/$(APT_REPO)/sources.list

add-key: ## Add a new GPG signing public key to APT keyring
	gpg --armor --export "$(APT_SIGN_EMAIL)" >> apt/KEY.gpg
	cat apt/KEY.gpg | gpg --dearmor -o apt/KEY.gpg.bin

test-apt: test-host-apt	test-guest-apt

test-host-apt: ## Test if remote host APT is working properly for given PLATFORM
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg APT_URL=$(APT_URL) --build-arg IMAGE=debian:bookworm-slim --progress=plain --file test-host-apt.Dockerfile .
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg APT_URL=$(APT_URL) --build-arg IMAGE=ubuntu:24.04 --progress=plain --file test-host-apt.Dockerfile .

test-guest-apt: ## Test if remote guest APT is working properly
	docker build --no-cache --platform=linux/riscv64 --build-arg APT_URL=$(APT_URL) --build-arg CARTESI_MACHINE_MAJMIN=$(LATEST_CARTESI_MACHINE_MAJMIN) --progress=plain --file test-guest-apt.Dockerfile .

apt/%:
	mkdir -p $@

distclean: ## Remove everything from APT directories
	rm -rf apt/host
	rm -rf apt/*-guest

help: ## Show this help
	@sed \
		-e '/^[a-zA-Z0-9_\-]*:.*##/!d' \
		-e 's/:.*##\s*/:/' \
		-e 's/^\(.\+\):\(.*\)/$(shell tput setaf 6)\1$(shell tput sgr0):\2/' \
		$(MAKEFILE_LIST) | column -c2 -t -s :
