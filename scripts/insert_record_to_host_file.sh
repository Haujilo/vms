#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

record="$1 $2"
echo '# custom virtual ip record' >> /etc/hosts
echo $record >> /etc/hosts
