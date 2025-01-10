FROM --platform=linux/riscv64 ubuntu:24.04

ARG CARTESI_MACHINE_MAJMIN=0.0
ARG APT_URL=https://

ADD --chmod=644 ${APT_URL}/KEY.gpg.bin /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg
ADD --chmod=644 ${APT_URL}/${CARTESI_MACHINE_MAJMIN}-guest/stable/sources.list /etc/apt/sources.list.d/cartesi-guest.list

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    apt-get update && \
    apt-get install -y cartesi-machine-guest-tools cartesi-machine-guest-libcmt cartesi-machine-guest-libcmt-dev

# Test the same steps shown in the README
RUN <<EOF
# Test some tools
rollup-http-server --help > /dev/null 2>&1
rollup --help > /dev/null 2>&1
echo tools OK!
EOF

# Show tools version (for debugging)
RUN apt-cache show cartesi-machine-guest-tools
