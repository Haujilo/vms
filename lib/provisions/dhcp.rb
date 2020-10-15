require_relative '../utils'
require_relative 'base'

module Provision

  class DHCP < Base

    def assign_subnet()
        return @@INFRASTRUCTURE_NET
    end

    def define_provisions(config, role, index)
      config.vm.provision "install-dhcp-server", type: "shell" do |s|
        s.path = self.get_script_path("install-server.sh")
        s.args = [
          @@nic1,
          self.ip_to_s(0xffffffff << (32 - @@netmask1) & 0xffffffff),
          self.ip_to_s(@@gateway1),
          @@dns.join(', '),
          @@hosts_mapping.to_json,
        ]
      end
    end

  end

end
