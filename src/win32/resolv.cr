{% if flag?(:win32) %}
  require "../ext/lib_c/get_network_params"

  module Resolv
    # Port of Ruby's `Win32::Resolv.get_dns_server_list`
    # https://ruby-doc.org/stdlib-3.1.0/libdoc/win32/rdoc/Resolv.html#method-c-get_dns_server_list
    #
    # ```
    # Win32::Resolv.send(:get_dns_server_list)
    # => ["10.0.2.3"]
    # ```
    #
    # ```
    # Resolv.get_dns_server_list
    # => ["10.0.2.3"]
    # ```
    def self.get_dns_server_list : Array(String)
      buffer_size = Pointer(UInt32).malloc(1)
      buffer_size.value = 0

      # Initial call to determine buffer size
      ret = LibC.GetNetworkParams(nil, buffer_size)
      raise "Failed to get buffer size" unless ret == LibC::WIN32_ERROR::ERROR_BUFFER_OVERFLOW

      # Allocate buffer
      buffer = Pointer(LibC::FIXED_INFO_W2KSP1).malloc(buffer_size.value)

      # Call GetNetworkParams with the allocated buffer
      ret = LibC.GetNetworkParams(buffer, buffer_size)
      raise "Failed to get network parameters" unless ret == LibC::WIN32_ERROR::NO_ERROR

      dns_servers = [] of String
      ipaddr = buffer.value.dns_server_list

      loop do
        # Convert the IP address to a string by taking bytes up to the first null (0)
        ip_string = ipaddr.ip_address.string.take_while { |byte| byte != 0 }.map(&.chr).join

        dns_servers << ip_string unless ip_string.empty? || ip_string == "0.0.0.0"

        break if ipaddr.next.null?

        ipaddr = ipaddr.next.value
      end

      dns_servers
    end
  end
{% end %}
