include Generator_intf.GENERATOR with type 'a C.t = 'a Codelib.code

val print : 'a c t -> unit
val jit : 'a c t -> (size:int -> random:Splittable_random.State.t -> 'a)

val split_bool : bool c -> bool t

module MakeSplit(X : Splittable.S) : sig
    val split : X.t c -> X.f t
end