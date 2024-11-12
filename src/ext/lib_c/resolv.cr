@[Link("resolv")]
lib LibResolv
  fun __res_init : Int32

  struct ResState
    nscount : Int32
    nsaddr_list : StaticArray(LibC::SockaddrIn, 3)
  end

  fun __res_state : Pointer(ResState)
end
