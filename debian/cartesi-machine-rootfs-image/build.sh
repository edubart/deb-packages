#!/bin/bash
set -e

pkgname=cartesi-machine-rootfs-image
pkgver=0.17.0
pkgrel=1
_pkgver=${pkgver}-test1
sources=("rootfs.ext2::https://github.com/cartesi/machine-guest-tools/releases/download/v${_pkgver}/rootfs-tools-v${_pkgver}.ext2")
sha256sums="6ca4073504bbc3e42cfda7641bb66aed1e0cd5122146544869b49aa09befe01e rootfs.ext2"
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
mv ../*.{deb,orig.tar.gz,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
/work/gen-index.sh
