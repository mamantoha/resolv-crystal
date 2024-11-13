{% if flag?(:darwin) %}
  @[Link("resolv")]
  lib LibResolv
    fun ninit = res_9_ninit(Pointer(State)) : Int32
    fun nclose = res_9_nclose(Pointer(State)) : Void

    struct State
      nscount : Int32
      nsaddr_list : StaticArray(LibC::SockaddrIn, 3)
    end
  end
{% end %}
