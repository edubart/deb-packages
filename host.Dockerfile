FROM debian:bookworm-20241223-slim AS toolchain

# Install build essential
RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential wget ca-certificates debhelper && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /work

# Compress .tar.gz files better
ENV GZIP_OPT=-9

########################################
## Build emulator package
FROM toolchain AS cartesi-machine-emulator

ARG EMULATOR_VER=0.18.2
ARG EMULATOR_TAG=${EMULATOR_VER}-test1
ARG EMUALTOR_TARGZ_SHA256SUM=9d5fb1139f0997f665a2130ab4a698080d7299d29d5e69494764510587ca9566
ARG EMUALTOR_PATCH_SHA256SUM=8f513f065e94e6ab969cd27186421e28db0091b3a563cd87280c3bb51671669e

# Download and extract
RUN wget -O cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz https://github.com/cartesi/machine-emulator/archive/refs/tags/v${EMULATOR_TAG}.tar.gz && \
    echo "${EMUALTOR_TARGZ_SHA256SUM} cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz" | sha256sum --check && \
    tar -xf cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz && \
    mv machine-emulator-${EMULATOR_TAG} cartesi-machine-emulator-${EMULATOR_VER}

WORKDIR /work/cartesi-machine-emulator-${EMULATOR_VER}

# Copy Debian package files
COPY cartesi-machine-emulator/debian debian

# Copy copyright file
RUN cp COPYING debian/copyright

# Patch sources
RUN wget -O debian/patches/add-generated-files.diff https://github.com/cartesi/machine-emulator/releases/download/v${EMULATOR_TAG}/add-generated-files.diff && \
    echo "${EMUALTOR_PATCH_SHA256SUM} debian/patches/add-generated-files.diff" | sha256sum --check && \
    patch -Np1 < debian/patches/add-generated-files.diff

# Install build dependencies
RUN apt-get update && \
    apt-get build-dep --no-install-recommends -y . && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Create Debian package
RUN dpkg-buildpackage && \
    rm -rf /work/cartesi-machine-emulator-${EMULATOR_VER}

########################################
## Build guest Linux package
FROM toolchain AS cartesi-machine-linux-image

ARG LINUX_IMAGE_VER=0.20.0
ARG LINUX_IMAGE_TAG=${LINUX_IMAGE_VER}
ARG LINUX_IMAGE_NAME=linux-6.5.13-ctsi-1-v${LINUX_IMAGE_TAG}
ARG LINUX_IMAGE_BIN_SHA256SUM=65dd100ff6204346ac2f50f772721358b5c1451450ceb39a154542ee27b4c947

# Download and package sources
RUN mkdir cartesi-machine-linux-image-${LINUX_IMAGE_VER} && \
    wget -O cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin https://github.com/cartesi/image-kernel/releases/download/v${LINUX_IMAGE_TAG}/${LINUX_IMAGE_NAME}.bin && \
    echo "${LINUX_IMAGE_BIN_SHA256SUM} cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin" | sha256sum --check && \
    tar --sort=name \
        --mtime="@$(stat -c %Y cartesi-machine-linux-image-${LINUX_IMAGE_VER}/linux.bin)" \
        --owner=0 --group=0 --numeric-owner \
        --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -czf cartesi-machine-linux-image_${LINUX_IMAGE_VER}.orig.tar.gz cartesi-machine-linux-image-${LINUX_IMAGE_VER}

WORKDIR /work/cartesi-machine-linux-image-${LINUX_IMAGE_VER}

# Copy Debian package files
COPY cartesi-machine-linux-image/debian debian

# Create Debian package
RUN dpkg-buildpackage --build=source,all && \
    rm -rf /work/cartesi-machine-linux-image-${LINUX_IMAGE_VER}

########################################
## Build rootfs image package
FROM toolchain AS cartesi-machine-rootfs-image

ARG ROOTFS_IMAGE_VER=0.16.2
ARG ROOTFS_IMAGE_TAG=${ROOTFS_IMAGE_VER}-test2
ARG ROOTFS_IMAGE_NAME=rootfs-tools-v${ROOTFS_IMAGE_TAG}
ARG ROOTFS_IMAGE_BIN_SHA256SUM=7d73e6298f9b7bafec1cfcb4923f1d9c80b33816cc9ecd00faac8c6d1e949679

# Download and package sources
RUN mkdir cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER} && \
    wget -O cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2 https://github.com/cartesi/machine-emulator-tools/releases/download/v${ROOTFS_IMAGE_TAG}/${ROOTFS_IMAGE_NAME}.ext2 && \
    echo "${ROOTFS_IMAGE_BIN_SHA256SUM} cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2" | sha256sum --check && \
    tar --sort=name \
        --mtime="@$(stat -c %Y cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}/rootfs.ext2)" \
        --owner=0 --group=0 --numeric-owner \
        --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -czf cartesi-machine-rootfs-image_${ROOTFS_IMAGE_VER}.orig.tar.gz cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}

WORKDIR /work/cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}

# Copy Debian package files
COPY cartesi-machine-rootfs-image/debian debian

# Create Debian package
RUN dpkg-buildpackage --build=source,all && \
    rm -rf /work/cartesi-machine-rootfs-image-${ROOTFS_IMAGE_VER}

########################################
## Install and test packages
FROM debian:bookworm-20241223-slim

WORKDIR /work
COPY --from=cartesi-machine-emulator /work /work
COPY --from=cartesi-machine-linux-image /work /work
COPY --from=cartesi-machine-rootfs-image /work /work

# Test installing all deb packages
RUN apt-get update && apt-get install -fy $(find . -name '*.deb')

# List all files (for debugging)
RUN find . -name '*.deb' -exec echo {} \; -exec dpkg -c {} \;

# Test booting a cartesi machine
RUN cartesi-machine && cartesi-machine --version
