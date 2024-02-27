#!/bin/bash
set -e
source scripts/global.sh

info "Remove kubernetes worker."

# Reset kubernetes worker node
info "kubeadm reset --force"
kubeadm reset --force
