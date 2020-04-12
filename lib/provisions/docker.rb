require_relative '../utils'
require_relative 'base'

module Provision

  class Docker < Base

    def initialize(cpus = 1, memory = 1024, role_assigned = {"server"=>1})
      super cpus, memory, role_assigned
    end

    def define_provisions(config, role, index)
      config.vm.provision "install-docker-engine", type: "shell" do |s|
        s.path = self.get_script_path("install-engine.sh")
      end
    end

  end

end
