{% if flag?(:linux) %}
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
{% end %}
