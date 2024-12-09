type t = Leaf | Node of t * int * int * t

val insert : int -> int -> t -> t
val find : int -> t -> int option

val g_basic : t Base_quickcheck.Generator.t
val g_insert_input : (int * int * t) Base_quickcheck.Generator.t

val g_fast : t Base_quickcheck.Generator.t
val g_insert_input_fast : (int * int * t) Base_quickcheck.Generator.t

val g_insert_post_input_fast : (int * int * int * t) Base_quickcheck.Generator.t
val g_insert_post_input : (int * int * int * t) Base_quickcheck.Generator.t



val shrink : t Base_quickcheck.Shrinker.t

val invariant : t -> unit

exception InvariantFail