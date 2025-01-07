DEBIAN_IMG=cartesi/machine-emulator-debian-package
PLATFORM?=$(shell dpkg --print-architecture)
DOCKER_RUN=docker run --platform=linux/$(PLATFORM) --user $(shell id -u):$(shell id -g) --volume .:/mnt --rm -it $(DEBIAN_IMG) bash -c

all:
	$(MAKE) copy-package PLATFORM=amd64
	$(MAKE) copy-package PLATFORM=arm64
	$(MAKE) copy-package-source PLATFORM=amd64

copy-package: image
	$(DOCKER_RUN) "cp *.{deb,buildinfo,changes} /mnt/"

copy-package-source: image
	$(DOCKER_RUN) "cp *.{orig.tar.gz,debian.tar.xz,dsc} /mnt/"

image:
	docker build --platform=linux/$(PLATFORM) --tag=$(DEBIAN_IMG) --progress=plain .

clean:
	rm -f cartesi-machine*_*
