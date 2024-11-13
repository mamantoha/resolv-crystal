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
  fun init = __res_init : Int32
  fun ninit = __res_ninit(Pointer(State)) : Int32
  fun nclose = __res_nclose(Pointer(State)) : Void

  struct State
    nscount : Int32
    nsaddr_list : StaticArray(LibC::SockaddrIn, 3)
  end

  fun state = __res_state : Pointer(State)
end

def get_dns_server_list : Array(String)
  # Initialize resolver
  LibResolv.init
  state = LibResolv.state.value

  # state_ptr = Pointer(LibResolv::State).malloc(sizeof(LibResolv::State))
  # LibResolv.ninit(state_ptr)
  # state = state_ptr.value
  # LibResolv.nclose(state_ptr)

  p! state

  dns_servers = [] of String

  state.nsaddr_list.each do |addr|
    next if addr.sin_port == 0
    next if addr.sin_family == 0

    ip_string = Socket::IPAddress.from(pointerof(addr)).address
    dns_servers << ip_string
  end

  dns_servers
end

puts get_dns_server_list
