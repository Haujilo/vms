#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

# for debug
echo "root:vagrant" | chpasswd
echo "vagrant:vagrant" | chpasswd
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
cp /tmp/id_rsa.pub /root/.ssh/authorized_keys
cp /tmp/id_rsa /root/.ssh/id_rsa
rm -rf /tmp/id_rsa*
chmod 600 /root/.ssh/*
cp /root/.ssh/* ~vagrant/.ssh/
chown vagrant:vagrant ~vagrant/.ssh/*

# config kernel params
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
echo >> /etc/sysctl.conf << EOF
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 65535
net.core.default_qdisc = fq
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.netfilter.nf_conntrack_max = 2621440
net.netfilter.nf_conntrack_tcp_timeout_established=1200
fs.file-max = 6815744
EOF
sysctl -p
echo >> /etc/security/limits.conf << EOF
* soft nofile 1024000
* hard nofile 1024000
root soft nofile 1024000
root hard nofile 1024000
EOF

# config repo and upgrade
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF
# stable
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free

# testing
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ testing main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ testing main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ testing-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ testing-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security testing-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security testing-security main contrib non-free

# sid
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
EOF
cat > /etc/apt/preferences.d/my_preferences << EOF
Package: *
Pin: release a=stable
Pin-Priority: 700

Package: *
Pin: release a=testing
Pin-Priority: 650

Package: *
Pin: release a=unstable
Pin-Priority: 600
EOF
apt -y update
apt -y dist-upgrade

TZ=Asia/Shanghai
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
echo "NTP=ntp1.aliyun.com ntp2.aliyun.com ntp3.aliyun.com ntp4.aliyun.com ntp5.aliyun.com ntp6.aliyun.com ntp7.aliyun.com" > /etc/systemd/timesyncd.conf

apt -y install tzdata locales snapd less net-tools iputils-ping \
  vim-tiny curl zip unzip apt-transport-https ca-certificates \
  gnupg2 software-properties-common psmisc tmux
dpkg-reconfigure locales tzdata
systemctl restart systemd-timesyncd
