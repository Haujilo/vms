require_relative 'provisions/dhcp'
require_relative 'provisions/dnsmasq'
require_relative 'provisions/openldap'
require_relative 'provisions/nfs'
require_relative 'provisions/docker'
require_relative 'provisions/kubernetes'

module Provision

  extend self

  def define(config)
    groups = {}
    [
      DHCP.new.define(config),
      Dnsmasq.new.define(config),
      OpenLDAP.new.define(config),
      NFS.new.define(config),
      Docker.new.define(config),
      Kubernetes.new.define(config),
    ].each do |item|
      groups.merge!(item)
    end
    groups["infra"] = groups["dhcp"] | groups["dnsmasq"]
    return groups
  end

end
