#!/bin/bash

# Define color prefixes
RED='\033[31m'
NC='\033[0m' # No Color

# Function to print messages with the [INFO] prefix
info() {
    echo -e "[${RED}INFO${NC}] $1"
}

set -e

KUBECONFIG_DIR="/root/.kube"
KUBECONFIG_FILE="${KUBECONFIG_DIR}/config"
KUBECONFIG_BACKUP_FILE="${KUBECONFIG_DIR}/config-backup"

mkdir -p "$KUBECONFIG_DIR"

if [ -f "$KUBECONFIG_FILE" ]; then
    cp "$KUBECONFIG_FILE" "$KUBECONFIG_BACKUP_FILE" || true
    info "Config backup: $KUBECONFIG_BACKUP_FILE"
fi

# Generate KUBECONFIG from files
FILES=$(find $KUBECONFIG_DIR -type f \( -name '*.yaml' -o -name '*.yml' \) | tr '\n' ':')
export KUBECONFIG="$FILES"

kubectl config view --flatten > "${KUBECONFIG_DIR}/all-in-one-kubeconfig.yaml"
mv "${KUBECONFIG_DIR}/all-in-one-kubeconfig.yaml" "$KUBECONFIG_FILE"

info "Config merged: $KUBECONFIG_FILE"