#!/bin/bash
set -e

pkgname=cartesi-machine-guest-tools
pkgver=0.16.1
_pkgver=${pkgver}
pkgrel=1
sources=("cartesi-machine-guest-tools.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v${_pkgver}/machine-emulator-tools-v${_pkgver}.deb"
         "libcmt.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v${_pkgver}/libcmt-v${_pkgver}.deb"
         "libcmt-dev.deb::https://github.com/cartesi/machine-emulator-tools/releases/download/v${_pkgver}/libcmt-dev-v${_pkgver}.deb")
sha256sums=("6ad99e74375a543884235405f6afd424fdb4c9ca35c67c57f8bca1bb0101470b  cartesi-machine-guest-tools.deb"
            "dc56a7fdbcf93d9ff4a9067ef97b7d492c6b0dabb180906f6ce9531129c3d380  libcmt.deb"
            "ac93f0b8b2c8be85e1b3956f3e0206009fbb8c73f9327948a811b1864a2cee8d  libcmt-dev.deb")
pkgdeb=${pkgname}_${pkgver}-${pkgrel}_$(dpkg --print-architecture).deb
pkgsigner="Cartesi Deb Builder <cartesi-deb-builder@builder>"

# Maybe skip build
if [ "$(find . -type f -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1)" -lt "$(stat -c %Y /apt/${REPO_NAME}/${pkgdeb})" ]; then
    echo "${pkgname}: Package is up to date"; exit 0
fi

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
cat <<EOF > debian/changelog
${pkgname} (${pkgver}-${pkgrel}) RELEASED; urgency=low

  * Please read the project sources for release change logs.

 -- ${pkgsigner}  $(date -R -u)
EOF

# Ensure reproducibility
export SOURCE_DATE_EPOCH=$(stat -c %Y ../build.sh) DEB_BUILD_OPTIONS="reproducible=+all"
touch -r ../build.sh **/**

# Package
dpkg-buildpackage --unsigned-source --unsigned-changes --build=source,any

# Update repository
mv ../*.{deb,orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
/work/gen-index.sh
