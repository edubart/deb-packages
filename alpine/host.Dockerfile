ARG HOST_BASE_IMG=alpine
FROM ${HOST_BASE_IMG} AS toolchain

# Install build essential
RUN apk update && \
    apk add alpine-sdk doas && \
    echo "permit nopass builder" > /etc/doas.conf

# Setup builder user
RUN adduser -D builder && \
    addgroup builder abuild
USER builder
WORKDIR /work
RUN abuild-keygen -a -i -n

########################################
## Build emulator package
FROM toolchain AS cartesi-machine-emulator
COPY --chown=builder:builder cartesi-machine-emulator /work/cartesi-machine-emulator
RUN cd cartesi-machine-emulator && SOURCE_DATE_EPOCH=$(stat -c %Y APKBUILD) abuild -r -P /work/apk

########################################
## Build linux image package
FROM toolchain AS cartesi-machine-linux-image
COPY --chown=builder:builder cartesi-machine-linux-image /work/cartesi-machine-linux-image
RUN cd cartesi-machine-linux-image && SOURCE_DATE_EPOCH=$(stat -c %Y APKBUILD) abuild -r -P /work/apk

########################################
## Build rootfs image package
FROM toolchain AS cartesi-machine-rootfs-image
COPY --chown=builder:builder cartesi-machine-rootfs-image /work/cartesi-machine-rootfs-image
RUN cd cartesi-machine-rootfs-image && SOURCE_DATE_EPOCH=$(stat -c %Y APKBUILD) abuild -r -P /work/apk

########################################
## Install and test packages
FROM toolchain

WORKDIR /work
COPY --from=cartesi-machine-emulator /work /work
COPY --from=cartesi-machine-linux-image /work /work
COPY --from=cartesi-machine-rootfs-image /work /work

# Test installing all packages
RUN doas -u root apk add $(find -name '*.apk')

# List all files (for debugging)
RUN apk info -L $(apk info | grep cartesi)

# Run tests
RUN find . -name test.sh -exec {} \;
