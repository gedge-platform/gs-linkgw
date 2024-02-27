#!/bin/bash
set -e
source scripts/global.sh

if [[ -f $SYSTEMCTL_CONFIG_FILE_ORIG_BAK ]]; then
    mv -f $SYSTEMCTL_CONFIG_FILE_ORIG_BAK $SYSTEMCTL_CONFIG_FILE
fi

# Remove symbolic link file
if [[ -L $RUNC_DIST_BIN_FILE ]]; then
    rm -f $RUNC_DIST_BIN_FILE
fi

# Delete runc bin
if [[ -f $RUNC_DIST_BIN_FILE ]]; then
    rm -f $RUNC_DIST_BIN_FILE
fi

# Delete containerd service file
if [[ -f $CONTAINERD_SERVICE_FILE ]]; then
    rm $CONTAINERD_SERVICE_FILE
fi

# Delete containerd config file
if [[ -f $CONTAINERD_CONFIG_FILE ]]; then
    rm -f $CONTAINERD_CONFIG_FILE
fi

# Delete runc distributed version
if [[ -f $RUNC_BUILD_DIST_BIN ]]; then
    rm -f $RUNC_BUILD_DIST_BIN
fi

# Stop containerd service
systemctl stop containerd || true
systemctl disable containerd || true
systemctl daemon-reload || true

# Uninstall containerd-cri
cd $CONTAINERD_CRI_PKG_DIR && make uninstall

# Delete containerd-1.3.6 binaries
for item in $(cat $CONTAINERD_v1_3_6_BIN_LIST_FILE); do
    bin="$CONTAINERD_v1_3_6_DIST_DIR/$(echo $item | tr -d '\r')"
    info "rm -f $bin"
    rm -f $bin
done

