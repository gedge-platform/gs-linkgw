#!/bin/bash
source scripts/global.sh

# Deploy rsa key
if [ ! -f $RSA_KEY_FILE ]; then
# if not exist rsa key in master node, create rsa key
    info "Generate rsa key"
    info "Execute ssh-keygen -t rsa"
    ssh-keygen -t rsa || true  
fi

# Deploy ssh rsa key to workers
for host in ${GATEWAY_NODES[@]};
do
    if [ $host == $(hostname -I | cut -d' ' -f1) ]; then
        continue
    fi

    # check whether rsa key is distributed to workers
    ssh -o PasswordAuthentication=no -o BatchMode=yes $host exit &>/dev/null

    if [ $? -ne 0 ]; then
        ssh-copy-id root@$host
    fi
done

# Deploy remote broker-info.subm file to gateway node in remote cluster
for host in ${GATEWAY_NODES[@]};
do
    if [ $host == $(hostname -I | cut -d' ' -f1) ]; then
        continue
    fi

    scp $LOCAL_BROKER_INFO_FILE root@$host:$REMOTE_BROKER_INFO_FILE
done