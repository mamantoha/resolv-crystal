@[Link("resolv")]
lib LibResolv
  fun init = __res_init : Int32

  struct State
    nscount : Int32
    nsaddr_list : StaticArray(LibC::SockaddrIn, 3)
  end

  fun state = __res_state : Pointer(State)
end
