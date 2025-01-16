#!/bin/bash
set -e

pkgname=cartesi-machine-emulator
pkgver=0.19.0
pkgrel=1
_pkgver=${pkgver}-test1
sources=("${pkgname}_${pkgver}.orig.tar.gz::https://github.com/cartesi/machine-emulator/archive/refs/tags/v${_pkgver}.tar.gz"
         "add-generated-files.diff::https://github.com/cartesi/machine-emulator/releases/download/v${_pkgver}/add-generated-files.diff")
sha256sums=("93121d1c7edf5ebc8d5b8b042d3b18a4cf2454c702ec2cfe8c92086d7529e16d  ${pkgname}_${pkgver}.orig.tar.gz"
            "162d62ec8b66801f1ad421774050ea1d6c5cc4c7dcc8f5615956853d6baed87f  add-generated-files.diff")
pkgdeb=${pkgname}_${pkgver}-${pkgrel}_$(dpkg --print-architecture).deb
pkgsigner="Cartesi Deb Builder <cartesi-deb-builder@builder>"

# Maybe skip build
if [ "/apt/${REPO_NAME}/${pkgdeb}" -nt "$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2)" ]; then
    echo "${pkgname}: Package is up to date"; exit 0
fi

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
tar -xf ${pkgname}_${pkgver}.orig.tar.gz
mv machine-emulator-${_pkgver} ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian
cat <<EOF > debian/changelog
${pkgname} (${pkgver}-${pkgrel}) RELEASED; urgency=low

  * Please read the project sources for release change logs.

 -- ${pkgsigner}  $(date --reference=../build.sh --rfc-email --utc)
EOF
mv ../add-generated-files.diff debian/patches/
patch -Np1 < debian/patches/add-generated-files.diff

# Ensure reproducibility
export SOURCE_DATE_EPOCH=$(stat -c %Y ../build.sh) DEB_BUILD_OPTIONS="reproducible=+all"
touch -r ../build.sh **/**

# Package
apt-get build-dep --no-install-recommends -y .
dpkg-buildpackage

# Update repository
mv ../*.{deb,orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
/work/gen-index.sh
