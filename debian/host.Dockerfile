FROM debian:bookworm-20241223-slim AS toolchain

# Install build essential
RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential wget ca-certificates debhelper

WORKDIR /work

########################################
## Build emulator package
FROM toolchain AS cartesi-machine-emulator
COPY cartesi-machine-emulator /work/cartesi-machine-emulator
RUN ./cartesi-machine-emulator/build.sh

########################################
## Build guest Linux package
FROM toolchain AS cartesi-machine-linux-image
COPY cartesi-machine-linux-image /work/cartesi-machine-linux-image
RUN ./cartesi-machine-linux-image/build.sh

########################################
## Build rootfs image package
FROM toolchain AS cartesi-machine-rootfs-image
COPY cartesi-machine-rootfs-image /work/cartesi-machine-rootfs-image
RUN ./cartesi-machine-rootfs-image/build.sh

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

# Run tests
RUN find . -name test.sh -exec {} \;
