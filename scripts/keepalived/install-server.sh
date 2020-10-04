#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

apt -y install keepalived

cluster_name=`echo $1 | tr '[:lower:]' '[:upper:]'`
vip="$2"
num="$3"
check_script="$4"

auth_pass=c61decf156d1fe60275fbf73c49e342d
interface="eth0"
router_id="${cluster_name}0$num"
virtual_router_id=`echo $vip | cut -d"." -f 4`
vrrp_interface_name="${cluster_name}"
state=MASTER
priority=100

if [ $num -ne 0 ]; then
  state=BACKUP
  priority=`expr 50 - $num`
fi

cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
  router_id $router_id
}

vrrp_script check_alive {
  script "$check_script"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance $vrrp_interface_name {
  state $state
  interface $interface
  virtual_router_id $virtual_router_id
  priority $priority
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass $auth_pass
  }
  virtual_ipaddress {
    ${vip}/24
  }
  track_script {
    check_alive
  }
}
EOF

systemctl enable --now keepalived.service
