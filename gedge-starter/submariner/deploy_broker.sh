#!/bin/bash
source scripts/global.sh
set -e

# Install subctl
info "Install subctl"
if [[ -f $SUBCTL_BIN ]]; then
    rm -f $SUBCTL_BIN
fi

curl -Ls $SUBCTL_REPO | bash
ln -s $SUBCTL_DOWNLOAD_BIN $SUBCTL_BIN

# Install submariner broker
cd submariner/local
rm -rf broker-info.subm

info "Deploy submariner broker"
info "SUBMARINER_VERSION=$SUBMARINER_VERSION"
subctl deploy-broker --version $SUBMARINER_VERSION --globalnet

if [ ! -f $LOCAL_BROKER_INFO_FILE ]; then
    error "Fail to deploy broker"
fi

info "'make deploy_broker_info' to transfer broker_info.subm file to master node"