#!/bin/bash
set -e

pkgname=cartesi-machine-linux-image
pkgver=0.20.0
_pkgver=${pkgver}
_linuxver=6.5.13-ctsi-1
sources=("linux.bin::https://github.com/cartesi/image-kernel/releases/download/v${_pkgver}/linux-$_linuxver-v$pkgver.bin")
sha256sums="65dd100ff6204346ac2f50f772721358b5c1451450ceb39a154542ee27b4c947 linux.bin"

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
mkdir ${pkgname}-${pkgver}
mv linux.bin ${pkgname}-${pkgver}/
tar --sort=name \
    --mtime="@$(stat -c %Y ${pkgname}-${pkgver}/linux.bin)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf ${pkgname}_${pkgver}.orig.tar.gz ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian

# Package
dpkg-buildpackage --build=source,all
