#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

apt -y autoremove
apt -y clean
rm -rf /var/lib/apt/lists/*

sed -i '/#VAGRANT-BEGIN/,/#VAGRANT-END/d' /etc/network/interfaces
sed -i '/dns-nameserver /d' /etc/network/interfaces
sed -i '/## vagrant-hostmanager-start/,/## vagrant-hostmanager-end/d' /etc/hosts
sed -i '/ base-/d' /etc/hosts
rm -rf /BUILD
rm -rf /tmp/*
rm -rf /var/log/*
dd if=/dev/zero of=/EMPTY bs=1M || rm -f /EMPTY
rm -rf /root/.bash_history
history -c
