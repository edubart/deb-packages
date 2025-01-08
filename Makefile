DEBIAN_IMG=cartesi/machine-emulator-debian-package
PLATFORM?=$(shell dpkg --print-architecture)
DOCKER_RUN=docker run --platform=linux/$(PLATFORM) --user $(shell id -u):$(shell id -g) --volume .:/mnt --rm -it $(DEBIAN_IMG) bash -c

packages:
	$(MAKE) copy-packages PLATFORM=amd64
	$(MAKE) copy-packages PLATFORM=arm64
	$(MAKE) copy-packages-source PLATFORM=amd64

ppa:
	mkdir -p ppa

copy-packages: image ppa
	$(DOCKER_RUN) "cp *.{deb,buildinfo,changes} /mnt/ppa/"

copy-packages-source: image ppa
	$(DOCKER_RUN) "cp *.{orig.tar.gz,debian.tar.xz,dsc} /mnt/ppa/"

image:
	docker build --platform=linux/$(PLATFORM) --tag=$(DEBIAN_IMG) --progress=plain .

update-ppa: ppa
	gpg --armor --export "$(PPA_SIGN_EMAIL)" > ppa/KEY.gpg
	cd ppa && dpkg-scanpackages --multiversion . > Packages
	gzip -k -f ppa/Packages
	cd ppa && apt-ftparchive release . > Release
	gpg --default-key "$(PPA_SIGN_EMAIL)" -abs -o - ppa/Release > ppa/Release.gpg
	gpg --default-key "$(PPA_SIGN_EMAIL)" --clearsign -o - ppa/Release > ppa/InRelease

test-ppa:
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg IMAGE=debian:bookworm-slim --progress=plain -f test.Dockerfile .
	docker build --no-cache --platform=linux/$(PLATFORM) --build-arg IMAGE=ubuntu:24.04 --progress=plain -f test.Dockerfile .

clean-packages:
	rm -f ppa/*.{deb,dsc,changes,buildinfo,orig.tar.gz,debian.tar.xz}

distclean: clean-packages
	rm -f ppa/KEY.gpg ppa/Packages ppa/Packages.gz ppa/Release ppa/Release.gpg ppa/InRelease
