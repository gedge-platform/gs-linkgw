#!/bin/bash
set -e
source scripts/global.sh

# disk swap off
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab

# Install kubernetes
info "Install kubernetes $K8S_VERSION"
apt-get install -y kubeadm=$K8S_VERSION kubelet=$K8S_VERSION kubectl=$K8S_VERSION
systemctl enable kubelet

# load kernel modules
modprobe overlay
modprobe br_netfilter

info "Create $K8S_KERNEL_MODULE_LOAD_CONFIG_FILE file"
cat << EOF | sudo tee $K8S_KERNEL_MODULE_LOAD_CONFIG_FILE
overlay
br_netfilter
EOF

# Update Kernel parameter
# config kubernetes kernel parameter
if [[ -f $SYSTEMCTL_CONFIG_FILE_ORIG_BAK ]]; then
    mv $SYSTEMCTL_CONFIG_FILE_ORIG_BAK $SYSTEMCTL_CONFIG_FILE
fi

# Set bridge nf-call-iptable, ipv4 forward
info "Create $SYSTEMCTL_K8S_CONFIG_FILE file"
cat << EOF | sudo tee $SYSTEMCTL_K8S_CONFIG_FILE
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

info "sysctl --system"
sysctl --system

# Update kubeadm, kubectl, containerd with podmigration version from SSU-DCN
rm -f $KUBEADM_BIN
rm -f $KUBELET_BIN

chmod +x $KUBEADM_BUILD_BIN
chmod +x $KUBELET_BUILD_BIN

cp -f $KUBEADM_BUILD_BIN $KUBEADM_BIN
cp -f $KUBELET_BUILD_BIN $KUBELET_BIN

# Restart containerd, kubelet
systemctl daemon-reload
systemctl restart containerd
systemctl restart kubelet

# Install criu
cd $CRIU_PKG_DIR && make install && criu check

# Create criu config file
if [[ ! -d $CRIU_CONFIG_DIR ]]; then
    mkdir -p $CRIU_CONFIG_DIR
fi

cat << EOF | tee $CRIU_CONFIG_FILE
tcp-established
tcp-close
EOF
