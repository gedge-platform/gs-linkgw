set -e

function error() {
    local message=$1
    echo -e "[ERROR] $message"
    exit 1
}

function info() {
    local message=$1
    echo -e "[INFO] $message"    
}

ROOT_DIR=$(realpath $(pwd))
ROOT_PARENT_DIR=$(dirname $ROOT_DIR)
SCRIPT_DIR=$ROOT_DIR/scripts
PKG_DIR=$ROOT_DIR/packages
CONTAINERD_CRI_PKG_DIR=$PKG_DIR/containerd-cri
CONTAINERD_CRI_BUILD_DIR=$CONTAINERD_CRI_PKG_DIR/_output
GO_PKG_DIR=$PKG_DIR/go-1.15.5.linux-amd64
GO_INSTALL_DIR=/usr/local/go
# ETRI Package
ETRI_PKG_DIR=$PKG_DIR/migration-controller
ETRI_PKG_INSTALL_DIR=$PKG_DIR/gs-linkgw
CRIU_DIR=$PKG_DIR/criu-3.14

# Clone containerd-cri
info "Git clone Containerd-cri"
info "$CONTAINERD_CRI_PKG_DIR"
git clone https://github.com/vutuong/containerd-cri.git $CONTAINERD_CRI_PKG_DIR
cd $CONTAINERD_CRI_PKG_DIR


# Clone Gedge-platform
info "Custom binaries update"
info "$ETRI_PKG_DIR"
cd $ETRI_PKG_DIR
tar -vxf binaries.tar.bz2
cd custom-binaries/
chmod +x containerd kubeadm kubelet

# Build containerd-cri
info "Build containerd-cri"
info "$CONTAINERD_CRI_PKG_DIR"
cd $CONTAINERD_CRI_PKG_DIR
make clean
go get github.com/containerd/cri/cmd/containerd
make


# Clone and Build criu 
info "Build criu 3.14"
info "$CRIU_DIR"
cd $PKG_DIR
curl -O -sSL http://download.openvz.org/criu/criu-3.14.tar.bz2
tar xjf criu-3.14.tar.bz2
cd $CRIU_DIR
make clean
make


# Golnag Update for ETRI Migration controller
cd $PKG_DIR
curl -O https://dl.google.com/go/go1.20.13.linux-amd64.tar.gz
rm -rf $GO_INSTALL_DIR
sudo tar -C /usr/local -xzf go1.20.13.linux-amd64.tar.gz


# Build ETRI migration controller
info "Build ETRI migration controller"
info "$ETRI_PKG_DIR"
cd $ETRI_PKG_DIR
make manifests
