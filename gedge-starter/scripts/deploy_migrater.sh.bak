#!/bin/bash
set -e
source scripts/global.sh

info "Install podmigration operator"

cd $ETRI_PKG_DIR
info "Install pod migration CRDs"
make install

# Clean old migrater service
info "Clean old migrater service"
rm -f $MIGRATION_SERVICE_FILE
systemctl daemon-reload

# Install podmigration operator service
cat << EOF | sudo tee $MIGRATION_SERVICE_FILE
[Unit]
Description=ETRI migration operator
Documentation=https://github.com/gedge-platform/gs-linkgw
ConditionPathExists=$ETRI_PKG_DIR/main.go
After=network.target

[Service]
Environment="GOROOT=/usr/local/go"
Environment="GOCACHE=$HOME/.cache/go-build"
Environment="GOPATH=$HOME/go"
Environment="GOBIN=$GOPATH/bin"
Environment="PATH=$GOROOT/bin:$GOBIN:$PATH"

LimitNOFILE=1048576
Restart=on-failure
RestartSec=10

ExecStartPre=/usr/bin/make generate
ExecStartPre=/usr/bin/make fmt
ExecStartPre=/usr/bin/make vet
ExecStartPre=/usr/bin/make manifests
 
ExecStart=$GOROOT/bin/go run $ETRI_PKG_DIR/main.go
WorkingDirectory=$ETRI_PKG_DIR
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=migrater

[Install]
WantedBy=multi-user.target
EOF

# systemctl enable
info "Register and run migrater service"
systemctl daemon-reload
systemctl start migrater
systemctl enable migrater
