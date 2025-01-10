#!/bin/bash
set -e

EMULATOR_VER=0.18.2
EMULATOR_TAG=${EMULATOR_VER}-test1
EMUALTOR_TARGZ_SHA256SUM=9d5fb1139f0997f665a2130ab4a698080d7299d29d5e69494764510587ca9566
EMUALTOR_PATCH_SHA256SUM=8f513f065e94e6ab969cd27186421e28db0091b3a563cd87280c3bb51671669e

# Download and extract
wget -O cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz https://github.com/cartesi/machine-emulator/archive/refs/tags/v${EMULATOR_TAG}.tar.gz
echo "${EMUALTOR_TARGZ_SHA256SUM} cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz" | sha256sum --check
tar -xf cartesi-machine-emulator_${EMULATOR_VER}.orig.tar.gz
mv machine-emulator-${EMULATOR_TAG} cartesi-machine-emulator-${EMULATOR_VER}
cd cartesi-machine-emulator-${EMULATOR_VER}

# Copy Debian package files
mv ../cartesi-machine-emulator/debian debian
cp COPYING debian/copyright

# Patch sources
wget -O debian/patches/add-generated-files.diff https://github.com/cartesi/machine-emulator/releases/download/v${EMULATOR_TAG}/add-generated-files.diff
echo "${EMUALTOR_PATCH_SHA256SUM} debian/patches/add-generated-files.diff" | sha256sum --check
patch -Np1 < debian/patches/add-generated-files.diff

# Install build dependencies
apt-get update
apt-get build-dep --no-install-recommends -y .

# Create Debian package
dpkg-buildpackage

# Remove temporary directories
cd .. && rm -r cartesi-machine-emulator-${EMULATOR_VER}
