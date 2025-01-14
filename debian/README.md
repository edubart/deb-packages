# Cartesi Debian packages

This repository contains scripts and `.deb` packages for Cartesi Machine and other Cartesi related software.

All packages binaries are available in the [cdn](https://github.com/edubart/linux-packages/tree/cdn) branch in the `deb` directory,
while the scripts to generate them are available in the main branch.

## Quick start

Packages provided by this repository can be installed on **Debian 12** (Bookworm) or **Ubuntu 24.04** (Noble) for *amd64*/*arm64*/*riscv64*` architectures using an APT package manager.
Here is a quick example on how to use it:

```sh
# Install key to verify signature of repository packages
wget -qO - https://edubart.github.io/linux-packages/apt/keys/cartesi-deb-key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-deb-key.gpg

# Add repository
echo "deb https://edubart.github.io/linux-packages/apt ./stable/" | sudo tee /etc/apt/sources.list.d/cartesi-deb-apt.list

# Update list of available packages
sudo apt-get update

# Install cartesi-machine
sudo apt-get install -y cartesi-machine

# Test cartesi-machine
cartesi-machine
```

### Guest using Dockerfile

In case you are building a riscv64 guest rootfs with a Dockerfile, it could be installed more simpler, this way:

```Dockerfile
FROM --platform=linux/riscv64 ubuntu:24.04

# Install guest tools
RUN apt-get update && apt-get install -y ca-certificates
ADD --chmod=644 https://edubart.github.io/linux-packages/apt/keys/cartesi-deb-key.gpg.bin /etc/apt/trusted.gpg.d/cartesi-deb-key.gpg
ADD --chmod=644 https://edubart.github.io/linux-packages/apt/stable/sources.list /etc/apt/sources.list.d/cartesi-deb-apt.list
RUN apt-get update && apt-get install -y cartesi-machine-guest-tools
```

## Developing

If you would like to contribute to a package addition or update, clone first:

```sh
git clone git@github.com:edubart/linux-packages.git
cd linux-packages/debian
```

You can check for all possible developing make targets with `make help`.
Make sure you have Docker is installed in your system to run any of them.

### Building packages

You can build all packages with:

```sh
make all
```

In the first time this will generate the Docker image, a new key for signing packages, and build all packages

This may take a while (hours) when building packages from scratch.
When finished the packages will be available in the `../cdn/apk` directory.

### Building a single package

First make sure you have signature key set up and the builder image for the architecture you want to build:

```sh
make key
make image TARGET_ARCH=riscv64
```

Now add or patch the related package build script,
you can then build it for a specific architecture with:

```sh
make cartesi-machine-emulator.apk TARGET_ARCH=riscv64
```

In this case it will build the `cartesi-machine-emulator` package for `riscv64`.

### Testing

You can test installing all built packages with:

```sh
make test
```

This will install all packages for all architectures, and run some very basic tests to check if it's working.

### Debugging

Sometimes to develop a new package build script, it's useful to have a shell to test things:

```sh
make shell TARGET_ARCH=riscv64
```
