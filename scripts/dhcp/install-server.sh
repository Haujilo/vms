#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

nic=$1
netmask=$2
gateway=$3
dns=$4
hosts_mapping=$5
ip=$(echo $hosts_mapping | jq -r ".[\"`hostname`\"].ip")

ifdown --force $nic
cat > /etc/network/interfaces.d/$nic << EOF
auto $nic
iface $nic inet static
    address $ip
    netmask $netmask
    gateway $gateway
    metric 1
EOF
systemctl daemon-reload
ifup $nic
apt-get install -y isc-dhcp-server
echo "INTERFACESv4=\"$nic\"" > /etc/default/isc-dhcp-server
dpkg-reconfigure isc-dhcp-server
cat > /etc/dhcp/dhcpd.conf << EOF
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers $dns;
subnet `route -n | grep $nic | cut -f 1 -d ' ' | grep -v 0.0.0.0` netmask $netmask {
    option subnet-mask $netmask;
    option routers $gateway;
}
EOF
echo '## vms-custom-start' >> /etc/dhcp/dhcpd.conf
echo $hosts_mapping | jq -r 'keys[] as $k | "host \($k) {\n    hardware ethernet \(.[$k] | .mac);\n    fixed-address \(.[$k] | .ip); \n}"' >> /etc/dhcp/dhcpd.conf
echo '## vms-custom-end' >> /etc/dhcp/dhcpd.conf
systemctl restart isc-dhcp-server.service
systemctl enable isc-dhcp-server.service