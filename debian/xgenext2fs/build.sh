#!/bin/bash
set -e

pkgname=xgenext2fs
pkgver=1.5.6
pkgrel=1
sources=("${pkgname}_${pkgver}.orig.tar.gz::https://github.com/cartesi/genext2fs/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=("34bfc26a037def23b85b676912462a3d126a87ef15c66c212b3500650da44f9e  ${pkgname}_${pkgver}.orig.tar.gz")
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
mv genext2fs-${pkgver} ${pkgname}-${pkgver}
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
