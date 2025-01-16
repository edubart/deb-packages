#!/bin/bash
set -e

pkgname=cartesi-machine-guest-linux-headers
pkgver=0.20.0
pkgrel=1
_linuxver=6.5.13-ctsi-1
sources=("${pkgname}_${pkgver}.orig.tar.xz::https://github.com/cartesi/image-kernel/releases/download/v$pkgver/linux-headers-$_linuxver-v$pkgver.tar.xz")
sha256sums="4a4714bfa8c0028cb443db2036fad4f8da07065c1cb4ac8e0921a259fddd731b  ${pkgname}_${pkgver}.orig.tar.xz"
pkgdeb=${pkgname}_${pkgver}-${pkgrel}_all.deb
pkgsigner="Cartesi Deb Builder <cartesi-deb-builder@builder>"

# Maybe skip build
if [ "/apt/${REPO_NAME}/${pkgdeb}" -nt "$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2)" ]; then
    echo "${pkgname}: Package is up to date"; exit 0
fi

# Download
for f in ${sources[*]}; do wget -O $(echo $f | sed 's/::/ /'); done
echo "${sha256sums}" | sha256sum --check

# Extract
tar -xf ${pkgname}_${pkgver}.orig.tar.xz
mv include ${pkgname}-${pkgver}
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
dpkg-buildpackage --build=source,all

# Update repository
mv ../*.{deb,orig.tar.xz,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
/work/gen-index.sh
