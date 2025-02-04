open Codelib

type 'a t

val return : 'a code -> 'a t
val bind : 'a t -> f:('a code -> 'b t) -> 'b t

val choose : (int code * 'a t) list -> 'a t

val int : lo:(int code) -> hi:(int code) -> int t
val bool : bool t

(*
(*
we could change these to not expose the "code" by changin the return type of RandGen to a ('a Code.t) CodeGen.t, but then we'd lose
the monad instance above, and hence the ability to use let syntax.
*)
val choose : (int Code.t * 'a t) -> (int Code.t * 'a t) -> 'a t
val with_size : 'a t -> size_c:(int Code.t) -> 'a t
val size : (int Code.t) t

val to_qc : ('a Code.t) t -> ('a Base_quickcheck.Generator.t) Code.t

type 'a recgen
val recurse : 'a recgen -> 'a Code.t t
val recursive : ('a recgen -> ('a Code.t t)) -> ('a Base_quickcheck.Generator.t) Code.t

val gen_if : (bool Code.t) -> 'a t -> 'a t -> 'a t

include Core.Monad.S with type 'a t := 'a t

*)