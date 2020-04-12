#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

# if only one node
# name=`kubeadm config view | grep clusterName | cut -d' ' -f 2`
# kubectl config delete-cluster $name
# kubeadm reset -f && ipvsadm -C


NODES=$(grep kubernetes- /etc/hosts | grep -v `hostname` | cut -f 2)
for node in ${NODES[@]} ; do
  kubectl drain $node --delete-local-data --force --ignore-daemonsets
  kubectl delete node $node
  ssh -o StrictHostKeyChecking=no vagrant@$node 'sudo kubeadm reset -f && sudo ipvsadm -C'
done

kubeadm reset -f && ipvsadm -C

# if use iptables
# iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

