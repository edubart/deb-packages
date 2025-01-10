FROM ubuntu:24.04 AS toolchain

# Install build essential
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential wget ca-certificates debhelper \
        gcc-12-riscv64-linux-gnu libc6-dev-riscv64-cross

WORKDIR /work

########################################
FROM toolchain AS cartesi-machine-guest-tools
COPY cartesi-machine-guest-tools /work/cartesi-machine-guest-tools
RUN ./cartesi-machine-guest-tools/build.sh

########################################
## Install and test packages
FROM --platform=linux/riscv64 ubuntu:24.04

WORKDIR /work
COPY --from=cartesi-machine-guest-tools /work /work

# Test installing all deb packages
RUN apt-get update && apt-get install -fy $(find . -name '*.deb')

# List all files (for debugging)
RUN find . -name '*.deb' -exec echo {} \; -exec dpkg -c {} \;

# Run tests
RUN find . -name test.sh -exec {} \;
