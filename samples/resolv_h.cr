require "socket"

class Socket
  struct IPAddress
    def self.from(sockaddr : LibC::SockaddrIn*) : IPAddress
      new(sockaddr, sizeof(typeof(sockaddr)))
    end
  end
end

@[Link("resolv")]
lib LibResolv
  fun __res_init : Int32

  struct ResState
    nscount : Int32
    nsaddr_list : StaticArray(LibC::SockaddrIn, 3)
  end

  fun __res_state : Pointer(ResState)
end

def get_dns_server_list : Array(String)
  # Initialize resolver
  LibResolv.__res_init

  res_state = LibResolv.__res_state.value

  dns_servers = [] of String

  res_state.nsaddr_list.each do |addr|
    next if addr.sin_port == 0
    next if addr.sin_family == 0

    ip_string = Socket::IPAddress.from(pointerof(addr)).address
    dns_servers << ip_string
  end

  dns_servers
end

puts get_dns_server_list
