#!/bin/bash
set -e

ROOTFS_IMAGE_VER=0.16.2
ROOTFS_IMAGE_TAG=${ROOTFS_IMAGE_VER}-test2
ROOTFS_IMAGE_NAME=rootfs-tools-v${ROOTFS_IMAGE_TAG}
ROOTFS_IMAGE_BIN_SHA256SUM=7d73e6298f9b7bafec1cfcb4923f1d9c80b33816cc9ecd00faac8c6d1e949679

# Download and package sources
mkdir cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}
wget -O cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2 https://github.com/cartesi/machine-emulator-tools/releases/download/v${ROOTFS_IMAGE_TAG}/${ROOTFS_IMAGE_NAME}.ext2
echo "${ROOTFS_IMAGE_BIN_SHA256SUM} cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2" | sha256sum --check
GZIP_OPT=-9 tar --sort=name \
    --mtime="@$(stat -c %Y cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf cartesi-machine-rootfs-image_${ROOTFS_IMAGE_VER}.orig.tar.gz cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}
cd cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}

# Copy Debian package files
mv ../cartesi-machine-rootfs-image/debian debian

# Create Debian package
dpkg-buildpackage --build=source,all

# Remove temporary directories
cd .. && rm -r cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}
