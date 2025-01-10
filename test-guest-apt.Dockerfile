FROM --platform=linux/riscv64 ubuntu:24.04

# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends wget gpg ca-certificates

ARG CARTESI_MACHINE_MAJMIN=0.0
# Test the same steps shown in the README
RUN <<EOF
set -e

# Install the signing key to verify downloaded packages
wget -qO - https://edubart.github.io/deb-packages/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb https://edubart.github.io/deb-packages ./${CARTESI_MACHINE_MAJMIN}-guest/stable/" | tee /etc/apt/sources.list.d/cartesi-archive-keyring.list

# Update list of available packages
apt-get update

# Install cartesi-machine
apt-get install -y --no-install-recommends cartesi-machine-guest-tools cartesi-machine-guest-libcmt cartesi-machine-guest-libcmt-dev

# Test some tools
rollup-http-server --help > /dev/null 2>&1
rollup --help > /dev/null 2>&1
echo tools OK!
EOF

# Show tools version (for debugging)
RUN apt-cache show cartesi-machine-guest-tools
