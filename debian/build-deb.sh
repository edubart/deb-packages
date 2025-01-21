#!/bin/bash
set -e

# Defaults
pkgsigner="Cartesi Deb Builder <cartesi-deb-builder@builder>"
arch=any

# Read package variables
source ./DEBBUILD

# Detect architecture
if [ "$arch" = "all" ]; then
    pkgdeb=${pkgname}_${pkgver}-${pkgrel}_all.deb
    dpkgbuild=source,all
elif [ "$arch" = "any" ]; then
    pkgdeb=${pkgname}_${pkgver}-${pkgrel}_$(dpkg --print-architecture).deb
    dpkgbuild=full
else
    pkgdeb=${pkgname}_${pkgver}-${pkgrel}_${arch}.deb
    dpkgbuild=full
fi

# Maybe skip build
if [ "/apt/${REPO_NAME}/${pkgdeb}" -nt "$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2)" ]; then
    echo "${pkgname}: Package is up to date"; exit 0
fi

# Download
for f in "${sources[@]}"; do wget -O $(echo $f | sed 's/::/ /'); done
for c in "${sha256sums[@]}"; do echo $c | sha256sum --check; done

# Prepare sources
sourcedir=$(realpath ${pkgname}-${pkgver})
prepare
cd ${sourcedir}

# Create debian directory
mv ../debian debian
cat <<EOF > debian/changelog
${pkgname} (${pkgver}-${pkgrel}) RELEASED; urgency=low

  * Please read the project sources for release change logs.

 -- ${pkgsigner}  $(date --reference=../DEBBUILD --rfc-email --utc)
EOF
mkdir -p debian/source
[ -f debian/source/format ] || echo "3.0 (quilt)" > debian/source/format
[ -f debian/watch ] || echo "version=3" > debian/watch

# Ensure reproducibility
export SOURCE_DATE_EPOCH=$(stat -c %Y ../DEBBUILD) DEB_BUILD_OPTIONS="reproducible=+all"
touch -r ../DEBBUILD **/**

# Build and package
apt-get build-dep --no-install-recommends -y .
dpkg-buildpackage --build=${dpkgbuild}

# Update repository
mv ../*.{deb,debian.tar.xz,dsc,buildinfo,changes} /apt/${REPO_NAME}/
mv ../*.orig.tar.* /apt/${REPO_NAME}/
/work/gen-index.sh
