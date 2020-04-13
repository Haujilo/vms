require_relative '../utils'
require_relative 'base'
require_relative 'haproxy'
require_relative 'keepalived'

module Provision

  class Kubernetes < Docker

    include HAProxy
    include Keepalived

    # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
    def initialize(cpus = 2, memory = 2048, role_assigned = { "master" => 3, "minion" => 1 })
      super cpus, memory, role_assigned
      @vip = self.assign_vip_addr
      @vip_port = 16443
      @pod_cidr = "10.244.0.0/16"
      @svc_cidr = "10.96.0.0/12"
    end

    def global_define_provisions(config)
      config.vm.provision "insert-vip-record", type: "shell" do |s|
        s.path = "scripts/insert_record_to_host_file.sh"
        s.args = [@vip, self.category]
      end
      super
    end

    def define_provisions(config, role, index)
      if role == "master" then
        self.define_haproxy_provisions(config, "#{self.category}-apiserver", "#{self.category}-#{role}-", @vip_port, 6443)
        self.define_keepalived_provisions(config, self.category, @vip, index, "/usr/bin/killall -0 haproxy")
        config.vm.provision "install-helm", type: "shell", run: "never" do |s|
          s.path = self.get_script_path("install-helm.sh")
        end
      end
      super
      config.vm.provision "install-kubernetes", type: "shell" do |s|
        s.path = self.get_script_path("install-kubernetes.sh")
      end
      if index == 0 then
        config.vm.provision "init-kubernetes-cluster", type: "shell" do |s|
          s.path = self.get_script_path("init-kubernetes-cluster.sh")
          s.args = ["#{self.category}:#{@vip_port}", @pod_cidr, @svc_cidr]
        end
        config.vm.provision "remove-kubernetes-cluster", type: "shell", run: "never" do |s|
          s.path = self.get_script_path("remove-kubernetes-cluster.sh")
        end
      end
    end

  end

end
