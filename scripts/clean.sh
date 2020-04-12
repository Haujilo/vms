#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

apt -y autoremove
apt -y clean
rm -rf /var/lib/apt/lists/*
