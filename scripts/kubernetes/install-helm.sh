#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive

MIRROR=https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

snap install helm --classic
helm repo add stable $MIRROR
helm repo update
