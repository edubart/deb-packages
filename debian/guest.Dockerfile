FROM ubuntu:24.04 AS builder

# Install build essential
RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential wget ca-certificates debhelper && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install riscv64 toolchain
RUN apt-get update && \
    apt-get install --no-install-recommends -y gcc-12-riscv64-linux-gnu libc6-dev-riscv64-cross && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Compress .tar.gz files better
ENV GZIP_OPT=-9

WORKDIR /work

ARG GUEST_TOOLS_VER=0.16.1
ARG GUEST_TOOLS_SHA256SUM=6ad99e74375a543884235405f6afd424fdb4c9ca35c67c57f8bca1bb0101470b

RUN <<EOF
set -e

wget -O cartesi-machine-guest-tools.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v${GUEST_TOOLS_VER}/machine-emulator-tools-v${GUEST_TOOLS_VER}.deb
echo "${GUEST_TOOLS_SHA256SUM} cartesi-machine-guest-tools.deb" | sha256sum --check
wget -O libcmt.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-v0.16.1.deb
wget -O libcmt-dev.deb https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-dev-v0.16.1.deb

dpkg-deb -x cartesi-machine-guest-tools.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
dpkg-deb -x libcmt.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
dpkg-deb -x libcmt-dev.deb cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
rm *.deb
tar --sort=name \
    --mtime="@$(stat -c %Y cartesi-machine-guest-tools.deb)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf cartesi-machine-guest-tools_${GUEST_TOOLS_VER}.orig.tar.gz cartesi-machine-guest-tools-${GUEST_TOOLS_VER}
EOF

WORKDIR /work/cartesi-machine-guest-tools-${GUEST_TOOLS_VER}

# Copy Debian package files
COPY cartesi-machine-guest-tools/debian debian

# Create Debian package
RUN dpkg-buildpackage --host-arch riscv64 --build=source,any && \
    rm -rf /work/cartesi-machine-guest-tools-${GUEST_TOOLS_VER}

########################################
## Install and test packages
FROM --platform=linux/riscv64 ubuntu:24.04

# Always test on an updated system
RUN apt-get update && apt-get upgrade --no-install-recommends -y

WORKDIR /work
COPY --from=builder /work /work

# Test installing all deb packages
RUN apt-get install -fy $(find . -name '*.deb')

# List all files (for debugging)
RUN find . -name '*.deb' -exec echo {} \; -exec dpkg -c {} \;

# Test some tools
RUN <<EOF
set -e
rollup-http-server --help > /dev/null 2>&1
rollup --help > /dev/null 2>&1
echo tools OK!
EOF
