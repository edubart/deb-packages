ARG HOST_BASE_IMG
FROM ${HOST_BASE_IMG}

ARG APT_URL=https://

# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends wget gpg sudo ca-certificates

# Test the same steps shown in the README
RUN <<EOF
set -e

# Install the signing key to verify downloaded packages
wget -qO - ${APT_URL}/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg

# Create file with repository information
echo "deb ${APT_URL} ./host/stable/" | sudo tee /etc/apt/sources.list.d/cartesi-host.list

# Update list of available packages
sudo apt-get update

# Install cartesi-machine
sudo apt-get install -y cartesi-machine cartesi-machine-emulator-dev cartesi-machine-emulator-dbgsym

# Test cartesi-machine by booting Linux and exiting
cartesi-machine
EOF
