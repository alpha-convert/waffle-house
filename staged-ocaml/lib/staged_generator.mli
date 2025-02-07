include Generator_intf.GENERATOR

val print : 'a t -> unit
val jit : 'a t -> (size:int -> random:Splittable_random.State.t -> 'a)