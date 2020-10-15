#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

CONTROL_PLANE_ENDPOINT=$1
POD_NETWORK_CIDR=$2
SVC_NETWORK_CIDR=$3
IFACE=$4
NODES=$5
ADVERTISE_ADDRESS=`ip -o -4 addr list $IFACE | grep dynamic | awk '{print $4}' | cut -d/ -f1`
IMAGE_REPOSITORY=registry.cn-hangzhou.aliyuncs.com/google_containers

# https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2
cat > /tmp/k8s-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDRESS
---
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: "$IMAGE_REPOSITORY"
kind: ClusterConfiguration
kubernetesVersion: `kubeadm version -o short`
controlPlaneEndpoint: "$CONTROL_PLANE_ENDPOINT"
networking:
  dnsDomain: cluster.local
  podSubnet: "$POD_NETWORK_CIDR"
  serviceSubnet: "$SVC_NETWORK_CIDR"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF

kubeadm init --config /tmp/k8s-config.yaml --upload-certs | tee /tmp/kubeadm-init.log
certificate_key=`grep '\-\-control-plane \-\-certificate-key' /tmp/kubeadm-init.log | awk '{print $3}'`
rm -rf /tmp/k8s-config.yaml /tmp/kubeadm-init.log

user=vagrant
home=~vagrant
export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $home/.kube
cp -f $KUBECONFIG $home/.kube/config
chown $user:$user $home/.kube/config
echo "export KUBECONFIG=$KUBECONFIG" >> ~root/.profile

# let other nodes join
TOKEN=`kubeadm token list | grep system:bootstrappers:kubeadm:default-node-token | cut -d ' ' -f 1`
SHA256_HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | cut -d ' ' -f 2`
DEFAULT_JUMP_CMD="kubeadm join $CONTROL_PLANE_ENDPOINT --token $TOKEN --discovery-token-ca-cert-hash sha256:$SHA256_HASH"

# https://docs.projectcalico.org/getting-started/kubernetes/quickstart
sed -i -e "s?192.168.0.0/16?$POD_NETWORK_CIDR?g" /tmp/custom-resources.yaml
kubectl create -f /tmp/tigera-operator.yaml && kubectl create -f /tmp/custom-resources.yaml && rm -rf /tmp/tigera-operator.yaml /tmp/custom-resources.yaml

OTHER_MASTER_NODES=$(echo $NODES | xargs -n 1 | grep -v `hostname` | grep -v minion)
for node in ${OTHER_MASTER_NODES[@]} ; do
  ip=$(ssh -o StrictHostKeyChecking=no vagrant@$node "ip -o -4 addr list $IFACE | grep dynamic | awk '{print \$4}' | cut -d/ -f1")
  ssh -o StrictHostKeyChecking=no vagrant@$node "sudo $DEFAULT_JUMP_CMD --apiserver-advertise-address $ip --control-plane --certificate-key $certificate_key"
  ssh -o StrictHostKeyChecking=no vagrant@$node "mkdir -p $home/.kube"
  ssh -o StrictHostKeyChecking=no vagrant@$node "sudo cp -f $KUBECONFIG $home/.kube/config"
  ssh -o StrictHostKeyChecking=no vagrant@$node "sudo chown $user:$user $home/.kube/config"
  ssh -o StrictHostKeyChecking=no vagrant@$node "echo export KUBECONFIG=$KUBECONFIG | sudo tee ~root/.profile"
done
# remove the taints on the master so that you can schedule pods on it.
kubectl taint nodes --all node-role.kubernetes.io/master-

MINION_NODES=$(echo $NODES | xargs -n 1 | grep minion)
for node in ${MINION_NODES[@]} ; do
  ip=$(ssh -o StrictHostKeyChecking=no vagrant@$node "ip -o -4 addr list $IFACE | grep dynamic | awk '{print \$4}' | cut -d/ -f1")
  ssh -o StrictHostKeyChecking=no vagrant@$node "sudo $DEFAULT_JUMP_CMD --apiserver-advertise-address $ip"
  kubectl label node $node node-role.kubernetes.io/minion=
done
