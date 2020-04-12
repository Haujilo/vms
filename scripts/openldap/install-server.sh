#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

PASSWORD=vagrant
DOMAIN="haujilo.xyz"

echo "slapd slapd/password1 password $PASSWORD" | debconf-set-selections
echo "slapd slapd/password2 password $PASSWORD" | debconf-set-selections
echo "slapd slapd/domain string $DOMAIN" | debconf-set-selections
echo "slapd shared/organization string $DOMAIN" | debconf-set-selections
apt -y install slapd ldap-utils ldapscripts
