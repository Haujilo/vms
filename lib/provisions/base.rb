module Provision
  class Base

    # 192.168.0.10/24
    @@vip = 0b11000000101010000000000000001010
    # 192.168.0.200/24
    @@ip = 0b11000000101010000000000011001000

    def assign_ip_addr(start_ip, max_ip)
      ip = start_ip + 1
      if (ip & 0b1111) == 0 then
        ip += 2
      elsif (ip & 0b1111) == 1 then
        ip += 1
      elsif (ip & 0b1111) == 255 then
        ip += 3
      elsif ip >= max_ip then
        raise "IP address allocation is completed"
      end
      return ip
    end

    def ip_to_s(ip)
      "#{ip >> 24 & 0b11111111}.#{ip >> 16 & 0b11111111}.#{ip >> 8 & 0b11111111}.#{ip & 0b11111111}"
    end

    def assign_vip_addr()
      @@vip = self.assign_ip_addr(@@vip, 0b11000000101010000000000001100100)
      ip_to_s(@@vip)
    end

    def assign_rip_addr()
      @@ip = self.assign_ip_addr(@@ip, 0b11000000101010000000000011111101)
      ip_to_s(@@ip)
    end

    def category()
      self.class.name.split('::').last.downcase
    end

    def initialize(cpus = 1, memory = 512, role_assigned = {"server"=>1})
      @cpus, @memory, @role_assigned = cpus, memory, role_assigned
      @amount = role_assigned.sum {|k, v| v }
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
      roles.reverse.each_with_index do |role, index|
        n = roles.length - index - 1
        vname = Utils::provider config, category, role, n, self.assign_rip_addr, @cpus, @memory do |node|
          self.global_define_provisions(node)
          self.define_provisions(node, role, n)
          self.global_define_after_provisions(node)
        end
        groups[category].push vname
        groups["#{category}-#{role}"].push vname
      end
      return groups
    end

  end
end
