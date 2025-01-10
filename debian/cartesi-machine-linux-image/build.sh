#!/bin/bash
set -e

LINUX_IMAGE_VER=0.20.0
LINUX_IMAGE_TAG=${LINUX_IMAGE_VER}
LINUX_IMAGE_NAME=linux-6.5.13-ctsi-1-v${LINUX_IMAGE_TAG}
LINUX_IMAGE_BIN_SHA256SUM=65dd100ff6204346ac2f50f772721358b5c1451450ceb39a154542ee27b4c947

# Download and package sources
mkdir cartesi-machine-linux-image-${LINUX_IMAGE_VER}
wget -O cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin https://github.com/cartesi/image-kernel/releases/download/v${LINUX_IMAGE_TAG}/${LINUX_IMAGE_NAME}.bin
echo "${LINUX_IMAGE_BIN_SHA256SUM} cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin" | sha256sum --check
GZIP_OPT=-9 tar --sort=name \
    --mtime="@$(stat -c %Y cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf cartesi-machine-linux-image_${LINUX_IMAGE_VER}.orig.tar.gz cartesi-machine-linux-image-${LINUX_IMAGE_VER}
cd cartesi-machine-linux-image-${LINUX_IMAGE_VER}

# Copy Debian package files
mv ../cartesi-machine-linux-image/debian debian

# Create Debian package
dpkg-buildpackage --build=source,all

# Remove temporary directories
cd .. && rm -r cartesi-machine-linux-image-${LINUX_IMAGE_VER}
