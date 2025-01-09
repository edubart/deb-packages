# Cartesi deb packages

This repository contains scripts and `.deb` packages for Cartesi Machine and other Cartesi related software to be installed on **Debian 12** (Bookworm) or **Ubuntu 24.04** (Noble)
using an APT package manager.

All packages binaries are available in the [apt](/tree/apt) branch,
while the scripts to generate them are available in the main branch.

Here is a quick example on how to use it:

```sh
# Install required tools
apt-get update
apt-get install -y --no-install-recommends wget gpg sudo ca-certificates apt-transport-https

# Install the signing key to verify downloaded packages
wget -qO - https://edubart.github.io/deb-packages/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb https://edubart.github.io/deb-packages host/stable/" | sudo tee /etc/apt/sources.list.d/cartesi-archive-keyring.list

# Update list of available packages
sudo apt-get update

# Install cartesi-machine
sudo apt-get install -y --no-install-recommends cartesi-machine

# Test cartesi-machine by booting Linux and exiting
cartesi-machine
```

## Building

If you would like to contribute to a package addition or update, clone first:

```sh
git clone git@github.com:edubart/deb-packages.git
cd deb-packages
```

Then patch the Package build scripts in `Dockerfile` and related subdirectory.
Make sure you have Docker and `dpkg` installed in your system, then you can build all packages with:

```sh
make packages
```

This will build all packages for both amd64/arm64 and make them available in the `apt` directory.

## Publishing

First make sure to have `apt` branch cloned by doing:

```sh
git worktree add apt -b apt origin/apt
```

Having a GPG for given email already set in the environment,
every developer must at least once add it to the keyring, with:

```sh
make add-key APT_SIGN_EMAIL=my@email.com
```

Then you can regenerate an apt package index and sign then with:

```sh
make update-apt APT_SIGN_EMAIL=my@email.com
```

Finally do a git commit and push from `apt` directory.

## Testing

You can test if the APT is working properly with:

```sh
make test-host-apt PLATFORM=amd64
```
