include Generator_intf.GENERATOR with type 'a C.t = 'a Codelib.code

val print : 'a c t -> unit
val jit : ?deps:string list -> 'a c t -> (size:int -> random:Splittable_random.State.t -> 'a)

val split_bool : bool c -> bool t
val split_list : 'a list c -> [`Nil | `Cons of 'a c * ('a list c)] t
val split_option : 'a option c -> [`None | `Some of 'a c] t
val split_pair : ('a * 'b) c -> ('a c * 'b c) t
val split_triple : ('a * 'b * 'c) c -> ('a c * 'b c * 'c c) t

module MakeSplit(X : Splittable.S) : sig
    val split : X.t c -> X.f t
end