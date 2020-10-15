require 'digest/md5'

module Utils

  extend self

  def hostname(prefix, n)
    suffix = Digest::MD5.hexdigest("#{prefix}-#{n}")[0,4]
    "#{prefix}-#{(prefix.length + n.to_i + 160).to_s(16)[0,2]}#{suffix}"
  end

  def provider(config, category, role, n, mac0, mac1, ip1, netmask1, gateway1, cpus, memory)
    provider_name = ENV["VAGRANT_DEFAULT_PROVIDER"] + '_provider'
    return method(provider_name).call(config, category, role, n, mac0, mac1, ip1, netmask1, gateway1, cpus, memory.to_s) do |node|
      yield node
    end
  end

  def virtualbox_provider(config, category, role, n, mac0, mac1, ip1, netmask1, gateway1, cpus, memory)
    name = hostname("#{category}-#{role}", n)
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", auto_config: false, ip: ip1, netmask: netmask1.to_s, virtualbox__intnet: "vvmsnet1"
      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.cpus = cpus
        vb.memory = memory
        vb.default_nic_type = "virtio"
        vb.customize ["modifyvm", :id, "--groups", "/vms/#{category}/#{role}"]
        vb.customize ['modifyvm', :id, "--natnet1", "172.18/16"]
        vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
        vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
        vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--macaddress1", mac0.split(':').join('')]
        vb.customize ["modifyvm", :id, "--macaddress2", mac1.split(':').join('')]
        if ENV['BUILD_BASE_BOX'] == nil then
          vb.linked_clone = true
        end
      end
      yield node
    end
    return name
  end

  def hyperv_provider(config, category, role, n, mac0, mac1, ip1, netmask1, gateway1, cpus, memory)
    name = hostname("#{category}-#{role}", n)
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.provider "hyperv" do |hv|
        hv.vmname = name
        hv.cpus = cpus
        hv.memory = memory
        if ENV['BUILD_BASE_BOX'] == nil then
          hv.linked_clone = true
        end
      end
      node.trigger.after "VagrantPlugins::HyperV::Action::Configure", type: :action do |trigger|
        trigger.info = "Setting HyperV VM Nics"
        trigger.run = {
          privileged: "true",
          powershell_elevated_interactive: "true",
          path: "./scripts/init-nic.ps1",
          args: [name, mac0, mac1]
        }
      end
      yield node
    end
    return name
  end

end
