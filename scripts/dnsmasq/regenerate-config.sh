#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive


sed -i '/## vms-custom-start/,/## vms-custom-end/d' /etc/hosts

echo '## vms-custom-start' >> /etc/hosts
echo $1 | jq -r 'to_entries|map("\(.key) \(.value)")|.[]' >> /etc/hosts
echo $2 | jq -r 'keys[] as $k | "\(.[$k] | .ip) \($k)"' >> /etc/hosts
echo '## vms-custom-end' >> /etc/hosts
systemctl restart dnsmasq