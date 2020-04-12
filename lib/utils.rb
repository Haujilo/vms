require 'digest/md5'

module Utils

  extend self

  def hostname(prefix, n)
    suffix = Digest::MD5.hexdigest("#{prefix}-#{n}")[0,4]
    "#{prefix}-#{(prefix.length + n.to_i + 160).to_s(16)[0,2]}#{suffix}"
  end

  def provider(config, category, role, n, ip, cpus, memory, t = "virtualbox")
    if t == "virtualbox" then
      return virtualbox_provider(config, category, role, n, ip, cpus, memory.to_s) do |node|
        yield node
      end
    end
  end

  def virtualbox_provider(config, category, role, n, ip, cpus, memory)
    name = hostname("#{category}-#{role}", n)
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: ip, netmask: "16", virtualbox__intnet: "vagrant", nic_type: "virtio"
      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.cpus = cpus
        vb.memory = memory
        vb.linked_clone = true
        vb.default_nic_type = "virtio"
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--groups", "/vagrant/#{category}/#{role}"]
      end
      yield node
    end
    return name
  end

end
