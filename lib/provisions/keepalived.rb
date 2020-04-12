require_relative '../utils'
require_relative 'base'

module Provision

  module Keepalived

    def define_keepalived_provisions(config, cluster_name, vip, num, check_script)
      config.vm.provision "install-keepalived-server", type: "shell" do |s|
        s.path = self.get_script_path("install-server.sh")
        s.args = [cluster_name, vip, num, check_script]
      end
    end

  end

end
