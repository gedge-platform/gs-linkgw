#!/bin/bash

source scripts/global.sh
set -e

trap \
 "{ \
kubectl taint nodes $(hostname) node-role.kubernetes.io/master:NoSchedule ; exit 255; }" \
SIGINT SIGTERM ERR EXIT

# release taint
kubectl taint nodes $(hostname) node-role.kubernetes.io/master-

# set master node label for submariner
kubectl label node $(hostname) submariner.io/gateway=true --overwrite

if [ $CLUSTER_ROLE == "Local" ]; then
    if [ ! -f $LOCAL_BROKER_INFO_FILE ]; then
    error "Not found $LOCAL_BROKER_INFO_FILE"
    fi

    subctl join $LOCAL_BROKER_INFO_FILE \
    --version $SUBMARINER_VERSION \
    --clusterid $CLUSTER_ID \
    --cable-driver wireguard \
    --natt=false
fi

if [ $CLUSTER_ROLE == "Remote" ]; then
  if [ ! -f $REMOTE_BROKER_INFO_FILE ]; then
    error "Not found $REMOTE_BROKER_INFO_FILE"
  fi

  subctl join $REMOTE_BROKER_INFO_FILE \
  --version $SUBMARINER_VERSION \
  --clusterid $CLUSTER_ID \
  --cable-driver wireguard \
  --natt=false
fi

# Recover taint for master node
kubectl taint nodes $(hostname) node-role.kubernetes.io/master:NoSchedule || true