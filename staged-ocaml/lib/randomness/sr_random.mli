include Random_intf.S with type t = Splittable_random.State.t

val bool' : t -> bool
val int' : t -> lo:int -> hi:int -> int