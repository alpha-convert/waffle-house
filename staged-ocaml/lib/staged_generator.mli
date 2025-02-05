open Codelib

include Generator_intf.GENERATOR with type 'a c = 'a code

val print : 'a t -> unit
val jit : 'a t -> 'a Base_quickcheck.Generator.t
(* type 'a t

val return : 'a -> 'a t
val bind : 'a t -> f:('a code -> 'b t) -> 'b t

val choose : (int code * 'a t) list -> 'a t

val int : lo:(int code) -> hi:(int code) -> int t
val bool : bool t

val size : int t
val with_size : 'a t -> size_c:(int code) -> 'a t

val to_qc : 'a t -> ('a Base_quickcheck.Generator.t) code
val to_fun : 'a t -> (size:int -> random:Splittable_random.State.t -> 'a) code
val jit : 'a t -> 'a Base_quickcheck.Generator.t

val print : 'a t -> unit

type ('a,'r) recgen
val recurse : ('a,'r) recgen -> 'r code -> 'a t
val recursive : 'r code -> (('a,'r) recgen -> 'r code -> 'a t) -> 'a t

end *)