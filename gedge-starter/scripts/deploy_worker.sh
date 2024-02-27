#!/bin/bash
set -e
source scripts/global.sh

info "Install kubernetes worker."

# Check whether kubernetes packages are installed
info "Check kubernetes packages"

if [[ ! -f $KUBEADM_BIN ]]; then
    error "Not found $KUBEADM_BIN"
fi

if [[ ! -f $KUBELET_BIN ]]; then
    error "Not found $KUBELET_BIN"
fi 

if [[ ! -f $CONTAINERD_BIN ]]; then
    error "Not found $CONTAINERD_BIN"
fi

if ! service_exists kubelet; then
    error "Not installed kubelet"
fi

if ! service_exists containerd; then
    error "Not installed containerd"
fi

# Clear CNI
clear_cni_configs

# Initialize kubeadm
info "kubeadm reset --force"
kubeadm reset --force

if [[ ! -f $K8S_MASTER_JOIN_FILE ]]; then
    error "Not found $K8S_MASTER_JOIN_FILE"
fi

# Join kubernetes master
$K8S_MASTER_JOIN_FILE
