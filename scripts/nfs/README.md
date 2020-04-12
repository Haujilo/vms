# NFS

## 客户端挂载

```shell
apt -y install nfs-common

export NFS_HOST=nfs-server-aa45e0
export NFS_PATH=/var/nfs/rw
export MOUNT_PATH=/mnt/share
mkdir -p $MOUNT_PATH
mount -t nfs4 $NFS_HOST:$NFS_PATH $MOUNT_PATH
```
