#!/bin/bash
set -e

pkgname=cartesi-machine-guest-tools
pkgver=0.16.2
_pkgver=37b1e2592b2fac56a6e16b1dd8ad3550c41d8d97
pkgrel=1
sources=("${pkgname}_${pkgver}.orig.tar.gz::https://github.com/cartesi/machine-emulator-tools/archive/$_pkgver.tar.gz")
sha256sums=("227edbfe4af4567d81c90ff97588c14e7d7a9b44c88cc0d23931b00c0b4f6584  ${pkgname}_${pkgver}.orig.tar.gz")
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
mv machine-emulator-tools-${_pkgver} ${pkgname}-${pkgver}
cd ${pkgname}-${pkgver}

# Patch
mv ../debian debian
cat <<EOF > debian/changelog
${pkgname} (${pkgver}-${pkgrel}) RELEASED; urgency=low

  * Please read the project sources for release change logs.

 -- ${pkgsigner}  $(date --reference=../build.sh --rfc-email --utc)
EOF

# Ensure reproducibility
export SOURCE_DATE_EPOCH=$(stat -c %Y ../build.sh) DEB_BUILD_OPTIONS="reproducible=+all"
touch -r ../build.sh **/**

# Package
apt-get build-dep --no-install-recommends -y .
dpkg-buildpackage

# Update repository
mv ../*.{deb,orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
/work/gen-index.sh
