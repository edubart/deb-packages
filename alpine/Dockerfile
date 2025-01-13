ARG BASE_IMAGE=alpine
FROM ${BASE_IMAGE}

# Install build essential
RUN apk update && \
    apk add alpine-sdk

# List local apk repository
RUN echo /root/packages/work >> /etc/apk/repositories && \
    adduser -D builder

WORKDIR /work
