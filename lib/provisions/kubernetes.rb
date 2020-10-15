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
      @vip_port = self.assign_port
      @secure_port = 6443
      @pod_cidr = "10.244.0.0/16"
      @svc_cidr = "172.20.0.0/16"
    end

    def define_provisions(config, role, index)
      if role == "master" then
        self.define_haproxy_provisions(config, "#{self.category}-apiserver", @vip_port, @secure_port, self.select_hosts(role))
        self.define_keepalived_provisions(config, self.category, @vip, index, "/usr/bin/killall -0 haproxy", @@nic1)
        config.vm.provision "install-helm", type: "shell", run: "never" do |s|
          s.path = self.get_script_path("install-helm.sh")
        end
      end
      super
      config.vm.provision "install-kubernetes", type: "shell" do |s|
        s.path = self.get_script_path("install-kubernetes.sh")
      end
      if index == 0 then
        config.vm.provision "file", source: "./data/calico/custom-resources.yaml", destination: "/tmp/custom-resources.yaml"
        config.vm.provision "file", source: "./data/calico/tigera-operator.yaml", destination: "/tmp/tigera-operator.yaml"
        config.vm.provision "init-kubernetes-cluster", type: "shell" do |s|
          s.path = self.get_script_path("init-kubernetes-cluster.sh")
          s.args = ["#{self.category}:#{@vip_port}", @pod_cidr, @svc_cidr, @@nic1, self.select_hosts.join(' ')]
        end
        config.vm.provision "remove-kubernetes-cluster", type: "shell", run: "never" do |s|
          s.path = self.get_script_path("remove-kubernetes-cluster.sh")
        end
      end
    end

  end

end
