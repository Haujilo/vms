#! /bin/bash

set -ueo pipefail

box_name="local/debian"
box_path="./base.box"
export BUILD_BASE_BOX=1
vm_name=`vagrant status | grep base- | cut -d' ' -f 1`
vagrant up $vm_name
export USE_LOCAL_KEY=1
vagrant vbguest $vm_name
vagrant reload $vm_name
vagrant provision $vm_name --provision-with clean-for-dump
vagrant halt $vm_name
VBoxManage modifyvm $vm_name --nic2 none
vagrant package --output $box_path $vm_name
vagrant box add --force $box_name $box_path
vagrant destroy -f $vm_name
rm -rf .vagrant $box_path
vagrant box list
