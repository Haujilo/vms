require_relative 'provisions/openldap'
require_relative 'provisions/nfs'
require_relative 'provisions/docker'
require_relative 'provisions/kubernetes'

module Provision

  extend self

  def define(config)
    groups = {}
    [
      OpenLDAP.new.define(config),
      NFS.new.define(config),
      Docker.new.define(config),
      Kubernetes.new.define(config),
    ].each do |item|
      groups.merge!(item)
    end
    return groups
  end

end
