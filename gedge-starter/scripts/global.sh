#! /bin/bash
function error() {
    local message=$1
    echo -e "[ERROR] $message"
    exit 1
}

function info() {
    local message=$1
    echo -e "[INFO] $message"    
}

function service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

function clear_cni_configs {
    rm -f /etc/cni/net.d/*
}

function delete_interface {
  if [[ -d /sys/class/net/${1} ]]; then
    ifconfig ${1} down
    ip link delete ${1}
  fi
}

ROOT_DIR=$(realpath $(pwd))
ROOT_PARENT_DIR=$(dirname $ROOT_DIR)
SCRIPT_DIR=$ROOT_DIR/scripts
PKG_DIR=$ROOT_DIR/packages
ETRI_PKG_DIR=$PKG_DIR/migration-controller
ETRI_PKG_INSTALL_DIR=$PKG_DIR/gs-linkgw

# containerd-1.3.6
# https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz
CONTAINERD_v1_3_6_PKG_DIR=$PKG_DIR/containerd-1.3.6
CONTAINERD_v1_3_6_BIN_DIR=$CONTAINERD_v1_3_6_PKG_DIR/bin
CONTAINERD_v1_3_6_BIN_LIST_FILE=$CONTAINERD_v1_3_6_PKG_DIR/bin.dep
CONTAINERD_v1_3_6_DIST_DIR=/bin

# containerd-cri
# https://github.com/vutuong/containerd-cri.git
CONTAINERD_CRI_PKG_DIR=$PKG_DIR/containerd-cri
CONTAINERD_CRI_BUILD_DIR=$CONTAINERD_CRI_PKG_DIR/_output
CONTAIENRD_CRI_DIST_DIR=/bin

CONTAINERD_CONFIG_DIR=/etc/containerd
CONTAINERD_CONFIG_FILE=$CONTAINERD_CONFIG_DIR/config.toml
CONTAINERD_SERVICE_FILE=/etc/systemd/system/containerd.service

# runc-1.0.0-rc92
# https://github.com/opencontainers/runc/releases/download/v1.0.0-rc92/runc.amd64
RUNC_BUILD_BIN=$PKG_DIR/runc-1.0.0-rc92/runc.amd64
RUNC_DIST_BIN_FILE=/usr/local/bin/runc
RUNC_DIST_DIR=/usr/local/bin

# kubernetes version
K8S_VERSION=1.19.0-00
KUBEADM_BIN=/usr/bin/kubeadm
KUBELET_BIN=/usr/bin/kubelet
CONTAINERD_BIN=/bin/containerd

# custom opersource build for ETRI migration controller
#  https://github.com/gedge-platform/gs-linkgw 
KUBEADM_BUILD_BIN=$ETRI_PKG_DIR/custom-binaries/kubeadm
KUBELET_BUILD_BIN=$ETRI_PKG_DIR/custom-binaries/kubelet
CONTAINERD_BUILD_BIN=$ETRI_PKG_DIR/custom-binaries/containerd

CRIU_PKG_DIR=$PKG_DIR/criu-3.14
CRIU_CONFIG_DIR=/etc/criu
CRIU_CONFIG_FILE=$CRIU_CONFIG_DIR/runc.conf
MIGRATION_SERVICE_FILE=/etc/systemd/system/migrater.service
#SSU_DCN_DEP_KUBERNETES_PKG_DIR=$PKG_DIR/kubernetes

# kernel parameter config
SYSTEMCTL_CONFIG_FILE=/etc/sysctl.conf
SYSTEMCTL_CONFIG_FILE_ORIG_BAK=/etc/sysctl.conf.orig.bak
SYSTEMCTL_K8S_CONFIG_FILE=/etc/sysctl.d/k8s.conf

# kernel module load config
K8S_KERNEL_MODULE_LOAD_CONFIG_FILE=/etc/modules-load.d/k8s.conf

# kubernetes cluster config
K8S_LOCAL_CLUSTER_CONFIG_FILE=$ROOT_DIR/config/local_cluster.cfg
K8S_MULTI_CLUSTER_CONFIG_FILE=$ROOT_DIR/config/multi_cluster.cfg
K8S_MASTER_JOIN_FILE=$ROOT_DIR/scripts/master_join.sh

# submariner.io
# release version info: https://submariner.io/community/releases/
SUBMARINER_VERSION=0.12.3
SUBCTL_BIN=/sbin/subctl
SUBCTL_REPO=https://get.submariner.io
SUBCTL_DOWNLOAD_BIN=~/.local/bin/subctl
LOCAL_BROKER_INFO_FILE=$ROOT_DIR/submariner/local/broker-info.subm
REMOTE_BROKER_INFO_FILE=$ROOT_DIR/submariner/remote/broker-info.subm

# validate containerd-1.3.6 binary package
if [[ ! -d $CONTAINERD_v1_3_6_PKG_DIR ]]; then
    error "Not found $CONTAINERD_v1_3_6_PKG_DIR directory"
fi

if [[ ! -d $CONTAINERD_v1_3_6_BIN_DIR ]]; then
    error "Not found $CONTAINERD_v1_3_6_BIN_DIR directory"
fi

if [[ ! -f $CONTAINERD_v1_3_6_BIN_LIST_FILE ]]; then
    error "Not found $CONTAINERD_v1_3_6_BIN_LIST_FILE file"
fi

# validate containerd-cri source package
if [[ ! -d $CONTAINERD_CRI_PKG_DIR ]]; then
    error "Not found $CONTAINERD_CRI_PKG_DIR directory. Try 'make build'"
fi

if [[ ! -d $CONTAINERD_CRI_BUILD_DIR ]]; then
    error "Not found $CONTAINERD_CRI_BUILD_DIR directory"
fi

# validate runc build binary
if [[ ! -f $RUNC_BUILD_BIN ]]; then
    error "Not found $RUNC_BUILD_BIN file"
fi

# validate podmigration(SSU_DCN) binary package
if [[ ! -d $ETRI_PKG_DIR ]]; then
    error "Not found $ETRI_PKG_DIR directory. Try 'make build'"
fi

if [[ ! -f $KUBEADM_BUILD_BIN ]]; then
    error "Not found $KUBEADM_BUILD_BIN file"
fi

if [[ ! -f $KUBELET_BUILD_BIN ]]; then
    error "Not found $KUBELET_BUILD_BIN file"
fi

if [[ ! -f $CONTAINERD_BUILD_BIN ]]; then
    error "Not found $CONTAINERD_BUILD_BIN file"
fi

# validate kubernetes cluster config
info "Check local cluster configuration"

if [[ ! -f $K8S_LOCAL_CLUSTER_CONFIG_FILE ]]; then
    error "Not found $K8S_LOCAL_CLUSTER_CONFIG_FILE file"
fi

source $K8S_LOCAL_CLUSTER_CONFIG_FILE

if [ -v $POD_NETWORK_CIDR ] || [ -z $POD_NETWORK_CIDR ]; then
  error "Not found POD_NETWORK_CIDR variable or value in $K8S_LOCAL_CLUSTER_CONFIG_FILE"
fi

if [ -v $SERVICE_CIDR ] || [ -z $SERVICE_CIDR ]; then
  error "Not found SERVICE_CIDR variable or value in $K8S_LOCAL_CLUSTER_CONFIG_FILE"
fi
if [ -v $API_SERVER_IP ] || [ -z $API_SERVER_IP ]; then
  error "Not found API_SERVER_IP variable or value in $K8S_LOCAL_CLUSTER_CONFIG_FILE"
fi

if [ -v $WORKERS ] && [ ${#WORKERS[@]} -gt 0 ]; then
    error "Not found WORKERS variable or value in $K8S_CLUSTER_CONFIG_FILE\n \
    Fill worker ip to WORKERS variable in $K8S_CLUSTER_CONFIG_FILE\n \
    e.g., WORKERS=("192.168.0.1" "192.168.0.2")"
else
    N_WORKERS=${#WORKERS[@]}
fi

info "Check multi cluster configuration"

if [[ ! -f $K8S_MULTI_CLUSTER_CONFIG_FILE ]]; then
    error "Not found $K8S_MULTI_CLUSTER_CONFIG_FILE file"
fi

source $K8S_MULTI_CLUSTER_CONFIG_FILE

if [ -v $CLUSTER_ID ] || [ -z $CLUSTER_ID ]; then
  error "Not found CLUSTER_ID variable or value in $K8S_MULTI_CLUSTER_CONFIG_FILE"
fi

if [ -v $CLUSTER_ROLE ] || [ -z $CLUSTER_ROLE ]; then
  error "Not found CLUSTER_ROLE variable or value in $K8S_MULTI_CLUSTER_CONFIG_FILE\n \
  Fill CLUSTER_ROLE with 'Local' or 'Remote'"
fi

if [ $CLUSTER_ROLE != "Local" ] && [ $CLUSTER_ROLE != "Remote" ]; then
    error "Invalid CLUSTER_ROLE value in $K8S_MULTI_CLUSTER_CONFIG_FILE\n \
    Fill CLUSTER_ROLE with 'Local' or 'Remote'"
fi

if [ -v $GATEWAY_NODES ] && [ ${#GATEWAY_NODES[@]} -gt 0 ]; then
    error "Not found GATEWAY_NODES variable or value in $K8S_MULTI_CLUSTER_CONFIG_FILE\n \
    Fill gateway node ip to GATEWAY_NODES variable in $K8S_MULTI_CLUSTER_CONFIG_FILE\n \
    e.g., GATEWAY_NODES=("$(hostname -I | cut -d' ' -f1)" "10.0.1.1")"
fi
