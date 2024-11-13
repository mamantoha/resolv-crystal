{% if flag?(:darwin) %}
  require "../../ext/lib_c/darwin/lib_resolv"

  module Resolv
    def self.get_dns_server_list : Array(String)
      state_ptr = Pointer(LibResolv::State).malloc(sizeof(LibResolv::State))
      LibResolv.ninit(state_ptr)
      state = state_ptr.value
      LibResolv.nclose(state_ptr)

      dns_servers = [] of String

      state.nsaddr_list.each do |addr|
        next if addr.sin_port == 0
        next if addr.sin_family == 0

        ip_string = Socket::IPAddress.from(pointerof(addr)).address
        dns_servers << ip_string
      end

      dns_servers
    end
  end
{% end %}
