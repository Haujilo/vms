#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

truncate -s 0 /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf

cat > /etc/hosts << EOF
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF
echo '## vms-custom-start' >> /etc/hosts
echo $1 | jq -r 'to_entries|map("\(.key) \(.value)")|.[]' >> /etc/hosts
echo $2 | jq -r 'keys[] as $k | "\(.[$k] | .ip) \($k)"' >> /etc/hosts
echo '## vms-custom-end' >> /etc/hosts
apt-get install -y dnsmasq
systemctl restart dnsmasq
systemctl enable dnsmasq