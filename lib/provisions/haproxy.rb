require_relative '../utils'
require_relative 'base'

module Provision

  module HAProxy

    def define_haproxy_provisions(config, name, frontend_port, backend_port, servers)
      config.vm.provision "install-haproxy-server", type: "shell" do |s|
        s.path = self.get_script_path("install-server.sh")
        s.args = [name, frontend_port, backend_port, servers.join(' ')]
      end
    end

  end

end
