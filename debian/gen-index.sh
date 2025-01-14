#!/bin/bash
set -e
cd /apt
dpkg-scanpackages --multiversion ${REPO_NAME} > ${REPO_NAME}/Packages
gzip -k -f /apt/${REPO_NAME}/Packages
apt-ftparchive \
      -o APT::FTPArchive::Release::Origin="Cartesi" \
      -o APT::FTPArchive::Release::Label="Cartesi APT Repository" \
      -o APT::FTPArchive::Release::Suite="stable" \
      release ${REPO_NAME} > ${REPO_NAME}/Release
gpg -abs -o - /apt/${REPO_NAME}/Release > /apt/${REPO_NAME}/Release.gpg
gpg --clearsign -o - /apt/${REPO_NAME}/Release > /apt/${REPO_NAME}/InRelease
echo "deb ${REPO_URL} ${REPO_NAME}/" > /apt/${REPO_NAME}/sources.list
