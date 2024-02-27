#!/bin/bash

source scripts/global.sh

RSA_KEY_FILE="/root/.ssh/id_rsa"
RSA_PUB_FILE="/root/.ssh/id_rsa.pub"

if [[ ! -f $K8S_MASTER_JOIN_FILE ]]; then
    error "Not found $K8S_MASTER_JOIN_FILE file.\n \
           You must execute 'make deploy_master' before 'make deploy_master_info'."
fi

# Check workers
if [ -v $N_WORKERS ] || [ -z $N_WORKERS ]; then
    error "No workers registered."
    error "Fill worker ip to WORKERS variable in $K8S_LOCAL_CLUSTER_CONFIG_FILE\n \
    e.g., WORKERS=("192.168.0.1" "192.168.0.2")"
fi

for worker in ${WORKERS[@]};
do
    info "DEPLOY WORKER: $worker"
done

# Deploy rsa key
if [ ! -f $RSA_KEY_FILE ]; then
# if not exist rsa key in master node, create rsa key
    info "Generate rsa key"
    info "Execute ssh-keygen -t rsa"
    ssh-keygen -t rsa || true  
fi

# Deploy ssh rsa key to workers
for host in ${WORKERS[@]};
do
    # check whether rsa key is distributed to workers
    ssh -p 122 -o PasswordAuthentication=no -o BatchMode=yes $host exit &>/dev/null

    if [ $? -ne 0 ]; then
        ssh-copy-id -p 122 root@$host
    fi
done

# deploy script to workers
for host in ${WORKERS[@]};
do    
    # Check whether already source is deployed
    ssh -p 122 root@$host test -d $PKG_DIR
    
    if [ $? -ne 0 ]; then
        error "Not found gedge-starter source in root@$host:$ROOT_DIR"
    fi

    # Deploy master join script
    scp -P 122 $K8S_MASTER_JOIN_FILE root@$host:$K8S_MASTER_JOIN_FILE

done
