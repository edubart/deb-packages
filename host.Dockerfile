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
FROM toolchain AS cartesi-machine-guest-linux

ARG GUEST_LINUX_VER=0.20.0
ARG GUEST_LINUX_TAG=${GUEST_LINUX_VER}
ARG GUEST_LINUX_NAME=linux-6.5.13-ctsi-1-v${GUEST_LINUX_TAG}
ARG GUEST_LINUX_BIN_SHA256SUM=65dd100ff6204346ac2f50f772721358b5c1451450ceb39a154542ee27b4c947

# Download and package sources
RUN mkdir cartesi-machine-guest-linux-${GUEST_LINUX_VER} && \
    wget -O cartesi-machine-guest-linux-${GUEST_LINUX_VER}/linux.bin https://github.com/cartesi/image-kernel/releases/download/v${GUEST_LINUX_TAG}/${GUEST_LINUX_NAME}.bin && \
    echo "${GUEST_LINUX_BIN_SHA256SUM} cartesi-machine-guest-linux-${GUEST_LINUX_VER}/linux.bin" | sha256sum --check && \
    tar --sort=name \
        --mtime="@$(stat -c %Y cartesi-machine-guest-linux-${GUEST_LINUX_VER}/linux.bin)" \
        --owner=0 --group=0 --numeric-owner \
        --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -czf cartesi-machine-guest-linux_${GUEST_LINUX_VER}.orig.tar.gz cartesi-machine-guest-linux-${GUEST_LINUX_VER}

WORKDIR /work/cartesi-machine-guest-linux-${GUEST_LINUX_VER}

# Copy Debian package files
COPY cartesi-machine-guest-linux/debian debian

# Create Debian package
RUN dpkg-buildpackage --build=source,all && \
    rm -rf /work/cartesi-machine-guest-linux-${GUEST_LINUX_VER}

########################################
## Build guest rootfs package
FROM toolchain AS cartesi-machine-guest-rootfs

ARG GUEST_ROOTFS_VER=0.16.2
ARG GUEST_ROOTFS_TAG=${GUEST_ROOTFS_VER}-test2
ARG GUEST_ROOTFS_NAME=rootfs-tools-v${GUEST_ROOTFS_TAG}
ARG GUEST_ROOTFS_BIN_SHA256SUM=7d73e6298f9b7bafec1cfcb4923f1d9c80b33816cc9ecd00faac8c6d1e949679

# Download and package sources
RUN mkdir cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER} && \
    wget -O cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}/rootfs.ext2 https://github.com/cartesi/machine-emulator-tools/releases/download/v${GUEST_ROOTFS_TAG}/${GUEST_ROOTFS_NAME}.ext2 && \
    echo "${GUEST_ROOTFS_BIN_SHA256SUM} cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}/rootfs.ext2" | sha256sum --check && \
    tar --sort=name \
        --mtime="@$(stat -c %Y cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}/rootfs.ext2)" \
        --owner=0 --group=0 --numeric-owner \
        --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -czf cartesi-machine-guest-rootfs_${GUEST_ROOTFS_VER}.orig.tar.gz cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}

WORKDIR /work/cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}

# Copy Debian package files
COPY cartesi-machine-guest-rootfs/debian debian

# Create Debian package
RUN dpkg-buildpackage --build=source,all && \
    rm -rf /work/cartesi-machine-guest-rootfs-${GUEST_ROOTFS_VER}

########################################
## Install and test packages
FROM debian:bookworm-20241223-slim

# Always test on an updated system
RUN apt-get update && apt-get upgrade --no-install-recommends -y

WORKDIR /work
COPY --from=cartesi-machine-emulator /work /work
COPY --from=cartesi-machine-guest-linux /work /work
COPY --from=cartesi-machine-guest-rootfs /work /work

# Test installing all deb packages
RUN apt-get install -fy $(find . -name '*.deb')

# List all files (for debugging)
RUN find . -name '*.deb' -exec echo {} \; -exec dpkg -c {} \;

# Test booting a cartesi machine
RUN cartesi-machine && cartesi-machine --version
