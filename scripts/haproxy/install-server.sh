#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

apt -y install haproxy

name="$1"
server_pattern="$2"
frontend_port="$3"
backend_port="$4"

stats_password=bf1edae188e1edae6b7d7a8bc8f8b202
stats_port=1080
servers=`grep "\s$server_pattern" /etc/hosts | grep -v 127.0 | awk 'BEGIN{x="        server "; y=":'"$backend_port"' check"}{print x $2,$1 y}'`

cat >> /etc/haproxy/haproxy.cfg << EOF

frontend $name
        mode                 tcp
        bind                 *:$frontend_port
        option               tcplog
        default_backend      $name

backend $name
        mode        tcp
        balance     roundrobin
${servers}

listen stats
        bind                 *:$stats_port
        stats auth           admin:$stats_password
        stats refresh        5s
        stats realm          HAProxy\ Statistics
        stats uri            /admin?stats
EOF

systemctl enable haproxy
systemctl restart haproxy
