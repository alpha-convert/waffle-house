include Generator_intf.GENERATOR with type 'a C.t = 'a Codelib.code

val print : 'a c t -> unit
val jit : 'a c t -> (size:int -> random:Splittable_random.State.t -> 'a)