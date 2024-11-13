{% if flag?(:linux) %}
  require "../../ext/lib_c/linux/lib_resolv"

  module Resolv
    def self.get_dns_server_list : Array(String)
      res = LibResolv.init

      raise "Failed to initialize libresolv" unless res == 0

      res_state = LibResolv.state.value

      dns_servers = [] of String

      res_state.nsaddr_list.each do |addr|
        next if addr.sin_port == 0
        next if addr.sin_family == 0

        ip_string = Socket::IPAddress.from(pointerof(addr)).address
        dns_servers << ip_string
      end

      dns_servers
    end
  end
{% end %}
