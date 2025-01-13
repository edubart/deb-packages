ARG GUEST_BASE_IMG=alpine
FROM ${GUEST_BASE_IMG} AS toolchain

# Install build essential
RUN apk update && \
    apk add alpine-sdk xz cargo clang-libclang

# List local apk repository
RUN echo /root/packages/work >> /etc/apk/repositories && \
    adduser -D builder

WORKDIR /work
