include Generator_intf.GENERATOR with type 'a C.t = 'a Codelib.code

val print : 'a t -> unit
val jit : 'a t -> (size:int -> random:Splittable_random.State.t -> 'a)