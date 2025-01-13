# Cartesi Alpine packages

This repository contains scripts and `.apk` packages for Cartesi Machine and other Cartesi related software.

All packages binaries are available in the [cdn](https://github.com/edubart/linux-packages/tree/cdn) branch in the `apk` directory,
while the scripts to generate them are available in the main branch.


## Quick start

Packages provided by this repository can be installed on **Alpine 3.21** for *amd64/arm64/riscv64 architectures using an APK package manager.
Here is a quick example on how to use it:

```sh
# Install key to verify signature of repository packages
wget -qO /etc/apk/keys/cartesi-apk-key.rsa.pub https://edubart.github.io/linux-packages/apk/keys/cartesi-apk-key.rsa.pub

# Add repository
echo "https://edubart.github.io/linux-packages/apk/stable" >> /etc/apk/repositories

# Update list of available packages
apk update

# Install cartesi-machine
apk add cartesi-machine

# Test cartesi-machine
cartesi-machine
```

## Guest using Dockerfile

In case you are building a riscv64 guest rootfs with a Dockerfile, it could be installed more simpler, this way:

```Dockerfile
FROM --platform=linux/riscv64 alpine:latest

# Install guest tools
ADD --chmod=644 https://edubart.github.io/linux-packages/apk/keys/cartesi-apk-key.rsa.pub /etc/apk/keys/cartesi-apk-key.rsa.pub
RUN echo "https://edubart.github.io/linux-packages/apk/stable" >> /etc/apk/repositories
RUN apk update && apk add cartesi-machine-guest-tools

# Remove unneeded packages to shrink image
RUN apk del --purge apk-tools alpine-release alpine-keys ca-certificates-bundle libc-utils && rm -rf /var/cache/apk /etc/apk
```

## Developing

If you would like to contribute to a package addition or update, clone first:

```sh
git clone git@github.com:edubart/linux-packages.git
cd linux-packages/alpine
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
