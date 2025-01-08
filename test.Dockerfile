ARG IMAGE=debian:bookworm-slim
FROM ${IMAGE}

# Always test on an updated system
RUN apt-get update && apt-get upgrade --no-install-recommends -y

# Test the same steps shown in the README
RUN <<EOF
set -e

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

# Test cartesi-machine
cartesi-machine
EOF

# Show cartesi-machine version (for debugging)
RUN cartesi-machine --version
