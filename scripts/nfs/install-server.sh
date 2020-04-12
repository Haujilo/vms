#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

NFS_SHARE_RW_PATH=/var/nfs/rw
NFS_SHARE_RO_PATH=/var/nfs/ro
mkdir -p $NFS_SHARE_RW_PATH
mkdir -p $NFS_SHARE_RO_PATH
chown nobody:nogroup /var/nfs/*
chmod 777 $NFS_SHARE_RW_PATH
apt -y install nfs-kernel-server portmap
echo "$NFS_SHARE_RW_PATH 192.168.0.0/16(rw,sync,no_subtree_check)" >> /etc/exports
echo "$NFS_SHARE_RO_PATH *(ro,async,no_subtree_check)" >> /etc/exports
systemctl restart nfs-kernel-server
