ARG BASE_IMAGE=debian
FROM ${BASE_IMAGE} AS toolchain

# Install build essential
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential wget ca-certificates debhelper apt-utils gnupg sudo debmake

WORKDIR /work
