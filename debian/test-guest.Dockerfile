ARG GUEST_BASE_IMG
FROM --platform=linux/riscv64 ${GUEST_BASE_IMG}

ARG CARTESI_MACHINE_MAJMIN=0.0
ARG APT_URL=https://

ADD --chmod=644 ${APT_URL}/KEY.gpg.bin /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg
ADD --chmod=644 ${APT_URL}/${CARTESI_MACHINE_MAJMIN}-guest/stable/sources.list /etc/apt/sources.list.d/cartesi-guest.list

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    apt-get update && \
    apt-get install -y cartesi-machine-guest-tools cartesi-machine-guest-libcmt cartesi-machine-guest-libcmt-dev

# Test
WORKDIR /work
COPY cartesi-machine-guest-tools/test.sh test.sh
RUN ./test.sh
