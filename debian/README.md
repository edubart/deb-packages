# Cartesi Debian packages

This repository contains scripts and `.deb` packages for Cartesi Machine and other Cartesi related software.

All packages binaries are available in the [cdn](https://github.com/edubart/linux-packages/tree/cdn) branch,
while the scripts to generate them are available in the main branch.

## Quick start (host)

Packages provided by this repository can be installed on **Debian 12** (Bookworm) or **Ubuntu 24.04** (Noble) for both *amd64* and *arm64* architectures using an APT package manager.
Here is a quick example on how to use it:

```sh
# Install the GPG key to verify repository packages
wget -qO - https://edubart.github.io/linux-packages/apt/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb https://edubart.github.io/linux-packages/apt ./host/stable/" | sudo tee /etc/apt/sources.list.d/cartesi-host.list

# Update list of available packages
sudo apt-get update

# Install cartesi-machine
sudo apt-get install -y cartesi-machine

# Test cartesi-machine by booting Linux and exiting
cartesi-machine
```

## Quick start (guest)

Packages provided by this repository can be installed on **Ubuntu 24.04** (Noble) for *riscv64* guest architecture using an APT package manager.
Here is a quick example on how to use it using:

```sh
# Install the GPG key to verify repository packages
wget -qO - https://edubart.github.io/linux-packages/apt/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb https://edubart.github.io/linux-packages/apt ./0.18-guest/stable/" | tee /etc/apt/sources.list.d/cartesi-guest.list

# Update list of available packages
apt-get update

# Install cartesi-machine-guest-tools
apt-get install -y cartesi-machine-guest-tools
```

### Guest using Dockerfile

In case you are building a guest rootfs with a Dockerfile, it could be installed with the need of using `wget` or `gpg`, this way:

```Dockerfile
FROM --platform=linux/riscv64 ubuntu:24.04

# Add guest apt repository
ADD --chmod=644 https://edubart.github.io/linux-packages/apt/KEY.gpg.bin /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg
ADD --chmod=644 https://edubart.github.io/linux-packages/apt/0.18-guest/stable/sources.list /etc/apt/sources.list.d/cartesi-guest.list

# Install guest tools
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    apt-get update && \
    apt-get install -y cartesi-machine-guest-tools
```

## Building

If you would like to contribute to a package addition or update, clone first:

```sh
git clone git@github.com:edubart/linux-packages.git
cd linux-packages
```

Then patch the Package build scripts in `Dockerfile` and related subdirectory.
Make sure you have Docker and `dpkg` installed in your system, then you can build all packages with:

```sh
make packages
```

This will build all packages for both amd64/arm64 and make them available in the `../cdn/apt` directory.

## Testing

You can test if the APT is working properly for both host and guest with:

```sh
make test
```

## Publishing

This is only relevant for maintainers of this repository,
in case you need to update listing of APT packages.

First make sure to have `cdn` branch cloned in top level directory by doing:

```sh
git worktree add cdn -b cdn origin/cdn
```

Having a GPG for given email already set in the environment,
every developer must at least once add it to the keyring, with:

```sh
make add-key APT_SIGN_EMAIL=my@email.com
```

Then you can regenerate an apt package index and sign then with:

```sh
make update APT_SIGN_EMAIL=my@email.com
```

Finally do a git commit and push from `cdn` directory.
