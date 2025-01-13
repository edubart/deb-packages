#!/bin/bash
set -e

pkgname=cartesi-machine-emulator
pkgver=0.18.2
_pkgver=${pkgver}-test1
sources=("${pkgname}_${pkgver}.orig.tar.gz::https://github.com/cartesi/machine-emulator/archive/refs/tags/v${_pkgver}.tar.gz"
         "add-generated-files.diff::https://github.com/cartesi/machine-emulator/releases/download/v${_pkgver}/add-generated-files.diff")
sha256sums=("9d5fb1139f0997f665a2130ab4a698080d7299d29d5e69494764510587ca9566  ${pkgname}_${pkgver}.orig.tar.gz"
            "8f513f065e94e6ab969cd27186421e28db0091b3a563cd87280c3bb51671669e  add-generated-files.diff")

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
tar -xf ${pkgname}_${pkgver}.orig.tar.gz
mv machine-emulator-${_pkgver} ${pkgname}-{$pkgver}
cd ${pkgname}-{$pkgver}

# Patch
mv ../debian debian
cp ../add-generated-files.diff debian/patches/
cp COPYING debian/copyright
if grep Ubuntu /etc/issue > /dev/null; then
    sed -i 's/libboost1.81/libboost1.83/' debian/control
fi
patch -Np1 < debian/patches/add-generated-files.diff

# Package
apt-get build-dep --no-install-recommends -y .
dpkg-buildpackage
