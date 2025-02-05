open Codelib

include Generator_intf.GENERATOR with type 'a c = 'a code

val print : 'a t -> unit
val jit : 'a t -> 'a Base_quickcheck.Generator.t