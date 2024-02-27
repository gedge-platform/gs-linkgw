#!/bin/bash
set -e
source scripts/global.sh

# Stop containerd service if exist
if service_exists containerd; then
    systemctl stop containerd || true
fi

# Install containerd-1.3.6 binary package(containerd packages)
for item in $(cat $CONTAINERD_v1_3_6_BIN_LIST_FILE); do
    bin="$CONTAINERD_v1_3_6_BIN_DIR/$(echo $item | tr -d '\r')"

    if [[ ! -f $bin ]]; then
        error "Not found $bin file."
        exit 1
    fi

    cp $bin $CONTAINERD_v1_3_6_DIST_DIR
done

# Install containerd-cri
cd $CONTAINERD_CRI_PKG_DIR && make install.deps
cd $CONTAINERD_CRI_PKG_DIR && make install

# Validate containerd bin is build
if [[ ! -f $CONTAINERD_CRI_BUILD_DIR/containerd ]]; then
    error "$CONTAINERD_CRI_BUILD_DIR/containerd file."
fi

# Distribute containerd-cri repo. containerd bin
# cp -f $CONTAINERD_CRI_BUILD_DIR/containerd $CONTAIENRD_CRI_DIST_DIR/containerd

# Distribute continaerd repo. build containerd
chmod +x $CONTAINERD_BUILD_BIN
cp -f $CONTAINERD_BUILD_BIN $CONTAINERD_BIN

# Install runc
chmod +x $RUNC_BUILD_BIN

# Backup origin runc
if [[ -f $RUNC_DIST_BIN_FILE ]]; then
    rm -f $RUNC_DIST_BIN_FILE
fi

cp -f $RUNC_BUILD_BIN $RUNC_DIST_BIN_FILE

# Create containerd config directory
if [[ ! -d $CONTAINERD_CONFIG_DIR ]]; then
    info "Create $CONTAINERD_CONFIG_DIR directory."
    mkdir -p $CONTAINERD_CONFIG_DIR
fi

# Create containerd config file
cat << EOF | tee $CONTAINERD_CONFIG_FILE
[plugins]
    [plugins.cri.containerd]
        snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

# Create containerd service file
cat << EOF | tee $CONTAINERD_SERVICE_FILE
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Start containerd service
systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd

# Solve a few problems introduced with containerd
if [[ ! -f $SYSTEMCTL_CONFIG_FILE_ORIG_BAK ]]; then
    cp -f $SYSTEMCTL_CONFIG_FILE $SYSTEMCTL_CONFIG_FILE_ORIG_BAK
fi
