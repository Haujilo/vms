#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

swapoff -a
sed -i "/swap/d" /etc/fstab

cat >> /etc/sysctl.conf << EOF
vm.swappiness = 0
EOF
echo '0' > /sys/fs/cgroup/memory/memory.swappiness
sysctl --system

curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
  $(lsb_release -cs) \
  stable"
apt -y update
apt -y install docker-ce docker-ce-cli containerd.io
usermod -aG docker vagrant
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://k2v57zxb.mirror.aliyuncs.com", "https://docker.mirrors.ustc.edu.cn"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
