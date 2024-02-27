#!/bin/bash
set -e
source scripts/global.sh

info "Remove kubernetes master node."

# Remove migrater
info "Remove migrater"

if service_exists migrater; then
    scripts/remove_migrater.sh
fi

# Remove submariner
info "Remove submariner"
submariner/remove_broker.sh

# flannel CNI
kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml || true

# Delete existing CNI
clear_cni_configs
delete_interface flannel.1
delete_interface weave
delete_interface cni0

# Delete old kubeconfig, master-join script
rm -f /root/.kube/config

# Initialize kubeadm
info "kubeadm reset --force"
kubeadm reset --force
