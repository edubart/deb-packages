#!/bin/bash
set -e

pkgname=cartesi-machine-guest-tools
pkgver=0.16.1
_pkgver=${pkgver}
sources=("cartesi-machine-guest-tools.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v${pkgver}/machine-emulator-tools-v${pkgver}.deb"
         "libcmt.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-v0.16.1.deb"
         "libcmt-dev.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v0.16.1/libcmt-dev-v0.16.1.deb")
sha256sums=("6ad99e74375a543884235405f6afd424fdb4c9ca35c67c57f8bca1bb0101470b  cartesi-machine-guest-tools.deb"
            "dc56a7fdbcf93d9ff4a9067ef97b7d492c6b0dabb180906f6ce9531129c3d380  libcmt.deb"
            "ac93f0b8b2c8be85e1b3956f3e0206009fbb8c73f9327948a811b1864a2cee8d  libcmt-dev.deb")

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
dpkg-deb -x ${pkgname}.deb ${pkgname}-${pkgver}
dpkg-deb -x libcmt.deb ${pkgname}-${pkgver}
dpkg-deb -x libcmt-dev.deb ${pkgname}-${pkgver}
rm *.deb
tar --sort=name \
    --mtime="@$(stat -c %Y ${pkgname}.deb)" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -czf ${pkgname}_${pkgver}.orig.tar.gz ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian

# Package
dpkg-buildpackage --build=source,any
