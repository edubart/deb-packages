DEBIAN_IMG=cartesi/deb-packages
PLATFORM?=$(shell dpkg --print-architecture)
DOCKER_RUN=docker run --platform=linux/$(PLATFORM) --user $(shell id -u):$(shell id -g) --volume .:/mnt --rm -it $(DEBIAN_IMG) bash -c
LATEST_CARTESI_MACHINE_MAJMIN=0.18

packages: ## Build packages for amd64/arm64 platforms
	$(MAKE) copy-host-packages PLATFORM=amd64
	$(MAKE) copy-host-packages PLATFORM=arm64
	$(MAKE) copy-host-packages-source PLATFORM=amd64

copy-host-packages: host-image apt/host/stable ## Copy packages built from Docker to apt directory for given PLATFORM
	$(DOCKER_RUN) "cp *.{deb,buildinfo,changes} /mnt/apt/host/stable"

copy-host-packages-source: host-image apt/host/stable ## Copy package sources from Docker to apt directory for given PLATFORM
	$(DOCKER_RUN) "cp *.{orig.tar.gz,debian.tar.xz,dsc} /mnt/apt/host/stable"

host-image: ## Build Docker image containing the packages for PLATFORM
	docker build --platform=linux/$(PLATFORM) --tag=$(DEBIAN_IMG) --progress=plain --file host.Dockerfile .

update-apt: ## Update APT package list and sign packages
	$(MAKE) update-apt-repo APT_REPO=host/stable
	$(MAKE) update-apt-repo APT_REPO=cartesi-machine-$(LATEST_CARTESI_MACHINE_MAJMIN)-guest/stable

update-apt-repo: apt/$(APT_REPO) ## Update APT package list and sign packages for given APT_REPO
	cd apt && dpkg-scanpackages --multiversion $(APT_REPO) > $(APT_REPO)/Packages
	gzip -k -f apt/$(APT_REPO)/Packages
	cd apt && apt-ftparchive release $(APT_REPO) > $(APT_REPO)/Release
	gpg --default-key "$(APT_SIGN_EMAIL)" -abs -o - apt/$(APT_REPO)/Release > apt/$(APT_REPO)/Release.gpg
	gpg --default-key "$(APT_SIGN_EMAIL)" --clearsign -o - apt/$(APT_REPO)/Release > apt/$(APT_REPO)/InRelease

add-key: ## Add a new GPG signing public key to APT keyring
	gpg --armor --export "$(APT_SIGN_EMAIL)" >> apt/KEY.gpg

test-host-apt: ## Test if remote host APT is working properly for given PLATFORM
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg IMAGE=debian:bookworm-slim --progress=plain --file test-host-apt.Dockerfile .
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg IMAGE=ubuntu:24.04 --progress=plain --file test-host-apt.Dockerfile .

apt/%:
	mkdir -p $@

distclean: ## Remove everything from APT directories
	rm -rf apt/host
	rm -rf apt/cartesi-machine-*-guest
	rm -f apt/KEY.gpg

help: ## Show this help.
	@sed \
		-e '/^[a-zA-Z0-9_\-]*:.*##/!d' \
		-e 's/:.*##\s*/:/' \
		-e 's/^\(.\+\):\(.*\)/$(shell tput setaf 6)\1$(shell tput sgr0):\2/' \
		$(MAKEFILE_LIST) | column -c2 -t -s :
