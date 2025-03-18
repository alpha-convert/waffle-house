include Generator_intf.S with type 'a t = 'a Base_quickcheck.Generator.t with type 'a C.t = 'a with module R = Sr_random

val get_num_binds : unit -> int
val reset_bind_count : unit -> unit