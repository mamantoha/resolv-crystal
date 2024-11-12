require "socket"

class Socket
  struct IPAddress
    def self.from(sockaddr : LibC::SockaddrIn*) : IPAddress
      new(sockaddr, sizeof(typeof(sockaddr)))
    end
  end
end
