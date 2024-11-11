@[Link("iphlpapi")]
lib LibC
  struct IP_ADDR_STRING
    next : Pointer(IP_ADDR_STRING)
    ip_address : IP_ADDRESS_STRING
    ip_mask : IP_ADDRESS_STRING
    context : UInt32
  end

  struct IP_ADDRESS_STRING
    string : StaticArray(UInt8, 16)
  end

  # https://learn.microsoft.com/en-us/windows/win32/api/iptypes/ns-iptypes-fixed_info_w2ksp1
  struct FIXED_INFO_W2KSP1
    host_name : StaticArray(UInt8, 132)
    domain_name : StaticArray(UInt8, 132)
    current_dns_server : Pointer(IP_ADDR_STRING)
    dns_server_list : IP_ADDR_STRING
    node_type : UInt32
    scope_id : StaticArray(UInt8, 260)
    enable_routing : UInt32
    enable_proxy : UInt32
    enable_dns : UInt32
  end

  enum WIN32_ERROR : UInt32
    NO_ERROR              =   0
    ERROR_BUFFER_OVERFLOW = 111
  end

  fun GetNetworkParams(
    pfixedinfo : Pointer(FIXED_INFO_W2KSP1),
    poutbuflen : Pointer(UInt32),
  ) : WIN32_ERROR
end
