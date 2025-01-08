# Cartesi Debian PPA

Cartesi Machine and other Cartesi related software can be installed on **Debian 12** (Bookworm) or **Ubuntu 24.04** (Noble)
using package repository provided by this PPA.

Here is a quick example on how to use it:

```sh
# Install required tools
apt-get update
apt-get install -y --no-install-recommends wget gpg sudo ca-certificates apt-transport-https

# Install the signing key to verify downloaded packages
wget -qO - https://edubart.github.io/debian-ppa/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb https://edubart.github.io/debian-ppa ./" | sudo tee /etc/apt/sources.list.d/cartesi-archive-keyring.list

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
git clone git@github.com:edubart/debian-ppa.git
cd debian-ppa
```

Then patch the Package build scripts in `Dockerfile` and related subdirectory.
Make sure you have Docker and `dpkg` installed in your system, then you can build all packages with:

```sh
make packages
```

This will build all packages for both amd64/arm64 and make them available in the `ppa` directory.

## Publishing

First make sure to have `ppa` branch cloned by doing:

```sh
git worktree add ppa -b ppa origin/ppa
```

Having a GPG for given email already set in the environment,
you can generate a ppa package index and sign then with:

```sh
make update-ppa PPA_SIGN_EMAIL=my@email.com
```

Finally do a git commit and push from `ppa` directory.

## Testing

You can test if the PPA is working properly with:

```sh
make test-ppa
```
