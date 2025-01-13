#!/bin/bash
set -e

pkgname=cartesi-machine-rootfs-image
pkgver=0.16.2
_pkgver=${pkgver}-test2
sources=("rootfs.ext2::https://github.com/cartesi/machine-emulator-tools/releases/download/v${_pkgver}/rootfs-tools-v${_pkgver}.ext2")
sha256sums="7d73e6298f9b7bafec1cfcb4923f1d9c80b33816cc9ecd00faac8c6d1e949679 rootfs.ext2"

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
mkdir ${pkgname}-${pkgver}
mv rootfs.ext2 ${pkgname}-${pkgver}/
tar --sort=name \
    --mtime="@$(stat -c %Y ${pkgname}-${pkgver}/rootfs.ext2)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf ${pkgname}_${pkgver}.orig.tar.gz ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian

# Package
dpkg-buildpackage --build=source,all
