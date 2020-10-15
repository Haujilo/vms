#! /usr/bin/env ruby

require_relative "lib/provisions"

PRI_SSH_KEY = "./data/ssh/id_rsa"
BUILD_FROM_BOX = "generic/debian10"
DEFAULT_BOX = "local/debian"

ENV["VAGRANT_EXPERIMENTAL"] = 'typed_triggers'
ENV["VAGRANT_DEFAULT_PROVIDER"] = 'virtualbox'

def powershell(cmd)
  require 'base64'
  encoded_cmd = Base64.strict_encode64(cmd.encode('utf-16le'))
  return `powershell.exe -encodedCommand #{encoded_cmd}`
end

def hyper?()
  cmd = %{(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | Format-Table State -hidetableheaders | Out-String).Trim()}
  powershell(cmd).strip!.downcase == 'enabled'
end

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil && hyper? then # Windows enable Hyper-v
  ENV["VAGRANT_DEFAULT_PROVIDER"] = 'hyperv'
end


Vagrant.require_version ">= 2.2.7"
Vagrant.configure("2") do |config|

  config.vm.box = DEFAULT_BOX
  config.vm.box_check_update = true
  # disabling the default /vagrant share
  config.vm.synced_folder ".", "/vagrant", disabled: true


  if ENV["VAGRANT_DEFAULT_PROVIDER"] == 'hyperv' then
    config.vm.network "public_network", bridge: "Default Switch"
  else
    # https://github.com/dotless-de/vagrant-vbguest
    config.vbguest.auto_update = false
  end

  if ENV['BUILD_BASE_BOX'] == nil then
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
  end

  # https://github.com/vagrant-group/vagrant-group
  config.group.groups = Provision::define(config)

  if ENV['BUILD_BASE_BOX'] != nil then
    Provision::Base.new.define(config)
  end

end