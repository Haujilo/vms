require_relative '../utils'
require_relative 'base'

module Provision

  class OpenLDAP < Base

    def define_provisions(config, role, index)
      config.vm.provision "install-openldap-server", type: "shell" do |s|
        s.path = self.get_script_path("install-server.sh")
      end
    end

  end

end
