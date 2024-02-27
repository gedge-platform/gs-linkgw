#!/bin/bash
set -e
source scripts/global.sh

info "Remove podmigration operator"

info "Uninstall ETRI migration CRDs"
cd $ETRI_PKG_DIR
make uninstall

rm -f $MIGRATION_SERVICE_FILE
systemctl disable migrater
systemctl stop migrater
systemctl daemon-reload
