#!/bin/bash
set -e
source scripts/global.sh

# delete CNI
delete_interface flannel.1
delete_interface weave
delete_interface cni0
clear_cni_configs

# Service stop and disable
systemctl stop kubelet || true
systemctl disable kubelet || true

# Reset kubernetes master in cluster
kubeadm reset --force || true

# Uninstall kubernetes 1.19
apt-get remove -y kubeadm=1.19.0-00 kubelet=1.19.0-00 kubectl=1.19.0-00

rm -f $KUBEADM_BIN
rm -f $KUBELET_BIN

# Uninstall CRIU
cd $CRIU_PKG_DIR && make uninstall || true

# Create CRIU config file
if [[ -f $CRIU_CONFIG_FILE ]]; then
    rm -rf $CRIU_CONFIG_FILE
fi

info "Remove $SYSTEMCTL_K8S_CONFIG_FILE"
rm -f $SYSTEMCTL_K8S_CONFIG_FILE

info "Remove $K8S_KERNEL_MODULE_LOAD_CONFIG_FILE"
rm -f $K8S_KERNEL_MODULE_LOAD_CONFIG_FILE
echo '0' > /proc/sys/net/ipv4/ip_forward

info "sysctl --system"
sysctl --system

