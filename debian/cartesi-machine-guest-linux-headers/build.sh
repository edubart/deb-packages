#!/bin/bash
set -e

pkgname=cartesi-machine-guest-linux-headers
pkgver=0.20.0
_pkgver=${pkgver}
_linuxver=6.5.13-ctsi-1
sources=("${pkgname}_${pkgver}.orig.tar.xz::https://github.com/cartesi/image-kernel/releases/download/v$pkgver/linux-headers-$_linuxver-v$pkgver.tar.xz")
sha256sums="4a4714bfa8c0028cb443db2036fad4f8da07065c1cb4ac8e0921a259fddd731b  ${pkgname}_${pkgver}.orig.tar.xz"

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
tar -xf ${pkgname}_${pkgver}.orig.tar.xz
mv include ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian

# Package
dpkg-buildpackage --build=source,all
