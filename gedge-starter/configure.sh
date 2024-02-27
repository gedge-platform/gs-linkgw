#!/bin/bash
set -e

ROOT_DIR=$(realpath $(pwd))
PKG_DIR=$ROOT_DIR/packages
GO_PKG_DIR=$PKG_DIR/go-1.15.5.linux-amd64
GO_INSTALL_DIR=/usr/local/go
PROFILE_FILE=/root/.profile
PROFILE_FILE_ORIG_BAK=/root/.profile.orig.bak
ENVS_FILE=$ROOT_DIR/.env

# Update repository
echo
echo "# [UPDATE] linux package repository"
echo

# Add kubernetes 1.19 repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

apt-get autoclean
apt-get update

# Install runtime packages
PKGS_LIST_FILE=$PKG_DIR/packages.dep
RUNTIME_PKGS=''

if [[ ! -d $GO_PKG_DIR ]]; then
    echo "[ERROR] Not found $GO_PKG_DIR directory."
    exit 1
fi

if [[ ! -f $PKGS_LIST_FILE ]]; then
    echo "[ERROR] Not found $PKGS_LIST_FILE file."
    exit 1
fi

for pkg in $(cat $PKGS_LIST_FILE); do    
    RUNTIME_PKGS="$RUNTIME_PKGS $(echo $pkg | tr -d '\r')"
done

echo
echo "# [INSTALL] below packages"
echo "$RUNTIME_PKGS"
echo

apt-get install -y $RUNTIME_PKGS

# Install go lang runtime
echo
echo "# [INSTALL] go runtime"
echo

if [[ -d $GO_INSTALL_DIR ]]; then
    rm -rf $GO_INSTALL_DIR
fi

cp -rf $GO_PKG_DIR $GO_INSTALL_DIR

echo
echo "# [UPDATE] go runtime environment "
echo
if [[ ! -f $PROFILE_FILE_ORIG_BAK ]]; then
    cp -f $PROFILE_FILE $PROFILE_FILE_ORIG_BAK
else
    cp -f $PROFILE_FILE_ORIG_BAK $PROFILE_FILE
fi

# Install kustomize
snap install kustomize

# Disable firewall
ufw disable

# set go envs to .profile in root
echo
echo "Run 'source /root/.profile'"
echo

cat $ENVS_FILE >> $PROFILE_FILE
