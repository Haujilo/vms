module Provision
  class Base
    @@hosts_mapping = Hash.new
    @@domains_mapping = Hash.new

    @@nic0 = 'eth0'
    @@nic1 = 'eth1'

    # 00:50:56:00:00:00
    @@mac0 = 345040224256
    # 00:50:56:1f:80:00
    @@mac1 = 345042288640

    # 172.19.0.0/16
    @@gateway1 = 0b10101100000100110000000000000001
    @@netmask1 = 16
    @@dns = []

    @@INFRASTRUCTURE_NET = 1
    @@subnet = @@INFRASTRUCTURE_NET

    @@vip1 = @@gateway1
    @@ip1 = @@gateway1 + (@@subnet << (@@netmask1 / 2))

    @@port = 40000

    def set_hosts_mapping(hostname, ip, mac)
      @@hosts_mapping[hostname] = {
        "ip": ip,
        "mac": mac,
      }
    end

    def select_hosts(role=nil, category=nil)
      if category == nil then
        category = self.category
      end
      prefix = "#{category}-"
      if role != nil then
        prefix += "#{role}"
      end
      @@hosts_mapping.keys.select { |key| key.to_s.start_with? prefix }
    end

    def mac_to_s(mac)
      s = []
      i = 5
      while i >= 0 do
        s.push((mac >> (i * 8) & 0b11111111).to_s(16).rjust(2, '0'))
        i -= 1
      end
      s.join(':')
    end

    # https://docs.vmware.com/cn/VMware-vSphere/6.5/com.vmware.vsphere.networking.doc/GUID-ADFECCE5-19E7-4A81-B706-171E279ACBCD.html
    def assign_mac_addr()
      @@mac0 += 1
      if @@mac0 >= 345042288640 then
        raise "Mac address allocation is completed"
      end
      @@mac1 += 1
      if @@mac1 >= 345044418559 then
        raise "Mac address allocation is completed"
      end
      [mac_to_s(@@mac0), mac_to_s(@@mac1)]
    end

    def assign_port()
      if @@port == 65535 then
        raise "Port allocation is completed"
      end
      @@port += 1
    end

    def assign_ip_addr(start_ip)
      ip = start_ip + 1
      if (ip & 0b1111) == 0 then
        ip += 2
      elsif (ip & 0b1111) == 1 then
        ip += 1
      elsif (ip & 0b1111) == 255 then
        ip += 3
      elsif ip >= ((start_ip & 0xffffff00) + 255) then
        raise "IP address allocation is completed"
      end
      return ip
    end

    def ip_to_s(ip)
      "#{ip >> 24 & 0b11111111}.#{ip >> 16 & 0b11111111}.#{ip >> 8 & 0b11111111}.#{ip & 0b11111111}"
    end

    def assign_subnet()
      @@subnet += 1
      if @@subnet >= 255 then
        raise "IP address allocation is completed"
      end
      return @@subnet
    end

    def assign_vip_addr(domain=nil)
      @@vip1 = self.assign_ip_addr(@@vip1)
      ip = ip_to_s(@@vip1)
      if domain == nil then
        domain = self.category
      end
      @@domains_mapping[ip] = domain
      return ip
    end

    def assign_rip_addr(carry = false)
      if carry then
        @@ip1 = (@@ip1 & 0xffffff00) + (((@@ip1 & 0xff) / 10) + 1) * 10 - 1
      end
      @@ip1 = self.assign_ip_addr(@@ip1)
      ip_to_s(@@ip1)
    end

    def category()
      self.class.name.split('::').last.downcase
    end

    def init_network()
      subnet = self.assign_subnet
      if subnet != @@INFRASTRUCTURE_NET then
        @@ip1 = (@@gateway1 & (0xffffffff << (32 - @@netmask1) & 0xffffffff)) + (subnet << (@@netmask1 / 2)) + 9
      end
    end

    def initialize(cpus = 1, memory = 512, role_assigned = {"server"=>1})
      @cpus, @memory, @role_assigned = cpus, memory, role_assigned
      @amount = role_assigned.sum {|k, v| v }
      self.init_network
    end

    def get_script_path(filename)
      dirname = File.basename(caller_locations(1,1)[0].path, '.rb')
      "scripts/#{dirname}/#{filename}"
    end

    def global_define_provisions(config)
      config.vm.provision "bootstrap", type: "shell" do |s|
        s.path = "scripts/bootstrap.sh"
      end
    end

    def global_define_after_provisions(config)
      config.vm.provision "clean", type: "shell" do |s|
        s.path = "scripts/clean.sh"
      end
    end

    def define_provisions(config, role, index)
      config.vm.provision "build", type: "shell" do |s|
        s.path = self.get_script_path("build.sh")
        s.args = [@@dns.join(',')]
      end
      config.vm.provision "clean-for-dump", type: "shell", run: "never" do |s|
        s.path = self.get_script_path("clean.sh")
      end
    end

    def define(config)
      index = @amount
      category = self.category
      groups = {
        "#{category}" => [],
      }
      roles = []
      @role_assigned.each do |role, num|
        groups["#{category}-#{role}"] = []
        (1..num).each do |n|
          roles.push(role)
        end
      end
      _role = roles[-1]
      roles.reverse.each_with_index do |role, index|
        n = roles.length - index - 1
        mac0, mac1 = self.assign_mac_addr
        ip1 = self.assign_rip_addr(_role != role)
        _role = role
        vname = Utils::provider config, category, role, n, mac0, mac1, self.ip_to_s(@@ip1), @@netmask1, @@gateway1, @cpus, @memory do |node|
          self.global_define_provisions(node)
          self.define_provisions(node, role, n)
          self.global_define_after_provisions(node)
        end
        set_hosts_mapping(vname, ip1, mac1)
        groups[category].push vname
        groups["#{category}-#{role}"].push vname
      end
      return groups
    end

  end
end
