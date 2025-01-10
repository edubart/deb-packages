#!/bin/bash
set -e

GUEST_TOOLS_VER=0.16.1
GUEST_TOOLS_SHA256SUM=6ad99e74375a543884235405f6afd424fdb4c9ca35c67c57f8bca1bb0101470b
GUEST_LIBCMT_SHA256SUM=dc56a7fdbcf93d9ff4a9067ef97b7d492c6b0dabb180906f6ce9531129c3d380
GUEST_LIBCMT_DEV_SHA256SUM=ac93f0b8b2c8be85e1b3956f3e0206009fbb8c73f9327948a811b1864a2cee8d

# Download and package sources
wget -O cartesi-machine-guest-tools.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v${GUEST_TOOLS_VER}/machine-emulator-tools-v${GUEST_TOOLS_VER}.deb
wget -O libcmt.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-v0.16.1.deb
wget -O libcmt-dev.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-dev-v0.16.1.deb
echo "${GUEST_TOOLS_SHA256SUM} cartesi-machine-guest-tools.deb" | sha256sum --check
echo "${GUEST_LIBCMT_SHA256SUM} libcmt.deb" | sha256sum --check
echo "${GUEST_LIBCMT_DEV_SHA256SUM} libcmt-dev.deb" | sha256sum --check
dpkg-deb -x cartesi-machine-guest-tools.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
dpkg-deb -x libcmt.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
dpkg-deb -x libcmt-dev.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
rm *.deb
GZIP_OPT=-9 tar --sort=name \
    --mtime="@$(stat -c %Y cartesi-machine-guest-tools.deb)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf cartesi-machine-guest-tools_${GUEST_TOOLS_VER}.orig.tar.gz cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
cd cartesi-machine-guest-tools-${GUEST_TOOLS_VER}

# Copy Debian package files
mv ../cartesi-machine-guest-tools/debian debian

# Create Debian package
dpkg-buildpackage --host-arch riscv64 --build=source,any

# Remove temporary directories
cd .. && rm -r cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
