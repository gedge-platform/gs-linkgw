#!/bin/bash
ROOT_DIR=$(realpath $(pwd))

DEPLOY_HOSTS=(
"10.0.0.159"
"10.0.0.171"
"10.0.0.175"
)

DEPLOY_FILES=(
    "configure.sh"
    "Makefile"
    # "config/cluster.cfg"
    # "scripts/global.sh"            
    "scripts/build.sh"
    # "scripts/01_install_containerd.sh"
    # "scripts/02_install_kubernetes.sh" 
    # "scripts/01_uninstall_kubernetes.sh"
    # "scripts/02_uninstall_containerd.sh"
    # "scripts/install_k8s_master.sh"
    # "scripts/install_k8s_worker.sh"
    # "scripts/install_podmigration_operator.sh"
    # "submariner/join_broker.sh"
    # "submariner/deploy_broker.sh"
    # "submariner/remove_broker.sh"
    # "submariner/deploy_broker_info.sh"        
)

for item in ${DEPLOY_FILES[@]}; do
    for host in ${DEPLOY_HOSTS[@]}; do
        # check whether rsa key is distributed to workers
        ssh -o PasswordAuthentication=no -o BatchMode=yes $host exit &>/dev/null

        if [ $? -ne 0 ]; then
            ssh-copy-id root@$host
        fi    

        # ssh root@$host mv $ROOT_DIR/test $ROOT_DIR/submariner
        # ssh root@$host mkdir -p $ROOT_DIR/test
        scp $item root@$host:$ROOT_DIR/$item
    done    
done