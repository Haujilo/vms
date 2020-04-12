#! /usr/bin/env ruby

require_relative "lib/provisions"

BUILD_BASE_BOX = ENV['BUILD_BASE_BOX']
PRI_SSH_KEY = "./data/ssh/id_rsa"
BUILD_FROM_BOX = "debian/buster64"
DEFAULT_BOX = "local/debian"

Vagrant.require_version ">= 2.2.7"
Vagrant.configure("2") do |config|

  config.vm.box = DEFAULT_BOX
  config.vm.box_check_update = true
  # disabling the default /vagrant share
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # https://github.com/devopsgroup-io/vagrant-hostmanager
  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  # https://github.com/dotless-de/vagrant-vbguest
  config.vbguest.auto_update = false

  if BUILD_BASE_BOX == nil then
    config.ssh.insert_key = false
    config.ssh.private_key_path = PRI_SSH_KEY
  else
    if ENV['USE_LOCAL_KEY'] != nil then
      config.ssh.insert_key = false
      config.ssh.private_key_path = PRI_SSH_KEY
    end
    config.vm.box = BUILD_FROM_BOX
    config.vm.provision "file", source: "./data/ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
    config.vm.provision "file", source: PRI_SSH_KEY, destination: "/tmp/id_rsa"
    Provision::Base.new.define(config)
  end

  # https://github.com/vagrant-group/vagrant-group
  config.group.groups = Provision::define(config)

end
