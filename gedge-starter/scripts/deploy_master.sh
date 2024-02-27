#!/bin/bash
set -e
source scripts/global.sh

info "Install kubernetes master."

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

# Delete old kubeconfig, master-join script
rm -f /root/.kube/config

# Initialize kubeadm
info "kubeadm reset --force"
kubeadm reset --force

# Initialize kubernetes master
info "kubeadm init parameter"
info "POD_NETWORK_CIDR=$POD_NETWORK_CIDR"
info "SERVICE_CIDR=$SERVICE_CIDR"
info "API_SERVER_IP=$API_SERVER_IP"
info "kubeadm init \
--pod-network-cidr $POD_NETWORK_CIDR \
--service-cidr $SERVICE_CIDR \
--apiserver-advertise-address $API_SERVER_IP"

kubeadm init \
--pod-network-cidr $POD_NETWORK_CIDR \
--service-cidr $SERVICE_CIDR \
--apiserver-advertise-address $API_SERVER_IP | tee | tail -n2 >> $K8S_MASTER_JOIN_FILE

chmod 755 $K8S_MASTER_JOIN_FILE

if [[ ! -f '/etc/kubernetes/admin.conf' ]]; then
    error "Fail to kubeadm init"
fi

# Configure kubernetes
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

# Install CNI
# weavenet CNI
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=$POD_NETWORK_CIDR"

# Delete existing CNI
clear_cni_configs
delete_interface flannel.1
delete_interface weave
delete_interface cni0

# flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

systemctl restart kubelet

# Setup kubernetes helper
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

source <(kubeadm completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubeadm completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
