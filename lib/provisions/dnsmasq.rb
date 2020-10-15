require_relative '../utils'
require_relative 'base'

module Provision

  class Dnsmasq < Base

    def assign_subnet()
        return @@INFRASTRUCTURE_NET
    end

    def assign_rip_addr(carry = false)
      ip = super carry
      @@dns.push(ip)
      return ip
    end

    def define_provisions(config, role, index)
      config.vm.provision "install-dnsmasq-server", type: "shell" do |s|
        s.path = self.get_script_path("install-server.sh")
        s.args = [@@domains_mapping.to_json, @@hosts_mapping.to_json]
      end
      config.vm.provision "regenerate-dnsmasq-config", type: "shell", run: "never" do |s|
        s.path = self.get_script_path("regenerate-config.sh")
        s.args = [@@domains_mapping.to_json, @@hosts_mapping.to_json]
      end
    end

  end

end
